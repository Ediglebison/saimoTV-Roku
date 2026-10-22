sub init()
    m.top.functionName = "runTask"
end sub

sub runTask()
    url = m.top.url.Trim()
    if url = "" then
        m.top.error = "Nenhuma URL de EPG configurada."
        return
    end if

    response = httpGet(url, m.top.userAgent, "")
    if not response.ok then
        m.top.error = "Nao foi possivel baixar o EPG: " + response.error
        return
    end if

    text = response.body
    if text = invalid or text = "" then
        m.top.error = "O EPG veio vazio."
        return
    end if
    if looksLikeHtml(text) then
        m.top.error = "O endereco do EPG retornou uma pagina HTML."
        return
    end if

    text = text.Replace("><", ">" + Chr(10) + "<")
    now = getNowSeconds()
    epg = {}
    current = invalid
    count = 0

    for each raw in text.Split(Chr(10))
        line = raw.Trim()
        if line = "" then
            ' vazio
        else if Instr(1, line, "<programme") > 0 then
            current = {
                channel: epgTagAttr(line, "channel")
                start: xmltvEpoch(epgTagAttr(line, "start"))
                stop: xmltvEpoch(epgTagAttr(line, "stop"))
                title: ""
            }
            if Instr(1, line, "<title") > 0 then
                current.title = xmltvTagValue(line)
                storeProgram(epg, current, now)
                count = count + 1
                current = invalid
            end if
        else if current <> invalid and Instr(1, line, "<title") > 0 then
            current.title = xmltvTagValue(line)
            if current.channel <> "" and current.start > 0 then
                storeProgram(epg, current, now)
                count = count + 1
            end if
            current = invalid
        end if
    end for

    if count = 0 then
        m.top.error = "O EPG nao possui programas reconheciveis."
        return
    end if

    m.top.resultJson = FormatJson(epg)
    m.top.count = count
    m.top.success = true
end sub

sub storeProgram(epg as object, program as object, now as integer)
    if program.channel = "" or program.title = "" then return
    entry = epg[program.channel]
    if entry = invalid then
        entry = {
            nowTitle: ""
            nowStart: 0
            nowStop: 0
            nextTitle: ""
            nextStart: 0
        }
        epg[program.channel] = entry
    end if

    if program.start <= now and program.stop > now then
        entry.nowTitle = program.title
        entry.nowStart = program.start
        entry.nowStop = program.stop
    else if program.start > now then
        if entry.nextStart = 0 or program.start < entry.nextStart then
            entry.nextTitle = program.title
            entry.nextStart = program.start
        end if
    end if
end sub

function getNowSeconds() as integer
    dt = CreateObject("roDateTime")
    dt.Mark()
    return dt.AsSeconds()
end function

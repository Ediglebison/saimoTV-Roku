' ====================================================================
' Saimo TV - SearchScreen (BrightScript)
' Teclado de letras à esquerda e resultados por fileira, como na TV Box.
' ====================================================================

sub init()
    m.campo = m.top.findNode("campo")
    m.teclas = m.top.findNode("teclas")
    m.resultados = m.top.findNode("resultados")
    m.dica = m.top.findNode("dica")
    m.buscaTimer = m.top.findNode("buscaTimer")
    m.texto = ""
    m.canais = invalid
    if m.canais = invalid then m.canais = m.top.channels
    m.titulos = invalid
    if m.titulos = invalid then m.titulos = m.top.vodItems
    m.searchIndex = invalid
    m.indiceDesatualizado = false
    m.buscaRemotaPendente = false
    m.buscaRemotaTask = invalid

    raiz = CreateObject("roSGNode", "ContentNode")
    for each t in "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9".Split(" ")
        raiz.CreateChild("ContentNode").title = t
    end for
    for each t in ["espaço", "apagar", "limpar"]
        raiz.CreateChild("ContentNode").title = t
    end for
    m.teclas.content = raiz
    m.teclas.observeField("itemSelected", "onTecla")
    m.resultados.observeField("rowItemSelected", "onResultado")
    m.top.observeField("focusedChild", "onFocusedChildChange")
    if m.buscaTimer <> invalid then m.buscaTimer.observeField("fire", "onBuscaTimerFire")
    carregarIndice()
end sub

sub onFocusedChildChange()
    if m.top.isInFocusChain() and not m.teclas.isInFocusChain() and not m.resultados.isInFocusChain() then
        m.teclas.setFocus(true)
    end if
end sub

sub onTecla()
    t = m.teclas.content.getChild(m.teclas.itemSelected).title
    if t = "espaço" then
        m.texto = m.texto + " "
    else if t = "apagar" then
        if Len(m.texto) > 0 then m.texto = Left(m.texto, Len(m.texto) - 1)
    else if t = "limpar" then
        m.texto = ""
    else
        m.texto = m.texto + LCase(t)
    end if
    m.campo.text = m.texto
    buscar()
    agendarBusca()
end sub

sub buscar()
    query = m.texto.Trim()
    if query = "" then
        m.resultados.content = invalid
        m.dica.visible = true
        m.dica.text = "Digite o nome: os resultados aparecem enquanto você digita."
        return
    end if

    if m.canais = invalid then m.canais = m.top.channels
    if m.titulos = invalid then m.titulos = m.top.vodItems

    raiz = CreateObject("roSGNode", "ContentNode")

    ' Canais (cap 30 por fileira)
    canais = invalid
    if m.canais <> invalid then
        for each ch in m.canais
            if Instr(1, foldText(ch.name), foldText(query)) > 0 then
                if canais = invalid then
                    canais = raiz.CreateChild("ContentNode")
                    canais.title = "Canais"
                end if
                no = canais.CreateChild("ContentNode")
                no.title = ch.name
                if ch.logo <> invalid then no.hdPosterUrl = ch.logo
                no.addFields({ itemType: "channel", item: ch })
                if canais.getChildCount() >= 30 then exit for
            end if
        end for
    end if

    ' Filmes e séries via indice local, resolvendo capa pelo titulo injetado
    titulos = invalid
    if m.searchIndex <> invalid then
        resultadosIndice = searchSaimoIndex(m.searchIndex, query, 160)
        totalVod = 0
        for each hit in resultadosIndice
            if totalVod >= 30 then exit for
            matched = invalid
            if m.titulos <> invalid then
                for each it in m.titulos
                    if it.title = hit.title then
                        matched = it
                        exit for
                    end if
                end for
            end if

            payload = invalid
            posterUrl = ""
            if matched <> invalid then
                payload = matched
                if matched.poster <> invalid then posterUrl = matched.poster
                if posterUrl = "" and matched.backdrop <> invalid then posterUrl = matched.backdrop
            else
                isSeries = (hit.type = "series")
                payload = { title: hit.title, letter: hit.letter, year: hit.year, isSeries: isSeries }
            end if

            if titulos = invalid then
                titulos = raiz.CreateChild("ContentNode")
                titulos.title = "Filmes e séries"
            end if
            no = titulos.CreateChild("ContentNode")
            no.title = hit.title
            if posterUrl <> "" then no.hdPosterUrl = posterUrl
            no.addFields({ itemType: "vod", item: payload })
            totalVod = totalVod + 1
        end for
    end if

    if raiz.getChildCount() = 0 then
        m.dica.visible = true
        m.dica.text = "Nada encontrado."
    else
        m.dica.visible = false
    end if
    AjustarFileiras(m.resultados, raiz)
    m.resultados.content = raiz
end sub

sub carregarIndice()
    raw = readCacheAscii("cachefs:/saimo_search_index.json")
    parsed = invalid
    if isStringValue(raw) and raw <> "" then
        parsed = ParseJson(raw)
        if type(parsed) <> "roAssociativeArray" then parsed = invalid
        if parsed <> invalid then
            if parsed.folded = invalid or parsed.payload = invalid then parsed = invalid
        end if
    end if
    if parsed <> invalid then m.searchIndex = parsed

    nowSeconds = CreateObject("roDateTime").AsSeconds()
    indexTimeRaw = readCacheAscii("cachefs:/saimo_search_index.time")
    stale = true
    if isStringValue(indexTimeRaw) and indexTimeRaw <> "" then
        indexTime = Val(indexTimeRaw.Trim())
        age = nowSeconds - indexTime
        if age >= 0 and age < 86400 then stale = false
    end if
    if stale or m.searchIndex = invalid then
        m.indiceDesatualizado = true
        agendarBusca()
    else
        m.indiceDesatualizado = false
    end if
end sub

sub agendarBusca()
    ' Agendamento on-demand do busca.txt remoto. So agenda quando o indice
    ' esta ausente ou desatualizado; os resultados locais permanecem instantaneos.
    if m.searchIndex <> invalid and m.indiceDesatualizado = false then return
    m.buscaRemotaPendente = true
    if m.buscaTimer <> invalid then
        m.buscaTimer.control = "stop"
        m.buscaTimer.control = "start"
    end if
end sub

sub onBuscaTimerFire()
    m.buscaRemotaPendente = false
    if m.buscaTimer <> invalid then m.buscaTimer.control = "stop"
    base = ReadSaimoKey("vodUrl")
    if base = "" then base = "https://filmes-saimo.pages.dev/"
    lowBase = LCase(base)
    if Instr(1, lowBase, "filmes-saimo.pages.dev") = 0 and Instr(1, lowBase, "saimoplayer") = 0 then
        ' Mantem base configurada; DataLoaderTask normaliza.
    end if
    task = CreateObject("roSGNode", "DataLoaderTask")
    task.requestType = "saimo_search_index"
    task.mode = "saimo_search_index"
    task.baseUrl = base
    task.requestUrl = base
    task.url = base
    task.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    m.buscaRemotaTask = task
    task.observeField("success", "onBuscaRemotaDone")
    task.control = "RUN"
end sub

sub onBuscaRemotaDone()
    evt = m.buscaRemotaTask
    m.buscaRemotaPendente = false
    m.buscaRemotaTask = invalid
    carregarIndice()
    if m.texto.Trim() <> "" then buscar()
end sub

sub onResultado()
    c = m.resultados.rowItemSelected
    no = m.resultados.content.getChild(c[0]).getChild(c[1])
    if no.itemType = "channel" then
        m.top.tuneRequested = no.item
    else
        m.top.itemSelected = no.item
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if m.resultados.isInFocusChain() then
        if key = "left" or key = "back" then
            m.teclas.setFocus(true)
            return true
        end if
        return false
    end if

    if key = "right" and m.resultados.content <> invalid then
        m.resultados.setFocus(true)
        return true
    else if key = "up" then
        m.top.focusUpRequested = true
        return true
    end if
    return false
end function

sub cleanUp()
    if m.buscaTimer <> invalid then m.buscaTimer.control = "stop"
    m.buscaRemotaTask = invalid
end sub
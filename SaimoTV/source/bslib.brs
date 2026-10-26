' Funcoes compartilhadas entre a cena principal e as tarefas.
' Nada aqui depende de estado da interface.

function isStringValue(value as dynamic) as boolean
    if value = invalid then return false
    valueType = type(value)
    return valueType = "roString" or valueType = "String"
end function

function strField(obj as object, key as string) as string
    if obj = invalid then return ""
    value = obj[key]
    if value = invalid then return ""
    if isStringValue(value) then return value
    return value.ToStr()
end function

function boolField(obj as object, key as string, fallback as boolean) as boolean
    if obj = invalid then return fallback
    value = obj[key]
    if value = invalid then return fallback
    if type(value) = "roBoolean" then return value
    return fallback
end function

function trimText(value as dynamic) as string
    if value = invalid then return ""
    return value.ToStr().Trim()
end function

' cachefs comeca vazio em uma instalacao nova. Verifica antes de ler para que
' misses normais de cache nao gerem erros no console do Roku/simulador.
function readCacheAscii(path as string) as string
    fs = CreateObject("roFileSystem")
    ' Alguns simuladores nao implementam roFileSystem; nesses casos mantem a
    ' leitura normal e o cache funcional em vez de tratar tudo como ausente.
    if fs <> invalid and not fs.Exists(path) then return ""
    value = ReadAsciiFile(path)
    if value = invalid then return ""
    return value
end function

function isValidUrl(url as string) as boolean
    if url = invalid then return false
    u = url.Trim()
    if u = "" then return false
    low = LCase(u)
    if Left(low, 7) = "http://" then return true
    if Left(low, 8) = "https://" then return true
    return false
end function

function isDeadUrl(url as string) as boolean
    if url = invalid then return true
    low = LCase(url)
    if Instr(1, low, "desativado.invalid") > 0 then return true
    if Instr(1, low, "/error.txt") > 0 then return true
    if Instr(1, low, ".html") > 0 then return true
    if Left(low, 11) = "javascript:" then return true
    if Left(low, 5) = "data:" then return true
    return false
end function

function streamFormatFor(url as string, live as boolean) as string
    low = LCase(url)
    if Instr(1, low, ".m3u8") > 0 then return "hls"
    if Instr(1, low, ".txt") > 0 then return "hls"
    if Instr(1, low, ".mpd") > 0 then return "dash"
    if Instr(1, low, ".mp4") > 0 then return "mp4"
    if Instr(1, low, ".m4v") > 0 then return "mp4"
    if Instr(1, low, ".mkv") > 0 then return "mkv"
    if Instr(1, low, ".ts") > 0 then return "hls"
    if live then return ""
    return ""
end function

function hostFromUrl(url as string) as string
    if url = invalid then return ""
    text = url.Trim()
    low = LCase(text)
    start = 0
    if Left(low, 8) = "https://" then
        start = 9
    else if Left(low, 7) = "http://" then
        start = 8
    end if
    if start = 0 then return ""
    rest = Mid(text, start, Len(text) - start + 1)
    slash = Instr(1, rest, "/")
    if slash > 0 then rest = Left(rest, slash - 1)
    return rest.Trim()
end function

function makeSource(url as string, referer as string, userAgent as string, name as string, quality as string, live as boolean) as object
    u = url.Trim()
    return {
        url: u
        referer: referer
        userAgent: userAgent
        name: name
        quality: quality
        streamFormat: streamFormatFor(u, live)
        isLive: live
    }
end function

function buildVideoHeaders(source as object, defaultUA as string) as object
    headers = []
    headers.Push("Accept:*/*")
    referer = strField(source, "referer")
    ua = strField(source, "userAgent")
    if ua = "" then ua = defaultUA

    ' Use somente os cabecalhos declarados na propria fonte autorizada.
    ' Nao injeta referers de terceiros nem tenta contornar hotlinking por dominio.
    if referer <> "" then headers.Push("Referer:" + referer)
    if ua <> "" then headers.Push("User-Agent:" + ua)
    return headers
end function

function httpGet(url as string, userAgent as string, referer as string) as object
    result = { ok: false, body: "", code: 0, error: "" }
    if not isValidUrl(url) then
        result.error = "Endereco invalido."
        return result
    end if

    port = CreateObject("roMessagePort")
    transfer = CreateObject("roUrlTransfer")
    transfer.SetPort(port)
    transfer.SetURL(url)
    if Left(LCase(url), 8) = "https://" then
        transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
        transfer.InitClientCertificates()
    end if
    if userAgent <> "" then transfer.AddHeader("User-Agent", userAgent)
    transfer.AddHeader("Accept", "*/*")
    if referer <> "" then transfer.AddHeader("Referer", referer)

    if not transfer.AsyncGetToString() then
        result.error = "Nao foi possivel iniciar a requisicao HTTP."
        return result
    end if

    message = wait(30000, port)
    if message = invalid or type(message) <> "roUrlEvent" then
        result.error = "Tempo limite esgotado (30 s)."
        return result
    end if

    code = message.GetResponseCode()
    result.code = code
    if code <= 0 then
        failure = message.GetFailureReason()
        if failure = invalid or failure = "" then failure = "Falha de rede (" + Str(code).Trim() + ")."
        result.error = failure
        return result
    end if
    if code < 200 or code >= 400 then
        result.error = "HTTP " + Str(code).Trim()
        return result
    end if

    body = message.GetString()
    if body = invalid then
        result.error = "O servidor nao retornou conteudo."
        return result
    end if

    result.body = body
    result.ok = true
    return result
end function

function looksLikeHtml(text as string) as boolean
    if text = invalid or text = "" then return false
    sample = LCase(Left(text.Trim(), 240))
    if Instr(1, sample, "<!doctype html") > 0 then return true
    if Instr(1, sample, "<html") > 0 then return true
    if Instr(1, sample, "<head") > 0 then return true
    return false
end function

' ---------------------------------------------------------------------------
' Enderecos e utilidades do catalogo Saimo
' ---------------------------------------------------------------------------

function normalizeSaimoBase(value as string) as string
    base = value.Trim()
    if base = "" then return ""
    low = LCase(base)
    if Right(low, 10) = "indice.txt" then base = Left(base, Len(base) - 10)
    if Right(base, 1) <> "/" then base = base + "/"
    return base
end function

function isSaimoVodUrl(url as string) as boolean
    low = LCase(url.Trim())
    if Instr(1, low, "saimo-filmes.pages.dev") > 0 then return true
    if Instr(1, low, "filmes-saimo.pages.dev") > 0 then return true
    if Instr(1, low, "saimoplayer/main/vod") > 0 then return true
    return false
end function

function saimoBaseUrl(url as string) as string
    base = url.Trim()
    low = LCase(base)
    if Instr(1, low, "saimo-filmes.pages.dev") > 0 or Instr(1, low, "filmes-saimo.pages.dev") > 0 or Instr(1, low, "saimoplayer/main/vod") > 0 then
        ' Hosts publicos e aliases antigos apontam para a mesma raiz oficial.
        base = "https://saimo-filmes.pages.dev/"
    end if
    return normalizeSaimoBase(base)
end function

function isSaimoCatalogUrl(url as string) as boolean
    low = LCase(url.Trim())
    if Instr(1, low, "saimo-canais.pages.dev") > 0 then return true
    if Instr(1, low, "canais-saimo.pages.dev") > 0 then return true
    if Instr(1, low, "raw.githubusercontent.com/gabrielsaimo/saimoplayer/main/catalogo.txt") > 0 then return true
    return false
end function

function saimoLetterCacheMarker(base as string, signature as string) as string
    return base.Trim() + "|" + signature.Trim()
end function

function saimoLetterCachePath(filter as string, letter as string) as string
    safeLetter = letter
    if letter = "#" then safeLetter = "hash"
    return "cachefs:/saimo_letter_" + filter + "_" + safeLetter + ".json"
end function

' Assinatura estavel do indice. Quando ela muda, letras, busca e capas
' derivadas do catalogo precisam ser descartadas.
function saimoIndexSignature(letters as object, bases as object) as string
    parts = []
    if type(letters) = "roArray" then
        for each row in letters
            parts.Push(strField(row, "letter") + ":" + Str(Val(strField(row, "moviesCount"))).Trim() + ":" + Str(Val(strField(row, "seriesCount"))).Trim() + ":" + Str(Val(strField(row, "extraCount"))).Trim())
        end for
    end if
    parts.Push("@bases")
    if type(bases) = "roAssociativeArray" then
        keys = bases.Keys()
        keys.Sort()
        for each key in keys
            parts.Push(key + "=" + strField(bases, key))
        end for
    end if
    signature = ""
    for each part in parts
        if signature <> "" then signature = signature + ";"
        signature = signature + part
    end for
    return signature
end function

function foldText(value as string) as string
    text = LCase(value.Trim())
    text = text.Replace("á", "a").Replace("à", "a").Replace("â", "a").Replace("ã", "a").Replace("ä", "a").Replace("å", "a")
    text = text.Replace("é", "e").Replace("è", "e").Replace("ê", "e").Replace("ë", "e")
    text = text.Replace("í", "i").Replace("ì", "i").Replace("î", "i").Replace("ï", "i")
    text = text.Replace("ó", "o").Replace("ò", "o").Replace("ô", "o").Replace("õ", "o").Replace("ö", "o")
    text = text.Replace("ú", "u").Replace("ù", "u").Replace("û", "u").Replace("ü", "u")
    text = text.Replace("ç", "c").Replace("ñ", "n").Replace("ý", "y").Replace("ÿ", "y")
    return text
end function

' Comentarios do catalogo usam "# " ou "#\t". Titulos reais podem comecar
' com "#" colado, como "#Alive (2020)", e nao devem ser descartados.
function isSaimoComment(value as string) as boolean
    line = value.Trim()
    if Left(line, 1) <> "#" then return false
    if Len(line) = 1 then return true
    second = Mid(line, 2, 1)
    if second = " " or second = Chr(9) then return true
    return false
end function

' ---------------------------------------------------------------------------
' M3U
' ---------------------------------------------------------------------------

function m3uAttr(line as string, name as string) as string
    needle = name + "=" + Chr(34)
    start = Instr(1, line, needle)
    if start = 0 then
        needle = name + "=" + Chr(39)
        start = Instr(1, line, needle)
        if start = 0 then return ""
    end if
    start = start + Len(needle)
    rest = Mid(line, start, Len(line) - start + 1)
    quote = Chr(34)
    if Instr(1, rest, Chr(39)) > 0 and Instr(1, rest, quote) = 0 then quote = Chr(39)
    finish = Instr(1, rest, quote)
    if finish = 0 then return rest.Trim()
    return Left(rest, finish - 1).Trim()
end function

function m3uTitleAfterLastComma(line as string) as string
    quoted = false
    comma = 0
    i = 1
    while i <= Len(line)
        c = Mid(line, i, 1)
        if c = Chr(34) then
            if quoted then
                quoted = false
            else
                quoted = true
            end if
        else if c = "," and not quoted then
            comma = i
        end if
        i = i + 1
    end while
    if comma = 0 then return ""
    return Mid(line, comma + 1, Len(line) - comma).Trim()
end function

function parseM3u(text as string, defaultUA as string) as object
    out = []
    byKey = {}
    current = invalid

    for each raw in text.Split(Chr(10))
        line = raw.Trim()
        if line = "" or line = "#EXTM3U" then
            ' vazio
        else if Left(UCase(line), 7) = "#EXTINF" then
            title = m3uTitleAfterLastComma(line)
            logo = m3uAttr(line, "tvg-logo")
            group = m3uAttr(line, "group-title")
            tvgId = m3uAttr(line, "tvg-id")
            if title = "" then title = "Canal"
            if group = "" then group = "Canais"
            current = {
                title: title
                logo: logo
                group: group
                tvgId: tvgId
                sources: []
            }
        else if Left(UCase(line), 8) = "#EXTGRP:" then
            if current <> invalid then
                value = Mid(line, 9, Len(line) - 8).Trim()
                if value <> "" then current.group = value
            end if
        else if Left(line, 1) = "#" then
            ' metadado ignorado
        else
            if current <> invalid and isValidUrl(line) and not isDeadUrl(line) then
                src = makeSource(line, "", defaultUA, "", "", true)
                current.sources.Push(src)
                key = current.tvgId
                if key = "" then key = current.title + "|" + current.group
                existing = byKey[key]
                if existing = invalid then
                    byKey[key] = current
                    out.Push(current)
                else if existing <> current then
                    existing.sources.Push(src)
                end if
            end if
        end if
    end for

    return out
end function

' ---------------------------------------------------------------------------
' Catalogo no formato Saimo: canal:, fonte:, referer:, agente:, chave:
' ---------------------------------------------------------------------------

sub flushCustomChannel(out as object, name as string, logo as string, group as string, sources as object)
    if name = "" or sources.Count() = 0 then return
    valid = []
    for each src in sources
        if src.url <> invalid and isValidUrl(src.url) and not isDeadUrl(src.url) then
            if src.drm <> true then valid.Push(src)
        end if
    end for
    if valid.Count() = 0 then return

    g = group
    if g = "" then g = "Canais"
    out.Push({
        title: name
        logo: logo
        group: g
        tvgId: ""
        sources: valid
    })
end sub

function parseCustom(text as string, defaultUA as string) as object
    out = []
    name = ""
    logo = ""
    group = "Canais"
    sources = []

    for each raw in text.Split(Chr(10))
        line = raw.Trim()
        if line = "" or Left(line, 1) = "#" then
            ' vazio/comentario
        else
            colon = Instr(1, line, ":")
            if colon > 1 then
                field = LCase(Left(line, colon - 1).Trim())
                value = Mid(line, colon + 1, Len(line) - colon).Trim()
                if value <> "" then
                    if field = "canal" then
                        flushCustomChannel(out, name, logo, group, sources)
                        name = value
                        logo = ""
                        group = "Canais"
                        sources = []
                    else if field = "logo" then
                        logo = value
                    else if field = "categoria" or field = "grupo" then
                        group = value
                    else if field = "fonte" then
                        sources.Push(makeSource(value, "", "", "", "", true))
                    else if sources.Count() > 0 then
                        last = sources[sources.Count() - 1]
                        if field = "nome" then
                            last.name = value
                        else if field = "qualidade" then
                            last.quality = value
                        else if field = "referer" then
                            last.referer = value
                        else if field = "agente" then
                            last.userAgent = value
                        else if field = "chave" then
                            last.drm = true
                        end if
                    end if
                end if
            end if
        end if
    end for

    flushCustomChannel(out, name, logo, group, sources)
    return out
end function

function parsePlaylist(text as string) as object
    if text = invalid or text.Trim() = "" then return []
    trimmed = text.Trim()
    if Left(UCase(trimmed), 7) = "#EXTM3U" then return parseM3u(text, "")
    if Instr(1, LCase(trimmed), "canal:") > 0 then return parseCustom(text, "")
    if Instr(1, UCase(trimmed), "#EXTINF") > 0 then return parseM3u(text, "")
    return []
end function

' ---------------------------------------------------------------------------
' Catalogo VOD autorizado em M3U
' ---------------------------------------------------------------------------

function isDigitChar(value as string) as boolean
    if value = "" then return false
    return Instr(1, "0123456789", value) > 0
end function

function cleanVodTitle(value as string) as string
    result = value.Trim()
    while Len(result) > 0
        first = Left(result, 1)
        if Instr(1, " -_.:|[]()", first) = 0 then exit while
        result = Mid(result, 2, Len(result) - 1).Trim()
    end while
    while Len(result) > 0
        last = Right(result, 1)
        if Instr(1, " -_.:|[]()", last) = 0 then exit while
        result = Left(result, Len(result) - 1).Trim()
    end while
    return result
end function

function episodeInfo(title as string) as object
    t = title.Trim()
    info = { isEpisode: false, seriesName: t, episodeTitle: t, season: 0, episode: 0 }

    ' Formatos habituais: S01E02, T01E02, 1x02.
    i = 1
    while i <= Len(t) - 4
        marker = UCase(Mid(t, i, 1))
        if marker = "S" or marker = "T" then
            j = i + 1
            seasonStart = j
            while j <= Len(t) and isDigitChar(Mid(t, j, 1))
                j = j + 1
            end while
            if j > seasonStart and j <= Len(t) and UCase(Mid(t, j, 1)) = "E" then
                seasonText = Mid(t, seasonStart, j - seasonStart)
                j = j + 1
                episodeStart = j
                while j <= Len(t) and isDigitChar(Mid(t, j, 1))
                    j = j + 1
                end while
                if j > episodeStart then
                    info.isEpisode = true
                    info.season = Val(seasonText)
                    info.episode = Val(Mid(t, episodeStart, j - episodeStart))
                    info.seriesName = cleanVodTitle(Left(t, i - 1))
                    suffix = Mid(t, j, Len(t) - j + 1).Trim()
                    label = "S" + twoDigit(info.season) + "E" + twoDigit(info.episode)
                    if suffix <> "" then label = label + "  •  " + cleanVodTitle(suffix)
                    info.episodeTitle = label
                    return info
                end if
            end if
        end if
        i = i + 1
    end while

    i = 1
    while i <= Len(t) - 2
        if isDigitChar(Mid(t, i, 1)) then
            seasonStart = i
            j = i
            while j <= Len(t) and isDigitChar(Mid(t, j, 1))
                j = j + 1
            end while
            if j <= Len(t) and LCase(Mid(t, j, 1)) = "x" then
                seasonText = Mid(t, seasonStart, j - seasonStart)
                j = j + 1
                episodeStart = j
                while j <= Len(t) and isDigitChar(Mid(t, j, 1))
                    j = j + 1
                end while
                if j > episodeStart and seasonStart > 1 then
                    info.isEpisode = true
                    info.season = Val(seasonText)
                    info.episode = Val(Mid(t, episodeStart, j - episodeStart))
                    info.seriesName = cleanVodTitle(Left(t, seasonStart - 1))
                    suffix = Mid(t, j, Len(t) - j + 1).Trim()
                    label = "S" + twoDigit(info.season) + "E" + twoDigit(info.episode)
                    if suffix <> "" then label = label + "  •  " + cleanVodTitle(suffix)
                    info.episodeTitle = label
                    return info
                end if
            end if
            i = j
        else
            i = i + 1
        end if
    end while
    return info
end function

function twoDigit(value as integer) as string
    result = Str(value).Trim()
    if value >= 0 and value < 10 then result = "0" + result
    return result
end function

sub sortVodEpisodes(series as object)
    if series = invalid or type(series.episodes) <> "roArray" then return
    if series.episodes.Count() < 2 then return

    keys = []
    byEpisode = {}
    for each episode in series.episodes
        seasonKey = Right("000" + Str(episode.season).Trim(), 3)
        episodeKey = Right("0000" + Str(episode.episode).Trim(), 4)
        key = seasonKey + ":" + episodeKey
        if byEpisode[key] = invalid then
            byEpisode[key] = episode
            keys.Push(key)
        end if
    end for
    keys.Sort()

    sorted = []
    for each key in keys
        sorted.Push(byEpisode[key])
    end for
    series.episodes = sorted
end sub

function isRestrictedVod(title as string, groupName as string) as boolean
    t = LCase(title)
    g = LCase(groupName)
    groupMarkers = ["adulto", "adult", "xxx", "porn", "erotico", "erótico", "18+"]
    titleMarkers = ["xxx", "pornografia", "pornográfico", "pornografico", "erótico", "erotico", "onlyfans", "camgirl"]
    for each marker in groupMarkers
        if Instr(1, g, marker) > 0 then return true
    end for
    for each marker in titleMarkers
        if Instr(1, t, marker) > 0 then return true
    end for
    return false
end function

function isSeriesVodGroup(groupName as string) as boolean
    g = LCase(groupName)
    markers = ["serie", "série", "series", "séries", "anime", "animes", "dorama", "temporada", "tv show", "episodio", "episódio"]
    for each marker in markers
        if Instr(1, g, marker) > 0 then return true
    end for
    return false
end function

function parseVodM3u(text as string, defaultUA as string) as object
    result = { items: [], error: "" }
    items = []
    byKey = {}
    current = invalid
    rawCount = 0
    maxEntries = 25000

    if text = invalid or text.Trim() = "" then
        result.error = "A lista VOD esta vazia."
        return result
    end if
    if looksLikeHtml(text) then
        result.error = "A URL do catalogo retornou HTML, nao M3U."
        return result
    end if

    for each raw in text.Split(Chr(10))
        line = raw.Trim()
        if line = "" then
            ' linhas vazias
        else if Left(UCase(line), 7) = "#EXTINF" then
            current = {
                title: m3uTitleAfterLastComma(line)
                cover: m3uAttr(line, "tvg-logo")
                group: m3uAttr(line, "group-title")
            }
            if current.title = "" then current.title = "Sem titulo"
            if current.group = "" then current.group = "Catalogo"
        else if Left(UCase(line), 8) = "#EXTGRP:" then
            if current <> invalid then
                grp = Mid(line, 9, Len(line) - 8).Trim()
                if grp <> "" then current.group = grp
            end if
        else if Left(line, 1) = "#" then
            ' outros metadados M3U
        else if current <> invalid then
            if isValidUrl(line) and not isDeadUrl(line) and not isRestrictedVod(current.title, current.group) then
                rawCount = rawCount + 1
                if rawCount > maxEntries then
                    result.error = "O catalogo excede 25.000 entradas. Use uma lista por categorias/paginada para manter a Roku responsiva."
                    return result
                end if

                info = episodeInfo(current.title)
                groupedSeries = info.isEpisode or isSeriesVodGroup(current.group)
                stream = makeSource(line, "", defaultUA, "", "", false)

                if info.isEpisode then
                    seriesTitle = info.seriesName
                    if seriesTitle = "" then seriesTitle = current.title
                    seriesKey = "series:" + LCase(seriesTitle)
                    series = byKey[seriesKey]
                    if series = invalid then
                        series = {
                            title: seriesTitle
                            cover: current.cover
                            group: current.group
                            type: "series"
                            year: ""
                            sources: []
                            episodes: []
                        }
                        byKey[seriesKey] = series
                        items.Push(series)
                    end if
                    episode = invalid
                    for each existingEpisode in series.episodes
                        if existingEpisode.season = info.season and existingEpisode.episode = info.episode then
                            episode = existingEpisode
                            exit for
                        end if
                    end for
                    if episode = invalid then
                        episode = {
                            title: info.episodeTitle
                            season: info.season
                            episode: info.episode
                            cover: current.cover
                            group: current.group
                            sources: []
                        }
                        series.episodes.Push(episode)
                    end if
                    episode.sources.Push(stream)
                    if episode.cover = "" and current.cover <> "" then episode.cover = current.cover
                    if series.cover = "" and current.cover <> "" then series.cover = current.cover
                else
                    kind = "movie"
                    if groupedSeries then kind = "series"
                    itemKey = kind + ":" + LCase(current.title)
                    item = byKey[itemKey]
                    if item = invalid then
                        item = {
                            title: current.title
                            cover: current.cover
                            group: current.group
                            type: kind
                            year: ""
                            sources: []
                            episodes: []
                        }
                        byKey[itemKey] = item
                        items.Push(item)
                    end if
                    item.sources.Push(stream)
                    if item.cover = "" and current.cover <> "" then item.cover = current.cover
                end if
            end if
            current = invalid
        end if
    end for

    if items.Count() = 0 then
        result.error = "Nenhum filme ou episodio valido foi encontrado na lista."
        return result
    end if

    for each item in items
        if LCase(strField(item, "type")) = "series" then sortVodEpisodes(item)
    end for

    result.items = items
    return result
end function

' ---------------------------------------------------------------------------
' Filmes
' ---------------------------------------------------------------------------

function stripYear(title as string) as string
    t = title.Trim()
    if Right(t, 1) <> ")" then return t
    marker = 0
    i = 1
    while i < Len(t)
        if Mid(t, i, 2) = " (" then marker = i
        i = i + 1
    end while
    if marker = 0 then return t
    inside = Mid(t, marker + 2, Len(t) - marker - 2)
    if Len(inside) = 4 and Val(inside) > 1800 and Val(inside) < 2200 then return Left(t, marker - 1).Trim()
    return t
end function

function parseHighlights(text as string) as object
    rows = []
    current = invalid
    coverBase = ""

    for each raw in text.Split(Chr(10))
        line = raw.Trim()
        if line = "" or isSaimoComment(line) then
            ' vazio
        else if LCase(Left(line, 5)) = "capa:" then
            coverBase = Mid(line, 6, Len(line) - 5).Trim()
            if coverBase <> "" and Right(coverBase, 1) <> "/" then coverBase = coverBase + "/"
        else
            fields = line.Split(Chr(9))
            first = LCase(fields[0].Trim())
            if first = "fila" then
                if current <> invalid and current.items.Count() > 0 then rows.Push(current)
                title = ""
                if fields.Count() > 1 then title = fields[1].Trim()
                current = { title: title, items: [] }
            else if current <> invalid and fields.Count() >= 5 then
                kind = LCase(fields[0].Trim())
                ' f = filme; s, d e a = series (series, doramas e animes).
                if kind = "f" or kind = "s" or kind = "d" or kind = "a" then
                    title = fields[1].Trim()
                    letter = fields[2].Trim()
                    year = fields[3].Trim()
                    poster = fields[4].Trim()
                    cover = poster
                    if poster <> "" and Left(poster, 1) = "/" then cover = coverBase + Mid(poster, 2, Len(poster) - 1)
                    itemType = "movie"
                    groupName = "Filmes"
                    if kind <> "f" then
                        itemType = "series"
                        groupName = "Series"
                    end if
                    if title <> "" and letter <> "" and not isRestrictedVod(title, groupName) then
                        current.items.Push({
                            title: title
                            letter: letter
                            year: year
                            cover: cover
                            type: itemType
                            group: groupName
                            shelf: current.title
                            sourceType: "saimo"
                        })
                    end if
                end if
            end if
        end if
    end for

    if current <> invalid and current.items.Count() > 0 then rows.Push(current)
    return rows
end function

function pickSaimoHighlights(items as object, filter as string, limit as integer) as object
    if type(items) <> "roArray" then return []
    if limit <= 0 then limit = 12
    movies = []
    series = []
    for each item in items
        kind = LCase(strField(item, "type"))
        if kind = "series" then
            series.Push(item)
        else
            movies.Push(item)
        end if
    end for

    out = []
    if filter = "movies" then
        for each item in movies
            if out.Count() >= limit then exit for
            out.Push(item)
        end for
        return out
    end if
    if filter = "series" then
        for each item in series
            if out.Count() >= limit then exit for
            out.Push(item)
        end for
        return out
    end if

    ' Alterna filmes e series para a tela Descobrir nao ficar dominada por um tipo.
    movieIndex = 0
    seriesIndex = 0
    while out.Count() < limit and (movieIndex < movies.Count() or seriesIndex < series.Count())
        if movieIndex < movies.Count() then
            out.Push(movies[movieIndex])
            movieIndex = movieIndex + 1
        end if
        if out.Count() < limit and seriesIndex < series.Count() then
            out.Push(series[seriesIndex])
            seriesIndex = seriesIndex + 1
        end if
    end while
    return out
end function


function parseBases(text as string) as object
    bases = {}
    for each raw in text.Split(Chr(10))
        line = raw.Trim()
        if LCase(Left(line, 5)) = "base:" then
            rest = Mid(line, 6, Len(line) - 5).Trim()
            space = Instr(1, rest, " ")
            if space > 1 then
                idx = Val(Left(rest, space - 1))
                base = Mid(rest, space + 1, Len(rest) - space).Trim()
                if base <> "" and Right(base, 1) <> "/" then base = base + "/"
                bases[Str(idx).Trim()] = base
            end if
        end if
    end for
    return bases
end function

function expandMovieSource(raw as string, bases as object) as string
    item = raw.Trim()
    low = LCase(item)
    if Left(low, 8) = "https://" or Left(low, 7) = "http://" then return item
    colon = Instr(1, item, ":")
    if colon <= 1 then return ""
    idx = Val(Left(item, colon - 1))
    base = bases[Str(idx).Trim()]
    if base = invalid then return ""
    rest = Mid(item, colon + 1, Len(item) - colon).Trim()
    if rest = "" then return ""
    if Instr(1, rest, ".") > 0 then return base + rest
    return base + rest + ".mp4"
end function

' ---------------------------------------------------------------------------
' Catalogos Saimo por fragmentos (funcoes puras, testaveis sem SceneGraph)
' ---------------------------------------------------------------------------

function extractSaimoYear(title as string) as string
    t = title.Trim()
    if Right(t, 1) <> ")" or Len(t) < 6 then return ""
    marker = 0
    for i = 1 to Len(t) - 1
        if Mid(t, i, 2) = " (" then marker = i
    end for
    if marker = 0 then return ""
    inside = Mid(t, marker + 2, Len(t) - marker - 2)
    if Len(inside) = 4 and Val(inside) > 1800 and Val(inside) < 2200 then return inside
    return ""
end function

function parseSaimoIndexLetters(text as string) as object
    letters = []
    for each raw in text.Split(Chr(10))
        line = raw.Trim()
        if line = "" or Left(LCase(line), 5) = "base:" then
            ' Cabecalhos e linhas vazias.
        else if isSaimoComment(line) and line.Split(Chr(9)).Count() < 3 then
            ' Comentario; a letra "#" com contagens continua valida.
        else
            fields = line.Split(Chr(9))
            if fields.Count() < 3 and Instr(1, line, "|") > 0 then fields = line.Tokenize("|")
            if fields.Count() < 3 and Instr(1, line, ";") > 0 then fields = line.Tokenize(";")
            if fields.Count() < 3 and Instr(1, line, ",") > 0 then fields = line.Tokenize(",")
            if fields.Count() < 3 and Instr(1, line, " ") > 0 then fields = line.Tokenize(" ")
            if fields.Count() >= 3 then
                letter = UCase(fields[0].Trim())
                if Right(letter, 1) = ":" then letter = Left(letter, Len(letter) - 1)
                if Right(letter, 1) = ")" then letter = Left(letter, Len(letter) - 1)
                if Len(letter) = 1 and ((letter >= "A" and letter <= "Z") or letter = "#") then
                    extraCount = 0
                    if fields.Count() > 3 then extraCount = Val(fields[3])
                    letters.Push({
                        letter: letter
                        moviesCount: Val(fields[1])
                        seriesCount: Val(fields[2])
                        extraCount: extraCount
                    })
                end if
            end if
        end if
    end for
    return letters
end function

function parseSaimoMovieItems(text as string, letter as string, bases as object, userAgent as string) as object
    items = []
    seen = {}
    for each raw in text.Split(Chr(10))
        line = raw.Trim()
        if line <> "" and not isSaimoComment(line) then
            fields = line.Split(Chr(9))
            if fields.Count() >= 2 then
                title = fields[0].Trim()
                if title <> "" and not isRestrictedVod(title, "Filmes") then
                    sources = []
                    sourceSeen = {}
                    for i = 1 to fields.Count() - 1
                        part = fields[i].Trim()
                        eq = Instr(1, part, "=")
                        if eq > 0 then
                            tag = LCase(Left(part, eq - 1).Trim())
                            payload = Mid(part, eq + 1, Len(part) - eq).Trim()
                            label = ""
                            if tag = "dub" then label = "Dublado"
                            if tag = "leg" then label = "Legendado"
                            if label <> "" and payload <> "" then
                                for each rawUrl in payload.Split(",")
                                    url = expandMovieSource(rawUrl, bases)
                                    if url <> "" and not isDeadUrl(url) and sourceSeen[url] = invalid then
                                        sourceSeen[url] = true
                                        sources.Push(makeSource(url, "", userAgent, label, "", false))
                                    end if
                                end for
                            end if
                        end if
                    end for
                    key = LCase(stripYear(title))
                    if sources.Count() > 0 and seen[key] = invalid then
                        seen[key] = true
                        items.Push({
                            title: title
                            year: extractSaimoYear(title)
                            cover: ""
                            genres: ""
                            group: "Filmes"
                            type: "movie"
                            sources: sources
                            episodes: []
                            sourceType: "saimo"
                            letter: letter
                        })
                    end if
                end if
            end if
        end if
        if items.Count() >= 12000 then exit for
    end for
    return items
end function

function parseSaimoSeriesItems(text as string, letter as string) as object
    items = []
    seen = {}
    for each raw in text.Split(Chr(10))
        line = raw.Trim()
        if line <> "" and not isSaimoComment(line) then
            fields = line.Split(Chr(9))
            if fields.Count() < 4 and Instr(1, line, "|") > 0 then fields = line.Tokenize("|")
            if fields.Count() < 4 and Instr(1, line, ";") > 0 then fields = line.Tokenize(";")
            if fields.Count() >= 4 then
                title = fields[0].Trim()
                if title <> "" and not isRestrictedVod(title, "Series") then
                    key = LCase(stripYear(title))
                    if seen[key] = invalid then
                        seen[key] = true
                        items.Push({
                            title: title
                            year: fields[1].Trim()
                            cover: ""
                            genres: ""
                            group: "Series"
                            type: "series"
                            sources: []
                            episodes: []
                            sourceType: "saimo"
                            letter: letter
                            piece: Val(fields[2])
                            episodeCount: Val(fields[3])
                        })
                    end if
                end if
            end if
        end if
        if items.Count() >= 12000 then exit for
    end for
    return items
end function

function parseSaimoEpisodeItems(text as string, wanted as string, bases as object, userAgent as string) as object
    items = []
    byKey = {}
    keys = []
    inside = false

    for each raw in text.Split(Chr(10))
        line = raw.Trim()
        if Left(line, 1) = "@" then
            if inside then exit for
            identity = Mid(line, 2, Len(line) - 1).Split(Chr(9))
            name = ""
            if identity.Count() > 0 then name = identity[0].Trim()
            inside = movieTitleMatches(name, wanted)
        else if inside and line <> "" and not isSaimoComment(line) then
            fields = line.Split(Chr(9))
            if fields.Count() >= 4 then
                season = Val(fields[0])
                episodeNo = Val(fields[1])
                language = LCase(fields[2].Trim())
                payload = fields[3].Trim()
                epKey = Right("000" + Str(season).Trim(), 3) + ":" + Right("0000" + Str(episodeNo).Trim(), 4)
                episode = byKey[epKey]
                if episode = invalid then
                    episode = {
                        title: "T" + twoDigit(season) + " E" + twoDigit(episodeNo)
                        season: season
                        episode: episodeNo
                        cover: ""
                        group: "Temporada " + Str(season).Trim()
                        type: "episode"
                        sources: []
                    }
                    byKey[epKey] = episode
                    keys.Push(epKey)
                end if
                label = "Legendado"
                if Left(language, 3) = "dub" or Left(language, 3) = "pt-" or language = "pt" then label = "Dublado"
                for each rawUrl in payload.Split(",")
                    url = expandMovieSource(rawUrl, bases)
                    if url <> "" and not isDeadUrl(url) then
                        duplicate = false
                        for each existing in episode.sources
                            if strField(existing, "url") = url then duplicate = true
                        end for
                        if not duplicate then episode.sources.Push(makeSource(url, "", userAgent, label, "", false))
                    end if
                end for
            end if
        end if
    end for

    keys.Sort()
    for each key in keys
        if byKey[key].sources.Count() > 0 then items.Push(byKey[key])
    end for
    return items
end function

function isSaimoSeriesKind(kind as string) as boolean
    k = LCase(kind.Trim())
    if k = "s" or k = "d" or k = "a" or k = "tv" then return true
    if Instr(1, k, "ser") > 0 then return true
    if Instr(1, k, "show") > 0 then return true
    if Instr(1, k, "anime") > 0 then return true
    if Instr(1, k, "dorama") > 0 then return true
    return false
end function

function parseSaimoSearchItems(text as string, query as string, limit as integer) as object
    results = []
    if query.Trim() = "" then return results
    if limit <= 0 then limit = 160
    q = foldText(query)
    seen = {}

    for each raw in text.Split(Chr(10))
        line = raw.Trim()
        if line <> "" and not isSaimoComment(line) then
            fields = line.Split(Chr(9))
            if fields.Count() >= 3 then
                title = fields[0].Trim()
                kind = fields[1].Trim()
                letter = fields[2].Trim()
                year = ""
                if fields.Count() > 3 then year = fields[3].Trim()
                itemType = "movie"
                group = "Filmes"
                if isSaimoSeriesKind(kind) then
                    itemType = "series"
                    group = "Series"
                end if
                if title <> "" and Instr(1, foldText(title), q) > 0 and not isRestrictedVod(title, group) then
                    key = itemType + ":" + LCase(stripYear(title))
                    if seen[key] = invalid then
                        seen[key] = true
                        results.Push({
                            title: title
                            type: itemType
                            group: group
                            year: year
                            letter: letter
                            sourceType: "saimo"
                        })
                        if results.Count() >= limit then exit for
                    end if
                end if
            end if
        end if
    end for
    return results
end function

function sortSaimoItems(items as object) as object
    if type(items) <> "roArray" or items.Count() < 2 then return items
    keys = []
    byKey = {}
    for each item in items
        key = LCase(foldText(stripYear(strField(item, "title")))) + "|" + LCase(strField(item, "type"))
        if byKey[key] = invalid then
            byKey[key] = item
            keys.Push(key)
        end if
    end for
    keys.Sort()
    sorted = []
    for each key in keys
        sorted.Push(byKey[key])
    end for
    return sorted
end function

function firstGenre(value as string) as string
    text = value.Trim()
    if text = "" then return ""
    comma = Instr(1, text, ",")
    if comma > 0 then text = Left(text, comma - 1).Trim()
    return text
end function

function saimoItemSubtitle(entry as object) as string
    kind = LCase(strField(entry, "type"))
    year = strField(entry, "year").Trim()
    if kind = "episode" then
        season = Val(strField(entry, "season"))
        number = Val(strField(entry, "episode"))
        text = "Temporada " + Str(season).Trim()
        if number > 0 then text = text + "  •  Episódio " + Str(number).Trim()
        return text
    end if
    if kind = "series" then
        text = "Série"
        if year <> "" then text = text + "  •  " + year
        count = Val(strField(entry, "episodeCount"))
        if count > 0 then text = text + "  •  " + Str(count).Trim() + " episódios"
        genre = firstGenre(strField(entry, "genres"))
        if genre <> "" then text = text + "  •  " + genre
        return text
    end if
    text = "Filme"
    if year <> "" then text = text + "  •  " + year
    genre = firstGenre(strField(entry, "genres"))
    if genre <> "" then text = text + "  •  " + genre
    return text
end function

' Legenda compacta da grade: o tipo do cartao define sua proporcao e contexto.
' A previa continua usando saimoItemSubtitle().
function saimoGridSubtitle(entry as object) as string
    kind = LCase(strField(entry, "type"))
    year = strField(entry, "year").Trim()
    if kind = "episode" then
        season = Val(strField(entry, "season"))
        number = Val(strField(entry, "episode"))
        text = strField(entry, "group").Trim()
        if text = "" and season > 0 then text = "Temporada " + Str(season).Trim()
        if text = "" and number > 0 then text = "Episódio " + Str(number).Trim()
        if text = "" then text = "Episódio"
        if type(entry.sources) = "roArray" and entry.sources.Count() > 0 then
            text = text + "  •  " + Str(entry.sources.Count()).Trim() + " fontes"
        end if
        return text
    end if
    if kind = "series" then
        text = "Série"
        count = Val(strField(entry, "episodeCount"))
        if count = 0 and type(entry.episodes) = "roArray" then count = entry.episodes.Count()
        if count > 0 then text = text + "  •  " + Str(count).Trim() + " episódios"
        if year <> "" then text = text + "  •  " + year
        genre = firstGenre(strField(entry, "genres"))
        if genre <> "" then text = text + "  •  " + genre
        return text
    end if
    text = "Filme"
    if year <> "" then text = text + "  •  " + year
    genre = firstGenre(strField(entry, "genres"))
    if genre <> "" then text = text + "  •  " + genre
    return text
end function

function saimoArtworkTitleKey(title as string) as string
    value = foldText(stripYear(title))
    separators = [" ", ".", "-", "_", ",", ":", ";", "!", "?", "'", Chr(34), "(", ")", "[", "]"]
    for each separator in separators
        value = value.Replace(separator, "")
    end for
    return LCase(value)
end function

function applySaimoArtwork(items as object, fichasText as string, fallbackCovers as object) as object
    if type(items) <> "roArray" then return items
    wanted = {}

    if type(fallbackCovers) = "roAssociativeArray" then
        for each item in items
            kind = LCase(strField(item, "type"))
            prefix = "f:"
            if kind = "series" then prefix = "s:"
            key = prefix + saimoArtworkTitleKey(strField(item, "title"))
            cover = fallbackCovers[key]
            if strField(item, "cover") = "" and cover <> invalid and cover <> "" then item.cover = cover
            wanted[key] = item
        end for
    else
        for each item in items
            kind = LCase(strField(item, "type"))
            prefix = "f:"
            if kind = "series" then prefix = "s:"
            key = prefix + saimoArtworkTitleKey(strField(item, "title"))
            wanted[key] = item
        end for
    end if

    if fichasText = invalid or fichasText = "" then return items
    coverBase = ""
    for each raw in fichasText.Split(Chr(10))
        line = raw.Trim()
        if LCase(Left(line, 5)) = "capa:" then
            coverBase = Mid(line, 6, Len(line) - 5).Trim()
            if coverBase <> "" and Right(coverBase, 1) <> "/" then coverBase = coverBase + "/"
        else if line <> "" and not isSaimoComment(line) then
            fields = line.Split(Chr(9))
            if fields.Count() >= 4 then
                rowType = LCase(fields[0].Trim())
                prefix = ""
                if rowType = "f" then prefix = "f:"
                if rowType = "s" then prefix = "s:"
                if prefix <> "" then
                    key = prefix + saimoArtworkTitleKey(fields[1].Trim())
                    target = wanted[key]
                    if target <> invalid then
                        if strField(target, "genres") = "" and fields.Count() > 4 then target.genres = fields[4].Trim()
                        if strField(target, "cover") = "" then
                            poster = fields[3].Trim()
                            if poster <> "" then
                                if Left(poster, 1) = "/" then
                                    poster = coverBase + Mid(poster, 2, Len(poster) - 1)
                                else if Left(LCase(poster), 8) <> "https://" and Left(LCase(poster), 7) <> "http://" then
                                    poster = coverBase + poster
                                end if
                                ' A ficha completa preenche apenas itens sem capa;
                                ' a capa do destaque existente e preservada.
                                if poster <> "" then target.cover = poster
                            end if
                        end if
                    end if
                end if
            end if
        end if
    end for
    return items
end function

function movieTitleMatches(candidate as string, wanted as string) as boolean
    a = LCase(candidate.Trim())
    b = LCase(wanted.Trim())
    if a = b then return true
    return LCase(stripYear(candidate.Trim())) = LCase(stripYear(wanted.Trim()))
end function

function parseMovieSources(text as string, bases as object, wanted as string) as object
    sources = []
    seen = {}
    found = false

    for each raw in text.Split(Chr(10))
        line = raw.Trim()
        if line = "" then
            ' vazio
        else
            fields = line.Split(Chr(9))
            if fields.Count() >= 2 and movieTitleMatches(fields[0], wanted) then
                found = true
                for i = 1 to fields.Count() - 1
                    field = fields[i].Trim()
                    label = ""
                    payload = ""
                    if LCase(Left(field, 4)) = "dub=" then
                        label = "Dublado"
                        payload = Mid(field, 5, Len(field) - 4)
                    else if LCase(Left(field, 4)) = "leg=" then
                        label = "Legendado"
                        payload = Mid(field, 5, Len(field) - 4)
                    end if
                    if payload <> "" then
                        for each part in payload.Split(",")
                            url = expandMovieSource(part, bases)
                            if url <> "" and not isDeadUrl(url) then
                                if seen[url] = invalid then
                                    seen[url] = true
                                    sources.Push(makeSource(url, "", "", label, "", false))
                                end if
                            end if
                        end for
                    end if
                end for
                exit for
            end if
        end if
    end for

    if not found then return []
    return sources
end function

' ---------------------------------------------------------------------------
' XMLTV
' ---------------------------------------------------------------------------

function decodeXml(value as string) as string
    text = value
    text = text.Replace("&amp;", "&")
    text = text.Replace("&quot;", Chr(34))
    text = text.Replace("&apos;", Chr(39))
    text = text.Replace("&lt;", "<")
    text = text.Replace("&gt;", ">")
    return text
end function

function xmltvTagValue(line as string) as string
    open = Instr(1, line, ">")
    if open = 0 then return ""
    rest = Mid(line, open + 1, Len(line) - open)
    close = Instr(1, rest, "<")
    if close = 0 then return ""
    return decodeXml(Left(rest, close - 1).Trim())
end function

function daysFromCivil(year as integer, month as integer, day as integer) as integer
    y = year
    mo = month
    if mo <= 2 then y = y - 1
    era = Int(y / 400)
    yoe = y - era * 400
    if mo > 2 then
        mp = mo - 3
    else
        mp = mo + 9
    end if
    doy = Int((153 * mp + 2) / 5) + day - 1
    doe = yoe * 365 + Int(yoe / 4) - Int(yoe / 100) + doy
    return era * 146097 + doe - 719468
end function

function xmltvEpoch(value as string) as integer
    if value = invalid or Len(value) < 14 then return 0
    year = Val(Mid(value, 1, 4))
    month = Val(Mid(value, 5, 2))
    day = Val(Mid(value, 7, 2))
    hour = Val(Mid(value, 9, 2))
    minute = Val(Mid(value, 11, 2))
    second = Val(Mid(value, 13, 2))
    seconds = daysFromCivil(year, month, day) * 86400 + hour * 3600 + minute * 60 + second

    signPos = Instr(15, value, "+")
    if signPos = 0 then signPos = Instr(15, value, "-")
    if signPos > 0 then
        sign = Mid(value, signPos, 1)
        offsetHours = Val(Mid(value, signPos + 1, 2))
        offsetMinutes = Val(Mid(value, signPos + 3, 2))
        offset = offsetHours * 3600 + offsetMinutes * 60
        if sign = "+" then seconds = seconds - offset else seconds = seconds + offset
    end if
    return seconds
end function

function epgTagAttr(line as string, name as string) as string
    needle = name + "=" + Chr(34)
    start = Instr(1, line, needle)
    if start = 0 then return ""
    start = start + Len(needle)
    rest = Mid(line, start, Len(line) - start + 1)
    finish = Instr(1, rest, Chr(34))
    if finish = 0 then return ""
    return Left(rest, finish - 1)
end function

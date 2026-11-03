sub init()
    m.top.functionName = "runTask"
end sub

sub runTask()
    reqType = ""
    if m.top.requestType <> invalid then reqType = m.top.requestType.Trim()
    if reqType <> "" then
        if reqType = "channels" then
            fetchChannels()
        else if reqType = "epg" then
            fetchEpg()
        else if reqType = "destaques" then
            fetchDestaques()
        else if reqType = "events" then
            fetchEvents()
        else if reqType = "radios" then
            fetchRadios()
        else if reqType = "playlist" then
            loadPlaylist()
        else if reqType = "vod_catalog" then
            loadVodCatalog()
        else if reqType = "saimo_index" then
            loadSaimoIndex()
        else if reqType = "saimo_letter" then
            loadSaimoLetter()
        else if reqType = "saimo_episodes" then
            loadSaimoEpisodes()
        else if reqType = "saimo_search_index" then
            loadSaimoSearchIndex()
        else
            mode = LCase(m.top.mode.Trim())
            if mode = "playlist" then
                loadPlaylist()
            else if mode = "vod_catalog" then
                loadVodCatalog()
            else if mode = "saimo_index" then
                loadSaimoIndex()
            else if mode = "saimo_letter" then
                loadSaimoLetter()
            else if mode = "saimo_episodes" then
                loadSaimoEpisodes()
            else if mode = "saimo_search_index" then
                loadSaimoSearchIndex()
            else
                m.top.error = "Modo de tarefa desconhecido."
            end if
        end if
    else
        mode = LCase(m.top.mode.Trim())
        if mode = "playlist" then
            loadPlaylist()
        else if mode = "vod_catalog" then
            loadVodCatalog()
        else if mode = "saimo_index" then
            loadSaimoIndex()
        else if mode = "saimo_letter" then
            loadSaimoLetter()
        else if mode = "saimo_episodes" then
            loadSaimoEpisodes()
        else if mode = "saimo_search_index" then
            loadSaimoSearchIndex()
        else
            m.top.error = "Modo de tarefa desconhecido."
        end if
    end if
end sub

sub fetchChannels()
    url = m.top.requestUrl
    if url = "" then url = m.top.url
    if url = "" then url = m.top.baseUrl
    if url = "" then url = "https://saimo-canais.pages.dev/catalogo.txt"
    ua = m.top.userAgent

    response = httpGet(url, ua, "")
    if (not response.ok or looksLikeHtml(response.body)) and isSaimoCatalogUrl(url) then
        response = httpGet("https://raw.githubusercontent.com/gabrielsaimo/SaimoPlayer/main/catalogo.txt", ua, "")
    end if
    if not response.ok then
        m.top.error = "Nao foi possivel baixar a lista: " + response.error
        return
    end if
    if looksLikeHtml(response.body) then
        m.top.error = "O endereco retornou HTML, nao uma lista. Confira a URL em Ajustes."
        return
    end if

    channels = []
    parsed = parsePlaylist(response.body)
    number = 1
    for each ch in parsed
        variants = []
        if ch.sources <> invalid then
            for each src in ch.sources
                v = { url: src.url, quality: src.quality, referer: src.referer, userAgent: src.userAgent }
                variants.Push(v)
            end for
        end if
        if variants.Count() = 0 then continue for
        channelName = ""
        if ch.title <> invalid then channelName = ch.title
        groupName = "Canais"
        if ch.group <> invalid and ch.group <> "" then groupName = ch.group
        logoValue = ""
        if ch.logo <> invalid then logoValue = ch.logo
        channels.Push({ name: channelName, number: number, category: groupName, logo: logoValue, variants: variants })
        number = number + 1
    end for

    if channels.Count() = 0 then
        m.top.error = "A lista foi baixada, mas nenhum canal foi reconhecido."
        return
    end if

    m.top.responseChannels = channels
    m.top.resultJson = FormatJson(channels)
    m.top.count = channels.Count()
    m.top.success = true
end sub

sub fetchEpg()
    base = m.top.baseUrl
    if base = "" then base = m.top.requestUrl
    if base = "" then base = "https://saimo-canais.pages.dev/"
    if Right(base, 1) <> "/" then base = base + "/"

    cache = "cachefs:/epg.json"
    agora = CreateObject("roDateTime").AsSeconds()
    bruto = readCacheAscii(cache)
    if bruto <> "" then
        dados = ParseJson(bruto)
        if dados <> invalid and dados.quando <> invalid and agora - dados.quando < 21600 then
            m.top.responseEpg = dados.mapa
            return
        end if
    end if

    sleep(15000)
    response = httpGet(base + "guia.txt", m.top.userAgent, "")
    text = ""
    if response <> invalid then
        if response.body <> invalid then text = response.body else if type(response) = "String" or type(response) = "roString" then text = response
    end if
    if text = "" then return

    fila = []
    for each rawLine in text.Split(Chr(10))
        parts = rawLine.Trim().Split(Chr(9))
        if parts.Count() >= 3 and parts[0] = "meuguia" then fila.Push({ nome: parts[1], codigo: parts[2] })
    end for

    epgMap = {}
    for canalIdx = 0 to fila.Count() - 1
        canalAtual = fila[canalIdx]
        html = httpGet("https://meuguia.tv/programacao/canal/" + canalAtual.codigo, m.top.userAgent, "")
        htmlText = ""
        if html <> invalid then
            if html.body <> invalid then htmlText = html.body else if type(html) = "String" or type(html) = "roString" then htmlText = html
        end if
        lista = lerMeuGuia(Left(htmlText, 60000), agora)
        if lista.Count() > 0 then epgMap[canalAtual.nome] = lista
        sleep(150)
    end for
    m.top.responseEpg = epgMap
    WriteAsciiFile(cache, FormatJson({ quando: agora, mapa: epgMap }))
end sub

function entre(texto as String, abre as String, fecha as String) as Dynamic
    p = Instr(1, texto, abre)
    if p = 0 then return invalid
    p = p + Len(abre)
    q = Instr(p, texto, fecha)
    if q = 0 then return invalid
    return Mid(texto, p, q - p)
end function

function doisDigitos(n as Integer) as String
    t = n.ToStr()
    if Len(t) < 2 then t = "0" + t
    return t
end function

function lerMeuGuia(html as String, agora as Integer) as Object
    if html = "" then return []
    hoje = CreateObject("roDateTime")
    hoje.FromSeconds(agora - 10800)
    ano = hoje.GetYear()
    mes = hoje.GetMonth()
    dia = hoje.GetDayOfMonth()
    programas = []
    conversor = CreateObject("roDateTime")

    for each item in html.Split("<li")
        if Instr(1, item, "subheader") > 0 then
            t = entre(Mid(item, Instr(1, item, "subheader")), ">", "<")
            if t <> invalid and Instr(1, t, ",") > 0 then
                d = Mid(t, Instr(1, t, ",") + 1).Trim().Split("/")
                if d.Count() = 2 then
                    dia = Val(d[0])
                    mes = Val(d[1])
                end if
            end if
        else
            relogio = entre(item, "lileft time'>", "<")
            if relogio = invalid then relogio = entre(item, "lileft time" + Chr(34) + ">", "<")
            titulo = entre(item, "<h2>", "</h2>")
            if relogio <> invalid and titulo <> invalid then
                hm = relogio.Trim().Split(":")
                if hm.Count() = 2 then
                    conversor.FromISO8601String(ano.ToStr() + "-" + doisDigitos(mes) + "-" + doisDigitos(dia) + "T" + doisDigitos(Val(hm[0])) + ":" + doisDigitos(Val(hm[1])) + ":00Z")
                    inicio = conversor.AsSeconds() + 10800
                    titulo = titulo.Replace("&amp;", "&").Replace("&#39;", "'").Replace("&quot;", Chr(34)).Trim()
                    if titulo <> "" then programas.Push({ title: titulo, startSec: inicio })
                end if
            end if
        end if
    end for

    saida = []
    for programaIdx = 0 to programas.Count() - 1
        programaAtual = programas[programaIdx]
        fim = programaAtual.startSec + 3600
        if programaIdx + 1 < programas.Count() then fim = programas[programaIdx + 1].startSec
        if fim > agora then
            dur = Int((fim - programaAtual.startSec) / 60)
            resta = Int((fim - agora) / 60)
            saida.Push({ title: programaAtual.title, startSec: programaAtual.startSec, stopSec: fim, durationMin: dur, remainingMin: resta, isCurrent: agora >= programaAtual.startSec })
            if saida.Count() >= 12 then exit for
        end if
    end for
    return saida
end function

sub fetchDestaques()
    base = m.top.baseUrl
    if base = "" then base = m.top.requestUrl
    if base = "" then base = "https://filmes-saimo.pages.dev/"
    if Right(base, 1) <> "/" then base = base + "/"

    url = base + "destaques.txt"
    text = httpGet(url, m.top.userAgent, "")
    body = ""
    if text <> invalid then
        if text.body <> invalid then body = text.body else if type(text) = "String" or type(text) = "roString" then body = text
    end if
    if body = "" then return

    lines = body.Split(Chr(10))
    rails = []
    currentRail = invalid
    capaBase = "https://image.tmdb.org/t/p/w342"
    allVodItems = []

    for each rawLine in lines
        line = rawLine.Trim()
        if line = "" or Left(line, 1) = "#" then continue for

        if Left(line, 5) = "capa:" then
            capaBase = Mid(line, 6).Trim()
        else if Left(line, 4) = "fila" then
            tabParts = line.Split(Chr(9))
            railTitle = "Em Destaque"
            if tabParts.Count() >= 2 then railTitle = tabParts[1].Trim()
            currentRail = { title: railTitle, items: [] }
            rails.Push(currentRail)
        else if currentRail <> invalid then
            tabParts = line.Split(Chr(9))
            if tabParts.Count() >= 5 then
                tipo = tabParts[0].Trim()
                title = tabParts[1].Trim()
                letter = tabParts[2].Trim()
                year = tabParts[3].Trim()
                posterPath = tabParts[4].Trim()
                posterUrl = posterPath
                if Left(posterPath, 1) = "/" then
                    posterUrl = capaBase + posterPath
                end if
                if isRestrictedVod(title, currentRail.title) then continue for
                isSeries = (tipo = "s")
                kind = "movie"
                if isSeries then kind = "series"
                item = {
                    title: title,
                    letter: letter,
                    id: title,
                    kind: kind,
                    poster: posterUrl,
                    backdrop: posterUrl,
                    rating: "",
                    year: year,
                    genres: currentRail.title,
                    overview: "",
                    isSeries: isSeries
                }
                currentRail.items.Push(item)
                allVodItems.Push(item)
            end if
        end if
    end for

    m.top.responseDestaques = rails
    m.top.responseVodItems = allVodItems
    m.top.success = true
end sub

sub fetchEvents()
    events = []
    eventsUrl = GetEventosUrl()
    response = httpGet(eventsUrl, m.top.userAgent, "")
    parsed = invalid
    body = ""
    if response <> invalid then
        if response.body <> invalid then body = response.body else if type(response) = "String" or type(response) = "roString" then body = response
    end if
    if body <> "" then parsed = ParseJson(body)
    if parsed <> invalid and type(parsed) = "roArray" then
        d = CreateObject("roDateTime")
        agora = d.AsSeconds()
        for each ev in parsed
            if ev.players <> invalid and ev.players.Count() > 0 and ev.teams <> invalid and ev.time_start <> invalid then
                d.FromISO8601String(Left(ev.time_start, 19) + "Z")
                inicio = d.AsSeconds() + 10800
                d.FromISO8601String(Left(ev.time_end, 19) + "Z")
                fim = d.AsSeconds() + 10800
                if fim > agora then
                    events.Push({
                        homeTeam: ev.teams.home.name,
                        awayTeam: ev.teams.away.name,
                        homeLogo: ev.teams.home.image.Replace("w_34,h_34", "w_256,h_256"),
                        awayLogo: ev.teams.away.image.Replace("w_34,h_34", "w_256,h_256"),
                        league: ev.league.name,
                        timeStr: Mid(ev.time_start, 12, 5),
                        aoVivo: agora >= inicio,
                        slugs: ev.players,
                        channelName: "",
                        score: ""
                    })
                end if
            end if
        end for
    end if
    m.top.responseEvents = events
    m.top.success = true
end sub

function estiloDaRadio(nome as String) as String
    n = LCase(nome) + " "
    estilos = [
        { t: "Rock", p: ["rock", "metal", "kiss", "punk"] },
        { t: "Notícias e esporte", p: ["news", "noticia", "cbn", "gaucha", "itatiaia", "tupi", "esporte", "jornal", "bandnews", "radio globo", "eldorado", "bandeirantes"] },
        { t: "Gospel e católicas", p: ["gospel", "evangel", "catolic", "crista", "louvor", "aleluia", "cancao nova", "novo tempo", "aparecida", "fe ", "deus", "jesus", "igreja", "biblia"] },
        { t: "Pop e hits", p: ["pop", "hits", "dance", "mix", "jovem pan", "transamerica", "energia", "eletro", "club", "pulse", "top"] },
        { t: "Sertanejo, MPB e samba", p: ["sertanej", "mpb", "samba", "pagode", "forro", "nativa", "caipira", "brega", "axe", "piseiro", "moda de viola"] },
        { t: "Clássica e jazz", p: ["classic", "jazz", "cultura", "educativa", "universit", "instrumental", "blues", "lounge"] }
    ]
    for each estilo in estilos
        for each palavra in estilo.p
            if Instr(1, n, palavra) > 0 then return estilo.t
        end for
    end for
    return "Outras"
end function

sub fetchRadios()
    base = m.top.baseUrl
    if base = "" then base = m.top.requestUrl
    if base = "" then base = "https://saimo-canais.pages.dev/"
    if Right(base, 1) <> "/" then base = base + "/"

    url = base + "radios.txt"
    text = httpGet(url, m.top.userAgent, "")
    body = ""
    if text <> invalid then
        if text.body <> invalid then body = text.body else if type(text) = "String" or type(text) = "roString" then body = text
    end if
    if body = "" then return

    lines = body.Split(Chr(10))
    radios = []

    for each rawLine in lines
        line = rawLine.Trim()
        if line = "" or Left(line, 1) = "#" then continue for
        parts = line.Split("|")
        if parts.Count() >= 2 then
            name = parts[0].Trim()
            streamUrl = parts[1].Trim()
            logo = ""
            if parts.Count() >= 3 then logo = parts[2].Trim()
            genre = estiloDaRadio(name)

            item = { name: name, url: streamUrl, genre: genre, logo: logo }
            radios.Push(item)
        end if
    end for

    m.top.responseRadios = radios
    m.top.success = true
end sub

sub loadPlaylist()
    url = m.top.url.Trim()
    if url = "" then
        m.top.error = "Nenhuma lista configurada."
        return
    end if

    response = httpGet(url, m.top.userAgent, "")
    if (not response.ok or looksLikeHtml(response.body)) and isSaimoCatalogUrl(url) then
        response = httpGet("https://raw.githubusercontent.com/gabrielsaimo/SaimoPlayer/main/catalogo.txt", m.top.userAgent, "")
    end if
    if not response.ok then
        m.top.error = "Nao foi possivel baixar a lista: " + response.error
        return
    end if
    if looksLikeHtml(response.body) then
        m.top.error = "O endereco retornou HTML, nao uma lista. Confira a URL em Ajustes."
        return
    end if

    channels = parsePlaylist(response.body)
    if channels.Count() = 0 then
        m.top.error = "A lista foi baixada, mas nenhum canal foi reconhecido."
        return
    end if

    m.top.resultJson = FormatJson(channels)
    m.top.count = channels.Count()
    m.top.success = true
end sub

' A fonte Saimo e um catalogo por fragmentos. O indice e pequeno; o app busca
' titulos por letra e episodios somente quando o usuario abre uma serie.
sub loadSaimoIndex()
    base = normalizeSaimoBase(m.top.baseUrl)
    if base = "" then
        m.top.error = "Fonte do catalogo invalida."
        return
    end if

    response = httpGet(base + "indice.txt", m.top.userAgent, "")
    if not response.ok or looksLikeHtml(response.body) then
        message = response.error
        if message = "" then message = "O indice VOD nao retornou texto valido."
        m.top.error = "Nao foi possivel atualizar o indice VOD: " + message
        return
    end if

    bases = parseBases(response.body)
    letters = parseSaimoIndexLetters(response.body)
    if letters.Count() = 0 then
        m.top.error = "O indice VOD foi baixado, mas nao contem letras validas."
        return
    end if

    WriteAsciiFile("cachefs:/saimo_vod_bases.json", FormatJson(bases))
    WriteAsciiFile("cachefs:/saimo_vod_bases.url", base)

    ' Destaques e capas saem de um arquivo pequeno; o catalogo completo de capas
    ' e baixado em tarefa separada para nao bloquear a primeira tela.
    covers = {}
    featured = []
    shelves = []
    featuredSeen = {}
    highlights = httpGet(base + "destaques.txt", m.top.userAgent, "")
    if highlights.ok and not looksLikeHtml(highlights.body) then
        shelves = parseHighlights(highlights.body)
        ' Consolida varias fileiras para manter filmes e series disponiveis no destaque.
        for each shelf in shelves
            for each feature in shelf.items
                prefix = "f:"
                if strField(feature, "type") = "series" then prefix = "s:"
                featureKey = prefix + saimoArtworkTitleKey(feature.title)
                if feature.cover <> "" then covers[featureKey] = feature.cover
                if featured.Count() < 60 and featuredSeen[featureKey] = invalid then
                    featuredSeen[featureKey] = true
                    featured.Push(feature)
                end if
            end for
        end for
    end if

    signature = saimoIndexSignature(letters, bases)
    WriteAsciiFile("cachefs:/saimo_vod_covers.json", FormatJson(covers))
    WriteAsciiFile("cachefs:/saimo_vod_covers.url", base)
    result = {
        letters: letters
        bases: bases
        covers: covers
        highlights: featured
        shelves: shelves
        baseUrl: base
        signature: signature
    }
    m.top.resultJson = FormatJson(result)
    m.top.count = letters.Count()
    m.top.success = true
end sub

function loadCachedSaimoBases(base as string) as object
    bases = {}
    marker = readCacheAscii("cachefs:/saimo_vod_bases.url")
    raw = readCacheAscii("cachefs:/saimo_vod_bases.json")
    if isStringValue(marker) and marker.Trim() = base and isStringValue(raw) and raw <> "" then
        parsed = ParseJson(raw)
        if type(parsed) = "roAssociativeArray" then return parsed
    end if

    response = httpGet(base + "indice.txt", m.top.userAgent, "")
    if response.ok and not looksLikeHtml(response.body) then
        bases = parseBases(response.body)
        if bases.Count() > 0 then
            WriteAsciiFile("cachefs:/saimo_vod_bases.json", FormatJson(bases))
            WriteAsciiFile("cachefs:/saimo_vod_bases.url", base)
        end if
    end if
    return bases
end function

sub loadSaimoLetter()
    base = normalizeSaimoBase(m.top.baseUrl)
    letter = m.top.letter.Trim()
    filter = LCase(m.top.title.Trim())
    if filter <> "movies" and filter <> "series" then filter = "all"
    if letter = "" then
        m.top.error = "Nenhuma letra selecionada."
        return
    end if
    if base = "" then
        m.top.error = "Fonte do catalogo invalida."
        return
    end if

    bases = loadCachedSaimoBases(base)
    if bases.Count() = 0 then
        m.top.error = "Nao foi possivel carregar as bases de video do catalogo."
        return
    end if

    fileLetter = letter
    if letter = "#" then fileLetter = "%23"
    items = []
    loadedAny = false
    errors = []

    if filter = "movies" or filter = "all" then
        movieResponse = httpGet(base + "filmes-" + fileLetter + ".txt", m.top.userAgent, "")
        if movieResponse.ok and not looksLikeHtml(movieResponse.body) then
            loadedAny = true
            movieItems = parseSaimoMovieItems(movieResponse.body, letter, bases, m.top.userAgent)
            for each item in movieItems
                items.Push(item)
            end for
        else
            errors.Push("filmes")
        end if
    end if

    if filter = "series" or filter = "all" then
        seriesResponse = httpGet(base + "series-" + fileLetter + ".txt", m.top.userAgent, "")
        if seriesResponse.ok and not looksLikeHtml(seriesResponse.body) then
            loadedAny = true
            seriesItems = parseSaimoSeriesItems(seriesResponse.body, letter)
            for each item in seriesItems
                items.Push(item)
            end for
        else
            errors.Push("series")
        end if
    end if

    if not loadedAny then
        m.top.error = "Nao foi possivel carregar os titulos desta letra. Verifique a conexao e tente novamente."
        return
    end if

    items = sortSaimoItems(items)

    ' As capas e os generos sao aplicados dentro da tarefa: fichas.txt tem cerca
    ' de 4 MB e nunca deve ser lido na linha principal da interface.
    fallbackCovers = {}
    coverMarker = readCacheAscii("cachefs:/saimo_vod_covers.url")
    coverRaw = readCacheAscii("cachefs:/saimo_vod_covers.json")
    if isStringValue(coverMarker) and coverMarker.Trim() = base and isStringValue(coverRaw) and coverRaw <> "" then
        coverParsed = ParseJson(coverRaw)
        if type(coverParsed) = "roAssociativeArray" then fallbackCovers = coverParsed
    end if

    fichas = ""
    cachedBase = readCacheAscii("cachefs:/saimo_vod_fichas.url")
    fichasReady = readCacheAscii("cachefs:/saimo_vod_fichas.ready")
    if isStringValue(cachedBase) and cachedBase.Trim() = base and isStringValue(fichasReady) and fichasReady.Trim() = "1" then
        fichas = readCacheAscii("cachefs:/saimo_vod_fichas.txt")
    end if

    ' As fichas completas só são baixadas quando o usuário entra no catálogo.
    ' A operação ocorre nesta tarefa em segundo plano, nunca durante a abertura.
    if not isStringValue(fichas) or fichas = "" then
        response = httpGet(base + "fichas.txt", m.top.userAgent, "")
        if response.ok and not looksLikeHtml(response.body) and response.body <> "" then
            fichas = response.body
            WriteAsciiFile("cachefs:/saimo_vod_fichas.txt", fichas)
            WriteAsciiFile("cachefs:/saimo_vod_fichas.url", base)
            WriteAsciiFile("cachefs:/saimo_vod_fichas.ready", "1")
        end if
    end if
    if not isStringValue(fichas) then fichas = ""
    applySaimoArtwork(items, fichas, fallbackCovers)

    if items.Count() = 0 then
        m.top.error = "Nenhum titulo valido foi encontrado nesta letra."
        return
    end if

    result = { items: items, filter: filter, letter: letter, baseUrl: base }
    m.top.resultJson = FormatJson(result)
    WriteAsciiFile(saimoLetterCachePath(filter, letter), m.top.resultJson)
    WriteAsciiFile("cachefs:/saimo_vod_letters.url", saimoLetterCacheMarker(base, m.top.signature))
    m.top.count = items.Count()
    m.top.success = true
    if errors.Count() > 0 then m.top.error = "Alguns fragmentos nao responderam; a lista exibida pode estar parcial."
end sub

sub loadSaimoEpisodes()
    base = normalizeSaimoBase(m.top.baseUrl)
    response = httpGet(m.top.url.Trim(), m.top.userAgent, "")
    if not response.ok or looksLikeHtml(response.body) then
        message = response.error
        if message = "" then message = "Resposta invalida do servidor."
        m.top.error = "Nao foi possivel carregar os episodios desta serie: " + message
        return
    end if

    bases = loadCachedSaimoBases(base)
    if bases.Count() = 0 then
        m.top.error = "As bases de video nao estao disponiveis. Atualize o catalogo e tente novamente."
        return
    end if

    items = parseSaimoEpisodeItems(response.body, m.top.title.Trim(), bases, m.top.userAgent)
    if items.Count() = 0 then
        m.top.error = "Nenhum episodio com fonte valida foi encontrado para esta serie."
        return
    end if

    m.top.resultJson = FormatJson(items)
    m.top.count = items.Count()
    m.top.success = true
end sub

' Prepara o indice local de busca: baixa o busca.txt quando necessario e
' grava os titulos ja normalizados para a linha principal so fazer Instr.
sub loadSaimoSearchIndex()
    base = normalizeSaimoBase(m.top.baseUrl)
    if base = "" then
        m.top.error = "Fonte do catalogo invalida."
        return
    end if

    raw = readCacheAscii("cachefs:/saimo_vod_search.txt")
    cachedBase = readCacheAscii("cachefs:/saimo_vod_search.url")
    indexBase = readCacheAscii("cachefs:/saimo_search_index.url")
    indexTime = readCacheAscii("cachefs:/saimo_search_index.time")

    hasRaw = isStringValue(raw) and raw <> "" and isStringValue(cachedBase) and cachedBase.Trim() = base
    hasIndex = isStringValue(indexBase) and indexBase.Trim() = base and isStringValue(indexTime)
    fresh = false
    if hasIndex then
        clock = CreateObject("roDateTime")
        age = clock.AsSeconds() - Val(indexTime.Trim())
        fresh = age >= 0 and age < 86400
    end if
    if hasRaw and hasIndex and fresh then
        m.top.success = true
        m.top.count = 0
        return
    end if

    downloaded = false
    if not hasRaw or not fresh then
        response = httpGet(base + "busca.txt", m.top.userAgent, "")
        if response.ok and not looksLikeHtml(response.body) then
            raw = response.body
            downloaded = true
            WriteAsciiFile("cachefs:/saimo_vod_search.txt", raw)
            WriteAsciiFile("cachefs:/saimo_vod_search.url", base)
        else if not hasRaw then
            m.top.error = "Nao foi possivel preparar a busca. Tente novamente quando a conexao estiver disponivel."
            return
        end if
    end if

    index = buildSaimoSearchIndex(raw)
    if index.folded.Count() = 0 then
        m.top.error = "O catalogo de busca chegou vazio."
        return
    end if

    WriteAsciiFile("cachefs:/saimo_search_index.json", FormatJson({
        version: 1
        base: base
        folded: index.folded
        payload: index.payload
    }))
    clock = CreateObject("roDateTime")
    stamp = clock.AsSeconds()
    ' Sem download novo o indice continua valido, mas tentamos de novo em 1h.
    if not downloaded then stamp = stamp - 82800
    WriteAsciiFile("cachefs:/saimo_search_index.time", Str(stamp).Trim())
    WriteAsciiFile("cachefs:/saimo_search_index.url", base)
    m.top.success = true
    m.top.count = index.folded.Count()
end sub

sub loadVodCatalog()
    url = m.top.url.Trim()
    if url = "" then
        m.top.error = "Configure uma URL M3U/M3U8 para um catalogo VOD autorizado."
        return
    end if

    response = httpGet(url, m.top.userAgent, "")
    if not response.ok then
        m.top.error = "Nao foi possivel atualizar o catalogo VOD: " + response.error
        return
    end if
    if looksLikeHtml(response.body) then
        m.top.error = "A URL do catalogo retornou HTML, nao uma lista M3U."
        return
    end if

    parsed = parseVodM3u(response.body, m.top.userAgent)
    if parsed.error <> "" then
        m.top.error = parsed.error
        return
    end if
    if type(parsed.items) <> "roArray" or parsed.items.Count() = 0 then
        m.top.error = "Nenhum filme ou episodio valido foi encontrado."
        return
    end if

    m.top.resultJson = FormatJson(parsed.items)
    m.top.count = parsed.items.Count()
    m.top.success = true
end sub

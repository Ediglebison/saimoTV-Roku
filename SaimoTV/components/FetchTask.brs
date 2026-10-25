sub init()
    m.top.functionName = "runTask"
end sub

sub runTask()
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
    else if mode = "saimo_search" then
        loadSaimoSearch()
    else
        m.top.error = "Modo de tarefa desconhecido."
    end if
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
        print "SAIMO_ART fichas http=" + Str(response.code).Trim() + " bytes=" + Str(Len(response.body)).Trim() + " error=" + response.error
        if response.ok and not looksLikeHtml(response.body) and response.body <> "" then
            fichas = response.body
            WriteAsciiFile("cachefs:/saimo_vod_fichas.txt", fichas)
            WriteAsciiFile("cachefs:/saimo_vod_fichas.url", base)
            WriteAsciiFile("cachefs:/saimo_vod_fichas.ready", "1")
        end if
    end if
    if not isStringValue(fichas) then fichas = ""
    applySaimoArtwork(items, fichas, fallbackCovers)
    coveredItems = 0
    for each artworkItem in items
        if strField(artworkItem, "cover") <> "" then coveredItems = coveredItems + 1
    end for
    print "SAIMO_ART letter=" + letter + " items=" + Str(items.Count()).Trim() + " covers=" + Str(coveredItems).Trim()

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

    tmdbId = m.top.tmdbId.Trim()
    if tmdbId = "" then
        ' A tarefa de capas pode terminar depois que a série já foi aberta.
        ' Aproveita o cache local para recuperar o ID sem reler fichas na UI.
        fichas = invalid
        cachedFichasBase = readCacheAscii("cachefs:/saimo_vod_fichas.url")
        fichasReady = readCacheAscii("cachefs:/saimo_vod_fichas.ready")
        if isStringValue(cachedFichasBase) and cachedFichasBase.Trim() = base and isStringValue(fichasReady) and fichasReady.Trim() = "1" then
            fichas = readCacheAscii("cachefs:/saimo_vod_fichas.txt")
        else
            fichasResponse = httpGet(base + "fichas.txt", m.top.userAgent, "")
            if fichasResponse.ok and not looksLikeHtml(fichasResponse.body) then
                fichas = fichasResponse.body
                WriteAsciiFile("cachefs:/saimo_vod_fichas.txt", fichas)
                WriteAsciiFile("cachefs:/saimo_vod_fichas.url", base)
                WriteAsciiFile("cachefs:/saimo_vod_fichas.ready", "1")
            end if
        end if
        if isStringValue(fichas) and fichas <> "" then
            series = [{ type: "series", title: m.top.title.Trim(), cover: "" }]
            applySaimoArtwork(series, fichas, {})
            tmdbId = strField(series[0], "tmdbId")
        end if
    end if
    if tmdbId <> "" and Val(tmdbId) > 0 then enrichSaimoEpisodes(items, tmdbId, m.top.userAgent)

    m.top.resultJson = FormatJson(items)
    m.top.count = items.Count()
    m.top.success = true
end sub

sub enrichSaimoEpisodes(items as object, tmdbId as string, userAgent as string)
    if type(items) <> "roArray" or Val(tmdbId) <= 0 then return
    seasons = {}
    for each item in items
        season = Val(strField(item, "season"))
        if season > 0 then seasons[Str(season).Trim()] = season
    end for

    for each seasonKey in seasons
        season = seasons[seasonKey]
        cacheBase = "cachefs:/saimo_tmdb_" + tmdbId + "_" + seasonKey
        cached = readCacheAscii(cacheBase + ".json")
        cachedAt = readCacheAscii(cacheBase + ".time")
        useCache = false
        if isStringValue(cached) and cached <> "" and isStringValue(cachedAt) then
            now = CreateObject("roDateTime").AsSeconds()
            if now - Val(cachedAt) < 86400 then useCache = true
        end if

        seasonJson = ""
        if useCache then
            seasonJson = cached
        else
            url = "https://saimotv-roku.ediglebison-sousa.workers.dev/api/tmdb/tv/" + tmdbId + "/season/" + seasonKey
            response = httpGet(url, userAgent, "")
            if response.ok and not looksLikeHtml(response.body) then
                seasonJson = response.body
                WriteAsciiFile(cacheBase + ".json", seasonJson)
                WriteAsciiFile(cacheBase + ".time", Str(CreateObject("roDateTime").AsSeconds()).Trim())
            else if isStringValue(cached) and cached <> "" then
                seasonJson = cached
            end if
        end if
        if seasonJson = "" then continue for

        parsed = ParseJson(seasonJson)
        if type(parsed) <> "roAssociativeArray" or type(parsed.episodes) <> "roArray" then continue for
        for each tmdbEpisode in parsed.episodes
            number = Val(strField(tmdbEpisode, "episode_number"))
            if number <= 0 then number = Val(strField(tmdbEpisode, "episode"))
            for each item in items
                if Val(strField(item, "season")) = season and Val(strField(item, "episode")) = number then
                    name = strField(tmdbEpisode, "name").Trim()
                    if name <> "" then item.title = name
                    overview = strField(tmdbEpisode, "overview").Trim()
                    if overview <> "" then item.synopsis = overview
                    runtime = Val(strField(tmdbEpisode, "runtime"))
                    if runtime > 0 then item.runtime = runtime
                    airDate = strField(tmdbEpisode, "air_date").Trim()
                    if airDate <> "" then item.airDate = airDate
                    still = strField(tmdbEpisode, "still_path").Trim()
                    if still <> "" then
                        if Left(LCase(still), 7) = "http://" or Left(LCase(still), 8) = "https://" then
                            item.cover = still
                        else if Left(still, 1) = "/" then
                            item.cover = "https://image.tmdb.org/t/p/w300" + still
                        end if
                    end if
                    exit for
                end if
            end for
        end for
    end for
end sub

sub loadSaimoSearch()
    base = normalizeSaimoBase(m.top.baseUrl)
    query = m.top.title.Trim()
    if query = "" then
        m.top.error = "Digite um termo para pesquisar."
        return
    end if

    raw = readCacheAscii("cachefs:/saimo_vod_search.txt")
    cachedBase = readCacheAscii("cachefs:/saimo_vod_search.url")
    if not isStringValue(cachedBase) or cachedBase.Trim() <> base or not isStringValue(raw) or raw = "" then
        response = httpGet(base + "busca.txt", m.top.userAgent, "")
        if not response.ok or looksLikeHtml(response.body) then
            m.top.error = "Nao foi possivel pesquisar o catalogo completo. Tente novamente quando a conexao estiver disponivel."
            return
        end if
        raw = response.body
        WriteAsciiFile("cachefs:/saimo_vod_search.txt", raw)
        WriteAsciiFile("cachefs:/saimo_vod_search.url", base)
    end if

    results = parseSaimoSearchItems(raw, query, 160)
    m.top.resultJson = FormatJson(results)
    m.top.count = results.Count()
    m.top.success = true
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

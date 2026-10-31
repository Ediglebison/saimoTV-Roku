' Testes de comportamento dos parsers puros do catalogo Saimo.
' Executar com: npx brs -r . SaimoTV/source/bslib.brs tools/tests/parsers_test.brs

sub main()
    m.checks = 0
    m.failures = 0

    testUrlHelpers()
    testIndexParser()
    testMovieParser()
    testSeriesParser()
    testEpisodeParser()
    testSearchParser()
    testHighlightsParser()
    testArtwork()
    testSubtitle()
    testChannelCatalog()
    testVodM3u()
    testSorting()

    if m.failures = 0 then
        print "TESTS_PASS " + Str(m.checks).Trim()
    else
        print "TESTS_FAILED " + Str(m.failures).Trim() + " de " + Str(m.checks).Trim()
    end if
end sub

function fixture(name as string) as string
    return ReadAsciiFile("pkg:/tools/tests/fixtures/" + name)
end function

sub ok(condition as boolean, message as string)
    m.checks = m.checks + 1
    if not condition then
        m.failures = m.failures + 1
        print "FAIL: " + message
    end if
end sub

sub eqStr(actual as string, expected as string, message as string)
    ok(actual = expected, message + " (esperado=[" + expected + "] obtido=[" + actual + "])")
end sub

sub eqInt(actual as integer, expected as integer, message as string)
    ok(actual = expected, message + " (esperado=" + Str(expected).Trim() + " obtido=" + Str(actual).Trim() + ")")
end sub

function findExact(items as object, title as string) as object
    if type(items) <> "roArray" then return invalid
    for each item in items
        if strField(item, "title") = title then return item
    end for
    return invalid
end function

function findLetter(letters as object, letter as string) as object
    if type(letters) <> "roArray" then return invalid
    for each row in letters
        if strField(row, "letter") = letter then return row
    end for
    return invalid
end function

function findSource(item as object, url as string) as object
    if item = invalid or type(item.sources) <> "roArray" then return invalid
    for each source in item.sources
        if strField(source, "url") = url then return source
    end for
    return invalid
end function

function hasSourceUrl(item as object, url as string) as boolean
    return findSource(item, url) <> invalid
end function

sub testUrlHelpers()
    eqStr(normalizeSaimoBase("https://exemplo.org/indice.txt"), "https://exemplo.org/", "normaliza indice para raiz")
    eqStr(normalizeSaimoBase("https://exemplo.org/vod"), "https://exemplo.org/vod/", "adiciona barra final")
    eqStr(saimoBaseUrl("https://filmes-saimo.pages.dev/indice.txt"), "https://filmes-saimo.pages.dev/", "host oficial permanece")
    eqStr(saimoBaseUrl("https://saimoplayer/main/vod"), "https://filmes-saimo.pages.dev/", "endereco legado vira host oficial")
    ok(isSaimoVodUrl("https://filmes-saimo.pages.dev/"), "reconhece host oficial do VOD")
    ok(isSaimoVodUrl("https://filmes-saimo.pages.dev/"), "reconhece alias do VOD")
    ok(not isSaimoVodUrl("https://exemplo.org/vod/"), "nao confunde VOD arbitrario")
    ok(isSaimoCatalogUrl("https://saimo-canais.pages.dev/catalogo.txt"), "reconhece host oficial dos canais")
    ok(isSaimoCatalogUrl("https://canais-saimo.pages.dev/catalogo.txt"), "reconhece alias dos canais")
    ok(not isSaimoCatalogUrl("https://exemplo.org/catalogo.txt"), "nao confunde catalogo arbitrario")
end sub

sub testIndexParser()
    text = fixture("indice.txt")
    letters = parseSaimoIndexLetters(text)
    bases = parseBases(text)
    eqInt(letters.Count(), 3, "indice le tres letras")
    a = findLetter(letters, "A")
    ok(a <> invalid, "indice contem a letra A")
    if a <> invalid then
        eqInt(a.moviesCount, 3, "contagem de filmes da letra A")
        eqInt(a.seriesCount, 2, "contagem de series da letra A")
        eqInt(a.extraCount, 1, "coluna extra da letra A")
    end if
    hash = findLetter(letters, "#")
    ok(hash <> invalid, "indice preserva a letra #")
    eqStr(bases["10"], "http://legacy.example/movie/", "base numerada do indice")
    signature = saimoIndexSignature(letters, bases)
    ok(signature <> "", "assinatura do indice nao e vazia")
    a.moviesCount = 99
    ok(saimoIndexSignature(letters, bases) <> signature, "assinatura muda quando o indice muda")
end sub

sub testMovieParser()
    bases = parseBases(fixture("indice.txt"))
    items = parseSaimoMovieItems(fixture("filmes-A.txt"), "A", bases, "TestAgent")
    eqInt(items.Count(), 3, "filmes validos e sem duplicatas")
    teia = findExact(items, "A Teia")
    ok(teia <> invalid, "filme A Teia encontrado")
    if teia <> invalid then
        eqStr(teia.type, "movie", "tipo do filme")
        eqStr(teia.group, "Filmes", "grupo do filme")
        eqStr(teia.letter, "A", "letra do filme")
        eqInt(teia.sources.Count(), 2, "duas fontes para A Teia")
        dub = findSource(teia, "https://cdn.example/a-teia.mp4")
        leg = findSource(teia, "https://cdn.example/a-teia-leg.mp4")
        ok(dub <> invalid, "fonte dublada absoluta")
        ok(leg <> invalid, "fonte legendada absoluta")
        if dub <> invalid then
            eqStr(dub.name, "Dublado", "rotulo da fonte dublada")
            eqStr(dub.userAgent, "TestAgent", "agente repassado a fonte")
        end if
    end if

    onda = findExact(items, "A 5a Onda (2016)")
    ok(onda <> invalid, "filme com source por base encontrado")
    if onda <> invalid then
        eqStr(onda.year, "2016", "ano extraido do titulo")
        eqInt(onda.sources.Count(), 1, "URL morta descartada")
        ok(hasSourceUrl(onda, "http://legacy.example/movie/2458625.mp4"), "source por base expandida")
    end if

    alive = findExact(items, "#Alive (2020)")
    ok(alive <> invalid, "titulo iniciado por # nao e tratado como comentario")
    if alive <> invalid then
        eqStr(alive.year, "2020", "ano de titulo com #")
    end if
    ok(findExact(items, "Adulto XXX") = invalid, "titulo adulto filtrado")
    ok(findExact(items, "Sem Fonte") = invalid, "titulo sem fonte valida descartado")
end sub

sub testSeriesParser()
    items = parseSaimoSeriesItems(fixture("series-A.txt"), "A")
    eqInt(items.Count(), 3, "series validas e sem duplicatas")
    academia = findExact(items, "A Academia")
    ok(academia <> invalid, "serie A Academia encontrada")
    if academia <> invalid then
        eqStr(academia.type, "series", "tipo da serie")
        eqStr(academia.group, "Series", "grupo da serie")
        eqStr(academia.year, "", "ano vazio da serie")
        eqInt(academia.piece, 0, "fragmento da serie")
        eqInt(academia.episodeCount, 8, "contagem de episodios")
    end if
    agencia = findExact(items, "A Agência")
    ok(agencia <> invalid, "serie com acento encontrada")
    if agencia <> invalid then
        eqStr(agencia.year, "2024", "ano da serie")
        eqInt(agencia.piece, 1, "segundo fragmento da serie")
        eqInt(agencia.episodeCount, 159, "episodios da serie")
    end if
    ok(findExact(items, "Serie Adulta XXX") = invalid, "serie adulta filtrada")
end sub

sub testEpisodeParser()
    bases = parseBases(fixture("indice.txt"))
    eps = parseSaimoEpisodeItems(fixture("series-A-0.txt"), "A Academia", bases, "TestAgent")
    eqInt(eps.Count(), 3, "episodios combinados e ordenados")
    if eps.Count() = 3 then
        eqStr(eps[0].title, "T01 E01", "primeiro episodio na ordem")
        eqStr(eps[1].title, "T01 E02", "segundo episodio na ordem")
        eqStr(eps[2].title, "T02 E01", "terceiro episodio na ordem")
        eqInt(eps[0].sources.Count(), 2, "fontes dub e leg combinadas")
        ok(hasSourceUrl(eps[0], "https://cdn.example/academia-s01e01.mp4"), "fonte dublada do episodio")
        ok(hasSourceUrl(eps[0], "https://cdn.example/academia-s01e01-leg.mp4"), "fonte legendada do episodio")
        ok(hasSourceUrl(eps[1], "http://legacy.example/movie/999.mp4"), "fonte de episodio por base expandida")
    end if
    eqInt(parseSaimoEpisodeItems(fixture("series-A-0.txt"), "A Academia (2024)", bases, "").Count(), 3, "busca de serie ignora ano")
    eqInt(parseSaimoEpisodeItems(fixture("series-A-0.txt"), "Outra Serie", bases, "").Count(), 1, "outra serie com um episodio")
    eqInt(parseSaimoEpisodeItems(fixture("series-A-0.txt"), "Nada", bases, "").Count(), 0, "serie inexistente nao retorna episodios")
end sub

sub testSearchParser()
    text = fixture("busca.txt")
    academia = parseSaimoSearchItems(text, "academia", 160)
    eqInt(academia.Count(), 1, "busca remove duplicata")
    if academia.Count() > 0 then
        eqStr(academia[0].type, "series", "busca classifica serie")
        eqStr(academia[0].letter, "A", "busca preserva a letra")
    end if
    agencia = parseSaimoSearchItems(text, "agencia", 160)
    eqInt(agencia.Count(), 1, "busca ignora acento")
    if agencia.Count() > 0 then eqStr(agencia[0].type, "series", "dorama e tratado como serie")
    alive = parseSaimoSearchItems(text, "#alive", 160)
    eqInt(alive.Count(), 1, "busca encontra titulo com #")
    if alive.Count() > 0 then eqStr(alive[0].type, "movie", "busca classifica filme")
    akira = parseSaimoSearchItems(text, "akira", 160)
    eqInt(akira.Count(), 1, "busca encontra anime")
    if akira.Count() > 0 then eqStr(akira[0].type, "series", "anime e tratado como serie")
    eqInt(parseSaimoSearchItems(text, "xxx", 160).Count(), 0, "busca filtra adulto")
    eqInt(parseSaimoSearchItems(text, "serie", 160).Count(), 1, "busca com acento na consulta")
    eqInt(parseSaimoSearchItems(text, "a", 2).Count(), 2, "busca respeita o limite")
end sub

sub testHighlightsParser()
    rows = parseHighlights(fixture("destaques.txt"))
    eqInt(rows.Count(), 2, "duas fileiras de destaques")
    if rows.Count() > 0 then
        eqStr(rows[0].title, "Em alta", "nome da primeira fileira")
        eqInt(rows[0].items.Count(), 4, "quatro itens validos na primeira fileira")
        first = rows[0].items[0]
        eqStr(first.cover, "https://img.example/w342/a-teia.jpg", "capa da fileira usa a base capa:")
        eqStr(first.shelf, "Em alta", "fileira preservada no item")
    end if

    flat = []
    for each row in rows
        for each item in row.items
            flat.Push(item)
        end for
    end for
    eqInt(flat.Count(), 5, "destaques consolidados")
    eqInt(pickSaimoHighlights(flat, "all", 4).Count(), 4, "selecao mista respeita o limite")
    eqInt(pickSaimoHighlights(flat, "movies", 12).Count(), 1, "filtro de filmes nos destaques")
    eqInt(pickSaimoHighlights(flat, "series", 12).Count(), 4, "filtro de series inclui s, d e a")
    mixed = pickSaimoHighlights(flat, "all", 2)
    eqStr(strField(mixed[0], "type"), "movie", "selecao mista comeca com filme")
    eqStr(strField(mixed[1], "type"), "series", "selecao mista alterna serie")
end sub

sub testArtwork()
    fichas = fixture("fichas.txt")
    items = []
    items.Push({ title: "A Teia", type: "movie", cover: "", genres: "" })
    items.Push({ title: "A 5a Onda (2016)", type: "movie", cover: "", genres: "" })
    items.Push({ title: "#Alive (2020)", type: "movie", cover: "", genres: "" })
    items.Push({ title: "Sem Capa", type: "movie", cover: "", genres: "" })
    applySaimoArtwork(items, fichas, {})
    teia = findExact(items, "A Teia")
    eqStr(teia.cover, "https://img.example/w342/a-teia.jpg", "capa relativa recebe base capa:")
    eqStr(teia.genres, "Ação,Drama", "generos aplicados junto da capa")
    onda = findExact(items, "A 5a Onda (2016)")
    eqStr(onda.cover, "https://direct.example/poster.jpg", "capa absoluta preservada")
    alive = findExact(items, "#Alive (2020)")
    eqStr(alive.cover, "https://img.example/w342/alive.jpg", "capa de titulo com #")
    eqStr(findExact(items, "Sem Capa").cover, "", "titulo sem ficha continua sem capa")

    existing = []
    existing.Push({ title: "A Teia", type: "movie", cover: "https://already.example/cover.jpg", genres: "" })
    applySaimoArtwork(existing, fichas, {})
    eqStr(existing[0].cover, "https://already.example/cover.jpg", "capa existente nao e sobrescrita")
    eqStr(existing[0].genres, "Ação,Drama", "generos preenchem item com capa existente")

    fallbackItems = []
    fallbackItems.Push({ title: "A Teia", type: "movie", cover: "", genres: "" })
    fallback = { "f:ateia": "https://destaque.example/a-teia.jpg" }
    applySaimoArtwork(fallbackItems, "", fallback)
    eqStr(fallbackItems[0].cover, "https://destaque.example/a-teia.jpg", "capa de destaque usada como fallback")

    normalizedItems = []
    normalizedItems.Push({ title: "B O (2024)", type: "movie", cover: "", genres: "" })
    normalizedFichas = "capa: https://img.example/w342" + Chr(10)
    normalizedFichas = normalizedFichas + "f" + Chr(9) + "B.O." + Chr(9) + "321" + Chr(9) + "/bo.jpg" + Chr(9) + "Drama"
    applySaimoArtwork(normalizedItems, normalizedFichas, {})
    eqStr(normalizedItems[0].cover, "https://img.example/w342/bo.jpg", "capa encontra título com pontuação e ano diferentes")
end sub

sub testSubtitle()
    eqStr(saimoItemSubtitle({ type: "movie", year: "2024", genres: "Ação,Drama" }), "Filme  •  2024  •  Ação", "legenda de filme")
    eqStr(saimoItemSubtitle({ type: "series", year: "2024", episodeCount: 8, genres: "Comédia" }), "Série  •  2024  •  8 episódios  •  Comédia", "legenda de serie")
    eqStr(saimoItemSubtitle({ type: "episode", season: 1, episode: 2 }), "Temporada 1  •  Episódio 2", "legenda de episodio")
    eqStr(saimoGridSubtitle({ type: "movie", year: "2024", genres: "Ação" }), "Filme  •  2024  •  Ação", "legenda compacta de filme")
    eqStr(saimoGridSubtitle({ type: "movie", year: "", genres: "Ação,Drama" }), "Filme  •  Ação", "legenda compacta por genero")
    eqStr(saimoGridSubtitle({ type: "series", year: "2024", episodeCount: 8, genres: "Comédia" }), "Série  •  8 episódios  •  2024  •  Comédia", "legenda compacta de serie")
    eqStr(saimoGridSubtitle({ type: "series", year: "2024", episodeCount: 0 }), "Série  •  2024", "legenda compacta de serie sem contagem")
    eqStr(saimoGridSubtitle({ type: "episode", season: 1, episode: 2 }), "Temporada 1", "legenda compacta de episodio")
    eqStr(saimoGridSubtitle({ type: "movie" }), "Filme", "legenda compacta padrao")
    eqStr(firstGenre("Ação, Drama"), "Ação", "primeiro genero")
    eqStr(firstGenre(""), "", "genero vazio")
end sub

sub testChannelCatalog()
    channels = parseCustom(fixture("catalogo.txt"), "TestAgent")
    eqInt(channels.Count(), 2, "canais com fonte valida")
    alpha = findExact(channels, "Canal Alpha")
    ok(alpha <> invalid, "canal Alpha encontrado")
    if alpha <> invalid then
        eqInt(alpha.sources.Count(), 1, "uma fonte no Alpha")
        eqStr(alpha.sources[0].referer, "https://site.example/", "referer da fonte")
        eqStr(alpha.sources[0].userAgent, "TestAgent/1.0", "agente da fonte")
        eqStr(alpha.sources[0].name, "Principal", "nome da fonte")
        eqStr(alpha.group, "Filmes", "categoria do canal")
    end if
    beta = findExact(channels, "Canal Beta")
    ok(beta <> invalid, "canal Beta encontrado")
    if beta <> invalid then
        eqInt(beta.sources.Count(), 2, "duas fontes no Beta")
        eqStr(beta.sources[1].quality, "1080p", "qualidade aplicada a fonte imediatamente anterior")
    end if
    ok(findExact(channels, "Canal ClearKey") = invalid, "fonte com chave DRM nao entra na lista")
    ok(findExact(channels, "Canal Vazio") = invalid, "canal sem fonte e descartado")
end sub

sub testVodM3u()
    parsed = parseVodM3u(fixture("vod.m3u"), "TestAgent")
    eqStr(parsed.error, "", "M3U VOD sem erro")
    eqInt(parsed.items.Count(), 2, "M3U VOD com filme e serie")
    movie = findExact(parsed.items, "Filme Um (2024)")
    ok(movie <> invalid, "filme da M3U encontrado")
    if movie <> invalid then
        eqStr(movie.type, "movie", "tipo do filme da M3U")
        eqStr(movie.cover, "https://img.example/a.jpg", "capa tvg-logo")
    end if
    series = findExact(parsed.items, "Série Teste")
    ok(series <> invalid, "serie agrupada na M3U")
    if series <> invalid then
        eqStr(series.type, "series", "tipo da serie da M3U")
        eqInt(series.episodes.Count(), 2, "episodios agrupados")
        eqStr(series.episodes[0].title, "S01E01  •  Piloto", "titulo do episodio normalizado")
        eqStr(series.episodes[1].title, "S01E02  •  Final", "segundo episodio normalizado")
    end if
    ok(findExact(parsed.items, "Conteudo XXX") = invalid, "grupo adulto filtrado na M3U")
end sub

sub testSorting()
    bases = parseBases(fixture("indice.txt"))
    movies = parseSaimoMovieItems(fixture("filmes-A.txt"), "A", bases, "")
    series = parseSaimoSeriesItems(fixture("series-A.txt"), "A")
    combined = []
    for each item in movies
        combined.Push(item)
    end for
    for each item in series
        combined.Push(item)
    end for
    sorted = sortSaimoItems(combined)
    eqInt(sorted.Count(), 6, "ordenacao preserva filmes e series")
    eqStr(sorted[0].title, "#Alive (2020)", "titulo com # ordena primeiro")
    eqStr(sorted[1].title, "A 5a Onda (2016)", "ordenacao alfabetica ignora ano")
end sub

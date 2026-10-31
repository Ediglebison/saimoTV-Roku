' Cliente nativo Saimo TV para Roku.
' Interface baseada em LabelList + indices. A selecao nao depende de campos
' personalizados em itens, o que evita o problema de clique sem resposta.

sub init()
    m.video = m.top.findNode("video")
    m.homeGroup = m.top.findNode("homeGroup")
    m.palette = appPalette()
    m.navList = m.top.findNode("navList")
    m.listEyebrow = m.top.findNode("listEyebrow")
    m.listTitle = m.top.findNode("listTitle")
    m.listSub = m.top.findNode("listSub")
    m.syncHint = m.top.findNode("syncHint")
    m.clock = m.top.findNode("clock")
    m.hint = m.top.findNode("hint")
    m.itemList = m.top.findNode("itemList")
    m.vodGrid = m.top.findNode("vodGrid")
    m.episodeGrid = m.top.findNode("episodeGrid")
    m.vodDetailGroup = m.top.findNode("vodDetailGroup")
    m.fichaBackdrop = m.top.findNode("fichaBackdrop")
    m.vodDetailPoster = m.top.findNode("vodDetailPoster")
    m.vodDetailTipo = m.top.findNode("vodDetailTipo")
    m.vodDetailTitle = m.top.findNode("vodDetailTitle")
    m.vodDetailFrase = m.top.findNode("vodDetailFrase")
    m.vodDetailMeta = m.top.findNode("vodDetailMeta")
    m.vodDetailSynopsis = m.top.findNode("vodDetailSynopsis")
    m.vodDetailActions = m.top.findNode("vodDetailActions")
    m.vodSeasonHeading = m.top.findNode("vodSeasonHeading")
    m.vodSeasonList = m.top.findNode("vodSeasonList")
    m.vodEpisodeEmpty = m.top.findNode("vodEpisodeEmpty")
    m.shelfList = m.top.findNode("shelfList")

    m.emptyLabel = m.top.findNode("emptyLabel")
    m.emptyIcon = m.top.findNode("emptyIcon")
    m.emptyAction = m.top.findNode("emptyAction")
    m.status = m.top.findNode("status")
    m.settingsGroup = m.top.findNode("settingsGroup")
    m.settingsList = m.top.findNode("settingsList")
    m.settingsHelp = m.top.findNode("settingsHelp")
    m.guideGroup = m.top.findNode("guideGroup")
    m.guideSub = m.top.findNode("guideSub")
    m.guideList = m.top.findNode("guideList")
    m.aboutGroup = m.top.findNode("aboutGroup")
    m.aboutText = m.top.findNode("aboutText")
    m.playerOverlay = m.top.findNode("playerOverlay")
    m.playerSpinner = m.top.findNode("playerSpinner")
    m.playerCenterState = m.top.findNode("playerCenterState")
    m.playerTitle = m.top.findNode("playerTitle")
    m.playerSubtitle = m.top.findNode("playerSubtitle")
    m.playerState = m.top.findNode("playerState")
    m.playerTime = m.top.findNode("playerTime")
    m.playerHint = m.top.findNode("playerHint")
    m.playerLive = m.top.findNode("playerLive")
    m.progressTrack = m.top.findNode("progressTrack")
    m.progressFill = m.top.findNode("progressFill")
    m.toastAccent = m.top.findNode("toastAccent")
    m.toastBg = m.top.findNode("toastBg")
    m.toastIcon = m.top.findNode("toastIcon")
    m.toast = m.top.findNode("toast")
    m.toastTimer = m.top.findNode("toastTimer")
    m.failoverTimer = m.top.findNode("failoverTimer")
    m.progressTimer = m.top.findNode("progressTimer")
    m.playerAutoHideTimer = m.top.findNode("playerAutoHideTimer")
    m.seekHoldTimer = m.top.findNode("seekHoldTimer")
    m.vodRefreshTimer = m.top.findNode("vodRefreshTimer")

    m.registry = CreateObject("roRegistrySection", "SaimoTV")
    m.defaultUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    m.playlistUrl = readSetting("playlistUrl")
    m.epgUrl = readSetting("epgUrl")
    m.userAgent = readSetting("userAgent")
    if m.userAgent = "" then m.userAgent = m.defaultUA
    m.vodUrl = readSetting("vodUrl")
    m.publicCatalog = "https://saimo-canais.pages.dev/catalogo.txt"
    m.defaultVodUrl = "https://filmes-saimo.pages.dev/"
    lowVod = LCase(m.vodUrl)
    if m.vodUrl = "" or Instr(1, lowVod, "filmes-saimo.pages.dev") > 0 or Instr(1, lowVod, "saimoplayer/main/vod") > 0 then
        m.vodUrl = m.defaultVodUrl
        writeSetting("vodUrl", m.vodUrl)
    end if

    m.channels = []
    m.groups = []
    m.visibleChannels = []
    m.movies = []
    m.movieRows = []
    m.vodAll = []
    m.vodMovies = []
    m.vodSeries = []
    m.vodVisibleItems = []
    m.vodFilter = "all"
    m.seriesDetail = invalid
    m.seriesReturnFilter = "all"
    m.seriesDetailReturnView = "vod"
    m.seriesDetailReturnIndex = 0
    m.seriesAllEpisodes = []
    m.seriesSeasonValues = []
    m.seriesCurrentSeason = 0
    m.detailItem = invalid
    m.detailIsSeries = false
    m.detailActionEntries = []
    m.detailReturnView = "vod"
    m.detailReturnIndex = 0
    m.detailReturnFilter = "all"
    m.pendingSaimoDetail = invalid
    m.pendingSaimoDetailReturnView = "saimo_home"
    m.pendingSaimoDetailReturnIndex = 0
    m.pendingSaimoDetailReturnFilter = "all"
    m.favoriteReturnView = "channels"
    m.favoriteReturnFilter = "all"
    m.vodLoaded = false
    m.vodRefreshing = false
    m.vodInitPending = false
    m.vodLastSync = Val(readSetting("vodLastSync"))
    m.playlistLastSync = Val(readSetting("playlistLastSync"))
    watchedRaw = readSetting("watchedEpisodes")
    if watchedRaw <> "" then
        parsed = ParseJSON(watchedRaw)
        if type(parsed) = "roAssociativeArray" then m.watchedEpisodes = parsed else m.watchedEpisodes = {}
    end if
    m.playlistNotify = false
    m.saimoIndexLetters = []
    m.saimoBases = {}
    m.saimoCovers = {}
    m.saimoHighlights = []
    m.saimoShelves = []
    m.shelfRows = []
    m.discoverHero = false
    m.saimoIndexLoaded = false
    m.saimoIndexSignature = ""
    m.saimoBase = ""
    m.saimoCurrentLetter = ""
    m.saimoCurrentItems = []
    m.saimoReturnFilter = "all"
    m.saimoBackToHome = false
    m.pendingSaimoLetter = ""
    m.pendingSaimoSeries = invalid
    m.saimoPendingFocusTitle = ""
    m.saimoPendingFocusType = ""
    m.saimoSearchEntries = []
    m.pendingSaimoSearch = ""
    m.pendingSaimoSearchEntries = []
    m.pendingVodFilter = "movies"
    m.navEntries = []
    m.listEntries = []
    m.settingsEntries = []
    m.guideChannels = []
    m.favorites = {}
    m.favoriteTitles = []
    m.vodFavoritesByKey = {}
    m.vodFavoriteItems = []
    m.epg = {}
    m.epgLoaded = false
    m.epgTask = invalid

    m.activeView = "channels"
    m.selectedGroup = ""
    m.searchActive = false
    m.searchReturnView = "channels"
    m.movieLoading = false
    m.playlistLoading = false
    m.pendingMovie = invalid
    m.pendingMoviesOpen = false

    m.fetchTask = invalid
    m.fetchKind = ""
    m.dialog = invalid
    m.editDialog = invalid
    m.editKey = ""

    m.playerVisible = false
    m.watchedEpisodes = {}
    m.pausedPosition = 0
    m.resumePending = false
    m.resumeAttempts = 0
    m.resumeTarget = 0
    m.seekHoldActive = false
    m.seekHoldDirection = 0
    m.seekHoldCount = 0
    m.seekHoldStartedAt = 0
    m.currentChannel = invalid
    m.currentSources = []
    m.currentSourceIndex = 0
    m.currentIsLive = true
    m.switchingSource = false
    m.allSourcesFailed = false

    m.settingsVisible = false
    m.guideVisible = false
    m.aboutVisible = false

    loadFavorites()
    loadVodFavorites()

    m.navList.observeField("itemSelected", "onNavSelected")
    m.itemList.observeField("itemSelected", "onItemSelected")
    m.vodGrid.observeField("itemSelected", "onVodItemSelected")
    m.vodGrid.observeField("itemFocused", "onVodItemFocused")
    m.episodeGrid.observeField("itemSelected", "onVodItemSelected")
    m.episodeGrid.observeField("itemFocused", "onVodItemFocused")
    m.vodDetailActions.observeField("itemSelected", "onVodDetailActionSelected")
    m.vodSeasonList.observeField("itemFocused", "onSeriesSeasonFocused")
    m.shelfList.observeField("rowItemSelected", "onShelfItemSelected")
    m.shelfList.observeField("rowItemFocused", "onShelfItemFocused")
    m.settingsList.observeField("itemSelected", "onSettingsSelected")
    m.settingsList.observeField("itemFocused", "onSettingsFocused")
    m.guideList.observeField("itemSelected", "onGuideSelected")

    m.video.observeField("state", "onVideoState")

    m.toastTimer.observeField("fire", "hideToast")
    m.failoverTimer.observeField("fire", "onFailoverTimer")
    m.progressTimer.observeField("fire", "onProgressTimer")
    m.playerAutoHideTimer.observeField("fire", "hidePlayerOverlay")
    if m.seekHoldTimer <> invalid then m.seekHoldTimer.observeField("fire", "onSeekHoldTimer")
    m.progressTimer.control = "start"
    m.vodRefreshTimer.observeField("fire", "onVodRefreshTimer")

    buildNav(false)
    updateChrome()
    m.top.setFocus(true)
    m.navList.setFocus(true)

    ' Primeira execucao: abre o catalogo publico por padrao. URLs customizadas
    ' continuam preservadas; somente os hosts antigos conhecidos sao migrados.
    lowPlaylist = LCase(m.playlistUrl)
    if m.playlistUrl = "" or Instr(1, lowPlaylist, "canais-saimo.pages.dev") > 0 then
        m.playlistUrl = m.publicCatalog
        writeSetting("playlistUrl", m.playlistUrl)
    end if

    loadCachedPlaylist()
    loadCachedVodCatalog()
    m.vodRefreshTimer.control = "start"
    runScheduledSync()
    if m.epgUrl <> "" then loadEpg()
end sub

' ---------------------------------------------------------------------------
' Persistencia
' ---------------------------------------------------------------------------

function readSetting(key as string) as string
    value = m.registry.Read(key)
    if value = invalid then return ""
    return value
end function

sub writeSetting(key as string, value as string)
    m.registry.Write(key, value)
    m.registry.Flush()
end sub

sub loadFavorites()
    raw = readSetting("favorites")
    if raw = "" then return
    parsed = ParseJson(raw)
    if type(parsed) <> "roArray" then return
    for each title in parsed
        if type(title) = "roString" or type(title) = "String" then
            if title <> "" then
                m.favorites[title] = true
                m.favoriteTitles.Push(title)
            end if
        end if
    end for
end sub

sub saveFavorites()
    writeSetting("favorites", FormatJson(m.favoriteTitles))
end sub

function vodFavoriteKey(item as object) as string
    if item = invalid then return ""
    itemType = LCase(strField(item, "type"))
    titleKey = saimoArtworkTitleKey(strField(item, "title"))
    if itemType = "" or titleKey = "" then return ""
    year = strField(item, "year")
    return itemType + "|" + titleKey + "|" + year
end function

function watchedKey(item as object) as string
    if item = invalid then return ""
    titleKey = saimoArtworkTitleKey(strField(item, "title"))
    if titleKey = "" then titleKey = LCase(strField(item, "title"))
    if titleKey = "" then return ""
    season = strField(item, "season")
    episode = strField(item, "episode")
    if season = "" then season = "0"
    if episode = "" then episode = "0"
    return titleKey + "|s" + season + "|e" + episode
end function

sub markWatched(item as object)
    if item = invalid then return
    key = watchedKey(item)
    if key = "" then return
    if m.watchedEpisodes = invalid then m.watchedEpisodes = {}
    m.watchedEpisodes[key] = true
    writeSetting("watchedEpisodes", FormatJSON(m.watchedEpisodes))
end sub

sub loadVodFavorites()
    raw = readSetting("vodFavorites")
    if raw = "" then return
    parsed = ParseJson(raw)
    if type(parsed) <> "roArray" then return
    for each item in parsed
        if type(item) <> "roAssociativeArray" then continue for
        key = vodFavoriteKey(item)
        if key <> "" and m.vodFavoritesByKey[key] = invalid then
            m.vodFavoritesByKey[key] = true
            m.vodFavoriteItems.Push(item)
        end if
    end for
end sub

sub saveVodFavorites()
    writeSetting("vodFavorites", FormatJson(m.vodFavoriteItems))
end sub

' ---------------------------------------------------------------------------
' Cache local
' ---------------------------------------------------------------------------

sub loadCachedPlaylist()
    if m.playlistUrl = "" then return
    cachedUrl = readCacheAscii("cachefs:/saimo_v2_playlist.url")
    if not isStringValue(cachedUrl) then return
    if cachedUrl.Trim() <> m.playlistUrl then return
    raw = readCacheAscii("cachefs:/saimo_v2_playlist.json")
    if not isStringValue(raw) or raw = "" then return
    parsed = ParseJson(raw)
    if type(parsed) <> "roArray" then return
    if parsed.Count() = 0 then return
    applyChannels(parsed, false)
end sub

sub saveCache(json as string)
    if json = "" then return
    WriteAsciiFile("cachefs:/saimo_v2_playlist.json", json)
    WriteAsciiFile("cachefs:/saimo_v2_playlist.url", m.playlistUrl)
end sub

sub loadCachedVodCatalog()
    m.vodAll = []
    m.vodMovies = []
    m.vodSeries = []
    m.vodVisibleItems = []
    m.vodLoaded = false
    m.saimoIndexLetters = []
    m.saimoHighlights = []
    m.saimoShelves = []
    m.saimoShelves = []
    m.saimoBases = {}
    m.saimoCovers = {}
    m.saimoIndexLoaded = false
    m.saimoIndexSignature = ""
    m.saimoBase = ""
    if m.vodGrid <> invalid then m.vodGrid.content = CreateObject("roSGNode", "ContentNode")
    if isSaimoVodUrl(m.vodUrl) then
        loadCachedSaimoIndex()
        return
    end if
    if m.vodUrl = "" then return
    cachedUrl = readCacheAscii("cachefs:/saimo_vod_catalog.url")
    if not isStringValue(cachedUrl) or cachedUrl.Trim() <> m.vodUrl then return
    raw = readCacheAscii("cachefs:/saimo_vod_catalog.json")
    if not isStringValue(raw) or raw = "" then return
    parsed = ParseJson(raw)
    if type(parsed) <> "roArray" or parsed.Count() = 0 then return
    m.vodAll = parsed
    rebuildVodIndexes()
    m.vodLoaded = true
    m.status.text = Str(m.vodAll.Count()).Trim() + " itens do catálogo local; sincronizando..."
end sub

sub saveVodCache(json as string)
    if json = "" or m.vodUrl = "" then return
    WriteAsciiFile("cachefs:/saimo_vod_catalog.json", json)
    WriteAsciiFile("cachefs:/saimo_vod_catalog.url", m.vodUrl)
end sub

sub loadCachedSaimoIndex()
    m.saimoIndexLoaded = false
    base = saimoBaseUrl(m.vodUrl)
    cachedUrl = readCacheAscii("cachefs:/saimo_vod_index.url")
    raw = readCacheAscii("cachefs:/saimo_vod_index.json")
    if not isStringValue(cachedUrl) or cachedUrl.Trim() <> base then return
    if not isStringValue(raw) or raw = "" then return
    parsed = ParseJson(raw)
    if type(parsed) <> "roAssociativeArray" then return
    if type(parsed.letters) <> "roArray" or parsed.letters.Count() = 0 then return
    m.saimoIndexLetters = parsed.letters
    if type(parsed.bases) = "roAssociativeArray" then m.saimoBases = parsed.bases
    if type(parsed.covers) = "roAssociativeArray" then m.saimoCovers = parsed.covers
    if type(parsed.highlights) = "roArray" then m.saimoHighlights = parsed.highlights
    if type(parsed.shelves) = "roArray" then m.saimoShelves = parsed.shelves
    if isStringValue(parsed.signature) then m.saimoIndexSignature = parsed.signature
    if m.saimoIndexSignature = "" then m.saimoIndexSignature = saimoIndexSignature(m.saimoIndexLetters, m.saimoBases)
    m.saimoBase = base
    m.saimoIndexLoaded = true
    m.status.text = Str(m.saimoIndexLetters.Count()).Trim() + " letras do catálogo em cache; verificando atualizações..."
end sub

sub saveSaimoIndex(json as string)
    if json = "" or m.vodUrl = "" then return
    WriteAsciiFile("cachefs:/saimo_vod_index.json", json)
    WriteAsciiFile("cachefs:/saimo_vod_index.url", saimoBaseUrl(m.vodUrl))
end sub

function isSyncStale(lastSync as integer) as boolean
    if lastSync <= 0 then return true
    clock = CreateObject("roDateTime")
    nowSeconds = clock.AsSeconds()
    return (nowSeconds - lastSync) >= 21600
end function

function playlistIsStale() as boolean
    return isSyncStale(m.playlistLastSync)
end function

sub rebuildVodIndexes()
    m.vodMovies = []
    m.vodSeries = []
    for each entry in m.vodAll
        if LCase(strField(entry, "type")) = "series" then
            m.vodSeries.Push(entry)
        else
            m.vodMovies.Push(entry)
        end if
    end for
    ' Compatibilidade com a busca local.
    m.movies = m.vodAll
    m.movieRows = []
end sub

function vodIsStale() as boolean
    return isSyncStale(m.vodLastSync)
end function

function relativeAge(lastSync as integer) as string
    if lastSync <= 0 then return "nunca"
    clock = CreateObject("roDateTime")
    delta = clock.AsSeconds() - lastSync
    if delta < 0 then delta = 0
    if delta < 60 then return "agora"
    if delta < 3600 then return Str(Int(delta / 60)).Trim() + " min"
    if delta < 86400 then return Str(Int(delta / 3600)).Trim() + " h"
    return Str(Int(delta / 86400)).Trim() + " d"
end function

function vodSyncLabel() as string
    if m.vodRefreshing then return "Atualizando agora..."
    if m.vodLastSync <= 0 then return "Ainda não sincronizado"
    if vodIsStale() then return "Cache antigo; sincronização pendente"
    return "Atualizado há " + relativeAge(m.vodLastSync)
end function

function playlistSyncLabel() as string
    if m.playlistLastSync <= 0 then return "Ainda não sincronizado"
    if playlistIsStale() then return "Cache antigo; sincronização pendente"
    return "Atualizado há " + relativeAge(m.playlistLastSync)
end function

sub clearCache()
    DeleteFile("cachefs:/saimo_v2_playlist.json")
    DeleteFile("cachefs:/saimo_v2_playlist.url")
    DeleteFile("cachefs:/saimo_playlist.txt")
    DeleteFile("cachefs:/saimo_playlist.url")
    DeleteFile("cachefs:/saimo_epg.xml")
    DeleteFile("cachefs:/saimo_epg.url")
    DeleteFile("cachefs:/saimo_vod_catalog.json")
    DeleteFile("cachefs:/saimo_vod_catalog.url")
    DeleteFile("cachefs:/saimo_vod_index.json")
    DeleteFile("cachefs:/saimo_vod_index.url")
    DeleteFile("cachefs:/saimo_vod_bases.json")
    DeleteFile("cachefs:/saimo_vod_bases.url")
    DeleteFile("cachefs:/saimo_vod_covers.json")
    DeleteFile("cachefs:/saimo_vod_covers.url")
    DeleteFile("cachefs:/saimo_vod_fichas.txt")
    DeleteFile("cachefs:/saimo_vod_fichas.url")
    DeleteFile("cachefs:/saimo_vod_fichas.ready")
    DeleteFile("cachefs:/saimo_vod_search.txt")
    DeleteFile("cachefs:/saimo_vod_search.url")
    DeleteFile("cachefs:/saimo_vod_letters.url")
    for each letter in ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","#"]
        DeleteFile(saimoLetterCachePath("all", letter))
        DeleteFile(saimoLetterCachePath("movies", letter))
        DeleteFile(saimoLetterCachePath("series", letter))
    end for
    m.saimoIndexLetters = []
    m.saimoHighlights = []
    m.saimoIndexLoaded = false
    m.saimoIndexSignature = ""
    m.saimoBases = {}
    m.saimoCovers = {}
    m.vodAll = []
    m.vodMovies = []
    m.vodSeries = []
    m.vodLoaded = false
    m.vodLastSync = 0
    m.playlistLastSync = 0
    writeSetting("vodLastSync", "0")
    writeSetting("playlistLastSync", "0")
    m.epg = {}
    m.epgLoaded = false
    showToastType("Cache local apagado.", "success")
end sub

sub invalidateSaimoDerivedCaches()
    DeleteFile("cachefs:/saimo_vod_search.txt")
    DeleteFile("cachefs:/saimo_vod_search.url")
    DeleteFile("cachefs:/saimo_vod_letters.url")
    for each letter in ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","#"]
        DeleteFile(saimoLetterCachePath("all", letter))
        DeleteFile(saimoLetterCachePath("movies", letter))
        DeleteFile(saimoLetterCachePath("series", letter))
    end for
end sub

' ---------------------------------------------------------------------------
' Lista de canais
' ---------------------------------------------------------------------------

sub refreshPlaylist(notify as boolean)
    if m.playlistUrl = "" then
        showToast("Configure a URL da lista em Ajustes.")
        return
    end if
    if m.fetchTask <> invalid then
        if notify then showToast("Aguarde o carregamento atual terminar.")
        return
    end if

    if not startFetch("playlist", m.playlistUrl, "", "", "", "") then return
    m.playlistLoading = true
    m.playlistNotify = notify
    m.status.text = "Baixando lista de canais..."
    if notify then showToast("Atualizando lista...")
end sub

sub refreshVodCatalog(notify as boolean)
    if m.vodUrl = "" then
        if notify then showToast("Configure a fonte do catálogo em Ajustes.")
        return
    end if
    if m.fetchTask <> invalid then
        if m.fetchKind = "playlist" then m.vodInitPending = true
        if notify then showToast("Outra atualização está em andamento; o catálogo será sincronizado em seguida.")
        return
    end if

    if isSaimoVodUrl(m.vodUrl) then
        base = saimoBaseUrl(m.vodUrl)
        if not startFetch("saimo_index", base + "indice.txt", base, "", "", "") then return
    else
        if not startFetch("vod_catalog", m.vodUrl, "", "", "", "") then return
    end if
    m.vodRefreshing = true
    m.status.text = "Sincronizando catálogo de filmes e séries..."
    if notify then showToast("Atualizando catálogo de filmes e séries...")
    updateChrome()
end sub

' Verifica a cada 15 minutos, mas baixa apenas quando o cache tem mais de
' 6 horas. Nunca interrompe a tela atual do usuario.
sub runScheduledSync()
    if m.fetchTask <> invalid then return
    needPlaylist = m.playlistUrl <> "" and playlistIsStale()
    needVod = m.vodUrl <> "" and vodIsStale()
    if needPlaylist then
        if needVod then m.vodInitPending = true
        refreshPlaylist(false)
    else if needVod then
        refreshVodCatalog(false)
    end if
end sub

sub onVodRefreshTimer()
    runScheduledSync()
end sub

function startFetch(mode as string, url as string, base as string, letter as string, title as string, signature as string) as boolean
    if m.fetchTask <> invalid then return false
    task = CreateObject("roSGNode", "FetchTask")
    task.mode = mode
    task.url = url
    task.baseUrl = base
    task.letter = letter
    task.title = title
    task.signature = signature
    task.userAgent = m.userAgent
    task.observeField("state", "onFetchState")
    m.fetchTask = task
    m.fetchKind = mode
    task.control = "RUN"
    return true
end function

sub onFetchState()
    if m.fetchTask = invalid then return
    state = m.fetchTask.state
    if state <> "done" and state <> "stop" then return

    task = m.fetchTask
    kind = m.fetchKind
    m.fetchTask = invalid
    m.fetchKind = ""

    if kind = "playlist" then
        handlePlaylistResult(task)
    else if kind = "vod_catalog" then
        handleVodCatalogResult(task)
    else if kind = "saimo_index" then
        handleSaimoIndexResult(task)
    else if kind = "saimo_letter" then
        handleSaimoLetterResult(task)
    else if kind = "saimo_episodes" then
        handleSaimoEpisodesResult(task)
    else if kind = "saimo_search" then
        handleSaimoSearchResult(task)
    end if

    ' Retoma a navegacao pedida enquanto outra requisicao terminava.
    if m.pendingSaimoLetter <> "" then
        letterPending = m.pendingSaimoLetter
        m.pendingSaimoLetter = ""
        loadSaimoLetter(letterPending)
    else if kind <> "saimo_episodes" and m.pendingSaimoSeries <> invalid then
        seriesPending = m.pendingSaimoSeries
        m.pendingSaimoSeries = invalid
        loadSaimoEpisodes(seriesPending)
    end if
    if m.fetchTask = invalid and kind <> "saimo_search" and m.pendingSaimoSearch <> "" then
        queryPending = m.pendingSaimoSearch
        entriesPending = m.pendingSaimoSearchEntries
        m.pendingSaimoSearch = ""
        m.pendingSaimoSearchEntries = []
        startSaimoSearch(queryPending, entriesPending)
    end if

    ' Se o usuario abriu o catalogo enquanto a lista de canais carregava,
    ' retoma a navegacao assim que a tarefa terminar.
    if kind = "playlist" and m.pendingMoviesOpen then
        m.pendingMoviesOpen = false
        openVod(m.pendingVodFilter)
    end if
    if kind = "playlist" and m.vodInitPending then
        m.vodInitPending = false
        if m.vodUrl <> "" then refreshVodCatalog(false)
    end if
end sub

sub handlePlaylistResult(task as object)
    m.playlistLoading = false
    notify = m.playlistNotify
    m.playlistNotify = false
    ' Descarta respostas de uma URL antiga, por exemplo se ela foi alterada em Ajustes.
    if task.url.Trim() <> m.playlistUrl then
        if m.playlistUrl <> "" then refreshPlaylist(false)
        return
    end if
    if task.success <> true then
        message = strField(task, "error")
        if message = "" then message = "Falha ao baixar a lista."
        m.status.text = message
        if notify or m.activeView = "channels" then showToastType(message, "error")
        if m.channels.Count() = 0 and m.activeView = "channels" then showEmptyState(message)
        return
    end if

    channels = ParseJson(task.resultJson)
    if type(channels) <> "roArray" or channels.Count() = 0 then
        m.status.text = "A lista não possui canais válidos."
        if notify or m.activeView = "channels" then showToastType("A lista não possui canais válidos.", "error")
        if m.channels.Count() = 0 and m.activeView = "channels" then showEmptyState("A lista não possui canais válidos.")
        return
    end if

    applyChannels(channels, notify)
    saveCache(task.resultJson)
    clock = CreateObject("roDateTime")
    m.playlistLastSync = clock.AsSeconds()
    writeSetting("playlistLastSync", Str(m.playlistLastSync).Trim())
    if notify or m.activeView = "channels" then showToastType(Str(m.channels.Count()).Trim() + " canais atualizados.", "success")
    if m.epgUrl <> "" and not m.epgLoaded then loadEpg()
end sub

sub applyChannels(rawChannels as object, forceFocus as boolean)
    normalized = []
    for each raw in rawChannels
        ch = normalizeChannel(raw)
        if ch <> invalid then normalized.Push(ch)
    end for
    if normalized.Count() = 0 then
        if m.activeView = "channels" then showEmptyState("A lista não possui canais válidos.")
        return
    end if

    wasChannels = m.activeView = "channels"
    m.channels = normalized
    buildGroups()
    if m.selectedGroup <> "" and findGroup(m.selectedGroup) = invalid then m.selectedGroup = ""
    buildNav(true)
    if wasChannels then
        m.searchActive = false
        populateChannels(m.selectedGroup, forceFocus)
    end if
    m.status.text = Str(m.channels.Count()).Trim() + " canais  •  " + Str(m.groups.Count()).Trim() + " grupos  •  " + playlistSyncLabel()
end sub

function normalizeChannel(raw as object) as object
    if type(raw) <> "roAssociativeArray" then return invalid
    title = strField(raw, "title").Trim()
    if title = "" then return invalid
    group = strField(raw, "group").Trim()
    if group = "" then group = "Canais"
    sourcesRaw = raw.sources
    if type(sourcesRaw) <> "roArray" then return invalid

    sources = []
    for each rawSource in sourcesRaw
        if type(rawSource) = "roAssociativeArray" then
            url = strField(rawSource, "url").Trim()
            if isValidUrl(url) and not isDeadUrl(url) then
                source = {
                    url: url
                    referer: strField(rawSource, "referer")
                    userAgent: strField(rawSource, "userAgent")
                    name: strField(rawSource, "name")
                    quality: strField(rawSource, "quality")
                    streamFormat: strField(rawSource, "streamFormat")
                    isLive: boolField(rawSource, "isLive", true)
                }
                sources.Push(source)
            end if
        end if
    end for
    if sources.Count() = 0 then return invalid

    return {
        title: title
        logo: strField(raw, "logo")
        group: group
        tvgId: strField(raw, "tvgId")
        sources: sources
        isLive: true
    }
end function

sub buildGroups()
    m.groups = []
    seen = {}
    for each ch in m.channels
        group = ch.group
        if group = "" then group = "Canais"
        count = 0
        if seen[group] = invalid then
            row = { name: group, count: 0 }
            seen[group] = row
            m.groups.Push(row)
        end if
        row = seen[group]
        row.count = row.count + 1
    end for
end sub

function findGroup(name as string) as object
    for each row in m.groups
        if row.name = name then return row
    end for
    return invalid
end function

sub buildNav(preserveSelection as boolean)
    oldKind = ""
    oldValue = ""
    if preserveSelection and m.navEntries.Count() > 0 then
        oldIndex = m.navList.itemFocused
        if oldIndex < 0 then oldIndex = m.navList.itemSelected
        if oldIndex >= 0 and oldIndex < m.navEntries.Count() then
            oldKind = m.navEntries[oldIndex].kind
            oldValue = m.navEntries[oldIndex].value
        end if
    end if

    entries = []
    entries.Push({ title: "Ao vivo", kind: "view", value: "channels", icon: "nav_live.png" })
    entries.Push({ title: "Descobrir", kind: "view", value: "discover", icon: "nav_discover.png" })
    entries.Push({ title: "Catálogo A–Z", kind: "view", value: "catalog", icon: "nav_catalog.png" })
    entries.Push({ title: "Filmes", kind: "view", value: "movies", icon: "nav_movies.png" })
    entries.Push({ title: "Séries", kind: "view", value: "series", icon: "nav_series.png" })
    entries.Push({ title: "Favoritos", kind: "view", value: "favorites", icon: "nav_favorites.png" })
    entries.Push({ title: "Buscar", kind: "search", value: "", icon: "nav_search.png" })
    entries.Push({ title: "Guia de TV", kind: "guide", value: "", icon: "nav_guide.png" })
    entries.Push({ title: "Ajustes", kind: "settings", value: "", icon: "nav_settings.png" })
    entries.Push({ title: "Sincronizar", kind: "refresh", value: "", icon: "nav_sync.png" })

    if m.channels.Count() > 0 then
        entries.Push({ title: "Categorias", kind: "header", value: "", icon: "nav_blank.png" })
        entries.Push({ title: "Todos os canais", kind: "group", value: "", icon: "nav_group.png" })
        for each row in m.groups
            entries.Push({ title: row.name + " (" + Str(row.count).Trim() + ")", kind: "group", value: row.name, icon: "nav_group.png" })
        end for
    end if

    m.navEntries = entries
    root = CreateObject("roSGNode", "ContentNode")
    for each entry in entries
        item = root.CreateChild("ContentNode")
        item.title = entry.title
        if entry.icon <> "" then
            iconPath = "pkg:/images/" + entry.icon
            item.HDListItemIconUrl = iconPath
            item.HDListItemIconSelectedUrl = iconPath
        end if
    end for
    m.navList.content = root

    ' O menu fica sempre no topo. Os grupos aparecem logo abaixo; nao pulamos
    ' para o grupo atual para nao esconder as acoes principais.
    restored = -1
    if preserveSelection and oldKind <> "" then restored = findNavIndex(oldKind, oldValue)
    if restored >= 0 then m.navList.jumpToItem = restored else m.navList.jumpToItem = 0
end sub

function findNavIndex(kind as string, value as string) as integer
    index = 0
    for each entry in m.navEntries
        if entry.kind = kind and entry.value = value then return index
        index = index + 1
    end for
    return -1
end function

' ---------------------------------------------------------------------------
' Cromo da tela: cabecalho, relogio e sincronizacao
' ---------------------------------------------------------------------------

sub setViewHeader(eyebrow as string, title as string, subText as string)
    m.shelfList.visible = false
    if m.vodDetailGroup <> invalid then m.vodDetailGroup.visible = false
    if m.discoverHero then
        m.discoverHero = false
        m.listEyebrow.translation = [452, 53]
        m.listTitle.translation = [450, 79]
        m.listSub.translation = [454, 157]
    end if
    if m.listEyebrow <> invalid then m.listEyebrow.text = eyebrow
    if m.listTitle <> invalid then m.listTitle.text = title
    if m.listSub <> invalid then m.listSub.text = subText
end sub

' Fundo proprio da ficha: cover http vira uri do fichaBackdrop; qualquer
' outra coisa (vazio, pkg:, caminho invalido) esconde a imagem de fundo.
sub showFichaBackdrop(cover as string)
    if m.fichaBackdrop = invalid then return
    if Left(cover, 4) = "http" then
        m.fichaBackdrop.uri = cover
        m.fichaBackdrop.visible = true
    else
        m.fichaBackdrop.uri = ""
        m.fichaBackdrop.visible = false
    end if
end sub

sub updateClock()
    if m.clock = invalid then return
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    m.clock.text = pad2(now.GetHours()) + ":" + pad2(now.GetMinutes())
end sub

sub updateSyncHint()
    if m.syncHint = invalid then return
    m.syncHint.text = syncHintText()
end sub

function syncHintText() as string
    if m.activeView = "channels" then
        if m.playlistLastSync <= 0 then return "CANAIS  •  Ainda não sincronizado"
        if playlistIsStale() then return "CANAIS  •  Atualização pendente"
        return "CANAIS  •  Atualizado " + relativeAge(m.playlistLastSync)
    end if
    if m.vodRefreshing then return "CATÁLOGO  •  Sincronizando agora..."
    if m.vodLastSync <= 0 then return "CATÁLOGO  •  Ainda não sincronizado"
    if vodIsStale() then return "CATÁLOGO  •  Atualização pendente"
    return "CATÁLOGO  •  Atualizado " + relativeAge(m.vodLastSync)
end function

sub updateChrome()
    if m.syncHint <> invalid then m.syncHint.color = m.palette.textSecondary
    if m.clock <> invalid then m.clock.color = m.palette.textPrimary
    if m.hint <> invalid then m.hint.color = m.palette.textSecondary
    updateClock()
    updateSyncHint()
end sub

sub onNavSelected()
    index = m.navList.itemSelected
    if index < 0 or index >= m.navEntries.Count() then return
    entry = m.navEntries[index]
    kind = entry.kind

    if kind = "header" then
        if m.itemList.content <> invalid then m.itemList.setFocus(true)
        return
    end if

    if kind = "view" and entry.value = "channels" then
        m.activeView = "channels"
        m.searchActive = false
        populateChannels(m.selectedGroup, true)
    else if kind = "view" and entry.value = "discover" then
        openVodHome("all")
    else if kind = "view" and entry.value = "catalog" then
        openCatalog()
    else if kind = "view" and entry.value = "movies" then
        openMovies()
    else if kind = "view" and entry.value = "series" then
        openSeries()
    else if kind = "view" and entry.value = "favorites" then
        m.favoriteReturnView = m.activeView
        m.favoriteReturnFilter = m.vodFilter
        showVodFavorites()
    else if kind = "search" then
        openSearchDialog()
    else if kind = "guide" then
        openGuide()
    else if kind = "settings" then
        openSettings()
    else if kind = "refresh" then
        if m.playlistUrl = "" then
            openSettings()
        else
            if m.vodUrl <> "" then m.vodInitPending = true
            refreshPlaylist(true)
        end if
    else if kind = "group" then
        m.activeView = "channels"
        m.searchActive = false
        populateChannels(entry.value, true)
    end if
end sub

sub populateChannels(groupName as string, forceFocus as boolean)
    previousIndex = m.itemList.itemFocused
    m.activeView = "channels"
    m.searchActive = false
    m.itemList.visible = true
    m.vodGrid.visible = false
    m.episodeGrid.visible = false
    m.selectedGroup = groupName
    m.listEntries = []
    m.visibleChannels = []
    sourceTotal = 0

    for each ch in m.channels
        if groupName = "" or ch.group = groupName then
            m.visibleChannels.Push(ch)
            m.listEntries.Push({ kind: "channel", data: ch })
            sourceTotal = sourceTotal + ch.sources.Count()
        end if
    end for

    title = "Todos os canais"
    if groupName <> "" then title = groupName
    setViewHeader("AO VIVO", title, Str(m.visibleChannels.Count()).Trim() + " canais  •  " + Str(sourceTotal).Trim() + " fontes  •  OK abre")
    m.emptyLabel.text = "Nenhum canal neste grupo."
    renderEntries(false)

    ' Uma atualizacao em segundo plano preserva o item em foco.
    focusIndex = 0
    if not forceFocus and previousIndex >= 0 and previousIndex < m.listEntries.Count() then focusIndex = previousIndex
    if m.listEntries.Count() > 0 then
        if not forceFocus and focusIndex > 0 then m.itemList.jumpToItem = focusIndex
    end if
    if forceFocus and not m.settingsVisible and not m.guideVisible and not m.aboutVisible then
        m.itemList.setFocus(true)
    end if
end sub

' ---------------------------------------------------------------------------
' Renderizacao da lista e previa
' ---------------------------------------------------------------------------

sub renderEntries(resetPosition as boolean)
    root = CreateObject("roSGNode", "ContentNode")
    for each entry in m.listEntries
        item = root.CreateChild("ContentNode")
        if entry.kind = "header" then
            item.title = "  " + entry.title
        else if entry.kind = "channel" then
            ch = entry.data
            prefix = ""
            if m.favorites[ch.title] = true then prefix = "★ "
            item.title = prefix + ch.title
            if ch.tvgId <> "" and m.epg[ch.tvgId] <> invalid then
                programme = m.epg[ch.tvgId]
                programmeTitle = strField(programme, "nowTitle")
                if programmeTitle <> "" then item.title = item.title + "  •  " + programmeTitle
                if Val(strField(programme, "nowStop")) > Val(strField(programme, "nowStart")) then
                    elapsed = CreateObject("roDateTime").AsSeconds() - Val(strField(programme, "nowStart"))
                    duration = Val(strField(programme, "nowStop")) - Val(strField(programme, "nowStart"))
                    percent = Int(100 * elapsed / duration)
                    if percent < 0 then percent = 0
                    if percent > 100 then percent = 100
                    item.title = item.title + "  ·  " + Str(percent).Trim() + "%"
                end if
            end if
        else if entry.kind = "movie" or entry.kind = "vod" then
            itemData = entry.data
            title = strField(itemData, "title")
            year = strField(itemData, "year")
            if year <> "" and Instr(1, title, "(" + year + ")") = 0 then title = title + "  (" + year + ")"
            item.title = title
        else if entry.kind = "saimo_letter" then
            letterRow = entry.data
            letterTitle = strField(letterRow, "letter")
            movieCount = Val(strField(letterRow, "moviesCount"))
            seriesCount = Val(strField(letterRow, "seriesCount"))
            if m.vodFilter = "movies" then
                item.title = letterTitle + "     " + Str(movieCount).Trim() + " filmes"
            else if m.vodFilter = "series" then
                item.title = letterTitle + "     " + Str(seriesCount).Trim() + " séries"
            else
                item.title = letterTitle + "     " + Str(movieCount).Trim() + " filmes  •  " + Str(seriesCount).Trim() + " séries"
            end if
        else if entry.kind = "saimo_search_result" then
            itemData = entry.data
            title = strField(itemData, "title")
            year = strField(itemData, "year")
            if year <> "" then title = title + "  (" + year + ")"
            if strField(itemData, "type") = "series" then title = "Série  •  " + title
            item.title = title
        end if
    end for

    m.itemList.content = root
    if resetPosition and m.listEntries.Count() > 0 then m.itemList.jumpToItem = 0
    empty = m.listEntries.Count() = 0
    m.emptyLabel.visible = empty
end sub

sub onItemSelected()
    index = m.itemList.itemSelected
    if index < 0 or index >= m.listEntries.Count() then return
    entry = m.listEntries[index]
    if entry.kind = "header" then return

    if entry.kind = "saimo_letter" then
        loadSaimoLetter(entry.data.letter)
    else if entry.kind = "saimo_search_result" then
        m.vodFilter = "movies"
        if strField(entry.data, "type") = "series" then m.vodFilter = "series"
        openSaimoEntry(entry.data, "search", index)
    else if entry.kind = "channel" then
        m.status.text = "Abrindo " + entry.data.title + "..."
        playChannel(entry.data)
    else if entry.kind = "movie" or entry.kind = "vod" then
        data = entry.data
        itemType = LCase(strField(data, "type"))
        if itemType = "series" and (strField(data, "sourceType") = "saimo" or (strField(data, "letter") <> "" and strField(data, "piece") <> "")) then
            m.seriesDetailReturnView = "search"
            m.seriesDetailReturnIndex = index
            loadSaimoEpisodes(data)
        else if itemType = "series" and type(data.episodes) = "roArray" and data.episodes.Count() > 0 then
            showSeriesEpisodes(data, "search", index)
        else if itemType = "series" then
            showSeriesDetails(data, [], "vod_episodes", "search", index)
        else
            showVodMovieDetails(data, "search", index)
        end if
    end if
end sub

sub showEmptyState(message as string)
    m.itemList.visible = true
    m.vodGrid.visible = false
    m.episodeGrid.visible = false
    m.listEntries = []
    m.visibleChannels = []
    renderEntries(false)
    setViewHeader("AO VIVO", "Canais", "Nenhum conteúdo carregado")
    m.emptyLabel.text = message + Chr(10) + Chr(10) + "Abra Ajustes para configurar sua lista de canais e, separadamente, o catálogo VOD autorizado."
    m.emptyIcon.visible = true
    m.emptyAction.visible = true
    m.status.text = message
    if not m.settingsVisible and not m.guideVisible and not m.aboutVisible then
        m.navList.setFocus(true)
    end if
end sub

' ---------------------------------------------------------------------------
' Filmes
' ---------------------------------------------------------------------------

sub openMovies()
    openVod("movies")
end sub

sub openSeries()
    openVod("series")
end sub

sub openCatalog()
    openVod("all")
end sub

sub openVodHome(filter as string)
    if isSaimoVodUrl(m.vodUrl) then
        showSaimoHome(filter)
        if not m.saimoIndexLoaded and m.fetchTask = invalid then refreshVodCatalog(false)
    else
        openVod(filter)
    end if
end sub

sub openVod(filter as string)
    if filter <> "movies" and filter <> "series" then filter = "all"
    if m.fetchTask <> invalid and m.fetchKind = "playlist" then
        m.pendingMoviesOpen = true
        m.pendingVodFilter = filter
        m.activeView = "vod"
        setViewHeader("CATÁLOGO", "Filmes e séries", "Aguardando a lista de canais terminar...")
        m.emptyLabel.text = "O catálogo abrirá assim que o carregamento atual terminar."
        m.emptyLabel.visible = true
        showToast("Aguarde; o catálogo será aberto em seguida.")
        return
    end if

    if m.fetchTask <> invalid and m.fetchKind <> "vod_catalog" and m.fetchKind <> "saimo_index" then
        showToast("Aguarde o carregamento atual terminar.")
        return
    end if

    m.vodFilter = filter
    m.seriesDetail = invalid
    if isSaimoVodUrl(m.vodUrl) then
        m.saimoReturnFilter = filter
        showSaimoLetters(filter)
        if not m.saimoIndexLoaded and m.fetchTask = invalid then refreshVodCatalog(false)
        return
    end if
    if m.vodLoaded then
        showVod(filter)
        if vodIsStale() and m.fetchTask = invalid then refreshVodCatalog(false)
        return
    end if

    m.activeView = "vod"
    m.searchActive = false
    setViewHeader("CATÁLOGO", vodTitleForFilter(filter), vodSyncLabel())
    m.itemList.visible = false
    m.vodGrid.visible = true
    m.episodeGrid.visible = false
    m.emptyLabel.visible = true
    if m.vodUrl = "" then
        m.emptyLabel.text = "Para carregar o catálogo completo, abra Ajustes e informe a URL M3U/M3U8 de filmes e séries que você tem permissão para acessar.\n\nO app verifica novidades a cada 15 minutos e baixa o catálogo quando o cache tem mais de 6 horas."
        m.listSub.text = "Nenhuma fonte VOD configurada"
    else
        m.emptyLabel.text = "Carregando o catálogo... os títulos em cache aparecerão primeiro quando estiverem disponíveis."
        if m.fetchTask = invalid then refreshVodCatalog(false)
    end if
    m.navList.setFocus(true)
end sub

sub showVodFavorites()
    m.activeView = "vod_favorites"
    m.seriesDetail = invalid
    m.vodVisibleItems = m.vodFavoriteItems
    m.searchActive = false
    m.itemList.visible = false
    m.vodGrid.visible = true
    m.episodeGrid.visible = false
    m.shelfList.visible = false
    setViewHeader("FAVORITOS", "Seus filmes e séries", Str(m.vodFavoriteItems.Count()).Trim() + " títulos salvos  •  OK abre os detalhes")
    m.emptyLabel.visible = m.vodFavoriteItems.Count() = 0
    if m.vodFavoriteItems.Count() = 0 then
        m.emptyLabel.text = "Sua lista de favoritos está vazia." + Chr(10) + Chr(10) + "Abra os detalhes de um filme ou série e selecione Favorito para salvar."
        m.vodGrid.content = CreateObject("roSGNode", "ContentNode")
        m.navList.setFocus(true)
        return
    end if
    buildVodGrid(m.vodFavoriteItems)
    m.emptyLabel.visible = false
    m.vodGrid.setFocus(true)
end sub

function vodTitleForFilter(filter as string) as string
    if filter = "movies" then return "Filmes"
    if filter = "series" then return "Séries e episódios"
    return "Catálogo completo"
end function

sub handleVodCatalogResult(task as object)
    m.vodRefreshing = false
    ' Nunca grava uma resposta antiga sob a URL VOD atual.
    if task.url.Trim() <> m.vodUrl then
        if m.vodUrl <> "" then refreshVodCatalog(false)
        return
    end if
    if task.success <> true then
        message = strField(task, "error")
        if message = "" then message = "Não foi possível atualizar o catálogo."
        m.status.text = message
        showToastType(message, "error")
        if m.activeView = "vod" and not m.vodLoaded then
            m.emptyLabel.text = message + Chr(10) + Chr(10) + "Confira a URL M3U em Ajustes."
            m.emptyLabel.visible = true
            m.listSub.text = "Falha na sincronização; cache preservado"
        else if m.vodLoaded then
            m.listSub.text = Str(m.vodAll.Count()).Trim() + " títulos  •  cache preservado"
        end if
        return
    end if

    parsed = ParseJson(task.resultJson)
    if type(parsed) <> "roArray" or parsed.Count() = 0 then
        showToastType("O catálogo retornou dados vazios; o cache foi preservado.", "error")
        return
    end if

    m.vodAll = parsed
    rebuildVodIndexes()
    m.vodLoaded = true
    saveVodCache(task.resultJson)
    clock = CreateObject("roDateTime")
    m.vodLastSync = clock.AsSeconds()
    writeSetting("vodLastSync", Str(m.vodLastSync).Trim())
    m.status.text = Str(m.vodAll.Count()).Trim() + " títulos sincronizados."
    showToastType(Str(m.vodAll.Count()).Trim() + " títulos no catálogo atualizados.", "success")

    if m.activeView = "vod" then
        showVod(m.vodFilter)
    else if m.activeView = "vod_episodes" and m.seriesDetail <> invalid then
        title = m.seriesDetail.title
        for each series in m.vodSeries
            if LCase(series.title) = LCase(title) then
                m.seriesDetail = series
                exit for
            end if
        end for
        showSeriesEpisodes(m.seriesDetail, m.seriesDetailReturnView, m.seriesDetailReturnIndex)
    end if
end sub

sub handleSaimoIndexResult(task as object)
    m.vodRefreshing = false
    base = saimoBaseUrl(m.vodUrl)
    if saimoBaseUrl(strField(task, "baseUrl")) <> base then
        if m.vodUrl <> "" then refreshVodCatalog(false)
        return
    end if
    if task.success <> true then
        message = strField(task, "error")
        if message = "" then message = "Não foi possível atualizar o índice do catálogo."
        m.status.text = message
        if not m.saimoIndexLoaded and (m.activeView = "saimo_letters" or m.activeView = "saimo_home") then
            m.emptyLabel.text = message + Chr(10) + Chr(10) + "O cache será preservado e o app tentará novamente quando houver conexão."
            m.emptyLabel.visible = true
            m.listSub.text = "Catálogo temporariamente indisponível"
        end if
        if m.saimoIndexLoaded then showToast("Catálogo offline: usando índice em cache.") else showToastType(message, "error")
        return
    end if

    parsed = ParseJson(task.resultJson)
    if type(parsed) <> "roAssociativeArray" or type(parsed.letters) <> "roArray" or parsed.letters.Count() = 0 then
        showToastType("O índice recebido não é válido; o cache foi preservado.", "error")
        return
    end if

    newSignature = strField(parsed, "signature")
    if newSignature = "" then newSignature = saimoIndexSignature(parsed.letters, parsed.bases)
    indexChanged = newSignature <> m.saimoIndexSignature
    if indexChanged then invalidateSaimoDerivedCaches()

    m.saimoIndexLetters = parsed.letters
    if type(parsed.bases) = "roAssociativeArray" then m.saimoBases = parsed.bases
    if type(parsed.covers) = "roAssociativeArray" then m.saimoCovers = parsed.covers
    if type(parsed.highlights) = "roArray" then m.saimoHighlights = parsed.highlights
    if type(parsed.shelves) = "roArray" then m.saimoShelves = parsed.shelves
    m.saimoIndexSignature = newSignature
    m.saimoBase = base
    m.saimoIndexLoaded = true
    saveSaimoIndex(task.resultJson)

    clock = CreateObject("roDateTime")
    m.vodLastSync = clock.AsSeconds()
    writeSetting("vodLastSync", Str(m.vodLastSync).Trim())
    m.status.text = Str(m.saimoIndexLetters.Count()).Trim() + " letras sincronizadas; catálogo atualizado."

    if m.activeView = "saimo_letters" then
        hadListFocus = m.itemList.hasFocus()
        focusIndex = m.itemList.itemFocused
        showSaimoLetters(m.vodFilter)
        if focusIndex > 0 and focusIndex < m.listEntries.Count() then m.itemList.jumpToItem = focusIndex
        if not hadListFocus then m.navList.setFocus(true)
    else if m.activeView = "saimo_home" then
        hadGridFocus = m.vodGrid.hasFocus()
        focusIndex = m.vodGrid.itemFocused
        showSaimoHome(m.vodFilter)
        if focusIndex > 0 and focusIndex < m.vodVisibleItems.Count() then m.vodGrid.jumpToItem = focusIndex
        if not hadGridFocus then m.navList.setFocus(true)
    else if indexChanged and m.activeView = "saimo_catalog" and m.saimoCurrentLetter <> "" then
        loadSaimoLetter(m.saimoCurrentLetter)
    end if
end sub

sub showSaimoHome(filter as string)
    if filter <> "movies" and filter <> "series" then filter = "all"
    if not m.saimoIndexLoaded then
        m.activeView = "saimo_home"
        m.vodFilter = filter
        m.itemList.visible = false
        m.vodGrid.visible = false
        m.episodeGrid.visible = false
        setViewHeader("DESCOBRIR", "Descubra filmes e séries", "Sincronizando o catálogo público...")
        m.emptyLabel.text = "Estamos carregando os destaques do catálogo." + Chr(10) + Chr(10) + "Assim que o índice estiver disponível, esta tela mostrará títulos em destaque. Você também pode usar Catálogo A-Z para navegar por letra."
        m.emptyLabel.visible = true
        m.navList.setFocus(true)
        return
    end if

    featured = pickSaimoHighlights(m.saimoHighlights, filter, 12)

    if m.saimoShelves.Count() > 0 then
        showSaimoShelves(filter)
        return
    end if

    if featured.Count() = 0 then
        showSaimoLetters(filter)
        showToast("Destaques indisponíveis; abrindo o catálogo por letra.")
        return
    end if

    m.activeView = "saimo_home"
    m.vodFilter = filter
    m.seriesDetail = invalid
    m.searchActive = false
    m.vodVisibleItems = featured
    m.saimoCurrentItems = featured
    m.itemList.visible = false
    m.vodGrid.visible = true
    m.episodeGrid.visible = false
    subText = Str(featured.Count()).Trim() + " destaques  •  filmes e séries  •  use Catálogo A-Z para explorar"
    setViewHeader("DESCOBRIR", "Em alta agora", subText)
    ' A grade ocupa a área livre ao lado da navegação.
    m.vodGrid.numColumns = 3
    ' Duas fileiras ficam visíveis; a terceira entra com a navegação vertical.
    ' Isso evita que os cartões invadam a barra inferior de status em 1080p.
    m.vodGrid.numRows = 2
    m.emptyLabel.visible = false
    buildVodGrid(featured)
    if featured.Count() > 0 then onVodItemFocused()
    if m.hint <> invalid then m.hint.text = "Setas navegam  •  OK abre o título no catálogo  •  Replay busca  •  Back retorna"
    m.vodGrid.setFocus(true)
end sub

sub showSaimoShelves(filter as string)
    root = CreateObject("roSGNode", "ContentNode")
    m.shelfRows = []
    for each shelf in m.saimoShelves
        rowItems = []
        if type(shelf.items) <> "roArray" then continue for
        for each entry in shelf.items
            entryType = strField(entry, "type")
            if filter = "movies" and entryType <> "movie" then continue for
            if filter = "series" and entryType <> "series" then continue for
            rowItems.Push(entry)
        end for
        if rowItems.Count() = 0 then continue for
        rowTitle = strField(shelf, "title")
        row = root.CreateChild("ContentNode")
        row.title = rowTitle
        for each entry in rowItems
            card = row.CreateChild("ContentNode")
            card.title = strField(entry, "title")
            poster = strField(entry, "cover")
            if poster = "" then poster = "pkg:/images/placeholder.png"
            card.hdPosterUrl = poster
        end for
        m.shelfRows.Push({ title: rowTitle, items: rowItems })
    end for

    m.activeView = "saimo_home"
    m.vodFilter = filter
    m.seriesDetail = invalid
    m.searchActive = false
    m.vodVisibleItems = []
    m.saimoCurrentItems = []
    m.itemList.visible = false
    m.vodGrid.visible = false
    m.episodeGrid.visible = false
    m.shelfList.visible = true
    m.shelfList.content = root
    setViewHeader("DESCOBRIR", "Descubra filmes e séries", Str(m.shelfRows.Count()).Trim() + " fileiras editoriais  •  ↑ ↓ percorre as fileiras")
    m.discoverHero = true
    m.listEyebrow.translation = [548, 53]
    m.listTitle.translation = [546, 79]
    m.listSub.translation = [550, 157]
    m.shelfList.visible = m.shelfRows.Count() > 0
    m.emptyLabel.visible = m.shelfRows.Count() = 0
    if m.shelfRows.Count() = 0 then
        m.emptyLabel.text = "Não há títulos nesta seleção. Escolha outra categoria."
        m.navList.setFocus(true)
        return
    end if
    if m.hint <> invalid then m.hint.text = "↑ ↓ percorre fileiras  •  ← → percorre títulos  •  OK abre  •  Replay busca"
    m.shelfList.setFocus(true)
end sub

sub onShelfItemFocused()
    focus = m.shelfList.rowItemFocused
    if type(focus) <> "roArray" or focus.Count() < 2 then return
    rowIndex = focus[0]
    itemIndex = focus[1]
    if rowIndex < 0 or rowIndex >= m.shelfRows.Count() then return
    row = m.shelfRows[rowIndex]
    if itemIndex < 0 or itemIndex >= row.items.Count() then return
    entry = row.items[itemIndex]
    title = strField(entry, "title")
    itemType = LCase(strField(entry, "type"))
    eyebrow = "FILME"
    if itemType = "series" then eyebrow = "SÉRIE"
    m.listEyebrow.text = row.title + "  •  " + eyebrow
    m.listTitle.text = title
    m.listSub.text = saimoItemSubtitle(entry) + "  •  OK abre"
end sub

sub onShelfItemSelected()
    selection = m.shelfList.rowItemSelected
    if type(selection) <> "roArray" or selection.Count() < 2 then return
    rowIndex = selection[0]
    itemIndex = selection[1]
    if rowIndex < 0 or rowIndex >= m.shelfRows.Count() then return
    row = m.shelfRows[rowIndex]
    if itemIndex < 0 or itemIndex >= row.items.Count() then return
    entry = row.items[itemIndex]
    openSaimoEntry(entry, "saimo_home", itemIndex)
end sub

sub showSaimoLetters(filter as string)
    if filter <> "movies" and filter <> "series" then filter = "all"
    m.saimoBackToHome = false
    m.activeView = "saimo_letters"
    m.vodFilter = filter
    m.saimoReturnFilter = filter
    m.searchActive = false
    m.itemList.visible = true
    m.vodGrid.visible = false
    m.episodeGrid.visible = false
    setViewHeader("CATÁLOGO", vodTitleForFilter(filter) + "  •  A–Z", "")
    m.listEntries = []

    for each row in m.saimoIndexLetters
        movies = Val(strField(row, "moviesCount"))
        series = Val(strField(row, "seriesCount"))
        include = false
        if filter = "movies" and movies > 0 then include = true
        if filter = "series" and series > 0 then include = true
        if filter = "all" and (movies > 0 or series > 0) then include = true
        if include then m.listEntries.Push({ kind: "saimo_letter", data: row })
    end for

    if m.saimoIndexLoaded and m.listEntries.Count() = 0 and m.saimoIndexLetters.Count() > 0 then
        ' Algumas versoes do indice publicam a letra sem contagens compativeis.
        ' Nao deixe a tela presa em "carregando": permita abrir a letra e ler o fragmento.
        for each row in m.saimoIndexLetters
            m.listEntries.Push({ kind: "saimo_letter", data: row })
        end for
        m.listSub.text = Str(m.listEntries.Count()).Trim() + " letras  •  contagens indisponíveis; selecione uma letra"
        m.emptyLabel.visible = false
    else if not m.saimoIndexLoaded then
        m.listSub.text = "Obtendo índice do catálogo..."
        m.emptyLabel.text = "Carregando o índice do catálogo." + Chr(10) + Chr(10) + "Os títulos são baixados por letra para manter a interface rápida."
        m.emptyLabel.visible = true
    else if m.listEntries.Count() = 0 then
        m.listSub.text = "Nenhuma letra tem títulos para este filtro. Use Replay para tentar novamente."
        m.emptyLabel.text = "O índice foi carregado, mas não informa títulos para este filtro." + Chr(10) + Chr(10) + "Pressione Replay para sincronizar novamente ou volte e tente Filmes e Séries."
        m.emptyLabel.visible = true
    else
        m.listSub.text = Str(m.listEntries.Count()).Trim() + " letras  •  selecione uma letra  •  OK abre"
        m.emptyLabel.visible = false
    end if
    renderEntries(true)
    if m.listEntries.Count() > 0 then
        m.itemList.setFocus(true)
    else
        m.navList.setFocus(true)
    end if
    if m.hint <> invalid then m.hint.text = "Setas navegam  •  OK abre a letra  •  Replay busca o catálogo completo  •  Back retorna"
end sub

sub loadSaimoLetter(letter as string)
    if letter = "" then return
    if m.fetchTask <> invalid then
        m.pendingSaimoLetter = letter
        showToast("Aguarde a requisição atual terminar; esta letra será aberta em seguida.")
        return
    end if

    m.saimoCurrentLetter = letter
    m.activeView = "saimo_catalog"
    m.itemList.visible = false
    m.vodGrid.visible = true
    m.episodeGrid.visible = false
    setViewHeader("CATÁLOGO", vodTitleForFilter(m.vodFilter) + "  •  " + letter, "Carregando títulos...  •  OK abre  •  Back volta às letras")
    m.emptyLabel.visible = false
    m.navList.setFocus(true)

    cachedUrl = readCacheAscii("cachefs:/saimo_vod_letters.url")
    cachePath = saimoLetterCachePath(m.vodFilter, letter)
    raw = readCacheAscii(cachePath)
    currentMarker = saimoLetterCacheMarker(saimoBaseUrl(m.vodUrl), m.saimoIndexSignature)
    if isStringValue(cachedUrl) and cachedUrl.Trim() = currentMarker and isStringValue(raw) and raw <> "" then
        parsedCache = ParseJson(raw)
        if type(parsedCache) = "roAssociativeArray" and type(parsedCache.items) = "roArray" and parsedCache.items.Count() > 0 then
            showSaimoGrid(parsedCache.items)
            if m.saimoPendingFocusTitle <> "" then focusSaimoTitle(m.saimoPendingFocusTitle, m.saimoPendingFocusType)
            m.listSub.text = Str(parsedCache.items.Count()).Trim() + " títulos  •  cache local  •  atualizando..."
        end if
    end if

    if m.fetchTask = invalid then
        base = saimoBaseUrl(m.vodUrl)
        if not startFetch("saimo_letter", base, base, letter, m.vodFilter, m.saimoIndexSignature) then return
        m.status.text = "Baixando fragmentos da letra " + letter + "..."
    else
        m.pendingSaimoLetter = letter
    end if
end sub

sub handleSaimoLetterResult(task as object)
    if saimoBaseUrl(strField(task, "baseUrl")) <> saimoBaseUrl(m.vodUrl) then return
    if task.success <> true then
        if m.pendingSaimoDetail <> invalid and strField(m.pendingSaimoDetail, "letter") = strField(task, "letter") then
            m.pendingSaimoDetail = invalid
        end if
        message = strField(task, "error")
        if message = "" then message = "Não foi possível atualizar esta letra."
        m.status.text = message
        if m.activeView = "saimo_catalog" and m.saimoCurrentItems.Count() = 0 then
            m.emptyLabel.text = message + Chr(10) + Chr(10) + "Tente novamente quando a conexão estiver disponível."
            m.emptyLabel.visible = true
        else
            showToastType("Atualização falhou; mantendo os títulos em cache.", "error")
        end if
        return
    end if

    parsed = ParseJson(task.resultJson)
    if type(parsed) <> "roAssociativeArray" or type(parsed.items) <> "roArray" then return
    items = parsed.items
    if items.Count() = 0 then return

    cachePath = saimoLetterCachePath(strField(parsed, "filter"), strField(parsed, "letter"))
    WriteAsciiFile(cachePath, task.resultJson)
    WriteAsciiFile("cachefs:/saimo_vod_letters.url", saimoLetterCacheMarker(saimoBaseUrl(m.vodUrl), m.saimoIndexSignature))

    if m.pendingSaimoDetail <> invalid and strField(parsed, "letter") = strField(m.pendingSaimoDetail, "letter") then
        pendingItem = m.pendingSaimoDetail
        pendingReturnView = m.pendingSaimoDetailReturnView
        pendingReturnIndex = m.pendingSaimoDetailReturnIndex
        pendingReturnFilter = m.pendingSaimoDetailReturnFilter
        m.pendingSaimoDetail = invalid
        m.saimoCurrentItems = items
        match = invalid
        for each candidate in items
            if LCase(strField(candidate, "type")) = LCase(strField(pendingItem, "type")) and movieTitleMatches(strField(candidate, "title"), strField(pendingItem, "title")) then
                match = candidate
                exit for
            end if
        end for
        if match <> invalid then
            if LCase(strField(match, "type")) = "series" then
                m.seriesDetailReturnView = pendingReturnView
                m.seriesDetailReturnIndex = pendingReturnIndex
                m.seriesReturnFilter = pendingReturnFilter
                loadSaimoEpisodes(match)
            else
                m.vodFilter = pendingReturnFilter
                showVodMovieDetails(match, pendingReturnView, pendingReturnIndex)
            end if
            return
        end if
    end if

    if strField(parsed, "letter") = m.saimoCurrentLetter and strField(parsed, "filter") = m.vodFilter and (m.activeView = "saimo_catalog" or m.activeView = "saimo_episodes_loading") then
        showSaimoGrid(items)
        if m.saimoPendingFocusTitle <> "" then focusSaimoTitle(m.saimoPendingFocusTitle, m.saimoPendingFocusType)
    end if
    m.status.text = Str(items.Count()).Trim() + " títulos carregados da letra " + strField(parsed, "letter") + "."
    if strField(task, "error") <> "" then showToastType(strField(task, "error"), "error")
end sub

sub showSaimoGrid(items as object)
    m.activeView = "saimo_catalog"
    m.vodGrid.itemSize = [210, 362]
    m.vodGrid.numColumns = 6
    m.vodGrid.numRows = 2
    m.saimoCurrentItems = items
    m.vodVisibleItems = items
    m.itemList.visible = false
    m.vodGrid.visible = true
    m.episodeGrid.visible = false
    setViewHeader("CATÁLOGO", vodTitleForFilter(m.vodFilter) + "  •  " + m.saimoCurrentLetter, Str(items.Count()).Trim() + " títulos  •  capas carregadas automaticamente  •  OK abre")
    m.emptyLabel.visible = items.Count() = 0
    if items.Count() = 0 then
        m.emptyLabel.text = "Nenhum título disponível para esta letra."
        m.vodGrid.content = CreateObject("roSGNode", "ContentNode")
        m.navList.setFocus(true)
        return
    end if
    buildVodGrid(items)
    m.emptyLabel.visible = false
    m.vodGrid.setFocus(true)
    if m.hint <> invalid then m.hint.text = "Setas navegam  •  OK abre ou reproduz  •  Back volta às letras  •  Replay busca"
end sub

sub focusSaimoTitle(title as string, kind as string)
    if title = "" or m.vodVisibleItems.Count() = 0 then return
    idx = 0
    for each entry in m.vodVisibleItems
        if movieTitleMatches(strField(entry, "title"), title) then
            if kind = "" or strField(entry, "type") = kind then
                m.vodGrid.jumpToItem = idx
                m.saimoPendingFocusTitle = ""
                m.saimoPendingFocusType = ""
                return
            end if
        end if
        idx = idx + 1
    end for
    m.saimoPendingFocusTitle = ""
    m.saimoPendingFocusType = ""
    showToast("O destaque não apareceu na lista atualizada; use a busca para encontrá-lo.")
end sub

sub loadSaimoEpisodes(series as object)
    if series = invalid then return
    if m.fetchTask <> invalid then
        m.pendingSaimoSeries = series
        showToast("Carregando os episódios assim que a tarefa atual terminar.")
        return
    end if
    m.seriesDetail = series
    m.activeView = "saimo_episodes_loading"
    showSeriesDetailLoading(series)
    base = saimoBaseUrl(m.vodUrl)
    letter = strField(series, "letter")
    fileLetter = letter
    if letter = "#" then fileLetter = "%23"
    piece = Str(Val(strField(series, "piece"))).Trim()
    url = base + "series-" + fileLetter + "-" + piece + ".txt"
    startFetch("saimo_episodes", url, base, letter, strField(series, "title"), "")
end sub

sub handleSaimoEpisodesResult(task as object)
    if saimoBaseUrl(strField(task, "baseUrl")) <> saimoBaseUrl(m.vodUrl) then return
    if task.success <> true then
        message = strField(task, "error")
        if message = "" then message = "Não foi possível carregar os episódios."
        m.vodEpisodeEmpty.text = message + Chr(10) + Chr(10) + "Back retorna ao catálogo; OK seleciona uma ação da série."
        m.vodEpisodeEmpty.visible = true
        m.vodDetailActions.setFocus(true)
        showToastType(message, "error")
        return
    end if
    episodes = ParseJson(task.resultJson)
    if type(episodes) <> "roArray" or episodes.Count() = 0 then
        m.vodEpisodeEmpty.text = "Nenhum episódio encontrado para esta série."
        m.vodEpisodeEmpty.visible = true
        return
    end if
    cover = strField(m.seriesDetail, "cover")
    for each episode in episodes
        if strField(episode, "cover") = "" then episode.cover = cover
    end for
    showSaimoEpisodes(episodes)
end sub

sub showSaimoEpisodes(episodes as object)
    showSeriesDetails(m.seriesDetail, episodes, "saimo_episodes", m.seriesDetailReturnView, m.seriesDetailReturnIndex)
end sub

sub showSeriesDetailLoading(series as object)
    m.detailItem = series
    m.detailIsSeries = true
    m.seriesAllEpisodes = []
    m.seriesSeasonValues = []
    m.vodVisibleItems = []
    m.itemList.visible = false
    m.vodGrid.visible = false
    m.episodeGrid.visible = false
    m.shelfList.visible = false
    m.emptyLabel.visible = false
    m.vodSeasonHeading.visible = false
    m.vodSeasonList.visible = false
    m.vodEpisodeEmpty.text = "Consultando temporadas e episódios..."
    m.vodEpisodeEmpty.visible = true
    setViewHeader("SÉRIE", strField(series, "title"), "Informações da série  •  carregando temporadas...")
    updateVodDetailContent(series)
    renderVodDetailActions(series, true)
    m.vodDetailGroup.visible = true
    m.vodDetailActions.setFocus(true)
end sub

sub showSeriesDetails(series as object, episodes as object, view as string, returnView as string, returnIndex as integer)
    if series = invalid then return
    if type(episodes) <> "roArray" then episodes = []
    m.seriesDetail = series
    m.seriesDetailReturnView = returnView
    m.seriesDetailReturnIndex = returnIndex
    m.seriesAllEpisodes = episodes
    m.detailItem = series
    m.detailIsSeries = true
    m.activeView = view
    m.vodVisibleItems = []
    m.itemList.visible = false
    m.vodGrid.visible = false
    m.shelfList.visible = false
    m.emptyLabel.visible = false
    m.episodeGrid.visible = episodes.Count() > 0
    m.vodEpisodeEmpty.visible = episodes.Count() = 0
    if episodes.Count() = 0 then
        m.vodEpisodeEmpty.text = "Esta fonte ainda não disponibilizou episódios para a série."
    end if
    setViewHeader("SÉRIE", strField(series, "title"), "Detalhes da série  •  escolha uma temporada e um episódio")
    updateVodDetailContent(series)
    if episodes.Count() > 0 then series.episodeCount = episodes.Count()
    m.vodDetailMeta.text = vodDetailsMeta(series)
    renderVodDetailActions(series, true)
    m.vodDetailGroup.visible = true
    buildSeriesSeasonList(episodes)
    m.lastSeasonFocusIndex = 0
    m.suppressSeasonFocus = false
    if m.seriesSeasonValues.Count() > 1 then
        m.vodSeasonHeading.text = "TEMPORADAS"
        m.vodSeasonHeading.visible = true
        m.vodSeasonList.visible = true
        m.vodSeasonList.setFocus(true)
    else if m.seriesSeasonValues.Count() = 1 then
        m.vodSeasonHeading.text = "TEMPORADA " + Str(m.seriesSeasonValues[0]).Trim()
        m.vodSeasonHeading.visible = true
        m.vodSeasonList.visible = false
        m.vodVisibleItems = episodesForSeason(episodes, m.seriesSeasonValues[0])
        buildEpisodeGrid(m.vodVisibleItems)
        if m.vodVisibleItems.Count() > 0 then m.episodeGrid.setFocus(true) else m.vodDetailActions.setFocus(true)
    else
        m.vodSeasonHeading.visible = false
        m.vodSeasonList.visible = false
        if episodes.Count() > 0 then
            m.vodVisibleItems = episodes
            buildEpisodeGrid(episodes)
            m.episodeGrid.setFocus(true)
        else
            m.vodDetailActions.setFocus(true)
        end if
    end if
end sub

sub buildSeriesSeasonList(episodes as object)
    seasons = []
    for each episode in episodes
        season = Val(strField(episode, "season"))
        if season < 0 then season = 0
        found = false
        for each existingSeason in seasons
            if existingSeason = season then found = true
        end for
        if not found then seasons.Push(season)
    end for
    for i = 0 to seasons.Count() - 2
        for j = i + 1 to seasons.Count() - 1
            if seasons[j] < seasons[i] then
                temp = seasons[i]
                seasons[i] = seasons[j]
                seasons[j] = temp
            end if
        end for
    end for
    m.seriesSeasonValues = seasons
    if seasons.Count() > 0 then m.vodSeasonList.numColumns = seasons.Count()
    m.lastSeasonFocusIndex = 0
    root = CreateObject("roSGNode", "ContentNode")
    for each season in seasons
        node = root.CreateChild("ContentNode")
        if season = 0 then
            node.title = "Especiais"
        else
        node.title = "Temporada " + Str(season).Trim()
        end if
    end for
    m.vodSeasonList.content = root
    if seasons.Count() > 0 then
        m.vodSeasonList.jumpToItem = 0
        m.seriesCurrentSeason = seasons[0]
        m.vodVisibleItems = episodesForSeason(episodes, seasons[0])
        buildEpisodeGrid(m.vodVisibleItems)
    else
        m.vodVisibleItems = episodes
        m.episodeGrid.content = CreateObject("roSGNode", "ContentNode")
    end if
end sub

function episodesForSeason(episodes as object, season as integer) as object
    result = []
    for each episode in episodes
        if Val(strField(episode, "season")) = season then result.Push(episode)
    end for
    return result
end function

sub onSeriesSeasonFocused()
    index = m.vodSeasonList.itemFocused
    if not m.vodDetailGroup.visible or (m.activeView <> "vod_episodes" and m.activeView <> "saimo_episodes") or index < 0 or index >= m.seriesSeasonValues.Count() then return
    if m.suppressSeasonFocus = invalid then m.suppressSeasonFocus = false
    if m.lastSeasonFocusIndex = invalid then m.lastSeasonFocusIndex = index
    if m.suppressSeasonFocus then return

    previousIndex = m.lastSeasonFocusIndex
    ' Movimento vertical da grelha de temporadas (ex.: baixo da 1a para a 5a)
    ' nao deve trocar de temporada nem reconstruir a grade. Down vai para
    ' episodios; up volta para acoes.
    verticalJump = previousIndex >= 0 and previousIndex <> index and Abs(index - previousIndex) >= 4
    if verticalJump then
        if index > previousIndex and m.vodVisibleItems.Count() > 0 then
            m.suppressSeasonFocus = true
            m.vodSeasonList.jumpToItem = previousIndex
            m.suppressSeasonFocus = false
            m.lastSeasonFocusIndex = previousIndex
            m.episodeGrid.setFocus(true)
            return
        end if
        m.suppressSeasonFocus = true
        m.vodSeasonList.jumpToItem = previousIndex
        m.suppressSeasonFocus = false
        m.lastSeasonFocusIndex = previousIndex
        return
    end if

    m.lastSeasonFocusIndex = index
    season = m.seriesSeasonValues[index]
    if season = m.seriesCurrentSeason then return
    m.seriesCurrentSeason = season
    m.vodVisibleItems = episodesForSeason(m.seriesAllEpisodes, season)
    buildEpisodeGrid(m.vodVisibleItems)
    m.vodEpisodeEmpty.visible = m.vodVisibleItems.Count() = 0
    if m.vodVisibleItems.Count() = 0 then m.vodEpisodeEmpty.text = "Nenhum episódio disponível nesta temporada."
end sub

sub startSaimoSearch(query as string, channelEntries as object)
    if m.fetchTask <> invalid then
        m.pendingSaimoSearch = query
        m.pendingSaimoSearchEntries = channelEntries
        showToast("A busca no catálogo será iniciada quando a requisição atual terminar.")
        return
    end if
    m.saimoSearchEntries = channelEntries
    m.searchReturnView = m.activeView
    m.activeView = "search"
    m.searchActive = true
    m.itemList.visible = true
    m.vodGrid.visible = false
    m.episodeGrid.visible = false
    setViewHeader("BUSCA", "Busca: " + query, "Pesquisando títulos no catálogo completo...")
    m.listEntries = channelEntries
    renderEntries(true)
    base = saimoBaseUrl(m.vodUrl)
    startFetch("saimo_search", base + "busca.txt", base, "", query, "")
end sub

sub handleSaimoSearchResult(task as object)
    if saimoBaseUrl(strField(task, "baseUrl")) <> saimoBaseUrl(m.vodUrl) then return
    if task.success <> true then
        message = strField(task, "error")
        if message = "" then message = "Não foi possível pesquisar o catálogo VOD."
        showToastType(message, "error")
        return
    end if
    found = ParseJson(task.resultJson)
    if type(found) <> "roArray" then return
    entries = m.saimoSearchEntries
    for each result in found
        entries.Push({ kind: "saimo_search_result", data: result })
    end for
    m.listEntries = entries
    m.activeView = "search"
    m.searchActive = true
    m.itemList.visible = true
    m.vodGrid.visible = false
    m.episodeGrid.visible = false
    m.listSub.text = Str(entries.Count()).Trim() + " resultados  •  OK abre a letra correspondente"
    if entries.Count() = 0 then m.emptyLabel.text = "Nenhum resultado para a busca."
    renderEntries(true)
    if entries.Count() > 0 then
        m.itemList.setFocus(true)
    else
        m.navList.setFocus(true)
    end if
end sub

sub showVod(filter as string)
    m.activeView = "vod"
    m.vodGrid.itemSize = [210, 362]
    m.vodGrid.numColumns = 6
    m.vodGrid.numRows = 2
    m.vodFilter = filter
    m.seriesDetail = invalid
    m.searchActive = false
    m.itemList.visible = false
    m.vodGrid.visible = true
    m.episodeGrid.visible = false
    setViewHeader("CATÁLOGO", vodTitleForFilter(filter), "")

    if filter = "movies" then
        m.vodVisibleItems = m.vodMovies
    else if filter = "series" then
        m.vodVisibleItems = m.vodSeries
    else
        m.vodVisibleItems = m.vodAll
    end if

    m.listSub.text = Str(m.vodVisibleItems.Count()).Trim() + " itens  •  OK abre"
    m.emptyLabel.visible = m.vodVisibleItems.Count() = 0
    if m.vodVisibleItems.Count() = 0 then
        if m.vodUrl = "" then
            m.emptyLabel.text = "Configure a URL do catálogo VOD em Ajustes para carregar filmes e séries."
        else
            m.emptyLabel.text = "Nenhum item encontrado nesta categoria. Pressione *Atualizar lista* ou confira a URL em Ajustes."
        end if
        m.vodGrid.content = CreateObject("roSGNode", "ContentNode")
        m.navList.setFocus(true)
        return
    end if

    buildVodGrid(m.vodVisibleItems)
    m.emptyLabel.visible = false
    m.vodGrid.setFocus(true)
end sub

sub buildEpisodeGrid(items as object)
    root = CreateObject("roSGNode", "ContentNode")
    for each entry in items
        node = root.CreateChild("ContentNode")
        node.addFields({ episodeCode: "", episodeTitle: "", episodeMeta: "", episodeSynopsis: "", episodeNumber: "", episodeArt: "", watched: false })
        node.episodeArt = strField(entry, "cover")
        season = Val(strField(entry, "season"))
        number = Val(strField(entry, "episode"))
        seasonCode = "T" + Right("00" + Str(season).Trim(), 2)
        episodeCode = "E" + Right("00" + Str(number).Trim(), 2)
        if season <= 0 then seasonCode = "TEMPORADA"
        if number <= 0 then episodeCode = "EPISÓDIO"
        node.episodeCode = seasonCode + "  •  " + episodeCode
        if number > 0 then node.episodeNumber = Str(number).Trim()
        title = strField(entry, "title").Trim()
        genericTitle = episodeCode
        if season > 0 then genericTitle = seasonCode + " " + episodeCode
        if title = "" or LCase(title) = LCase(genericTitle) or LCase(title) = LCase(episodeCode) then title = "Episódio " + Str(number).Trim()
        node.episodeTitle = title
        meta = ""
        groupName = strField(entry, "group").Trim()
        if groupName <> "" then meta = groupName
        if type(entry.sources) = "roArray" and entry.sources.Count() > 0 then
            if meta <> "" then meta = meta + "  •  "
            meta = meta + Str(entry.sources.Count()).Trim() + " fontes"
        end if
        runtime = Val(strField(entry, "runtime"))
        if runtime > 0 then
            if meta <> "" then meta = meta + "  •  "
            meta = meta + Str(runtime).Trim() + " min"
        end if
        node.episodeMeta = meta
        synopsis = strField(entry, "synopsis")
        if synopsis = "" then synopsis = strField(entry, "description")
        node.episodeSynopsis = synopsis
        if m.watchedEpisodes <> invalid then
            entryKey = watchedKey(entry)
            if entryKey <> "" and m.watchedEpisodes.DoesExist(entryKey) then node.watched = true
        end if
    end for
    if items.Count() > 0 then m.episodeGrid.numColumns = items.Count()
    m.episodeGrid.content = root
    m.episodeGrid.jumpToItem = 0
end sub

sub buildVodGrid(items as object)
    root = CreateObject("roSGNode", "ContentNode")
    for each entry in items
        node = root.CreateChild("ContentNode")
        node.title = strField(entry, "title")
        poster = strField(entry, "cover")
        if poster = "" then poster = "pkg:/images/placeholder.png"
        node.hdGridPosterUrl = poster
        itemType = strField(entry, "type")
        node.shortDescriptionLine1 = strField(entry, "title")
        node.shortDescriptionLine2 = saimoGridSubtitle(entry)
    end for
    m.vodGrid.content = root
    m.vodGrid.jumpToItem = 0
end sub

sub onVodItemFocused()
    index = m.vodGrid.itemFocused
    if m.activeView = "vod_episodes" or m.activeView = "saimo_episodes" then index = m.episodeGrid.itemFocused
    if index < 0 or index >= m.vodVisibleItems.Count() then return
    entry = m.vodVisibleItems[index]
    title = strField(entry, "title")
    itemType = LCase(strField(entry, "type"))
    subtitle = saimoItemSubtitle(entry)
    detail = title
    if subtitle <> "" then detail = detail + "  •  " + subtitle
    if itemType = "series" and Val(strField(entry, "episodeCount")) = 0 and type(entry.episodes) = "roArray" and entry.episodes.Count() > 0 then
        detail = detail + "  •  " + Str(entry.episodes.Count()).Trim() + " episódios"
    end if
    if type(entry.sources) = "roArray" and entry.sources.Count() > 1 then
        detail = detail + "  •  " + Str(entry.sources.Count()).Trim() + " fontes"
    end if
    m.listSub.text = detail
end sub

sub onVodItemSelected()
    index = m.vodGrid.itemSelected
    if m.activeView = "vod_episodes" or m.activeView = "saimo_episodes" then index = m.episodeGrid.itemSelected
    if index < 0 or index >= m.vodVisibleItems.Count() then return
    entry = m.vodVisibleItems[index]

    if m.activeView = "saimo_home" then
        openSaimoEntry(entry, "saimo_home", index)
        return
    end if

    if m.activeView = "vod_episodes" or m.activeView = "saimo_episodes" then
        playVodEntry(entry)
        return
    end if

    itemType = LCase(strField(entry, "type"))
    if itemType = "series" and (m.activeView = "saimo_catalog" or m.activeView = "vod_favorites") and (strField(entry, "sourceType") = "saimo" or (strField(entry, "letter") <> "" and strField(entry, "piece") <> "")) then
        m.seriesDetailReturnView = m.activeView
        m.seriesDetailReturnIndex = index
        openSaimoEntry(entry, m.activeView, index)
    else if itemType = "series" and strField(entry, "sourceType") = "saimo" and strField(entry, "piece") <> "" then
        m.seriesDetailReturnView = m.activeView
        m.seriesDetailReturnIndex = index
        openSaimoEntry(entry, m.activeView, index)
    else if itemType = "series" and type(entry.episodes) = "roArray" and entry.episodes.Count() > 0 then
        showSeriesEpisodes(entry, m.activeView, index)
    else if itemType = "series" then
        showSeriesDetails(entry, [], "vod_episodes", m.activeView, index)
    else
        showVodMovieDetails(entry, m.activeView, index)
    end if
end sub

sub showSeriesEpisodes(series as object, returnView as string, returnIndex as integer)
    if series = invalid then return
    m.seriesReturnFilter = m.vodFilter
    showSeriesDetails(series, series.episodes, "vod_episodes", returnView, returnIndex)
end sub

sub playVodEntry(entry as object)
    if entry = invalid then return
    sources = entry.sources
    if type(sources) <> "roArray" or sources.Count() = 0 then
        showToastType("Este item não possui um endereço de reprodução válido.", "error")
        return
    end if
    channel = {
        title: strField(entry, "title")
        logo: strField(entry, "cover")
        group: strField(entry, "group")
        tvgId: ""
        sources: sources
        isLive: false
    }
    markWatched(entry)
    playChannel(channel)
end sub

' ---------------------------------------------------------------------------
' Busca
' ---------------------------------------------------------------------------

sub openSearchDialog()
    if m.playerVisible or m.settingsVisible or m.guideVisible or m.aboutVisible then return
    m.searchReturnView = m.activeView

    dialog = CreateObject("roSGNode", "KeyboardDialog")
    dialog.title = "Buscar canal, filme ou série"
    dialog.buttons = ["Buscar", "Cancelar"]
    dialog.text = ""
    dialog.observeField("buttonSelected", "onSearchButtonSelected")
    m.dialog = dialog
    m.editKey = "search"
    m.top.appendChild(dialog)
    dialog.setFocus(true)
end sub

sub onSearchButtonSelected()
    if m.dialog = invalid then return
    index = m.dialog.buttonSelected
    text = m.dialog.text
    if text = invalid then text = ""
    closeDialog()
    if index = 0 and text.Trim() <> "" then runSearch(text.Trim())
end sub

sub runSearch(query as string)
    q = LCase(query)
    entries = []
    count = 0

    for each ch in m.channels
        if Instr(1, LCase(ch.title), q) > 0 or Instr(1, LCase(ch.group), q) > 0 then
            entries.Push({ kind: "channel", data: ch })
            count = count + 1
            if count >= 120 then exit for
        end if
    end for

    if count < 120 then
        for each item in m.vodAll
            if Instr(1, LCase(strField(item, "title")), q) > 0 or Instr(1, LCase(strField(item, "group")), q) > 0 then
                entries.Push({ kind: "vod", data: item })
                count = count + 1
                if count >= 120 then exit for
            end if
        end for
    end if

    if isSaimoVodUrl(m.vodUrl) then
        startSaimoSearch(query, entries)
        return
    end if

    m.activeView = "search"
    m.searchActive = true
    m.itemList.visible = true
    m.vodGrid.visible = false
    m.episodeGrid.visible = false
    m.listEntries = entries
    setViewHeader("BUSCA", "Busca: " + query, Str(entries.Count()).Trim() + " resultados  •  OK abre")
    m.emptyLabel.text = "Nenhum resultado para \"" + query + "\"."
    renderEntries(true)
    if entries.Count() > 0 then
        m.itemList.setFocus(true)
    else
        m.navList.setFocus(true)
    end if
end sub

sub restoreAfterSearch()
    m.searchActive = false
    if m.searchReturnView = "vod" then
        showVod(m.vodFilter)
    else if m.searchReturnView = "vod_episodes" and m.seriesDetail <> invalid then
        showSeriesEpisodes(m.seriesDetail, m.seriesDetailReturnView, m.seriesDetailReturnIndex)
    else if m.searchReturnView = "vod_movie_detail" and m.detailItem <> invalid then
        showVodMovieDetails(m.detailItem, m.detailReturnView, m.detailReturnIndex)
    else if m.searchReturnView = "vod_favorites" then
        showVodFavorites()
    else if m.searchReturnView = "saimo_home" then
        showSaimoHome(m.vodFilter)
    else if m.searchReturnView = "saimo_letters" then
        showSaimoLetters(m.vodFilter)
    else if m.searchReturnView = "saimo_catalog" then
        showSaimoGrid(m.saimoCurrentItems)
    else if m.searchReturnView = "saimo_episodes" and m.seriesDetail <> invalid then
        showSaimoEpisodes(m.vodVisibleItems)
    else
        populateChannels(m.selectedGroup, true)
    end if
end sub

' ---------------------------------------------------------------------------
' Favoritos
' ---------------------------------------------------------------------------

' Rotulo de tipo da ficha (fichaTipo do Android: caps em accent).
function vodDetailTypeLabel(item as object) as string
    if item = invalid then return "FILME"
    itemType = LCase(strField(item, "type"))
    if itemType = "series" then return "SÉRIE"
    if itemType = "episode" then return "EPISÓDIO"
    return "FILME"
end function

' Metadados da ficha no lugar de fichaSelos + fichaGeneros: ano, generos,
' duracao, contagem e fontes. O rotulo de tipo fica em vodDetailTipo.
function vodDetailsMeta(item as object) as string
    if item = invalid then return ""
    itemType = LCase(strField(item, "type"))
    meta = ""
    year = strField(item, "year").Trim()
    if year <> "" then meta = year
    genres = strField(item, "genres").Trim()
    if genres <> "" then
        if meta <> "" then meta = meta + "  •  "
        meta = meta + genres
    end if
    runtime = Val(strField(item, "runtime"))
    if runtime > 0 then
        if meta <> "" then meta = meta + "  •  "
        meta = meta + Str(runtime).Trim() + " min"
    end if
    if itemType = "series" then
        count = Val(strField(item, "episodeCount"))
        if count > 0 then
            if meta <> "" then meta = meta + "  •  "
            meta = meta + Str(count).Trim() + " episódios"
        end if
    else if type(item.sources) = "roArray" and item.sources.Count() > 0 then
        if meta <> "" then meta = meta + "  •  "
        meta = meta + Str(item.sources.Count()).Trim() + " fontes"
    end if
    return meta
end function

sub updateVodDetailContent(item as object)
    if item = invalid then return
    cover = strField(item, "cover")
    showFichaBackdrop(cover)
    if cover = "" then cover = "pkg:/images/placeholder.png"
    m.vodDetailPoster.uri = cover
    m.vodDetailTipo.text = vodDetailTypeLabel(item)
    m.vodDetailTitle.text = strField(item, "title")
    ' A frase da ficha recebe a dica da tela: setViewHeader roda logo antes
    ' nas tres fichas e o veu opaco esconderia o listSub por baixo.
    m.vodDetailFrase.text = m.listSub.text
    m.vodDetailMeta.text = vodDetailsMeta(item)
    synopsis = strField(item, "overview")
    if synopsis = "" then synopsis = strField(item, "synopsis")
    if synopsis = "" then synopsis = strField(item, "description")
    if synopsis = "" and LCase(strField(item, "type")) = "series" then
        synopsis = "Informações detalhadas da série e sinopse não foram fornecidas por esta fonte. Selecione uma temporada para ver os episódios disponíveis."
    else if synopsis = "" then
        synopsis = "Sinopse não fornecida por esta fonte."
    end if
    m.vodDetailSynopsis.text = synopsis
end sub

sub renderVodDetailActions(item as object, isSeries as boolean)
    root = CreateObject("roSGNode", "ContentNode")
    entries = []
    if not isSeries then entries.Push({ title: "▶  Assistir", kind: "play" })
    favoriteTitle = "☆  Adicionar aos favoritos"
    key = vodFavoriteKey(item)
    if key <> "" and m.vodFavoritesByKey[key] = true then favoriteTitle = "★  Remover dos favoritos"
    entries.Push({ title: favoriteTitle, kind: "favorite" })
    entries.Push({ title: "Voltar", kind: "back" })
    m.detailActionEntries = entries
    for each entry in entries
        node = root.CreateChild("ContentNode")
        node.addFields({ kind: entry.kind })
        node.title = entry.title
    end for
    m.vodDetailActions.content = root
    m.vodDetailActions.jumpToItem = 0
end sub

sub showVodMovieDetails(item as object, returnView as string, returnIndex as integer)
    if item = invalid then return
    m.detailReturnView = returnView
    m.detailReturnIndex = returnIndex
    m.detailReturnFilter = m.vodFilter
    m.detailItem = item
    m.detailIsSeries = false
    m.activeView = "vod_movie_detail"
    m.seriesDetail = invalid
    m.itemList.visible = false
    m.vodGrid.visible = false
    m.episodeGrid.visible = false
    m.shelfList.visible = false
    m.emptyLabel.visible = false
    m.vodSeasonHeading.visible = false
    m.vodSeasonList.visible = false
    m.vodEpisodeEmpty.visible = false
    setViewHeader("FILME", strField(item, "title"), "Detalhes do filme  •  escolha uma ação")
    updateVodDetailContent(item)
    renderVodDetailActions(item, false)
    m.vodDetailGroup.visible = true
    m.vodDetailActions.setFocus(true)
end sub

sub toggleVodFavorite(item as object)
    if item = invalid then return
    key = vodFavoriteKey(item)
    if key = "" then return
    if m.vodFavoritesByKey[key] = true then
        m.vodFavoritesByKey.Delete(key)
        updated = []
        for each favorite in m.vodFavoriteItems
            if vodFavoriteKey(favorite) <> key then updated.Push(favorite)
        end for
        m.vodFavoriteItems = updated
        showToast("Removido dos favoritos: " + strField(item, "title"))
    else
        m.vodFavoritesByKey[key] = true
        m.vodFavoriteItems.Push(item)
        showToast("Adicionado aos favoritos: " + strField(item, "title"))
    end if
    saveVodFavorites()
    if m.vodDetailGroup.visible then renderVodDetailActions(item, m.detailIsSeries)
end sub

sub onVodDetailActionSelected()
    index = m.vodDetailActions.itemSelected
    if index < 0 or index >= m.detailActionEntries.Count() then return
    action = m.detailActionEntries[index]
    if action.kind = "play" then
        playVodEntry(m.detailItem)
    else if action.kind = "favorite" then
        toggleVodFavorite(m.detailItem)
        m.vodDetailActions.jumpToItem = index
        m.vodDetailActions.setFocus(true)
    else if action.kind = "back" then
        if m.detailIsSeries then
            restoreSeriesDetailReturn()
        else
            restoreVodDetailReturn()
        end if
    end if
end sub

sub restoreVodDetailReturn()
    returnView = m.detailReturnView
    returnIndex = m.detailReturnIndex
    m.vodDetailGroup.visible = false
    m.detailItem = invalid
    if returnView = "saimo_home" then
        showSaimoHome(m.detailReturnFilter)
    else if returnView = "saimo_catalog" then
        showSaimoGrid(m.saimoCurrentItems)
        if returnIndex >= 0 and returnIndex < m.saimoCurrentItems.Count() then m.vodGrid.jumpToItem = returnIndex
        m.vodGrid.setFocus(true)
    else if returnView = "vod_favorites" then
        showVodFavorites()
        if returnIndex >= 0 and returnIndex < m.vodFavoriteItems.Count() then m.vodGrid.jumpToItem = returnIndex
        m.vodGrid.setFocus(true)
    else if returnView = "vod" then
        showVod(m.detailReturnFilter)
        if returnIndex >= 0 and returnIndex < m.vodVisibleItems.Count() then m.vodGrid.jumpToItem = returnIndex
        m.vodGrid.setFocus(true)
    else if returnView = "search" then
        m.activeView = "search"
        m.vodGrid.visible = false
        m.episodeGrid.visible = false
        m.itemList.visible = true
        setViewHeader("BUSCA", "Resultados", Str(m.listEntries.Count()).Trim() + " itens  •  OK abre")
        renderEntries(false)
        if m.listEntries.Count() > 0 then
            if returnIndex >= 0 and returnIndex < m.listEntries.Count() then m.itemList.jumpToItem = returnIndex
            m.itemList.setFocus(true)
        else
            m.navList.setFocus(true)
        end if
    else
        populateChannels(m.selectedGroup, true)
    end if
end sub

sub restoreSeriesDetailReturn()
    returnView = m.seriesDetailReturnView
    returnIndex = m.seriesDetailReturnIndex
    m.vodDetailGroup.visible = false
    m.seriesDetail = invalid
    m.seriesAllEpisodes = []
    m.seriesSeasonValues = []
    if returnView = "saimo_home" then
        showSaimoHome(m.seriesReturnFilter)
    else if returnView = "saimo_catalog" then
        showSaimoGrid(m.saimoCurrentItems)
        if returnIndex >= 0 and returnIndex < m.saimoCurrentItems.Count() then m.vodGrid.jumpToItem = returnIndex
        m.vodGrid.setFocus(true)
    else if returnView = "vod_favorites" then
        showVodFavorites()
        if returnIndex >= 0 and returnIndex < m.vodFavoriteItems.Count() then m.vodGrid.jumpToItem = returnIndex
        m.vodGrid.setFocus(true)
    else if returnView = "search" then
        m.activeView = "search"
        m.vodGrid.visible = false
        m.episodeGrid.visible = false
        m.itemList.visible = true
        setViewHeader("BUSCA", "Resultados", Str(m.listEntries.Count()).Trim() + " itens  •  OK abre")
        renderEntries(false)
        if m.listEntries.Count() > 0 then
            if returnIndex >= 0 and returnIndex < m.listEntries.Count() then m.itemList.jumpToItem = returnIndex
            m.itemList.setFocus(true)
        else
            m.navList.setFocus(true)
        end if
    else
        showVod(m.seriesReturnFilter)
        if returnIndex >= 0 and returnIndex < m.vodVisibleItems.Count() then m.vodGrid.jumpToItem = returnIndex
        m.vodGrid.setFocus(true)
    end if
end sub

sub openSaimoEntry(item as object, returnView as string, returnIndex as integer)
    if item = invalid then return
    itemType = LCase(strField(item, "type"))
    returnFilter = m.vodFilter
    m.seriesReturnFilter = returnFilter
    m.pendingSaimoDetailReturnFilter = returnFilter
    m.detailReturnFilter = returnFilter
    m.vodFilter = "movies"
    if itemType = "series" then m.vodFilter = "series"
    if itemType = "series" and strField(item, "piece") <> "" and strField(item, "letter") <> "" then
        m.seriesDetailReturnView = returnView
        m.seriesDetailReturnIndex = returnIndex
        loadSaimoEpisodes(item)
        return
    end if
    letter = strField(item, "letter")
    if letter = "" then
        showToast("Este título ainda não tem uma letra válida no catálogo.")
        return
    end if
    m.pendingSaimoDetail = item
    m.pendingSaimoDetailReturnView = returnView
    m.pendingSaimoDetailReturnIndex = returnIndex
    loadSaimoLetter(letter)
end sub

sub toggleFavorite()
    if m.playerVisible or m.settingsVisible or m.guideVisible or m.aboutVisible then return
    if m.activeView = "vod" or m.activeView = "vod_episodes" or m.activeView = "saimo_letters" or m.activeView = "saimo_home" or m.activeView = "saimo_catalog" or m.activeView = "saimo_episodes" or m.activeView = "saimo_episodes_loading" or m.activeView = "vod_movie_detail" or m.activeView = "vod_favorites" then return
    index = m.itemList.itemFocused
    if index < 0 or index >= m.listEntries.Count() then return
    entry = m.listEntries[index]
    if entry.kind <> "channel" then return

    title = entry.data.title
    if m.favorites[title] = true then
        m.favorites.Delete(title)
        newTitles = []
        for each name in m.favoriteTitles
            if name <> title then newTitles.Push(name)
        end for
        m.favoriteTitles = newTitles
        showToast("Removido dos favoritos: " + title)
    else
        m.favorites[title] = true
        m.favoriteTitles.Push(title)
        showToast("Adicionado aos favoritos: " + title)
    end if
    saveFavorites()
    renderEntries(false)
    m.itemList.jumpToItem = index
    m.itemList.setFocus(true)
end sub

' ---------------------------------------------------------------------------
' Ajustes
' ---------------------------------------------------------------------------

sub openSettings()
    if m.playerVisible then return
    m.settingsVisible = true
    m.homeGroup.visible = false
    m.guideGroup.visible = false
    m.aboutGroup.visible = false
    m.settingsGroup.visible = true
    buildSettings()
    m.settingsList.setFocus(true)
end sub

sub closeSettings()
    m.settingsVisible = false
    m.settingsGroup.visible = false
    m.homeGroup.visible = true
    focusListOrNav()
end sub

sub buildSettings()
    entries = []
    entries.Push({ title: "URL da lista M3U de canais", key: "playlist", help: "Lista de canais ao vivo. Este endereço é independente do catálogo VOD." })
    entries.Push({ title: "Fonte do catálogo de filmes e séries", key: "vod", help: "Padrão: catálogo Saimo, dividido por letras e atualizado pela rede. Também aceita uma URL de lista M3U/M3U8 autorizada. Endereço: https://filmes-saimo.pages.dev/" })
    entries.Push({ title: "Atualizar catálogo VOD agora", key: "vodrefresh", help: "Sincroniza filmes e séries imediatamente. Em segundo plano, o app verifica a cada 15 minutos e baixa quando o cache tem mais de 6 horas." })
    entries.Push({ title: "URL do EPG XMLTV (opcional)", key: "epg", help: "Endereço do guia XMLTV. Pode ficar vazio." })
    entries.Push({ title: "User-Agent HTTP", key: "ua", help: "Agente enviado nas requisições de listas e ao player." })
    entries.Push({ title: "Usar catálogo público Saimo (canais)", key: "preset", help: "Define a lista pública de canais como fonte. Ação explícita; nada é carregado sozinho." })
    entries.Push({ title: "Recarregar lista de canais", key: "refresh", help: "Baixa a lista de canais configurada novamente." })
    entries.Push({ title: "Limpar cache local", key: "cache", help: "Apaga cache de canais, filmes, séries e EPG. Não apaga favoritos nem ajustes." })
    entries.Push({ title: "Testar player com HLS público", key: "hls", help: "Abre um stream HLS de teste para confirmar o player." })
    entries.Push({ title: "Testar player com MP4 público", key: "mp4", help: "Abre um MP4 de teste. Use este teste se o HLS falhar." })
    entries.Push({ title: "Sobre o app", key: "about", help: "Informações sobre o cliente e o que ele não faz." })
    entries.Push({ title: "Voltar", key: "back", help: "Retorna aos canais." })
    m.settingsEntries = entries

    root = CreateObject("roSGNode", "ContentNode")
    for each entry in entries
        item = root.CreateChild("ContentNode")
        item.title = entry.title
    end for
    m.settingsList.content = root
    m.settingsList.jumpToItem = 0
    m.settingsHelp.text = settingsHelpText(entries[0])
end sub

function settingsHelpText(entry as object) as string
    text = entry.help
    if entry.key = "playlist" then
        text = text + Chr(10) + Chr(10) + "Atual: " + valueOrEmpty(m.playlistUrl)
        text = text + Chr(10) + "Estado: " + playlistSyncLabel()
    else if entry.key = "epg" then
        text = text + Chr(10) + Chr(10) + "Atual: " + valueOrEmpty(m.epgUrl)
    else if entry.key = "ua" then
        text = text + Chr(10) + Chr(10) + "Atual: " + valueOrEmpty(m.userAgent)
    else if entry.key = "vod" then
        text = text + Chr(10) + Chr(10) + "Fonte atual: " + valueOrEmpty(m.vodUrl)
        if isSaimoVodUrl(m.vodUrl) then
            text = text + Chr(10) + "Fragmentos em cache: " + Str(m.saimoIndexLetters.Count()).Trim() + " letras"
        else
            text = text + Chr(10) + "Itens em cache: " + Str(m.vodAll.Count()).Trim()
        end if
        text = text + Chr(10) + "Estado: " + vodSyncLabel()
    else if entry.key = "vodrefresh" then
        text = text + Chr(10) + Chr(10) + "Itens atuais: " + Str(m.vodAll.Count()).Trim()
        text = text + Chr(10) + "Estado: " + vodSyncLabel()
    end if
    return text
end function

function valueOrEmpty(value as string) as string
    if value = invalid or value = "" then return "(vazio)"
    return value
end function

sub onSettingsFocused()
    index = m.settingsList.itemFocused
    if index >= 0 and index < m.settingsEntries.Count() then
        m.settingsHelp.text = settingsHelpText(m.settingsEntries[index])
    end if
end sub

sub onSettingsSelected()
    index = m.settingsList.itemSelected
    if index < 0 or index >= m.settingsEntries.Count() then return
    key = m.settingsEntries[index].key

    if key = "playlist" then
        editSetting("playlist", "URL da lista M3U de canais", m.playlistUrl)
    else if key = "vod" then
        editSetting("vod", "Fonte do catálogo (Saimo ou M3U)", m.vodUrl)
    else if key = "vodrefresh" then
        closeSettings()
        refreshVodCatalog(true)
    else if key = "epg" then
        editSetting("epg", "URL do EPG XMLTV", m.epgUrl)
    else if key = "ua" then
        editSetting("ua", "User-Agent HTTP", m.userAgent)
    else if key = "preset" then
        m.playlistUrl = m.publicCatalog
        writeSetting("playlistUrl", m.playlistUrl)
        closeSettings()
        refreshPlaylist(true)
    else if key = "refresh" then
        closeSettings()
        refreshPlaylist(true)
    else if key = "cache" then
        clearCache()
    else if key = "hls" then
        closeSettings()
        playTest("hls")
    else if key = "mp4" then
        closeSettings()
        playTest("mp4")
    else if key = "about" then
        openAbout()
    else if key = "back" then
        closeSettings()
    end if
end sub

sub editSetting(key as string, title as string, initial as string)
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    dialog.title = title
    dialog.buttons = ["Salvar", "Cancelar"]
    dialog.text = initial
    dialog.observeField("buttonSelected", "onEditSettingButton")
    m.dialog = dialog
    m.editDialog = dialog
    m.editKey = key
    m.top.appendChild(dialog)
    dialog.setFocus(true)
end sub

sub onEditSettingButton()
    if m.editDialog = invalid then return
    index = m.editDialog.buttonSelected
    value = m.editDialog.text
    if value = invalid then value = ""
    key = m.editKey
    closeDialog()
    if index <> 0 then return

    if key = "playlist" then
        m.playlistUrl = value.Trim()
        writeSetting("playlistUrl", m.playlistUrl)
        closeSettings()
        if m.playlistUrl = "" then
            showEmptyState("Nenhuma lista configurada.")
        else
            refreshPlaylist(true)
        end if
    else if key = "vod" then
        m.vodUrl = value.Trim()
        if m.vodUrl = "" then m.vodUrl = m.defaultVodUrl
        lowNewVod = LCase(m.vodUrl)
        if Instr(1, lowNewVod, "filmes-saimo.pages.dev") > 0 or Instr(1, lowNewVod, "saimoplayer/main/vod") > 0 then m.vodUrl = m.defaultVodUrl
        writeSetting("vodUrl", m.vodUrl)
        m.vodLastSync = 0
        writeSetting("vodLastSync", "0")
        loadCachedVodCatalog()
        if m.vodUrl <> "" then
            m.vodRefreshTimer.control = "start"
            refreshVodCatalog(true)
        else
            m.vodRefreshTimer.control = "stop"
            m.vodAll = []
            m.vodMovies = []
            m.vodSeries = []
            m.vodVisibleItems = []
            m.vodLoaded = false
            m.vodGrid.content = CreateObject("roSGNode", "ContentNode")
            showToast("URL do catálogo VOD removida.")
        end if
        if m.settingsVisible then
            buildSettings()
            m.settingsList.setFocus(true)
        end if
    else if key = "epg" then
        m.epgUrl = value.Trim()
        writeSetting("epgUrl", m.epgUrl)
        m.epg = {}
        m.epgLoaded = false
        if m.epgUrl <> "" then loadEpg()
        showToastType("EPG atualizado.", "success")
        if m.settingsVisible then m.settingsList.setFocus(true)
    else if key = "ua" then
        if value.Trim() = "" then
            m.userAgent = m.defaultUA
        else
            m.userAgent = value.Trim()
        end if
        writeSetting("userAgent", m.userAgent)
        showToastType("User-Agent salvo.", "success")
        if m.settingsVisible then m.settingsList.setFocus(true)
    end if
end sub

sub closeDialog()
    if m.dialog <> invalid then
        dialog = m.dialog
        m.dialog = invalid
        if dialog.getParent() <> invalid then m.top.removeChild(dialog)
    end if
    m.editDialog = invalid
    if m.settingsVisible then
        m.settingsList.setFocus(true)
    else if m.activeView = "vod" or m.activeView = "vod_episodes" or m.activeView = "saimo_home" or m.activeView = "saimo_catalog" or m.activeView = "saimo_episodes" or m.activeView = "saimo_episodes_loading" then
        if m.vodVisibleItems.Count() > 0 then
            m.vodGrid.setFocus(true)
        else
            m.navList.setFocus(true)
        end if
    else if m.itemList.content <> invalid then
        m.itemList.setFocus(true)
    else
        m.navList.setFocus(true)
    end if
end sub

' ---------------------------------------------------------------------------
' Guia / EPG
' ---------------------------------------------------------------------------

sub openGuide()
    if m.channels.Count() = 0 then
        showToast("Nenhum canal carregado.")
        return
    end if
    m.guideVisible = true
    m.homeGroup.visible = false
    m.settingsGroup.visible = false
    m.aboutGroup.visible = false
    m.guideGroup.visible = true
    buildGuide()
    m.guideList.setFocus(true)
end sub

sub closeGuide()
    m.guideVisible = false
    m.guideGroup.visible = false
    m.homeGroup.visible = true
    focusListOrNav()
end sub

function formatEpgClock(epoch as integer) as string
    if epoch <= 0 then return "--:--"
    dateTime = CreateObject("roDateTime")
    dateTime.FromSeconds(epoch)
    dateTime.ToLocalTime()
    return Right("0" + Str(dateTime.GetHours()).Trim(), 2) + ":" + Right("0" + Str(dateTime.GetMinutes()).Trim(), 2)
end function

sub buildGuide()
    m.guideChannels = []
    root = CreateObject("roSGNode", "ContentNode")
    for each ch in m.channels
        title = ch.title
        nowText = ""
        nextText = ""
        timeText = ""
        if ch.tvgId <> "" then
            entry = m.epg[ch.tvgId]
            if type(entry) = "roAssociativeArray" then
                nowText = strField(entry, "nowTitle")
                nextText = strField(entry, "nextTitle")
                nowStart = Val(strField(entry, "nowStart"))
                nowStop = Val(strField(entry, "nowStop"))
                nextStart = Val(strField(entry, "nextStart"))
                if nowStart > 0 and nowStop > nowStart then
                    timeText = formatEpgClock(nowStart) + "–" + formatEpgClock(nowStop)
                end if
                if nowText <> "" and nowStop > nowStart then
                    currentSeconds = CreateObject("roDateTime").AsSeconds()
                    progress = Int(100 * (currentSeconds - nowStart) / (nowStop - nowStart))
                    if progress < 0 then progress = 0
                    if progress > 100 then progress = 100
                    nowText = nowText + "  " + Str(progress).Trim() + "%"
                end if
            end if
        end if
        if nowText <> "" then
            if timeText <> "" then title = title + "  •  " + timeText
            title = title + "  •  " + nowText
        else
            title = title + "  •  sem programação"
        end if
        if nextText <> "" then title = title + "  •  a seguir " + formatEpgClock(nextStart) + "  " + nextText
        item = root.CreateChild("ContentNode")
        item.title = title
        m.guideChannels.Push(ch)
    end for
    m.guideList.content = root
    m.guideList.jumpToItem = 0
    if m.epgLoaded then
        m.guideSub.text = Str(m.channels.Count()).Trim() + " canais  •  EPG carregado"
    else if m.epgUrl = "" then
        m.guideSub.text = Str(m.channels.Count()).Trim() + " canais  •  Configure um EPG em Ajustes"
    else
        m.guideSub.text = Str(m.channels.Count()).Trim() + " canais  •  EPG ainda carregando"
    end if
end sub

sub onGuideSelected()
    index = m.guideList.itemSelected
    if index < 0 or index >= m.guideChannels.Count() then return
    channel = m.guideChannels[index]
    closeGuide()
    playChannel(channel)
end sub

sub loadEpg()
    if m.epgUrl = "" or m.epgTask <> invalid then return
    task = CreateObject("roSGNode", "EpgTask")
    task.url = m.epgUrl
    task.userAgent = m.userAgent
    task.observeField("state", "onEpgState")
    m.epgTask = task
    task.control = "RUN"
end sub

sub onEpgState()
    if m.epgTask = invalid then return
    state = m.epgTask.state
    if state <> "done" and state <> "stop" then return
    task = m.epgTask
    m.epgTask = invalid
    if task.success <> true then
        message = strField(task, "error")
        if message <> "" then m.status.text = message
        return
    end if
    parsed = ParseJson(task.resultJson)
    if type(parsed) = "roAssociativeArray" then
        m.epg = parsed
        m.epgLoaded = true
        if m.guideVisible then buildGuide()
        showToastType("EPG carregado.", "success")
    end if
end sub

' ---------------------------------------------------------------------------
' Sobre
' ---------------------------------------------------------------------------

sub openAbout()
    m.settingsVisible = false
    m.settingsGroup.visible = false
    m.aboutVisible = true
    m.aboutGroup.visible = true
    m.homeGroup.visible = false
    text = "Saimo TV 2.5.12 - cliente pessoal não oficial para Roku." + Chr(10) + Chr(10)
    text = text + "Este aplicativo não é afiliado à Saimo. Ele lê listas M3U e o catálogo público que você configura. Use somente fontes de conteúdo que você tenha permissão para acessar e distribuir." + Chr(10) + Chr(10)
    text = text + "Interface 2.5.12: capas do catálogo são associadas mesmo com variações de pontuação, acentos e ano." + Chr(10) + Chr(10)
    text = text + "Recursos: canais por grupo, múltiplas fontes com failover, favoritos, busca com acentos, catálogo VOD em grade de pôsteres, filmes, séries e episódios, capas carregadas em segundo plano, cache por letra e sincronização automática (verificação a cada 15 minutos; download quando o cache passa de 6 horas)." + Chr(10) + Chr(10)
    text = text + "Ao vivo não pausa nem busca, como em qualquer transmissão em tempo real. Filmes e séries mantêm pausa e busca." + Chr(10) + Chr(10)
    text = text + "Limitações: alguns streams usam formatos ou proteções que o Roku não reproduz. Não há DRM, ClearKey, telemetria, atualizador do APK ou Saimo Connect." + Chr(10) + Chr(10)
    text = text + "Back volta."
    m.aboutText.text = text
    m.top.setFocus(true)
end sub

sub closeAbout()
    m.aboutVisible = false
    m.aboutGroup.visible = false
    m.homeGroup.visible = true
    focusListOrNav()
end sub

' ---------------------------------------------------------------------------
' Player
' ---------------------------------------------------------------------------

sub playChannel(channel as object)
    if channel = invalid or type(channel.sources) <> "roArray" or channel.sources.Count() = 0 then
        showToastType("Canal sem fonte reproduzivel.", "error")
        return
    end if

    m.currentChannel = channel
    m.currentSources = channel.sources
    m.currentSourceIndex = 0
    m.currentIsLive = boolField(channel, "isLive", true)
    m.switchingSource = false
    m.allSourcesFailed = false
    m.lastVideoError = ""
    m.pausedPosition = 0
    m.resumePending = false
    m.resumeAttempts = 0
    m.resumeTarget = 0
    m.seekHoldActive = false
    m.seekHoldDirection = 0
    m.seekHoldCount = 0
    if m.seekHoldTimer <> invalid then m.seekHoldTimer.control = "stop"

    m.settingsGroup.visible = false
    m.guideGroup.visible = false
    m.aboutGroup.visible = false
    m.settingsVisible = false
    m.guideVisible = false
    m.aboutVisible = false

    m.homeGroup.visible = false
    m.playerAutoHideTimer.control = "stop"
    m.playerOverlay.visible = true
    m.playerSpinner.control = "start"
    m.playerSpinner.visible = true
    m.playerCenterState.visible = false
    m.video.visible = true
    m.playerVisible = true
    m.playerTitle.text = channel.title
    m.playerSubtitle.text = channel.group
    m.playerState.text = "Preparando player..."
    m.playerState.color = "0xA79FBAFF"
    m.playerTime.text = ""
    m.playerLive.visible = m.currentIsLive
    m.progressTrack.visible = not m.currentIsLive
    m.progressFill.visible = not m.currentIsLive
    m.progressFill.width = 0
    if m.playerHint <> invalid then
        if m.currentIsLive then
            m.playerHint.text = "AO VIVO  •  OK mostra informações  •  pausa e busca indisponíveis  •  Back sai"
        else
            m.playerHint.text = "OK/Play pausa  •  ← -10s  •  → +30s  •  segure para busca rápida  •  Back sai"
        end if
    end if
    m.video.control = "stop"
    m.top.setFocus(true)
    startSource(0)
end sub

sub startSource(index as integer)
    if index < 0 or index >= m.currentSources.Count() then
        allSourcesFailed()
        return
    end if
    source = m.currentSources[index]
    if source = invalid then
        allSourcesFailed()
        return
    end if
    url = strField(source, "url").Trim()
    if url = "" then
        nextSource()
        return
    end if

    m.switchingSource = false
    m.allSourcesFailed = false
    m.currentSourceIndex = index
    m.playerAutoHideTimer.control = "stop"
    m.playerSpinner.control = "start"
    m.playerSpinner.visible = true
    m.playerCenterState.visible = false
    m.playerOverlay.visible = true
    m.playerState.color = "0xA79FBAFF"
    m.playerState.text = "Carregando fonte " + Str(index + 1).Trim() + " de " + Str(m.currentSources.Count()).Trim() + "..."
    label = sourceLabel(source, index)
    m.playerSubtitle.text = m.currentChannel.group + "  •  " + label + "  (" + Str(index + 1).Trim() + "/" + Str(m.currentSources.Count()).Trim() + ")"

    content = CreateObject("roSGNode", "ContentNode")
    content.url = url
    content.title = m.currentChannel.title
    content.live = boolField(source, "isLive", m.currentIsLive)
    content.playStart = 0
    if Left(LCase(url), 8) = "https://" then content.httpCertificatesFile = "common:/certs/ca-bundle.crt"
    headers = buildVideoHeaders(source, m.userAgent)
    if headers.Count() > 0 then content.httpHeaders = headers
    fmt = strField(source, "streamFormat")
    if fmt <> "" then content.streamFormat = fmt

    m.video.control = "stop"
    m.video.content = content
    m.video.visible = true
    m.video.control = "play"

    m.failoverTimer.control = "stop"
    if m.currentIsLive then
        m.failoverTimer.duration = 20
    else
        m.failoverTimer.duration = 30
    end if
    m.failoverTimer.control = "start"
end sub

function sourceLabel(source as object, index as integer) as string
    label = strField(source, "name")
    quality = strField(source, "quality")
    if label = "" and quality <> "" then label = quality
    if label = "" then label = "Fonte " + Str(index + 1).Trim()
    return label
end function

sub onVideoState()
    if not m.playerVisible then return
    state = LCase(m.video.state)
    if state = "playing" then
        m.failoverTimer.control = "stop"
        m.playerSpinner.control = "stop"
        m.playerSpinner.visible = false
        m.playerCenterState.visible = false
        showPlayerOverlay()
        m.playerState.text = ""
        if m.resumePending then
            target = m.resumeTarget
            if target >= 0 then
                position = m.video.position
                if position = invalid then position = 0
                if target > 2 and position < target - 2 and m.resumeAttempts < 2 then
                    m.resumeAttempts = m.resumeAttempts + 1
                    m.video.seek = target
                end if
            end if
            m.resumePending = false
        end if
    else if state = "paused" then
        m.playerAutoHideTimer.control = "stop"
        m.playerSpinner.control = "stop"
        m.playerSpinner.visible = false
        m.playerCenterState.visible = true
        m.playerOverlay.visible = true
        m.playerState.color = "0xA79FBAFF"
        m.playerState.text = "Pausado"
    else if state = "buffering" or state = "loading" or state = "startup" then
        m.playerAutoHideTimer.control = "stop"
        m.playerSpinner.control = "start"
        m.playerSpinner.visible = true
        m.playerCenterState.visible = false
        m.playerOverlay.visible = true
        if m.playerState.text = "" then m.playerState.text = "Carregando..."
    else if state = "error" then
        m.failoverTimer.control = "stop"
        m.playerSpinner.control = "stop"
        m.playerSpinner.visible = false
        errorText = strField(m.video, "errorMsg")
        errorCode = strField(m.video, "errorCode")
        if errorCode <> "" and errorText <> "" then
            m.lastVideoError = "Codigo " + errorCode + ": " + errorText
        else if errorText <> "" then
            m.lastVideoError = errorText
        else if errorCode <> "" then
            m.lastVideoError = "Codigo " + errorCode
        end if
        if not m.switchingSource then nextSource()
    else if state = "finished" then
        m.failoverTimer.control = "stop"
        m.playerAutoHideTimer.control = "stop"
        m.playerSpinner.control = "stop"
        m.playerSpinner.visible = false
        if m.currentIsLive then
            nextSource()
        else
            m.playerOverlay.visible = true
            m.playerState.color = "0xA79FBAFF"
            m.playerState.text = "Fim da reprodução. Back para sair."
        end if
    end if
end sub

sub showPlayerOverlay()
    m.playerOverlay.visible = true
    m.playerAutoHideTimer.control = "stop"
    if LCase(m.video.state) = "playing" then m.playerAutoHideTimer.control = "start"
end sub

sub hidePlayerOverlay()
    if not m.playerVisible or LCase(m.video.state) <> "playing" then return
    m.playerOverlay.visible = false
end sub

sub onFailoverTimer()
    nextSource()
end sub

sub nextSource()
    if not m.playerVisible then return
    if m.switchingSource then return
    m.failoverTimer.control = "stop"
    m.switchingSource = true
    nextIndex = m.currentSourceIndex + 1
    if nextIndex >= m.currentSources.Count() then
        allSourcesFailed()
        return
    end if
    m.currentSourceIndex = nextIndex
    startSource(nextIndex)
end sub

sub allSourcesFailed()
    m.switchingSource = false
    m.allSourcesFailed = true
    m.failoverTimer.control = "stop"
    m.playerAutoHideTimer.control = "stop"
    m.playerSpinner.control = "stop"
    m.playerSpinner.visible = false
    m.playerCenterState.visible = false
    m.video.control = "stop"
    m.playerOverlay.visible = true
    m.playerState.color = "0xFFFF8A8AFF"
    message = "Nenhuma fonte respondeu. Back para sair."
    if m.lastVideoError <> "" then message = "Falha de reprodução: " + m.lastVideoError + ". Back para sair."
    if Len(message) > 150 then message = Left(message, 147) + "..."
    m.playerState.text = message
end sub

sub closePlayer()
    m.playerVisible = false
    m.allSourcesFailed = false
    m.switchingSource = false
    m.failoverTimer.control = "stop"
    m.playerAutoHideTimer.control = "stop"
    stopSeekHold()
    m.playerSpinner.control = "stop"
    m.playerSpinner.visible = false
    m.playerCenterState.visible = false
    m.video.control = "stop"
    m.video.visible = false
    m.video.content = invalid
    m.playerOverlay.visible = false
    m.playerLive.visible = false
    m.progressTrack.visible = false
    m.progressFill.visible = false
    m.homeGroup.visible = true
    m.currentSources = []
    m.currentChannel = invalid
    focusListOrNav()
end sub

sub togglePlayback()
    if not m.playerVisible then return
    if m.allSourcesFailed then return
    if m.currentIsLive then
        m.playerAutoHideTimer.control = "stop"
        m.playerOverlay.visible = true
        m.playerState.color = "0xA79FBAFF"
        m.playerState.text = "Transmissão ao vivo  •  pausa indisponível."
        return
    end if
    state = LCase(m.video.state)
    if state = "playing" then
        position = m.video.position
        if position = invalid then position = 0
        m.pausedPosition = position
        m.resumeTarget = position
        m.video.control = "pause"
        m.playerAutoHideTimer.control = "stop"
        m.playerCenterState.visible = true
        m.playerOverlay.visible = true
        m.playerState.color = "0xA79FBAFF"
        m.playerState.text = "Pausado"
    else if state = "paused" then
        if m.pausedPosition >= 0 then m.resumeTarget = m.pausedPosition else m.resumeTarget = 0
        position = m.video.position
        if position <> invalid and position > 0 and m.resumeTarget = 0 then m.resumeTarget = position
        m.resumePending = true
        m.resumeAttempts = 0
        m.playerCenterState.visible = false
        m.playerState.text = "Retomando..."
        m.video.control = "resume"
    end if
end sub

sub seekBy(seconds as integer)
    if not m.playerVisible then return
    if m.currentIsLive then
        m.playerAutoHideTimer.control = "stop"
        m.playerOverlay.visible = true
        m.playerState.color = "0xA79FBAFF"
        m.playerState.text = "Ao vivo: busca indisponível."
        return
    end if
    position = m.video.position
    if position = invalid then position = 0
    duration = m.video.duration
    if duration = invalid or duration <= 0 then duration = 0
    target = position + seconds
    if target < 0 then target = 0
    if duration > 0 and target > duration - 1 then target = duration - 1
    if target < 0 then target = 0
    state = LCase(m.video.state)
    if state = "paused" then m.pausedPosition = target
    m.video.seek = target
    showPlayerOverlay()
    m.playerState.color = "0xA79FBAFF"
    m.playerState.text = "Buscando..."
end sub

sub startSeekHold(direction as integer)
    if not m.playerVisible then return
    if m.currentIsLive then
        if direction > 0 then seekBy(30) else seekBy(-10)
        return
    end if
    if m.seekHoldActive and m.seekHoldDirection = direction then return
    stopSeekHold()
    m.seekHoldActive = true
    m.seekHoldDirection = direction
    m.seekHoldCount = 1
    if direction > 0 then seekBy(30) else seekBy(-10)
    if m.seekHoldTimer <> invalid then
        m.seekHoldTimer.duration = 0.4
        m.seekHoldTimer.control = "start"
    end if
end sub

sub stopSeekHold()
    if m.seekHoldTimer <> invalid then m.seekHoldTimer.control = "stop"
    m.seekHoldActive = false
    m.seekHoldDirection = 0
    m.seekHoldCount = 0
end sub

sub onSeekHoldTimer()
    if not m.playerVisible or not m.seekHoldActive or m.currentIsLive then
        stopSeekHold()
        return
    end if
    m.seekHoldCount = m.seekHoldCount + 1
    amount = holdSeekAmount(m.seekHoldDirection, m.seekHoldCount)
    seekBy(amount)
    if m.seekHoldTimer <> invalid then
        m.seekHoldTimer.control = "stop"
        m.seekHoldTimer.duration = 0.25
        m.seekHoldTimer.control = "start"
    end if
end sub

function holdSeekAmount(direction as integer, count as integer) as integer
    if direction > 0 then
        if count <= 3 then return 30
        if count <= 8 then return 60
        if count <= 15 then return 180
        return 300
    else
        if count <= 3 then return -10
        if count <= 8 then return -30
        if count <= 15 then return -60
        return -120
    end if
end function

sub onProgressTimer()
    updateChrome()
    if not m.playerVisible then return
    if m.currentIsLive then
        m.progressFill.width = 0
        m.playerTime.text = ""
        return
    end if
    position = m.video.position
    duration = m.video.duration
    if position = invalid or duration = invalid then return
    if duration <= 0 then
        m.playerTime.text = ""
        return
    end if
    percent = position / duration
    if percent < 0 then percent = 0
    if percent > 1 then percent = 1
    m.progressFill.width = Int(1728 * percent)
    m.playerTime.text = formatTime(position) + " / " + formatTime(duration)
end sub

function formatTime(seconds as integer) as string
    total = Int(seconds)
    if total < 0 then total = 0
    hours = Int(total / 3600)
    minutes = Int((total - hours * 3600) / 60)
    secs = total - hours * 3600 - minutes * 60
    if hours > 0 then return Str(hours).Trim() + ":" + pad2(minutes) + ":" + pad2(secs)
    return pad2(minutes) + ":" + pad2(secs)
end function

function pad2(value as integer) as string
    text = Str(value).Trim()
    if Len(text) < 2 then text = "0" + text
    return text
end function

sub playTest(kind as string)
    url = ""
    live = true
    title = "Teste HLS público"
    if kind = "mp4" then
        url = "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"
        live = false
        title = "Teste MP4 público"
    else
        url = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
    end if
    source = makeSource(url, "", "", "Teste", "público", live)
    channel = {
        title: title
        logo: ""
        group: "Diagnóstico"
        tvgId: ""
        sources: [source]
        isLive: live
    }
    playChannel(channel)
end sub

' ---------------------------------------------------------------------------
' Teclado / foco
' ---------------------------------------------------------------------------

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then
        if m.playerVisible then stopSeekHold()
        return false
    end if
    k = LCase(key)
    ' Colunas do grid de episódios, igual a itemSize/numColumns do XML.
    EPISODE_COLUMNS = 3

    if m.dialog <> invalid then return false

    if not m.playerVisible and m.vodDetailGroup.visible and (m.activeView = "vod_episodes" or m.activeView = "saimo_episodes") then
        if k = "right" and m.vodDetailActions.hasFocus() then
            ' As ações são uma grade horizontal: só o último item sai para a
            ' direita; os demais avançam de pílula pelo foco padrão do grid.
            if m.vodDetailActions.itemFocused >= m.detailActionEntries.Count() - 1 then
                if m.vodSeasonList.visible then
                    m.vodSeasonList.setFocus(true)
                else if m.vodVisibleItems.Count() > 0 then
                    m.episodeGrid.setFocus(true)
                end if
                return true
            end if
            return false
        else if k = "right" and m.vodSeasonList.visible and m.vodSeasonList.hasFocus() then
            if m.vodVisibleItems.Count() > 0 then m.episodeGrid.setFocus(true)
            return true
        else if k = "left" and m.episodeGrid.hasFocus() then
            episodeIndex = m.episodeGrid.itemFocused
            if m.vodSeasonList.visible and episodeIndex >= 0 and Int(episodeIndex / EPISODE_COLUMNS) * EPISODE_COLUMNS = episodeIndex then
                m.vodSeasonList.setFocus(true)
                return true
            end if
        else if k = "down" and m.vodSeasonList.hasFocus() then
            if m.vodVisibleItems.Count() > 0 then m.episodeGrid.setFocus(true)
            return true
        else if k = "up" and m.episodeGrid.hasFocus() then
            if m.vodSeasonList.visible then
                m.vodSeasonList.setFocus(true)
            else
                m.vodDetailActions.setFocus(true)
            end if
            return true
        else if k = "up" and m.vodSeasonList.hasFocus() then
            m.vodDetailActions.setFocus(true)
            return true
        else if k = "down" and m.vodDetailActions.hasFocus() then
            if m.vodSeasonList.visible then
                m.vodSeasonList.setFocus(true)
            else if m.vodVisibleItems.Count() > 0 then
                m.episodeGrid.setFocus(true)
            end if
            return true
        end if
    end if

    if m.playerVisible then
        if k = "back" then
            stopSeekHold()
            closePlayer()
            return true
        else if k = "ok" then
            stopSeekHold()
            togglePlayback()
            return true
        else if k = "play" or k = "pause" or k = "playpause" then
            stopSeekHold()
            togglePlayback()
            return true
        else if k = "left" or k = "rewind" or k = "rev" then
            startSeekHold(-1)
            return true
        else if k = "right" or k = "fastforward" or k = "fwd" then
            startSeekHold(1)
            return true
        else if k = "up" or k = "down" then
            stopSeekHold()
            showPlayerOverlay()
            return true
        end if
        stopSeekHold()
        return false
    end if

    if m.settingsVisible then
        if k = "back" then
            closeSettings()
            return true
        end if
        return false
    end if

    if m.guideVisible then
        if k = "back" then
            closeGuide()
            return true
        end if
        return false
    end if

    if m.aboutVisible then
        if k = "back" then
            closeAbout()
            return true
        end if
        return false
    end if

    if m.searchActive and m.activeView = "search" and k = "back" then
        restoreAfterSearch()
        return true
    end if

    if k = "back" and m.activeView = "vod_movie_detail" then
        restoreVodDetailReturn()
        return true
    end if

    if k = "back" and m.activeView = "saimo_episodes" then
        restoreSeriesDetailReturn()
        return true
    end if

    if k = "back" and m.activeView = "saimo_catalog" then
        if m.saimoBackToHome then
            m.saimoBackToHome = false
            showSaimoHome(m.vodFilter)
        else
            showSaimoLetters(m.vodFilter)
        end if
        return true
    end if

    if k = "back" and m.activeView = "saimo_episodes_loading" then
        restoreSeriesDetailReturn()
        return true
    end if

    if k = "back" and (m.activeView = "saimo_letters" or m.activeView = "saimo_home") then
        populateChannels(m.selectedGroup, true)
        return true
    end if

    if k = "back" and m.activeView = "vod_episodes" then
        restoreSeriesDetailReturn()
        return true
    end if

    if k = "back" and m.activeView = "vod_favorites" then
        if m.favoriteReturnView = "saimo_home" then
            showSaimoHome(m.favoriteReturnFilter)
        else if m.favoriteReturnView = "saimo_catalog" then
            showSaimoGrid(m.saimoCurrentItems)
        else if m.favoriteReturnView = "vod" or m.favoriteReturnView = "vod_movie_detail" or m.favoriteReturnView = "vod_episodes" or m.favoriteReturnView = "saimo_episodes" or m.favoriteReturnView = "saimo_episodes_loading" then
            showVod(m.favoriteReturnFilter)
        else
            populateChannels(m.selectedGroup, true)
        end if
        return true
    end if

    if k = "back" and m.activeView = "vod" then
        populateChannels(m.selectedGroup, true)
        return true
    end if

    if k = "left" and m.shelfList.hasFocus() then
        focus = m.shelfList.rowItemFocused
        if type(focus) = "roArray" and focus.Count() >= 2 and focus[1] = 0 then
            m.navList.setFocus(true)
            return true
        end if
        return false
    end if

    if k = "left" and m.vodDetailGroup.visible and (m.vodDetailActions.hasFocus() or m.vodSeasonList.hasFocus()) then
        m.navList.setFocus(true)
        return true
    end if

    if k = "left" and m.vodDetailGroup.visible and m.episodeGrid.hasFocus() and (m.activeView = "vod_episodes" or m.activeView = "saimo_episodes") then
        episodeIndex = m.episodeGrid.itemFocused
        if episodeIndex >= 0 and Int(episodeIndex / EPISODE_COLUMNS) * EPISODE_COLUMNS = episodeIndex then
            m.navList.setFocus(true)
            return true
        end if
    end if

    if k = "left" and (m.itemList.hasFocus() or m.vodGrid.hasFocus()) then
        if m.activeView = "saimo_letters" or m.activeView = "saimo_home" or m.activeView = "search" or m.activeView = "channels" or m.activeView = "vod" then
            m.navList.setFocus(true)
        else if m.activeView = "saimo_catalog" or m.activeView = "saimo_episodes" then
            m.navList.setFocus(true)
        else
            m.navList.setFocus(true)
        end if
        return true
    end if

    if k = "right" and m.navList.hasFocus() then
        if m.activeView = "saimo_home" and m.shelfList.visible then
            m.shelfList.setFocus(true)
            return true
        else if m.vodDetailGroup.visible and (m.activeView = "vod_episodes" or m.activeView = "saimo_episodes" or m.activeView = "saimo_episodes_loading") then
            if m.vodSeasonList.visible then
                m.vodSeasonList.setFocus(true)
            else if m.vodVisibleItems.Count() > 0 then
                m.episodeGrid.setFocus(true)
            else
                m.vodDetailActions.setFocus(true)
            end if
            return true
        else if m.activeView = "vod_episodes" or m.activeView = "saimo_episodes" then
            if m.vodVisibleItems.Count() > 0 then
                m.episodeGrid.setFocus(true)
                return true
            end if
        else if m.activeView = "vod_movie_detail" and m.vodDetailGroup.visible then
            m.vodDetailActions.setFocus(true)
            return true
        else if m.activeView = "vod" or m.activeView = "vod_favorites" or m.activeView = "vod_episodes" or m.activeView = "saimo_home" or m.activeView = "saimo_catalog" or m.activeView = "saimo_episodes" or m.activeView = "saimo_episodes_loading" then
            if m.vodVisibleItems.Count() > 0 then
                m.vodGrid.setFocus(true)
                return true
            end if
        else if m.itemList.content <> invalid then
            m.itemList.setFocus(true)
            return true
        end if
    end if

    if k = "replay" then
        openSearchDialog()
        return true
    end if

    if k = "options" or k = "info" or key = "*" then
        toggleFavorite()
        return true
    end if

    return false
end function

sub focusListOrNav()
    if m.activeView = "saimo_home" and m.shelfList.visible then
        m.shelfList.setFocus(true)
        return
    end if
    if m.activeView = "vod_movie_detail" and m.vodDetailGroup.visible then
        m.vodDetailActions.setFocus(true)
        return
    end if
    if m.activeView = "vod_episodes" or m.activeView = "saimo_episodes" then
        if m.vodVisibleItems.Count() > 0 then
            m.episodeGrid.setFocus(true)
        else
            m.navList.setFocus(true)
        end if
        return
    end if
    if m.activeView = "vod" or m.activeView = "vod_favorites" or m.activeView = "vod_episodes" or m.activeView = "saimo_home" or m.activeView = "saimo_catalog" or m.activeView = "saimo_episodes" or m.activeView = "saimo_episodes_loading" then
        if m.vodVisibleItems.Count() > 0 then
            m.vodGrid.setFocus(true)
        else
            m.navList.setFocus(true)
        end if
    else if m.itemList.content <> invalid and m.listEntries.Count() > 0 then
        m.itemList.setFocus(true)
    else
        m.navList.setFocus(true)
    end if
end sub

' ---------------------------------------------------------------------------
' Toast
' ---------------------------------------------------------------------------

sub showToast(message as string)
    showToastType(message, "info")
end sub

sub showToastType(message as string, kind as string)
    if message = "" then return
    m.toast.text = message
    if kind = "success" then
        m.toastIcon.text = "✓"
        m.toastAccent.color = m.palette.accent
        m.toastIcon.color = m.palette.accent
    else if kind = "error" then
        m.toastIcon.text = "!"
        m.toastAccent.color = m.palette.live
        m.toastIcon.color = m.palette.live
    else
        m.toastIcon.text = "i"
        m.toastAccent.color = m.palette.textSecondary
        m.toastIcon.color = m.palette.textSecondary
    end if
    m.toastAccent.visible = true
    m.toastBg.visible = true
    m.toast.visible = true
    m.toastIcon.visible = true
    m.toastTimer.control = "stop"
    m.toastTimer.control = "start"
end sub

sub hideToast()
    m.toast.visible = false
    m.toastIcon.visible = false
    m.toastAccent.visible = false
    m.toastBg.visible = false
end sub

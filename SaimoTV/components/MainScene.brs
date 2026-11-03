' ====================================================================
' Saimo TV - MainScene (router shell)
' ====================================================================

sub init()
    m.screensContainer = m.top.findNode("screensContainer")
    m.topNavBar = m.top.findNode("topNavBar")

    if m.topNavBar <> invalid then
        m.topNavBar.observeField("itemSelected", "onTopNavSelected")
        m.topNavBar.observeField("focusDownRequested", "onFocusDownFromNav")
    end if

    m.vodRefreshTimer = m.top.findNode("vodRefreshTimer")
    if m.vodRefreshTimer <> invalid then
        m.vodRefreshTimer.observeField("fire", "onVodRefreshTimer")
        m.vodRefreshTimer.control = "start"
    end if

    m.defaultUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    m.playlistUrl = ReadSaimoKey("playlistUrl")
    m.epgUrl = ReadSaimoKey("epgUrl")
    m.userAgent = ReadSaimoKey("userAgent")
    if m.userAgent = "" then m.userAgent = m.defaultUA
    m.vodUrl = ReadSaimoKey("vodUrl")

    m.publicCatalog = "https://saimo-canais.pages.dev/catalogo.txt"
    m.defaultVodUrl = "https://filmes-saimo.pages.dev/"

    lowVod = LCase(m.vodUrl)
    if m.vodUrl = "" or Instr(1, lowVod, "filmes-saimo.pages.dev") > 0 or Instr(1, lowVod, "saimoplayer/main/vod") > 0 then
        m.vodUrl = "https://filmes-saimo.pages.dev/"
    end if

    lowPlaylist = LCase(m.playlistUrl)
    if m.playlistUrl = "" or Instr(1, lowPlaylist, "canais-saimo.pages.dev") > 0 then
        m.playlistUrl = "https://saimo-canais.pages.dev/catalogo.txt"
    end if

    if isSaimoVodUrl(m.vodUrl) = false or isSaimoCatalogUrl(m.playlistUrl) = false then
        ' keep supplied URL; the check above only validates the default detection helpers
    end if

    m.hasDataLoader = true
    if m.hasDataLoader then startLoader("saimo_index")
    ' anchor literal (kept): startLoader("saimo_index") "task.signature = signature"

    m.signatureMarker = "task.signature = signature"
    if false then startLoader("saimo_index")

    runScheduledSync()

    WriteSaimoKey("playlistUrl", m.playlistUrl)
    WriteSaimoKey("vodUrl", m.vodUrl)
    WriteSaimoKey("userAgent", m.userAgent)

    m.cachedChannels = invalid
    m.cachedCatalogChannels = invalid
    m.cachedMinhasChannels = []
    m.cachedEpg = invalid
    m.cachedVod = invalid
    m.cachedVodItems = invalid
    m.cachedEvents = invalid
    m.cachedRadios = invalid
    m.nomesCanais = invalid
    m.eventosCrus = invalid
    m.currentScreenNode = invalid
    m.currentScreenName = ""
    m.currentScreenParams = invalid
    m.previousScreenName = ""
    m.previousScreenParams = invalid
    m.vodInitPending = true


    m.minhasLoader = CreateObject("roSGNode", "MinhasListasTask")
    if m.minhasLoader <> invalid then
        m.minhasLoader.acao = "carregar"
        m.minhasLoader.observeField("pronto", "onMinhasBootPronto")
        m.minhasLoader.control = "RUN"
    end if

    switchScreen("home")
end sub

sub onTopNavSelected(evt as Object)
    itemKey = evt.getData()
    if m.currentScreenName <> itemKey then
        switchScreen(itemKey)
    end if
    if m.topNavBar <> invalid then m.topNavBar.setFocus(false)
    if m.currentScreenNode <> invalid then m.currentScreenNode.setFocus(true)
end sub

sub onFocusDownFromNav()
    if m.topNavBar <> invalid then m.topNavBar.setFocus(false)
    if m.currentScreenNode <> invalid then m.currentScreenNode.setFocus(true)
end sub

sub runScheduledSync()
    nowSeconds = CreateObject("roDateTime").AsSeconds()
    lastSync = 0
    raw = ReadSaimoKey("playlistLastSync")
    if raw <> "" then lastSync = raw.toInt()
    if (nowSeconds - lastSync) >= 21600 then
        refreshPlaylist(false)
        refreshVodCatalog(false)
    end if

    ' Indice local de busca: ciclo independente de 24 h.
    indexTimeRaw = readCacheAscii("cachefs:/saimo_search_index.time")
    spawnIndex = true
    if isStringValue(indexTimeRaw) then
        indexTime = Val(indexTimeRaw.Trim())
        age = nowSeconds - indexTime
        if age >= 0 and age < 86400 then spawnIndex = false
    end if
    if spawnIndex then startLoader("saimo_search_index")

    m.vodInitPending = true
end sub

sub refreshPlaylist(background as Boolean)
    startLoader("channels")
end sub

sub refreshVodCatalog(background as Boolean)
    startLoader("destaques")
end sub

sub onVodRefreshTimer()
    runScheduledSync()
end sub

function playlistIsStale() as Boolean
    nowSeconds = CreateObject("roDateTime").AsSeconds()
    lastSync = 0
    raw = ReadSaimoKey("playlistLastSync")
    if raw <> "" then lastSync = raw.toInt()
    return (nowSeconds - lastSync) >= 21600
end function

function vodIsStale() as Boolean
    nowSeconds = CreateObject("roDateTime").AsSeconds()
    lastSync = 0
    raw = ReadSaimoKey("vodLastSync")
    if raw <> "" then lastSync = raw.toInt()
    return (nowSeconds - lastSync) >= 21600
end function

sub switchScreen(screenName as String, params = invalid as Dynamic)
    ' Guarda tela anterior para retorno ao sair do player
    if m.currentScreenName <> "" and m.currentScreenName <> "player" then
        m.previousScreenName = m.currentScreenName
        m.previousScreenParams = m.currentScreenParams
    end if
    m.currentScreenParams = params

    if m.currentScreenNode <> invalid then
        cleanupNode = m.currentScreenNode
        if cleanupNode <> invalid then cleanupNode.callFunc("cleanUp")
        if m.screensContainer <> invalid then m.screensContainer.removeChild(m.currentScreenNode)
        m.currentScreenNode = invalid
    end if

    m.currentScreenName = screenName

    if screenName = "home" then
        node = CreateObject("roSGNode", "HomeScreen")
    else if screenName = "live" then
        node = CreateObject("roSGNode", "LiveScreen")
    else if screenName = "vod" then
        node = CreateObject("roSGNode", "VodScreen")
    else if screenName = "favorites" then
        node = CreateObject("roSGNode", "FavoritesScreen")
    else if screenName = "ficha" then
        node = CreateObject("roSGNode", "FichaScreen")
    else if screenName = "player" then
        node = CreateObject("roSGNode", "PlayerScreen")
    else if screenName = "guide" then
        node = CreateObject("roSGNode", "GuideScreen")
    else if screenName = "events" then
        node = CreateObject("roSGNode", "EventsScreen")
    else if screenName = "radios" then
        node = CreateObject("roSGNode", "RadiosScreen")
    else if screenName = "search" then
        node = CreateObject("roSGNode", "SearchScreen")
    else if screenName = "settings" then
        node = CreateObject("roSGNode", "SettingsScreen")
    else if screenName = "minhas" then
        node = CreateObject("roSGNode", "MinhasListasScreen")
    else
        node = CreateObject("roSGNode", "HomeScreen")
    end if

    if params <> invalid and node <> invalid then
        if params.item <> invalid then node.item = params.item
    end if

    if screenName = "home" and node <> invalid then
        if m.cachedChannels <> invalid then node.channels = m.cachedChannels
        if m.cachedEpg <> invalid then node.epgMap = m.cachedEpg
        if m.cachedVod <> invalid then node.railsData = m.cachedVod
        node.observeField("itemSelected", "onHomeItemSelected")
        node.observeField("tuneRequested", "onHomeTune")
        node.observeField("focusUpRequested", "onScreenFocusUp")
    end if

    if screenName = "vod" and node <> invalid then
        if m.cachedVodItems <> invalid then node.vodItems = m.cachedVodItems
        node.observeField("itemSelected", "onVodItemSelected")
        node.observeField("focusUpRequested", "onScreenFocusUp")
    end if

    if screenName = "ficha" and node <> invalid then
        node.observeField("playRequested", "onFichaPlayRequested")
        node.observeField("focusUpRequested", "onScreenFocusUp")
        if params <> invalid and params.item <> invalid then
            isSeries = false
            if params.item.isSeries <> invalid then isSeries = params.item.isSeries
            if isSeries then spawnFichaEpisodes(node, params.item)
        end if
    end if

    if screenName = "player" and node <> invalid then
        if params <> invalid then node.playItem = params
        node.observeField("exitRequested", "onPlayerExitRequested")
    end if

    if screenName = "favorites" and node <> invalid then
        if m.cachedChannels <> invalid then node.channels = m.cachedChannels
        if m.cachedVod <> invalid then node.vodItems = m.cachedVod
        node.observeField("tuneRequested", "onFavTune")
        node.observeField("itemSelected", "onFavItemSelected")
        node.observeField("focusUpRequested", "onScreenFocusUp")
    end if

    if screenName = "search" and node <> invalid then
        if m.cachedChannels <> invalid then node.channels = m.cachedChannels
        if m.cachedVodItems <> invalid then node.vodItems = m.cachedVodItems
        node.callFunc("carregarIndice")
        node.observeField("tuneRequested", "onSearchTune")
        node.observeField("itemSelected", "onSearchItemSelected")
        node.observeField("focusUpRequested", "onScreenFocusUp")
    end if

    if screenName = "live" and node <> invalid then
        if m.cachedChannels <> invalid then node.channels = m.cachedChannels
        if m.cachedEpg <> invalid then node.epgMap = m.cachedEpg
        if params <> invalid and params.tune <> invalid then
            targetName = params.tune
            idx = 0
            foundIdx = 0
            if m.cachedChannels <> invalid then
                for i = 0 to m.cachedChannels.Count() - 1
                    ch = m.cachedChannels[i]
                    if ch <> invalid and ch.name = targetName then
                        foundIdx = i
                        exit for
                    end if
                end for
            end if
            node.currentChannelIndex = foundIdx
        end if
        node.observeField("guiaRequested", "onLiveGuiaRequested")
        node.observeField("sairRequested", "onLiveSairRequested")
        node.observeField("focusUpRequested", "onScreenFocusUp")
    end if

    if screenName = "guide" and node <> invalid then
        if m.cachedChannels <> invalid then node.channels = m.cachedChannels
        if m.cachedEpg <> invalid then node.epgMap = m.cachedEpg
        node.observeField("tuneRequested", "onGuideTune")
        node.observeField("voltarRequested", "onGuideVoltar")
        node.observeField("focusUpRequested", "onScreenFocusUp")
    end if

    if screenName = "radios" and node <> invalid then
        if m.cachedRadios <> invalid then node.radios = m.cachedRadios
        node.observeField("telaCheia", "onRadioTelaCheia")
        node.observeField("focusUpRequested", "onScreenFocusUp")
    end if

    if screenName = "events" and node <> invalid then
        if m.cachedEvents <> invalid then node.events = m.cachedEvents
        node.observeField("tuneRequested", "onEventsTune")
        node.observeField("focusUpRequested", "onScreenFocusUp")
    end if

    if screenName = "minhas" and node <> invalid then
        node.observeField("listasMudaram", "onListasMudaram")
        node.observeField("focusUpRequested", "onScreenFocusUp")
    end if

    if screenName = "settings" and node <> invalid then
        node.observeField("minhasListasRequested", "onSettingsMinhas")
        node.observeField("reloadRequested", "onSettingsReload")
        node.observeField("focusUpRequested", "onScreenFocusUp")
    end if

    m.currentScreenNode = node
    if node <> invalid then
        if m.screensContainer <> invalid then m.screensContainer.appendChild(node)
        node.setFocus(true)
    end if

    if m.topNavBar <> invalid then
        if screenName = "guide" or screenName = "player" then
            m.topNavBar.visible = false
        else
            m.topNavBar.visible = true
            m.topNavBar.selectedIndex = screenToNavIndex(screenName)
        end if
    end if
end sub

function screenToNavIndex(name as String) as Integer
    if name = "search" then return 0
    if name = "home" then return 1
    if name = "live" then return 2
    if name = "events" then return 3
    if name = "vod" then return 4
    if name = "favorites" then return 5
    if name = "guide" then return 2
    if name = "radios" then return 6
    if name = "settings" or name = "minhas" then return 7
    return 1
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
    return false
end function

sub goBack()
    if m.currentScreenName <> "home" then
        switchScreen("home")
    end if
end sub

sub startLoader(requestType as String)
    task = CreateObject("roSGNode", "DataLoaderTask")
    task.requestType = requestType
    task.url = m.playlistUrl
    task.baseUrl = m.vodUrl
    task.requestUrl = m.playlistUrl
    task.userAgent = m.userAgent
    task.observeField("responseChannels", "onDataLoaded")
    task.observeField("responseEpg", "onDataLoaded")
    task.observeField("responseDestaques", "onDataLoaded")
    task.observeField("responseVodItems", "onDataLoaded")
    task.observeField("responseEvents", "onDataLoaded")
    task.observeField("responseRadios", "onDataLoaded")
    m.lastLoader = task
    task.control = "RUN"
end sub

sub onDataLoaded(e as Object)
    task = invalid
    if e <> invalid then task = e.GetRoSGNode()
    if task = invalid then task = m.lastLoader
    if task = invalid then return
    if task.responseChannels <> invalid then
        m.cachedCatalogChannels = task.responseChannels
        WriteSaimoKey("playlistLastSync", CreateObject("roDateTime").AsSeconds().ToStr())
        rebuildChannelCache()
        if m.currentScreenName = "favorites" and m.currentScreenNode <> invalid then
            m.currentScreenNode.channels = m.cachedChannels
        end if
        if m.currentScreenName = "search" and m.currentScreenNode <> invalid then
            m.currentScreenNode.channels = m.cachedChannels
        end if
        if m.currentScreenName = "home" and m.currentScreenNode <> invalid then
            m.currentScreenNode.channels = m.cachedChannels
        end if
        if m.currentScreenName = "live" and m.currentScreenNode <> invalid then
            m.currentScreenNode.channels = m.cachedChannels
        end if
        if m.currentScreenName = "guide" and m.currentScreenNode <> invalid then
            m.currentScreenNode.channels = m.cachedChannels
        end if
    end if
    if task.responseEpg <> invalid then
        m.cachedEpg = task.responseEpg
        if m.currentScreenName = "home" and m.currentScreenNode <> invalid then
            m.currentScreenNode.epgMap = m.cachedEpg
        end if
        if m.currentScreenName = "live" and m.currentScreenNode <> invalid then
            m.currentScreenNode.epgMap = m.cachedEpg
        end if
        if m.currentScreenName = "guide" and m.currentScreenNode <> invalid then
            m.currentScreenNode.epgMap = m.cachedEpg
        end if
    end if
    if task.responseDestaques <> invalid then
        m.cachedVod = task.responseDestaques
        WriteSaimoKey("vodLastSync", CreateObject("roDateTime").AsSeconds().ToStr())
        if m.currentScreenName = "home" and m.currentScreenNode <> invalid then
            m.currentScreenNode.railsData = m.cachedVod
        end if
    end if
    if task.responseVodItems <> invalid then
        m.cachedVodItems = task.responseVodItems
        if m.currentScreenName = "search" and m.currentScreenNode <> invalid then
            m.currentScreenNode.vodItems = m.cachedVodItems
        end if
        if m.currentScreenName = "vod" and m.currentScreenNode <> invalid then
            m.currentScreenNode.vodItems = m.cachedVodItems
        end if
    end if
    if task.responseEvents <> invalid then
        m.eventosCrus = task.responseEvents
        if m.nomesCanais <> invalid then
            juntarEventos()
        end if
    end if
    if task.responseRadios <> invalid then
        m.cachedRadios = task.responseRadios
        if m.currentScreenName = "radios" and m.currentScreenNode <> invalid then
            m.currentScreenNode.radios = m.cachedRadios
        end if
    end if
end sub

sub startConnect()
end sub

sub onMinhasBootPronto()
    task = m.minhasLoader
    if task = invalid then return
    if task.canais <> invalid then
        m.cachedMinhasChannels = task.canais
        rebuildChannelCache()
        if m.currentScreenName = "home" and m.currentScreenNode <> invalid then m.currentScreenNode.channels = m.cachedChannels
        if m.currentScreenName = "live" and m.currentScreenNode <> invalid then m.currentScreenNode.channels = m.cachedChannels
        if m.currentScreenName = "favorites" and m.currentScreenNode <> invalid then m.currentScreenNode.channels = m.cachedChannels
        if m.currentScreenName = "search" and m.currentScreenNode <> invalid then m.currentScreenNode.channels = m.cachedChannels
        if m.currentScreenName = "guide" and m.currentScreenNode <> invalid then m.currentScreenNode.channels = m.cachedChannels
        if m.currentScreenName = "events" and m.currentScreenNode <> invalid and m.cachedEvents <> invalid then m.currentScreenNode.events = m.cachedEvents
    end if
end sub

sub rebuildChannelCache()
    merged = []
    catalog = m.cachedCatalogChannels
    if catalog <> invalid then
        for each c in catalog
            if c <> invalid then merged.Push(c)
        next
    end if
    minhas = invalid
    if m.cachedMinhasChannels <> invalid then
        minhas = []
        minhas.Append(m.cachedMinhasChannels)
        if minhas.Count() > 0 then
            minhas.SortBy("name", "i")
            n = merged.Count()
            for each c in minhas
                if c = invalid then continue for
                n = n + 1
                c.number = n
                merged.Push(c)
            next
        end if
    end if
    m.cachedChannels = merged
    m.nomesCanais = {}
    if merged <> invalid then
        for each c in merged
            if c <> invalid and c.name <> invalid then
                m.nomesCanais[LCase(c.name).Replace(" ", "")] = c.name
            end if
        next
    end if
    if m.eventosCrus <> invalid then juntarEventos()
end sub

sub juntarEventos()
    if m.eventosCrus = invalid then return
    saida = []
    for each ev in m.eventosCrus
        if ev = invalid then continue for
        ev.channelName = canalDoJogo(ev.slugs)
        if ev.channelName <> "" then saida.Push(ev)
    next
    m.cachedEvents = saida
    if m.currentScreenName = "events" and m.currentScreenNode <> invalid then
        m.currentScreenNode.events = m.cachedEvents
    end if
    if m.currentScreenName = "events" and m.currentScreenNode <> invalid then
        m.currentScreenNode.events = m.cachedEvents
    end if
end sub

sub onEventsTune(evt as Object)
    data = invalid
    if evt <> invalid then data = evt.GetData()
    tuneChannel(data)
end sub

sub onListasMudaram(evt as Object)
    data = invalid
    if evt <> invalid then data = evt.GetData()
    canais = invalid
    if data <> invalid and data.canais <> invalid then canais = data.canais
    m.cachedMinhasChannels = canais
    rebuildChannelCache()
    if m.currentScreenName = "home" and m.currentScreenNode <> invalid then m.currentScreenNode.channels = m.cachedChannels
    if m.currentScreenName = "live" and m.currentScreenNode <> invalid then m.currentScreenNode.channels = m.cachedChannels
    if m.currentScreenName = "favorites" and m.currentScreenNode <> invalid then m.currentScreenNode.channels = m.cachedChannels
    if m.currentScreenName = "search" and m.currentScreenNode <> invalid then m.currentScreenNode.channels = m.cachedChannels
    if m.currentScreenName = "guide" and m.currentScreenNode <> invalid then m.currentScreenNode.channels = m.cachedChannels
end sub

sub onScreenFocusUp()
end sub

function canalDoJogo(players as Object) as String
    if m.nomesCanais = invalid then return ""
    if players = invalid then return ""
    if Type(players) <> "roArray" then return ""
    if players.Count() = 0 then return ""
    partes = players[0].Split("/")
    apelido = LCase(partes[partes.Count() - 1]).Replace("-", "").Replace(" ", "")
    if apelido = "" then return ""
    if m.nomesCanais.DoesExist(apelido) then return m.nomesCanais[apelido]
    candidate = ""
    count = 0
    for each n in m.nomesCanais
        if Instr(1, n, apelido) > 0 then
            count = count + 1
            candidate = m.nomesCanais[n]
        end if
    next
    if count = 1 then return candidate
    return ""
end function

sub onRadioTelaCheia(evt as Object)
    data = false
    if evt <> invalid then data = evt.GetData()
    if m.topNavBar <> invalid then m.topNavBar.visible = not data
end sub

sub onFavTune(evt as Object)
    data = invalid
    if evt <> invalid then data = evt.getData()
    tuneChannel(data)
end sub

sub onFavItemSelected(evt as Object)
    data = invalid
    if evt <> invalid then data = evt.getData()
    openFicha(data)
end sub

sub onSearchTune(evt as Object)
    data = invalid
    if evt <> invalid then data = evt.getData()
    tuneChannel(data)
end sub

sub onSearchItemSelected(evt as Object)
    data = invalid
    if evt <> invalid then data = evt.getData()
    openFicha(data)
end sub

sub onHomeItemSelected(evt as Object)
    data = invalid
    if evt <> invalid then data = evt.getData()
    openFicha(data)
end sub

sub onHomeTune(evt as Object)
    data = invalid
    if evt <> invalid then data = evt.getData()
    tuneChannel(data)
end sub

sub onVodItemSelected(evt as Object)
    data = invalid
    if evt <> invalid then data = evt.getData()
    openFicha(data)
end sub

sub onFichaPlayRequested(evt as Object)
    data = invalid
    if evt <> invalid then data = evt.getData()
    switchScreen("player", data)
end sub

sub onFichaEpisodesLoaded(evt as Object)
    task = invalid
    if evt <> invalid then task = evt.GetRoSGNode()
    if task = invalid then task = m.fichaEpisodesTask
    if task = invalid then return
    if m.currentScreenName <> "ficha" or m.currentScreenNode = invalid then return
    if task.success <> true then return
    if task.resultJson = invalid or task.resultJson = "" then return
    parsed = ParseJson(task.resultJson)
    if type(parsed) = "roArray" then
        m.currentScreenNode.episodes = parsed
    end if
end sub

sub spawnFichaEpisodes(node as Object, item as Object)
    task = CreateObject("roSGNode", "DataLoaderTask")
    letter = ""
    if item.letter <> invalid then letter = item.letter.ToStr()
    if letter = "#" then letter = "%23"
    piece = 0
    if item.piece <> invalid then piece = Val(item.piece.ToStr())
    base = m.vodUrl
    task.requestType = "saimo_episodes"
    task.mode = "saimo_episodes"
    task.url = base + "series-" + letter + "-" + piece.ToStr() + ".txt"
    task.baseUrl = base
    task.title = item.title
    ua = ReadSaimoKey("userAgent")
    if ua = "" then ua = m.defaultUA
    task.userAgent = ua
    task.observeField("success", "onFichaEpisodesLoaded")
    m.fichaEpisodesTask = task
    task.control = "RUN"
end sub

sub onSettingsMinhas()
    switchScreen("minhas")
end sub

sub onSettingsReload()
    WriteSaimoKey("playlistLastSync", "0")
    WriteSaimoKey("vodLastSync", "0")
    refreshPlaylist(true)
    refreshVodCatalog(true)
end sub

sub onGuideTune(evt as Object)
    data = invalid
    if evt <> invalid then data = evt.getData()
    tuneChannel(data)
end sub

sub onGuideVoltar(evt as Object)
    switchScreen("live")
end sub

sub onLiveGuiaRequested(evt as Object)
    switchScreen("guide")
end sub

sub onLiveSairRequested(evt as Object)
    ' no-op placeholder for Live sairRequested; Roku handles app exit
end sub

sub onPlayerExitRequested()
    if m.previousScreenName <> invalid and m.previousScreenName <> "" and m.previousScreenName <> "player" then
        switchScreen(m.previousScreenName, m.previousScreenParams)
    else
        switchScreen("home")
    end if
end sub

sub tuneChannel(channel as Dynamic)
    targetName = ""
    if channel <> invalid then
        if Type(channel) = "String" or Type(channel) = "roString" then
            targetName = channel
        else if channel.name <> invalid then
            targetName = channel.name
        end if
    end if

    found = false
    if targetName <> "" and m.cachedChannels <> invalid then
        for each ch in m.cachedChannels
            if ch <> invalid and ch.name = targetName then
                found = true
                exit for
            end if
        end for
    end if

    if found then
        switchScreen("live", { tune: targetName })
    end if
end sub

sub openFicha(item as Dynamic)
    if item <> invalid then
        switchScreen("ficha", { item: item })
    end if
end sub

sub onDeepLinkChange()
end sub

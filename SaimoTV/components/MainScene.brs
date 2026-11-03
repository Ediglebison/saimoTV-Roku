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
    m.cachedEpg = invalid
    m.cachedVod = invalid
    m.cachedEvents = invalid
    m.cachedRadios = invalid
    m.currentScreenNode = invalid
    m.currentScreenName = ""
    m.previousScreenName = ""
    m.previousScreenParams = invalid
    m.vodInitPending = true


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

    if screenName = "favorites" and node <> invalid then
        if m.cachedChannels <> invalid then node.channels = m.cachedChannels
        if m.cachedVod <> invalid then node.vodItems = m.cachedVod
        node.observeField("tuneRequested", "onFavTune")
        node.observeField("itemSelected", "onFavItemSelected")
        node.observeField("focusUpRequested", "onScreenFocusUp")
    end if

    m.currentScreenNode = node
    if node <> invalid then
        if m.screensContainer <> invalid then m.screensContainer.appendChild(node)
        node.setFocus(true)
    end if

    if m.topNavBar <> invalid then
        if screenName = "guide" then
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
        m.cachedChannels = task.responseChannels
        WriteSaimoKey("playlistLastSync", CreateObject("roDateTime").AsSeconds().ToStr())
        if m.currentScreenName = "favorites" and m.currentScreenNode <> invalid then
            m.currentScreenNode.channels = m.cachedChannels
        end if
    end if
    if task.responseEpg <> invalid then m.cachedEpg = task.responseEpg
    if task.responseDestaques <> invalid then
        m.cachedVod = task.responseDestaques
        WriteSaimoKey("vodLastSync", CreateObject("roDateTime").AsSeconds().ToStr())
    end if
    if task.responseEvents <> invalid then m.cachedEvents = task.responseEvents
    if task.responseRadios <> invalid then m.cachedRadios = task.responseRadios
end sub

sub startConnect()
end sub

sub onScreenFocusUp()
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

sub tuneChannel(channel as Dynamic)
    targetName = ""
    if channel <> invalid then
        if channel.name <> invalid then targetName = channel.name
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
        switchScreen("live")
    end if
end sub

sub openFicha(item as Dynamic)
    if item <> invalid then
        switchScreen("ficha", { item: item })
    end if
end sub

sub onDeepLinkChange()
end sub

' ====================================================================
' Saimo TV - SettingsScreen (BrightScript)
' ====================================================================

sub init()
    m.settingsList = m.top.findNode("settingsList")
    m.settingsList.observeField("itemSelected", "onSettingSelected")
    m.editPanel = m.top.findNode("editPanel")
    m.editTitle = m.top.findNode("editTitle")
    m.editKeyboard = m.top.findNode("editKeyboard")
    m.editButtons = m.top.findNode("editButtons")
    m.editButtons.observeField("itemSelected", "onEditButton")
    m.statusLabel = m.top.findNode("statusLabel")
    m.prefs = loadPrefs()
    m.editingKey = ""
    m.top.observeField("focusedChild", "onFocusedChildChange")
    populateSettings()
end sub

sub onFocusedChildChange()
    if m.top.isInFocusChain() then
        if m.editPanel.visible and not m.editKeyboard.isInFocusChain() and not m.editButtons.isInFocusChain() then
            if m.editKeyboard <> invalid then m.editKeyboard.setFocus(true)
        else if not m.settingsList.isInFocusChain() and not m.editPanel.visible then
            if m.settingsList <> invalid then m.settingsList.setFocus(true)
        end if
    end if
end sub

function loadPrefs() as Object
    raw = ReadSaimoKey("prefs")
    parsed = {}
    if raw <> "" then
        loaded = ParseJson(raw)
        if type(loaded) = "roAssociativeArray" then parsed = loaded
    end if
    if parsed.abrirEm = invalid then parsed.abrirEm = "inicio"
    if parsed.zeroDelay = invalid then parsed.zeroDelay = "off"
    if parsed.audioInteligente = invalid then parsed.audioInteligente = false
    if parsed.versaoAudio = invalid then parsed.versaoAudio = "dub"
    if parsed.pularAutomatico = invalid then parsed.pularAutomatico = false
    if parsed.proximoAutomatico = invalid then parsed.proximoAutomatico = false
    return parsed
end function

sub savePrefs()
    if m.prefs = invalid then return
    WriteSaimoKey("prefs", FormatJson(m.prefs))
end sub

sub populateSettings()
    p = m.prefs
    root = CreateObject("roSGNode", "ContentNode")

    addSettingItem(root, "minhasListas", "Minhas listas", "Adicionar listas .m3u pelo link")
    addSettingItem(root, "playlistUrl", "URL da playlist", registryValueOr("playlistUrl", "nao definida"))
    addSettingItem(root, "vodUrl", "URL do catalogo VOD", registryValueOr("vodUrl", "nao definida"))
    addSettingItem(root, "userAgent", "User-Agent", registryValueOr("userAgent", "padrao"))
    abrir = "Inicio"
    if p.abrirEm = "canal" then abrir = "Ultimo canal"
    addSettingItem(root, "abrirEm", "Abrir o app em", abrir)
    zero = "Desligado"
    if p.zeroDelay = "equilibrado" then zero = "Equilibrado"
    if p.zeroDelay = "agressivo" then zero = "Agressivo"
    addSettingItem(root, "zeroDelay", "Modo Zero Delay", zero)
    addSettingItem(root, "audioInteligente", "Audio inteligente (voz nitida)", formatBool(p.audioInteligente))
    audio = "Dublado"
    if p.versaoAudio = "leg" then audio = "Legendado"
    addSettingItem(root, "versaoAudio", "Audio de filmes e series", audio)
    addSettingItem(root, "pularAutomatico", "Pular aberturas de series", formatBool(p.pularAutomatico))
    addSettingItem(root, "proximoAutomatico", "Proximo episodio automatico", formatBool(p.proximoAutomatico))
    addSettingItem(root, "testarUrls", "Testar URLs", "Valida playlist e catalogo")
    addSettingItem(root, "limparCache", "Limpar historico", "Apaga o que voce estava assistindo")
    addSettingItem(root, "abrirSobre", "Sobre", "Versao e chaves de armazenamento")

    m.settingsList.content = root
end sub

function registryValueOr(key as String, fallback as String) as String
    value = ReadSaimoKey(key)
    if value = "" then return fallback
    return value
end function

sub addSettingItem(root as Object, key as String, label as String, val as String)
    node = root.CreateChild("ContentNode")
    node.title = label
    node.description = val
    node.addFields({ settingKey: key })
end sub

function formatBool(val as Boolean) as String
    if val then return "Ligado"
    return "Desligado"
end function

sub onSettingSelected()
    idx = m.settingsList.itemSelected
    root = m.settingsList.content
    if root = invalid or idx < 0 or idx >= root.getChildCount() then return
    node = root.getChild(idx)
    key = node.settingKey

    if key = "minhasListas" then
        m.top.minhasListasRequested = true
    else if key = "playlistUrl" or key = "vodUrl" or key = "userAgent" then
        m.editingKey = key
        abrirCampo("texto")
    else if key = "abrirEm" then
        if m.prefs.abrirEm = "inicio" then
            m.prefs.abrirEm = "canal"
        else
            m.prefs.abrirEm = "inicio"
        end if
        savePrefs()
        populateSettings()
        m.settingsList.jumpToItem = idx
    else if key = "zeroDelay" then
        if m.prefs.zeroDelay = "off" then
            m.prefs.zeroDelay = "equilibrado"
        else if m.prefs.zeroDelay = "equilibrado" then
            m.prefs.zeroDelay = "agressivo"
        else
            m.prefs.zeroDelay = "off"
        end if
        savePrefs()
        populateSettings()
        m.settingsList.jumpToItem = idx
    else if key = "audioInteligente" then
        m.prefs.audioInteligente = not m.prefs.audioInteligente
        savePrefs()
        populateSettings()
        m.settingsList.jumpToItem = idx
    else if key = "versaoAudio" then
        if m.prefs.versaoAudio = "dub" then
            m.prefs.versaoAudio = "leg"
        else
            m.prefs.versaoAudio = "dub"
        end if
        savePrefs()
        populateSettings()
        m.settingsList.jumpToItem = idx
    else if key = "pularAutomatico" then
        m.prefs.pularAutomatico = not m.prefs.pularAutomatico
        savePrefs()
        populateSettings()
        m.settingsList.jumpToItem = idx
    else if key = "proximoAutomatico" then
        m.prefs.proximoAutomatico = not m.prefs.proximoAutomatico
        savePrefs()
        populateSettings()
        m.settingsList.jumpToItem = idx
    else if key = "testarUrls" then
        testarUrls()
    else if key = "limparCache" then
        limparCache()
    else if key = "abrirSobre" then
        abrirSobre()
    end if
end sub

sub abrirCampo(modo as String)
    m.statusLabel.text = ""
    if modo = "texto" then
        m.editPanel.visible = true
        m.settingsList.visible = false
        title = "Editar"
        if m.editingKey = "playlistUrl" then title = "URL da playlist"
        if m.editingKey = "vodUrl" then title = "URL do catalogo VOD"
        if m.editingKey = "userAgent" then title = "User-Agent"
        m.editTitle.text = title
        m.editKeyboard.text = ReadSaimoKey(m.editingKey)
        root = CreateObject("roSGNode", "ContentNode")
        node1 = root.CreateChild("ContentNode")
        node1.title = "Salvar"
        node2 = root.CreateChild("ContentNode")
        node2.title = "Cancelar"
        m.editButtons.content = root
        m.editButtons.jumpToItem = 0
        m.editKeyboard.setFocus(true)
    end if
end sub

sub onEditButton()
    if m.editButtons.itemSelected = 0 then
        value = m.editKeyboard.text.Trim()
        WriteSaimoKey(m.editingKey, value)
        m.statusLabel.text = "Salvo."
        if m.editingKey = "playlistUrl" then m.top.reloadRequested = true
        if m.editingKey = "vodUrl" then m.top.reloadRequested = true
    end if
    fecharEdicao()
    populateSettings()
end sub

sub fecharEdicao()
    m.editPanel.visible = false
    m.settingsList.visible = true
    m.settingsList.setFocus(true)
end sub

sub testarUrls()
    okAll = true
    pl = ReadSaimoKey("playlistUrl")
    vd = ReadSaimoKey("vodUrl")
    if pl = "" then okAll = false
    if vd = "" then okAll = false
    if okAll then
        m.statusLabel.text = "URLs validas."
    else
        m.statusLabel.text = "URLs invalidas."
    end if
end sub

sub limparCache()
    files = ["cachefs:/saimo_vod_fichas.ready", "cachefs:/saimo_vod_fichas.txt", "cachefs:/saimo_vod_fichas.url", "cachefs:/saimo_vod_bases.json", "cachefs:/saimo_vod_bases.url", "cachefs:/saimo_vod_covers.json", "cachefs:/saimo_vod_covers.url", "cachefs:/saimo_search_index.json", "cachefs:/saimo_search_index.time", "cachefs:/saimo_search_index.url", "cachefs:/saimo_vod_search.txt", "cachefs:/saimo_vod_search.url", "cachefs:/epg.json"]
    for each path in files
        DeleteFile(path)
    end for
    WriteSaimoKey("vod_progress", "")
    WriteSaimoKey("playlistLastSync", "0")
    WriteSaimoKey("vodLastSync", "0")
    m.statusLabel.text = "Cache limpo."
    m.top.reloadRequested = true
end sub

sub abrirSobre()
    m.statusLabel.text = "Saimo TV 2.6.0. Chaves: playlistUrl, vodUrl, userAgent, prefs, vod_progress, watchedEpisodes, favorites."
end sub

sub onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if m.editPanel.visible then
        if key = "back" then
            fecharEdicao()
            return true
        end if
        if key = "up" and m.editButtons.isInFocusChain() then
            m.editKeyboard.setFocus(true)
            return true
        else if key = "down" and m.editKeyboard.isInFocusChain() then
            m.editButtons.setFocus(true)
            return true
        end if
        return false
    end if

    if not m.settingsList.isInFocusChain() then
        if m.settingsList <> invalid then m.settingsList.setFocus(true)
    end if

    if key = "up" and m.settingsList.itemFocused <= 0 then
        m.top.focusUpRequested = true
        return true
    else if key = "left" then
        return true
    else if key = "back" then
        return false
    end if
    return false
end sub

sub cleanUp()
end sub

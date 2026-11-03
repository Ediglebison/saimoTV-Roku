' ====================================================================
' Saimo TV - FichaScreen (BrightScript)
' ====================================================================

sub init()
    m.backdropPoster = m.top.findNode("backdropPoster")
    m.posterNode = m.top.findNode("posterNode")
    m.titleLabel = m.top.findNode("titleLabel")
    m.metaLabel = m.top.findNode("metaLabel")
    m.genresLabel = m.top.findNode("genresLabel")
    m.overviewLabel = m.top.findNode("overviewLabel")

    m.playBtnBg = m.top.findNode("playBtnBg")
    m.playBtnText = m.top.findNode("playBtnText")
    m.playBtnBorder = m.top.findNode("playBtnBorder")

    m.resumeBtnGroup = m.top.findNode("resumeBtnGroup")
    m.resumeBtnBg = m.top.findNode("resumeBtnBg")
    m.resumeBtnText = m.top.findNode("resumeBtnText")
    m.resumeBtnBorder = m.top.findNode("resumeBtnBorder")

    m.versionBtnGroup = m.top.findNode("versionBtnGroup")
    m.versionBtnBg = m.top.findNode("versionBtnBg")
    m.versionBtnText = m.top.findNode("versionBtnText")
    m.versionBtnBorder = m.top.findNode("versionBtnBorder")

    m.favBtnGroup = m.top.findNode("favBtnGroup")
    m.favBtnBg = m.top.findNode("favBtnBg")
    m.favBtnText = m.top.findNode("favBtnText")
    m.favBtnBorder = m.top.findNode("favBtnBorder")

    m.seriesPanel = m.top.findNode("seriesPanel")
    m.seasonsBar = m.top.findNode("seasonsBar")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.episodesRowList = m.top.findNode("episodesRowList")
    m.episodesRowList.observeField("rowItemSelected", "onEpisodeSelected")

    m.seasonNodes = []
    m.seasonValues = []
    m.seasonIndex = 0
    m.currentSeason = 1
    m.currentVersion = "dub"

    m.focusedArea = "buttons"
    m.focusedButton = 0

    m.top.observeField("focusedChild", "onFocusedChildChange")
end sub

sub onFocusedChildChange()
    if m.top.isInFocusChain() then
        updateFocusVisuals()
    end if
end sub

sub onItemChange()
    item = m.top.item
    if item = invalid then return

    title = ""
    if item.title <> invalid then title = item.title.ToStr()
    m.titleLabel.text = title

    if item.backdrop <> invalid and item.backdrop <> "" then
        m.backdropPoster.uri = item.backdrop
    else if item.poster <> invalid and item.poster <> "" then
        m.backdropPoster.uri = item.poster
    end if

    if item.poster <> invalid and item.poster <> "" then
        m.posterNode.uri = item.poster
    end if

    tipo = "Filme"
    if item.isSeries <> invalid and item.isSeries then tipo = "Serie"
    year = ""
    if item.year <> invalid then year = item.year.ToStr()
    rating = ""
    if item.rating <> invalid then rating = item.rating.ToStr()
    meta = tipo
    if year <> "" then meta = meta + "  |  " + year
    if rating <> "" then meta = meta + "  |  " + rating
    m.metaLabel.text = meta

    if item.genres <> invalid and item.genres <> "" then
        m.genresLabel.text = item.genres.ToStr()
    else
        m.genresLabel.text = ""
    end if

    if item.overview <> invalid and item.overview <> "" then
        m.overviewLabel.text = item.overview.ToStr()
    else
        m.overviewLabel.text = ""
    end if

    prog = GetVODProgress(title)
    showResume = false
    if prog <> invalid then
        posSec = 0
        if prog.posSec <> invalid then posSec = prog.posSec
        percent = 0
        if prog.percent <> invalid then percent = prog.percent
        if posSec > 60 and percent < 92 then showResume = true
    end if
    m.resumeBtnGroup.visible = showResume
    if showResume then
        minRemaining = 0
        if prog <> invalid and prog.posSec <> invalid then minRemaining = Int(prog.posSec / 60)
        m.resumeBtnText.text = "Continuar (" + minRemaining.ToStr() + "m)"
        m.versionBtnGroup.translation = [632, 0]
        m.favBtnGroup.translation = [948, 0]
    else
        m.versionBtnGroup.translation = [316, 0]
        m.favBtnGroup.translation = [632, 0]
    end if

    updateFavButtonText()

    prefsRaw = ReadSaimoKey("prefs")
    prefs = {}
    if prefsRaw <> "" then
        loaded = ParseJson(prefsRaw)
        if type(loaded) = "roAssociativeArray" then prefs = loaded
    end if
    if prefs.versaoAudio <> invalid then m.currentVersion = prefs.versaoAudio.ToStr()
    updateVersionButtonText()

    if item.isSeries <> invalid and item.isSeries then
        m.seriesPanel.visible = true
        if m.loadingLabel <> invalid then m.loadingLabel.visible = true
        m.seasonValues = []
        m.seasonNodes = []
        m.seasonIndex = 0
        m.currentSeason = 1
        bar = m.seasonsBar
        if bar <> invalid then
            while bar.GetChildCount() > 0
                bar.removeChild(bar.GetChild(0))
            end while
        end if
    else
        m.seriesPanel.visible = false
    end if

    m.focusedArea = "buttons"
    m.focusedButton = 0
    updateFocusVisuals()
end sub

sub carregarEpisodios()
    if m.top.episodes = invalid then return

    episodes = m.top.episodes
    if m.loadingLabel <> invalid then m.loadingLabel.visible = false

    if type(episodes) <> "roArray" or episodes.Count() = 0 then
        if m.loadingLabel <> invalid then
            m.loadingLabel.visible = true
            m.loadingLabel.text = "Nenhum episodio encontrado."
        end if
        return
    end if

    montarTemporadas(episodes)

    if m.seasonValues.Count() > 0 then
        m.seasonIndex = 0
        m.currentSeason = m.seasonValues[0]
    end if

    selecionarTemporada(m.currentSeason)
    updateSeasonTabsVisuals()
    updateFocusVisuals()
end sub

sub montarTemporadas(episodes as Object)
    values = []
    for each ep in episodes
        if ep = invalid or ep.season = invalid then continue for
        season = asInteger(ep.season)
        found = false
        for each v in values
            if v = season then found = true
        next
        if not found then values.Push(season)
    next

    sortAscending(values)
    m.seasonValues = values

    bar = m.seasonsBar
    if bar <> invalid then
        while bar.GetChildCount() > 0
            bar.removeChild(bar.GetChild(0))
        end while
    end if
    m.seasonNodes = []

    for i = 0 to values.Count() - 1
        season = values[i]
        group = CreateObject("roSGNode", "Group")
        group.translation = [i * 240, 0]

        border = CreateObject("roSGNode", "Rectangle")
        border.width = 0
        border.height = 0
        border.visible = false

        bg = CreateObject("roSGNode", "Poster")
        bg.width = 224
        bg.height = 60
        bg.uri = "pkg:/images/p_branca.9.png"
        bg.blendColor = &hFFFFFF24

        labelText = CreateObject("roSGNode", "Label")
        labelText.width = 224
        labelText.height = 60
        labelText.horizAlign = "center"
        labelText.vertAlign = "center"
        labelText.text = "Temporada " + season.ToStr()
        labelText.color = &hFFFFFFFF
        font = CreateObject("roSGNode", "Font")
        font.uri = "pkg:/fonts/Roboto-Medium.ttf"
        font.size = 28
        labelText.font = font

        group.appendChild(border)
        group.appendChild(bg)
        group.appendChild(labelText)

        if bar <> invalid then bar.appendChild(group)

        nodeInfo = { border: border, bg: bg, label: labelText }
        m.seasonNodes.Push(nodeInfo)
    next
end sub

sub sortAscending(values as Object)
    count = values.Count()
    for i = 0 to count - 2
        for j = 0 to count - i - 2
            if values[j] > values[j + 1] then
                temp = values[j]
                values[j] = values[j + 1]
                values[j + 1] = temp
            end if
        next
    next
end sub

function asInteger(value as Dynamic) as Integer
    if value = invalid then return 0
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then
        return value
    end if
    if valueType = "String" or valueType = "roString" then
        return value.ToInt()
    end if
    return Int(value)
end function

sub selecionarTemporada(n as Integer)
    episodes = m.top.episodes
    if episodes = invalid then return

    root = CreateObject("roSGNode", "ContentNode")
    row = root.CreateChild("ContentNode")

    for each ep in episodes
        if ep = invalid or ep.season = invalid then continue for
        if asInteger(ep.season) <> n then continue for

        node = row.CreateChild("ContentNode")
        nodeTitle = "Episodio " + asInteger(ep.episode).ToStr()
        if ep.title <> invalid and ep.title <> "" then nodeTitle = ep.title.ToStr()
        node.title = nodeTitle

        cover = ""
        if ep.cover <> invalid and ep.cover <> "" then cover = ep.cover.ToStr()
        if cover = "" and m.top.item <> invalid and m.top.item.poster <> invalid then
            cover = m.top.item.poster.ToStr()
        end if
        if cover <> "" then node.hdPosterUrl = cover

        epNum = 0
        if ep.episode <> invalid then epNum = asInteger(ep.episode)
        epTitle = nodeTitle
        watched = false
        watchedItem = { title: m.top.item.title, season: asInteger(ep.season), episode: epNum, seriesTitle: m.top.item.title }
        watched = IsEpisodeWatched(watchedItem)
        node.addFields({ seasonNum: asInteger(ep.season), episodeNum: epNum, episodeTitle: epTitle, seriesTitle: m.top.item.title, watched: watched })
    next

    m.episodesRowList.content = root
    if m.loadingLabel <> invalid then m.loadingLabel.visible = false
end sub

sub onEpisodeSelected()
    coords = m.episodesRowList.rowItemSelected
    if coords = invalid then return
    col = coords[1]
    root = m.episodesRowList.content
    if root = invalid or root.getChildCount() = 0 then return
    row = root.getChild(0)
    if row = invalid or col >= row.getChildCount() then return
    epNode = row.getChild(col)
    if epNode = invalid then return

    tocar(0, epNode.seasonNum, epNode.episodeNum, epNode.title)
end sub

sub tocar(resumePos as Integer, season as Integer, episode as Integer, epTitle as String)
    item = m.top.item
    if item = invalid then return

    itemId = ""
    if item.id <> invalid then itemId = item.id.ToStr()
    letter = ""
    if item.letter <> invalid then letter = item.letter.ToStr()
    year = ""
    if item.year <> invalid then year = item.year.ToStr()
    title = ""
    if item.title <> invalid then title = item.title.ToStr()

    if season <= 0 then season = 1
    if episode <= 0 then episode = 1
    if resumePos < 0 then resumePos = 0

    if epTitle = "" then epTitle = "Episodio " + season.ToStr() + "x" + episode.ToStr()

    markItem = { title: title, letter: letter, year: year, isSeries: true, season: season, episode: episode }
    MarkWatched(markItem)

    m.top.playRequested = {
        title: title,
        letter: letter,
        year: year,
        resumePos: resumePos,
        isSeries: true,
        season: season,
        episode: episode,
        id: itemId,
        epTitle: epTitle
    }
end sub

sub handleButtonClick()
    item = m.top.item
    if item = invalid then return
    itemId = ""
    if item.id <> invalid then itemId = item.id.ToStr()

    if m.focusedButton = 0 then
        tocar(0, 1, 1, "")
    else if m.focusedButton = 1 then
        prog = GetVODProgress(item.title)
        resPos = 0
        resSeason = 1
        resEp = 1
        if prog <> invalid then
            if prog.posSec <> invalid then resPos = prog.posSec
            if prog.season <> invalid and prog.season > 0 then resSeason = prog.season
            if prog.episode <> invalid and prog.episode > 0 then resEp = prog.episode
        end if
        tocar(resPos, resSeason, resEp, "")
    else if m.focusedButton = 2 then
        if m.currentVersion = "dub" then
            m.currentVersion = "leg"
        else
            m.currentVersion = "dub"
        end if
        updateVersionButtonText()
        prefsRaw = ReadSaimoKey("prefs")
        prefs = {}
        if prefsRaw <> "" then
            loaded = ParseJson(prefsRaw)
            if type(loaded) = "roAssociativeArray" then prefs = loaded
        end if
        prefs.versaoAudio = m.currentVersion
        WriteSaimoKey("prefs", FormatJson(prefs))
    else if m.focusedButton = 3 then
        ToggleFavoriteVOD(item)
        updateFavButtonText()
    end if
end sub

sub updateFavButtonText()
    m.favBtnText.text = "Favoritar"
    if isFavoriteTitle() then m.favBtnText.text = "Nos favoritos"
end sub

function isFavoriteTitle() as Boolean
    item = m.top.item
    if item = invalid then return false
    title = ""
    if item.title <> invalid then title = item.title.ToStr()
    year = ""
    if item.year <> invalid then year = item.year.ToStr()
    itemType = "vod"
    if item.isSeries <> invalid and item.isSeries then itemType = "series"

    favs = LoadFavoriteVOD()
    if favs = invalid then return false
    for each fav in favs
        favTitle = ""
        if fav.title <> invalid then favTitle = fav.title.ToStr()
        favYear = ""
        if fav.year <> invalid then favYear = fav.year.ToStr()
        favType = "vod"
        if fav.type <> invalid then favType = fav.type.ToStr()
        if LCase(favTitle) = LCase(title) and favYear = year and favType = itemType then
            return true
        end if
    next
    return false
end function

sub updateVersionButtonText()
    if m.currentVersion = "leg" then
        m.versionBtnText.text = "Versao: Legendado"
    else
        m.versionBtnText.text = "Versao: Dublado"
    end if
end sub

sub updateSeasonTabsVisuals()
    for i = 0 to m.seasonNodes.Count() - 1
        info = m.seasonNodes[i]
        bg = info.bg
        label = info.label
        border = info.border
        if bg = invalid or label = invalid then continue for
        if m.seasonValues[i] = m.currentSeason then
            bg.blendColor = &hFFFFFFFF
            label.color = &h0B0E14FF
            if border <> invalid then border.visible = (m.focusedArea = "seasons")
        else
            bg.blendColor = &hFFFFFF24
            label.color = &hFFFFFFFF
            if border <> invalid then border.visible = false
        end if
    next
end sub

sub updateFocusVisuals()
    isBtns = (m.focusedArea = "buttons")

    m.playBtnBorder.visible = (isBtns and m.focusedButton = 0)
    m.resumeBtnBorder.visible = (isBtns and m.focusedButton = 1)
    m.versionBtnBorder.visible = (isBtns and m.focusedButton = 2)
    m.favBtnBorder.visible = (isBtns and m.focusedButton = 3)

    if isBtns and m.focusedButton = 0 then
        m.playBtnBg.blendColor = &hFFFFFFFF
        m.playBtnText.color = &h0B0E14FF
    else
        m.playBtnBg.blendColor = &hFFFFFF24
        m.playBtnText.color = &hFFFFFFFF
    end if

    if isBtns and m.focusedButton = 1 then
        m.resumeBtnBg.blendColor = &hFFFFFFFF
        m.resumeBtnText.color = &h0B0E14FF
    else
        m.resumeBtnBg.blendColor = &hFFFFFF24
        m.resumeBtnText.color = &hFFFFFFFF
    end if

    if isBtns and m.focusedButton = 2 then
        m.versionBtnBg.blendColor = &hFFFFFFFF
        m.versionBtnText.color = &h0B0E14FF
    else
        m.versionBtnBg.blendColor = &hFFFFFF24
        m.versionBtnText.color = &hFFFFFFFF
    end if

    if isBtns and m.focusedButton = 3 then
        m.favBtnBg.blendColor = &hFFFFFFFF
        m.favBtnText.color = &h0B0E14FF
    else
        m.favBtnBg.blendColor = &hFFFFFF24
        m.favBtnText.color = &hFFFFFFFF
    end if

    updateSeasonTabsVisuals()

    if m.focusedArea = "episodes" then
        m.episodesRowList.setFocus(true)
    else
        m.top.setFocus(true)
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if m.focusedArea = "buttons" then
        if key = "right" then
            if m.focusedButton < 3 then
                m.focusedButton = m.focusedButton + 1
                if m.focusedButton = 1 and not m.resumeBtnGroup.visible then
                    m.focusedButton = 2
                end if
                updateFocusVisuals()
                return true
            end if
        else if key = "left" then
            if m.focusedButton > 0 then
                m.focusedButton = m.focusedButton - 1
                if m.focusedButton = 1 and not m.resumeBtnGroup.visible then
                    m.focusedButton = 0
                end if
                updateFocusVisuals()
                return true
            end if
        else if key = "down" then
            if m.seriesPanel.visible then
                m.focusedArea = "seasons"
                updateFocusVisuals()
                return true
            end if
        else if key = "up" then
            m.top.focusUpRequested = true
            return true
        else if key = "OK" or key = "select" then
            handleButtonClick()
            return true
        end if
    else if m.focusedArea = "seasons" then
        if key = "right" then
            if m.seasonIndex < m.seasonValues.Count() - 1 then
                m.seasonIndex = m.seasonIndex + 1
                m.currentSeason = m.seasonValues[m.seasonIndex]
                selecionarTemporada(m.currentSeason)
                updateSeasonTabsVisuals()
                return true
            end if
        else if key = "left" then
            if m.seasonIndex > 0 then
                m.seasonIndex = m.seasonIndex - 1
                m.currentSeason = m.seasonValues[m.seasonIndex]
                selecionarTemporada(m.currentSeason)
                updateSeasonTabsVisuals()
                return true
            end if
        else if key = "down" then
            m.focusedArea = "episodes"
            updateFocusVisuals()
            return true
        else if key = "up" then
            m.focusedArea = "buttons"
            updateFocusVisuals()
            return true
        end if
    else if m.focusedArea = "episodes" then
        if key = "up" then
            if m.seriesPanel.visible then
                m.focusedArea = "seasons"
            else
                m.focusedArea = "buttons"
            end if
            updateFocusVisuals()
            return true
        else if key = "back" then
            m.focusedArea = "buttons"
            updateFocusVisuals()
            return true
        end if
    end if

    return false
end function

sub cleanUp()
    m.seasonNodes = []
    m.seasonValues = []
end sub

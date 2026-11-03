sub init()
    m.thumb = m.top.findNode("thumb")
    m.title = m.top.findNode("title")
    m.epBadge = m.top.findNode("epBadge")
    m.focusBorder = m.top.findNode("focusBorder")
end sub

sub onItemContentChange()
    itemContent = m.top.itemContent
    item = itemContent
    if itemContent <> invalid and itemContent.hdPosterUrl <> invalid then
    end if
    if item <> invalid then
        if item.hdPosterUrl <> invalid and item.hdPosterUrl <> "" then
            m.thumb.uri = item.hdPosterUrl
        end if
        if item.title <> invalid then
            m.title.text = item.title
        end if
        if itemContent <> invalid and itemContent.episodeNum <> invalid then
        end if
        if item.episodeNum <> invalid then
            m.epBadge.text = "EPISÓDIO " + item.episodeNum.ToStr()
        else
            m.epBadge.text = "EPISÓDIO"
        end if
        if item.seriesTitle <> invalid then
            checkItem = { seriesTitle: item.seriesTitle, season: item.seasonNum, episode: item.episodeNum }
        else
            checkItem = item
        end if
        if checkItem <> invalid then
            if IsEpisodeWatched(checkItem) then
                m.title.text = m.title.text + "  ✓"
            end if
        end if
    end if
end sub

sub onFocusChange()
    if m.top.rowFocusPercent > 0.5 then
        m.focusBorder.visible = true
        m.title.color = &h5BF0C8FF
    else
        m.focusBorder.visible = false
        m.title.color = &hF7F7FAFF
    end if
end sub

sub cleanUp()
end sub

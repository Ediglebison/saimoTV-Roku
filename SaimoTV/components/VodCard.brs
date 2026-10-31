sub init()
    m.poster = m.top.findNode("poster")
    m.title = m.top.findNode("title")
    m.meta = m.top.findNode("meta")
    m.focusHalo = m.top.findNode("focusHalo")
    m.posterUri = ""
    m.poster.observeField("loadStatus", "onPosterLoadStatus")
end sub

sub showItem()
    item = m.top.itemContent
    if item = invalid then return
    m.posterUri = strField(item, "hdGridPosterUrl")
    if m.posterUri = "" then m.posterUri = strField(item, "hdPosterUrl")
    m.title.text = strField(item, "shortDescriptionLine1")
    if m.title.text = "" then m.title.text = strField(item, "title")
    m.meta.text = strField(item, "shortDescriptionLine2")
    m.poster.uri = "pkg:/images/placeholder.png"
    loadPoster()
end sub

sub updateFocus()
    if m.top.itemHasFocus then
        m.focusHalo.opacity = 0.2 + (m.top.focusPercent * 0.8)
        loadPoster()
    else
        m.focusHalo.opacity = 0
    end if
end sub

sub loadPoster()
    if m.posterUri <> "" and m.poster.uri <> m.posterUri then m.poster.uri = m.posterUri
end sub

sub onPosterLoadStatus()
    status = m.poster.loadStatus
    uri = m.poster.uri
    if Left(LCase(uri), 7) <> "http://" and Left(LCase(uri), 8) <> "https://" then return
    ' Image loading is intentionally silent; Roku console must not be flooded.
end sub

sub init()
    m.poster = m.top.findNode("poster")
    m.focusHalo = m.top.findNode("focusHalo")
    m.cardTitle = m.top.findNode("cardTitle")
    m.posterUri = ""
    m.top.scale = [1.0, 1.0]
    m.poster.observeField("loadStatus", "onPosterLoadStatus")
end sub

sub showItem()
    item = m.top.itemContent
    if item = invalid then return
    m.cardTitle.text = item.title
    m.posterUri = strField(item, "hdPosterUrl")
    if m.posterUri = "" then m.posterUri = strField(item, "cover")
    m.poster.uri = "pkg:/images/placeholder.png"
    loadPoster()
end sub

sub updateFocus()
    focusAmount = m.top.focusPercent
    if m.top.itemHasFocus then
        focusScale = 1.0
        m.focusHalo.opacity = 0.25 + (focusAmount * 0.75)
        loadPoster()
    else
        focusScale = 1.0
        m.focusHalo.opacity = 0.0
    end if
    m.top.scale = [focusScale, focusScale]
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

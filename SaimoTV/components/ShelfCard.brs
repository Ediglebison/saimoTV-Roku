sub init()
    m.poster = m.top.findNode("poster")
    m.focusHalo = m.top.findNode("focusHalo")
    m.cardTitle = m.top.findNode("cardTitle")
    m.top.scale = [1.0, 1.0]
end sub

sub showItem()
    item = m.top.itemContent
    if item = invalid then return
    m.cardTitle.text = item.title
    uri = strField(item, "hdPosterUrl")
    if uri = "" then uri = "pkg:/images/placeholder.png"
    m.poster.uri = uri
end sub

sub updateFocus()
    focusAmount = m.top.focusPercent
    if m.top.itemHasFocus then
        focusScale = 1.0
        m.focusHalo.opacity = 0.25 + (focusAmount * 0.75)
    else
        focusScale = 1.0
        m.focusHalo.opacity = 0.0
    end if
    m.top.scale = [focusScale, focusScale]
end sub

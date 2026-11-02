' TopTab.brs — cartão de aba da barra superior (MarkupGrid item)
sub init()
    m.top.observeField("itemContent", "showItem")
    m.top.observeField("itemHasFocus", "updateFocus")
    m.top.observeField("focusPercent", "updateFocus")
    m.pill = m.top.findNode("pill")
    m.icon = m.top.findNode("icon")
    m.label = m.top.findNode("label")
end sub

sub showItem()
    content = m.top.itemContent
    if content = invalid then return
    m.label.text = content.title
    if content.HDListItemIconUrl <> invalid and content.HDListItemIconUrl <> "" then
        m.icon.uri = content.HDListItemIconUrl
    end if
    updateFocus()
end sub

sub updateFocus()
    focused = m.top.itemHasFocus
    if focused then
        m.label.color = "0x0B0E14FF"
    else
        m.label.color = "0xA8B4C0FF"
    end if
    p = m.top.focusPercent
    if p < 0 then p = 0
    if p > 1 then p = 1
    m.pill.opacity = p
end sub
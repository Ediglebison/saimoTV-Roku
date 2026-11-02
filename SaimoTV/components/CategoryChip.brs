sub init()
    m.bg = m.top.findNode("bg")
    m.border = m.top.findNode("border")
    m.label = m.top.findNode("label")
end sub

sub onFocusChange()
    if m.hasFocus() then
        m.bg.color = "0x26FFFFFF"
        m.border.visible = true
        m.label.color = "0xFFFFFFFF"
    else
        m.bg.color = "0x1C1C26FF"
        m.border.visible = false
        m.label.color = "0xA8B4C0FF"
    end if
end sub

function onContentChange()
    if m.itemContent <> invalid then
        m.label.text = m.itemContent.title
    end if
end function

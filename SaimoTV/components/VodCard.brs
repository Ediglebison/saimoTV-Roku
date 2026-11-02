sub init()
    m.focusBorder = m.top.findNode("focusBorder")
    m.poster = m.top.findNode("poster")
    m.title = m.top.findNode("title")
    m.meta = m.top.findNode("meta")
end sub

sub onFocusChange()
    if m.hasFocus() then
        m.focusBorder.visible = true
    else
        m.focusBorder.visible = false
    end if
end sub

function onContentChange()
    if m.itemContent <> invalid then
        m.title.text = m.itemContent.title
        m.poster.uri = m.itemContent.hdPosterUrl
        if m.itemContent.shortDescriptionLine2 <> invalid then
            m.meta.text = m.itemContent.shortDescriptionLine2
        end if
    end if
end function

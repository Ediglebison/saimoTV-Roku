' Chip de temporada no estilo bg_chip_neutro: pastilha escura em repouso,
' com foco o bitmap focus_chip.png desenha a borda accent 3px e o texto
' fica branco (SceneGraph nao tem raio de canto).
sub init()
    m.chipFocus = m.top.findNode("chipFocus")
    m.chipText = m.top.findNode("chipText")
end sub

sub showItem()
    item = m.top.itemContent
    if item <> invalid then m.chipText.text = strField(item, "title")
end sub

sub updateFocus()
    m.chipFocus.opacity = m.top.focusPercent
    if m.top.itemHasFocus then
        m.chipText.color = "0xFFFFFFFF"
    else
        m.chipText.color = "0xA8B4C0FF"
    end if
end sub

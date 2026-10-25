' Botao de acao da ficha (botao_ficha do Android): repouso #26ffffff com
' texto branco, foco vira pilula branca cheia com texto surface #0B0E14.
sub init()
    m.pillBg = m.top.findNode("pillBg")
    m.pillFocus = m.top.findNode("pillFocus")
    m.pillLabel = m.top.findNode("pillLabel")
end sub

sub showItem()
    item = m.top.itemContent
    if item = invalid then return
    m.pillLabel.text = strField(item, "title")
end sub

sub updateFocus()
    m.pillFocus.opacity = m.top.focusPercent
    if m.top.focusPercent >= 0.5 then
        m.pillLabel.color = "0x0B0E14FF"
    else
        m.pillLabel.color = "0xFFFFFFFF"
    end if
end sub

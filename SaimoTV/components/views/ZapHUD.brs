sub init()
    m.hud = m.top.findNode("hud")
    m.visibleState = false
end sub

sub alternar()
    m.visibleState = not m.visibleState
    if m.hud <> invalid then m.hud.visible = m.visibleState
    m.top.visible = m.visibleState
end sub

sub showHUD()
    if m.hud <> invalid then m.hud.visible = true
    m.top.visible = true
end sub

sub hideHUD()
    if m.hud <> invalid then m.hud.visible = false
    m.top.visible = false
end sub
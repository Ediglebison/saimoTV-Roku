' theme.brs — tokens de cor da paleta Saimo TV (referência SaimoTV.mp4)
' Contrato: expõe apenas constantes de cor (sem estado de UI)
' Formato: &hRRGGBBAA (hex BrightScript, alpha no ultimo byte)

function appPalette() as object
    return {
        bgBase:        &h06060FFF
        bgMid:         &h0B0E14FF
        surface:       &h0B0E14FF
        surfaceCard:   &h16161FFF
        surfaceRaised: &h1C1C26FF
        surfacePanel:  &h101720FF
        textPrimary:   &hF7F7FAFF
        textSecondary: &hA8B4C0FF
        textFaint:     &h6B7280FF
        accent:        &h5BF0C8FF
        accentDim:     &h335BF0C8
        accentEdge:    &h665BF0C8
        live:          &hFF4D4FFF
        aberturaFundo: &h0B0F2AFF
    }
end function
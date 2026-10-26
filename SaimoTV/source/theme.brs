' theme.brs — tokens de cor da paleta Android Saimo TV
' Contrato: expõe apenas constantes de cor (sem estado de UI)
' Fonte: android-ref/values/colors.xml
' Formato: &hRRGGBBAA (hex BrightScript, alpha no ultimo byte)

function appPalette() as object
    return {
        surface:       &h0B0E14FF
        surfaceCard:   &hD90B0E14
        surfaceRaised: &h14FFFFFF
        textPrimary:   &hFFFFFFFF
        textSecondary: &hA8B4C0FF
        textFaint:     &h66FFFFFF
        accent:        &h4FE3D0FF
        accentDim:     &h334FE3D0
        accentEdge:    &h664FE3D0
        live:          &hFF4D4FFF
        aberturaFundo: &h0B0F2AFF
    }
end function

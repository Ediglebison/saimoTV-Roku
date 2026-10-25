' theme.brs — tokens de cor da paleta Android Saimo TV
' Contrato: expõe apenas constantes de cor (sem estado de UI)
' Fonte: android-ref/values/colors.xml
' Formato: 0xRRGGBBFF (alpha aplicado via node.opacity)

function appPalette() as object
    return {
        surface:       &h0B0E14FF
        surfaceCard:   &h0B0E14FF
        surfaceRaised: &hFFFFFFFF
        textPrimary:   &hFFFFFFFF
        textSecondary: &hA8B4C0FF
        textFaint:     &hFFFFFFFF
        accent:        &h4FE3D0FF
        accentDim:     &h4FE3D0FF
        accentEdge:    &h4FE3D0FF
        live:          &hFF4D4FFF
        aberturaFundo: &h0B0F2AFF
    }
end function
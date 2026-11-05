' ====================================================================
' Saimo TV - ArvoreCanaisTask
' Monta, fora da thread da tela, a arvore secao > canal do Ao vivo.
' A tela recebe o no pronto: abrir o Ao vivo so aponta para ele.
' ====================================================================

sub init()
    m.top.functionName = "montar"
end sub

sub montar()
    canais = m.top.canais
    if canais = invalid or canais.Count() = 0 then
        m.top.error = "SemCanais"
        return
    end if

    epg = m.top.epg
    agora = CreateObject("roDateTime").AsSeconds()
    raiz = CreateObject("roSGNode", "ContentNode")
    secoes = {}
    for each c in canais
        grupo = c.category
        if grupo = invalid or grupo = "" then grupo = "Outros"
        secao = secoes[grupo]
        if secao = invalid then
            secao = raiz.CreateChild("ContentNode")
            secao.title = grupo
            secoes[grupo] = secao
        end if
        no = secao.CreateChild("ContentNode")
        no.title = c.name
        logo = ""
        if c.logo <> invalid then
            logo = c.logo
            no.hdPosterUrl = logo
        end if
        campos = { name: c.name, number: c.number, category: grupo, logo: logo, variants: c.variants, numero: c.number.ToStr(), grupoTexto: UCase(grupo), programa: "", progresso: 0.0, ini: 0, fim: 0, seguinte: "" }
        if epg <> invalid and epg[c.name] <> invalid then
            lista = epg[c.name]
            for i = 0 to lista.Count() - 1
                programa = lista[i]
                if agora >= programa.startSec and agora < programa.stopSec then
                    campos.programa = programa.title
                    campos.ini = programa.startSec
                    campos.fim = programa.stopSec
                    if programa.stopSec > programa.startSec then
                        campos.progresso = (agora - programa.startSec) / (programa.stopSec - programa.startSec)
                    end if
                    if i + 1 < lista.Count() then campos.seguinte = lista[i + 1].title
                    exit for
                end if
            end for
        end if
        no.addFields(campos)
    end for
    m.top.arvore = raiz
end sub

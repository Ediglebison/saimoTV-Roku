' ====================================================================
' Saimo TV - AcervoTask
' O acervo inteiro do On Demand, em pedaços: o índice de letras de cada
' categoria e, quando uma fileira entra em foco, os títulos dela já como
' ContentNode. Uma página tem no máximo 50 títulos.
' ====================================================================

sub init()
    m.top.functionName = "executar"
end sub

' Mesmo contrato HTTP do app: limite de 30 s e corpo HTML tratado como falha.
function baixar(url as String) as String
    resposta = httpGet(url, "SaimoTV (RokuOS)", "")
    if not resposta.ok or looksLikeHtml(resposta.body) then return ""
    return resposta.body
end function

sub reportarFalha(motivo as String)
    m.top.error = motivo
end sub

sub lerIndice(base as String)
    texto = baixar(base + "roku/indice.txt")
    if texto = invalid or texto = "" then
        reportarFalha("IndiceVazio")
        return
    end if
    m.top.indice = parseAcervoIndice(texto)
end sub

sub lerPagina(base as String, categoria as String, letra as String, pagina as Integer)
    arquivo = letra
    if letra = "#" then arquivo = "0"
    texto = baixar(base + "roku/" + categoria + "-" + arquivo + "-" + pagina.ToStr() + ".txt")
    if texto = invalid or texto = "" then
        reportarFalha("PaginaVazia")
        return
    end if
    capa = "https://image.tmdb.org/t/p/w185"
    capaGrande = "https://image.tmdb.org/t/p/w780"
    serie = (categoria <> "filmes")
    linha = CreateObject("roSGNode", "ContentNode")
    for each item in parseAcervoPagina(texto)
        caminho = item.posterPath
        ehAbsoluto = (Left(caminho, 4) = "http")
        poster = caminho
        backdrop = caminho
        if not ehAbsoluto then
            poster = capa + caminho
            backdrop = capaGrande + caminho
        end if
        no = linha.CreateChild("ContentNode")
        no.title = item.title
        no.hdPosterUrl = poster
        no.addFields({ itemType: "vod", rawItem: {
            title: item.title, letter: letra, isSeries: serie, year: item.year,
            poster: poster, backdrop: backdrop
        } })
    end for
    m.top.linha = linha
end sub

sub executar()
    base = m.top.baseUrl
    if base = invalid or base = "" then base = LoadPreferences().urlFilmes
    if base = invalid or base = "" then base = "https://filmes-saimo.pages.dev/"
    base = normalizeSaimoBase(base)
    if m.top.categoria = "" then
        lerIndice(base)
    else
        lerPagina(base, m.top.categoria, m.top.letra, m.top.pagina)
    end if
end sub

' ====================================================================
' Saimo TV - MinhasListasTask (BrightScript)
' Baixa, guarda e entrega as listas .m3u do usuário. O link fica no
' registro do aparelho; os canais lidos, no cachefs (o sistema pode limpar
' o cachefs: nesse caso a lista é baixada de novo ao abrir).
' ====================================================================

sub init()
    m.top.functionName = "executar"
end sub

sub executar()
    acao = m.top.acao
    erro = ""
    if acao = "adicionar" then
        erro = adicionar(m.top.link.Trim(), m.top.nome.Trim())
    else if acao = "atualizar" then
        erro = atualizar(m.top.listaId)
    end if
    if erro = "" then m.top.canais = canaisAtivos()
    m.top.listas = LoadMinhasListas()
    m.top.erro = erro
    m.top.pronto = true
end sub

function caminho(id as String) as String
    return "cachefs:/minhas_" + id + ".json"
end function

' Devolve os canais lidos, ou uma mensagem (String) para a pessoa.
function baixar(link as String) as Dynamic
    if not m3uEhHttp(link) then return "O link precisa começar com http:// ou https://"
    temporario = "tmp:/lista.m3u"
    porta = CreateObject("roMessagePort")
    ut = CreateObject("roUrlTransfer")
    ut.SetMessagePort(porta)
    ut.SetUrl(link)
    ut.SetCertificatesFile("common:/certs/ca-bundle.crt")
    ut.InitClientCertificates()
    ua = ReadSaimoKey("userAgent")
    if ua = "" then ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    ut.AddHeader("User-Agent", ua)
    if not ut.AsyncGetToFile(temporario) then return "Não consegui baixar essa lista"
    msg = Wait(30000, porta)
    if msg = invalid then
        ut.AsyncCancel()
        return "Não consegui baixar essa lista"
    end if
    if msg.GetResponseCode() <> 200 then return "Não consegui baixar essa lista"

    estado = CreateObject("roFileSystem").Stat(temporario)
    if estado <> invalid and estado.size <> invalid and estado.size > 30 * 1024 * 1024 then
        DeleteFile(temporario)
        return "A lista passa de 30 MB"
    end if
    texto = ReadAsciiFile(temporario)
    DeleteFile(temporario)

    if Left(texto, 1) = Chr(65279) then texto = Mid(texto, 2)
    limpo = UCase(Left(texto.Trim(), 7))
    if limpo <> "#EXTM3U" and Instr(1, UCase(texto), "#EXTINF") = 0 then return "Isso não parece uma lista .m3u"
    ' A memória do Roku é curta: até 5.000 canais por lista.
    lidos = LerM3u(texto, 5000)
    if lidos.Count() = 0 then return "Essa lista não tem canais"
    return lidos
end function

' Só o que os canais usam, já sem os restritos: o Roku não tem onde escondê-los.
function reduzir(lidos as Object) as Object
    saida = []
    for each canalLido in lidos
        if not EhRestrito(canalLido) then
            fontes = []
            for each fonte in canalLido.fontes
                v = { url: fonte.url, quality: "Auto" }
                if fonte.qualidade <> invalid then v.quality = fonte.qualidade
                if fonte.referer <> invalid then v.referer = fonte.referer
                if fonte.ua <> invalid then v.userAgent = fonte.ua
                fontes.Push(v)
            end for
            item = { name: canalLido.nome, category: "Minhas listas", variants: fontes, logo: "" }
            if canalLido.logo <> invalid then item.logo = canalLido.logo
            saida.Push(item)
        end if
    end for
    return saida
end function

function agora() as Integer
    return CreateObject("roDateTime").AsSeconds()
end function

function adicionar(link as String, nome as String) as String
    listas = LoadMinhasListas()
    if listas.Count() >= 10 then return "Já são 10 listas: remova uma antes"
    for each listaAtual in listas
        if listaAtual.link = link then return "Essa lista já foi adicionada"
    end for
    lidos = baixar(link)
    if Type(lidos) = "String" or Type(lidos) = "roString" then return lidos

    id = CreateObject("roDeviceInfo").GetRandomUUID().Replace("-", "").Left(10)
    canais = reduzir(lidos)
    WriteAsciiFile(caminho(id), FormatJson(canais))
    if nome = "" then nome = "Lista " + (listas.Count() + 1).ToStr()
    listas.Push({ id: id, nome: nome, link: link, atualizadaEm: agora(), ativa: true, total: canais.Count() })
    SaveMinhasListas(listas)
    return ""
end function

function atualizar(id as String) as String
    listas = LoadMinhasListas()
    for each listaAtual in listas
        if listaAtual.id = id then
            lidos = baixar(listaAtual.link)
            if Type(lidos) = "String" or Type(lidos) = "roString" then return lidos
            canais = reduzir(lidos)
            WriteAsciiFile(caminho(id), FormatJson(canais))
            listaAtual.atualizadaEm = agora()
            listaAtual.total = canais.Count()
            SaveMinhasListas(listas)
            return ""
        end if
    end for
    return ""
end function

function canaisAtivos() as Object
    listas = LoadMinhasListas()
    todos = []
    mudou = false
    for each listaAtual in listas
        if listaAtual.ativa then
            canais = invalid
            bruto = ReadAsciiFile(caminho(listaAtual.id))
            if bruto <> "" then canais = ParseJson(bruto)
            ' Sem cópia guardada ou com mais de 12 h: baixa; se falhar, fica a que tem.
            if canais = invalid or agora() - listaAtual.atualizadaEm > 43200 then
                lidos = baixar(listaAtual.link)
                if Type(lidos) = "roArray" then
                    canais = reduzir(lidos)
                    WriteAsciiFile(caminho(listaAtual.id), FormatJson(canais))
                    listaAtual.atualizadaEm = agora()
                    listaAtual.total = canais.Count()
                    mudou = true
                end if
            end if
            if canais <> invalid then todos.Append(canais)
        end if
    end for
    if mudou then SaveMinhasListas(listas)
    return todos
end function

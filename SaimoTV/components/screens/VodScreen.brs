' ====================================================================
' Saimo TV - VodScreen
' ====================================================================

sub init()
    m.heroBanner = m.top.findNode("heroBanner")
    m.vodRowList = m.top.findNode("vodRowList")
    m.heroTimer = m.top.findNode("heroTimer")
    m.heroTimer.observeField("fire", "aplicarDestaque")
    m.vodRowList.observeField("rowItemSelected", "onRowItemSelected")
    m.vodRowList.observeField("rowItemFocused", "onRowItemFocused")

    m.currentCategoryIdx = 0
    m.categories = ["Filmes", "Séries", "Animes", "Doramas"]
    m.cores = ["#5BF0C8", "#7AA2FF", "#FFB454", "#FF7EB6"]
    m.icones = ["m_movie", "m_live_tv", "m_star", "m_more"]
    m.chaves = ["filmes", "series", "animes", "doramas"]
    m.indice = invalid
    m.tarefaIndice = invalid
    m.linhas = {}
    m.geracao = 0
    m.tarefas = {}
    m.top.observeField("focusedChild", "onFocusedChildChange")
    montarIndice()
end sub

sub montarIndice()
    if m.indice <> invalid or m.tarefaIndice <> invalid then return
    m.tarefaIndice = CreateObject("roSGNode", "AcervoTask")
    m.tarefaIndice.observeField("indice", "onIndice")
    m.tarefaIndice.observeField("error", "onIndiceFalha")
    m.tarefaIndice.control = "RUN"
end sub

sub onIndice()
    if m.tarefaIndice <> invalid then m.indice = m.tarefaIndice.indice
    m.tarefaIndice = invalid
    if m.grupos = invalid then separar()
    montar()
end sub

sub onIndiceFalha()
    m.tarefaIndice = invalid
    print "AcervoIndiceFalha"
end sub

function totalDaCategoria(i as Integer) as Integer
    total = 0
    if m.indice <> invalid then
        letras = m.indice.letras[m.chaves[i]]
        if letras <> invalid then
            for each entrada in letras
                total = total + entrada.total
            end for
        end if
    end if
    if total = 0 and m.grupos <> invalid then total = m.grupos[i].Count()
    return total
end function

sub onFocusedChildChange()
    if m.top.isInFocusChain() and not m.vodRowList.isInFocusChain() then m.vodRowList.setFocus(true)
end sub

sub onItemsChange()
    separar()
    montar()
end sub

sub onCategoryChange()
    for i = 0 to m.categories.Count() - 1
        if m.categories[i] = m.top.selectedCategory then m.currentCategoryIdx = i
    end for
    if m.grupos <> invalid then montar()
end sub

sub separar()
    m.grupos = [[], [], [], []]
    allItems = m.top.vodItems
    if allItems = invalid then return
    for each it in allItems
        itCat = ""
        if it.category <> invalid then itCat = LCase(it.category)
        itTitle = ""
        if it.title <> invalid then itTitle = LCase(it.title)
        if Instr(1, itCat, "anime") > 0 or Instr(1, itTitle, "anime") > 0 then
            m.grupos[2].Push(it)
        else if Instr(1, itCat, "dorama") > 0 or Instr(1, itTitle, "dorama") > 0 then
            m.grupos[3].Push(it)
        else if it.isSeries then
            m.grupos[1].Push(it)
        else
            m.grupos[0].Push(it)
        end if
    end for
end sub

function textoTitulos(n as Integer) as String
    if n = 1 then return "1 título"
    return n.ToStr() + " títulos"
end function

sub fileira(raiz as Object, titulo as String, itens as Object, de as Integer, ate as Integer)
    if ate >= itens.Count() then ate = itens.Count() - 1
    if de > ate then return
    linha = raiz.CreateChild("ContentNode")
    linha.title = titulo
    for i = de to ate
        it = itens[i]
        no = linha.CreateChild("ContentNode")
        no.title = it.title
        if it.poster <> invalid then no.hdPosterUrl = it.poster
        no.addFields({ itemType: "vod", rawItem: it })
    end for
end sub

sub esperar(linha as Object)
    espera = linha.CreateChild("ContentNode")
    espera.title = "Carregando…"
    espera.addFields({ itemType: "carregando" })
end sub

sub carregarPagina(i as Integer)
    info = m.linhas[i.ToStr()]
    if info = invalid then return
    if info.estado <> "" then return
    info.estado = "baixando"
    tarefa = CreateObject("roSGNode", "AcervoTask")
    tarefa.id = i.ToStr() + ":" + m.geracao.ToStr()
    tarefa.categoria = m.chaves[m.currentCategoryIdx]
    tarefa.letra = info.letra
    tarefa.pagina = info.pagina
    tarefa.observeField("linha", "onLinha")
    tarefa.observeField("error", "onLinhaFalha")
    m.tarefas[tarefa.id] = tarefa
    tarefa.control = "RUN"
end sub

' Baixa a fileira focada e as duas seguintes; devolve à espera as que ficaram
' longe, para a memória não crescer enquanto a pessoa desce o acervo.
sub carregarPerto(r as Integer)
    raiz = m.vodRowList.content
    for each chave in m.linhas
        info = m.linhas[chave]
        numeroLinha = Val(chave)
        if info.estado = "pronto" and (numeroLinha < r - 4 or numeroLinha > r + 6) and raiz <> invalid then
            linha = raiz.getChild(numeroLinha)
            if linha <> invalid then
                linha.removeChildrenIndex(linha.getChildCount(), 0)
                esperar(linha)
            end if
            info.estado = ""
        end if
    end for
    for i = r to r + 2
        carregarPagina(i)
    end for
end sub

sub montar()
    montarIndice()
    if m.grupos = invalid then return
    raiz = CreateObject("roSGNode", "ContentNode")
    cats = raiz.CreateChild("ContentNode")
    cats.title = "Categorias"
    for i = 0 to 3
        g = m.grupos[i]
        capas = []
        for c = 0 to 3
            if c < g.Count() and g[c].poster <> invalid then capas.Push(g[c].poster)
        end for
        no = cats.CreateChild("ContentNode")
        no.title = m.categories[i]
        no.addFields({ itemType: "categoria", indice: i, subTitulo: textoTitulos(totalDaCategoria(i)), cor: m.cores[i], icone: "pkg:/images/icons/" + m.icones[i] + ".png", capas: capas })
    end for

    g = m.grupos[m.currentCategoryIdx]
    fileira(raiz, "Em alta", g, 0, 19)
    fileira(raiz, "Recomendados para você", g, 20, 39)
    fileira(raiz, "Mais títulos", g, 40, 119)

    ' O acervo inteiro em páginas de até 50 títulos, uma fileira por página; só
    ' as páginas perto do foco ficam baixadas, para o Roku mais fraco aguentar.
    m.geracao = m.geracao + 1
    m.linhas = {}
    letras = invalid
    if m.indice <> invalid then letras = m.indice.letras[m.chaves[m.currentCategoryIdx]]
    if letras <> invalid then
        for each entrada in letras
            for pagina = 1 to entrada.paginas
                linha = raiz.CreateChild("ContentNode")
                linha.title = entrada.letra
                if entrada.paginas > 1 then linha.title = entrada.letra + " · " + pagina.ToStr() + " de " + entrada.paginas.ToStr()
                esperar(linha)
                m.linhas[(raiz.getChildCount() - 1).ToStr()] = { letra: entrada.letra, pagina: pagina, estado: "" }
            end for
        end for
    end if

    AjustarFileiras(m.vodRowList, raiz)
    m.vodRowList.content = raiz
    mostrarCategoria(m.currentCategoryIdx)
    carregarPerto(0)
end sub

sub mostrarCategoria(i as Integer)
    m.heroBanner.featuredItem = { title: m.categories[i], genres: textoTitulos(totalDaCategoria(i)), overview: "Lançamentos, clássicos e tudo entre eles, dublados e legendados.", semFundo: true }
end sub

function noEm(coords as Dynamic) as Dynamic
    root = m.vodRowList.content
    if root = invalid or coords = invalid or coords.Count() < 2 then return invalid
    if coords[0] >= root.getChildCount() then return invalid
    linha = root.getChild(coords[0])
    if linha = invalid or coords[1] >= linha.getChildCount() then return invalid
    return linha.getChild(coords[1])
end function

function adaptarAcervo(raw as Dynamic) as Dynamic
    kind = "movie"
    if raw.isSeries then kind = "series"
    return {
        title: raw.title,
        letter: raw.letter,
        id: raw.title,
        kind: kind,
        poster: raw.poster,
        backdrop: raw.backdrop,
        rating: "",
        year: raw.year,
        genres: m.categories[m.currentCategoryIdx],
        overview: "",
        isSeries: raw.isSeries
    }
end function

' Resolve a fileira viva da tarefa; invalid quando a categoria ja mudou.
function linhaDaTarefa(tarefa as Object) as Object
    m.tarefas.Delete(tarefa.id)
    partes = tarefa.id.Split(":")
    if Val(partes[1]) <> m.geracao then return invalid
    raiz = m.vodRowList.content
    if raiz = invalid then return invalid
    linha = raiz.getChild(Val(partes[0]))
    if linha = invalid then return invalid
    return { linha: linha, chave: partes[0] }
end function

sub onLinha(evento as Object)
    tarefa = evento.getRoSGNode()
    alvo = linhaDaTarefa(tarefa)
    if alvo = invalid then return
    linha = alvo.linha
    novos = tarefa.linha
    if novos = invalid then return
    grupo = m.categories[m.currentCategoryIdx]
    itens = []
    for each bruto in novos.getChildren(-1, 0)
        raw = bruto.rawItem
        if raw = invalid then continue for
        if not isRestrictedVod(raw.title, grupo) then itens.Push(raw)
    end for
    info = m.linhas[alvo.chave]
    if itens.Count() = 0 then
        if info <> invalid then info.estado = ""
        return
    end if
    if info <> invalid then info.estado = "pronto"
    linha.removeChildrenIndex(linha.getChildCount(), 0)
    for each raw in itens
        no = linha.CreateChild("ContentNode")
        no.title = raw.title
        no.hdPosterUrl = raw.poster
        no.addFields({ itemType: "vod", rawItem: adaptarAcervo(raw) })
    end for
end sub

sub onLinhaFalha(evento as Object)
    tarefa = evento.getRoSGNode()
    alvo = linhaDaTarefa(tarefa)
    if alvo = invalid then return
    linha = alvo.linha
    info = m.linhas[alvo.chave]
    if info = invalid then return
    info.estado = "erro"
    linha.removeChildrenIndex(linha.getChildCount(), 0)
    falha = linha.CreateChild("ContentNode")
    falha.title = "Falha ao carregar · OK tenta de novo"
    falha.addFields({ itemType: "erro" })
    print "AcervoPaginaFalha"
end sub

sub onRowItemFocused()
    foco = m.vodRowList.rowItemFocused
    if foco <> invalid and foco.Count() >= 1 then carregarPerto(foco[0])
    m.heroTimer.control = "stop"
    m.heroTimer.control = "start"
end sub

sub aplicarDestaque()
    no = noEm(m.vodRowList.rowItemFocused)
    if no = invalid then return
    if no.itemType = "categoria" then
        mostrarCategoria(no.indice)
    else if no.rawItem <> invalid then
        m.heroBanner.featuredItem = no.rawItem
    end if
end sub

sub onRowItemSelected()
    coords = m.vodRowList.rowItemSelected
    no = noEm(coords)
    if no = invalid then return
    if no.itemType = "erro" then
        info = m.linhas[coords[0].ToStr()]
        if info <> invalid and info.estado = "erro" then
            info.estado = ""
            carregarPagina(coords[0])
        end if
    else if no.itemType = "categoria" then
        if no.indice <> m.currentCategoryIdx then
            m.currentCategoryIdx = no.indice
            montar()
            m.vodRowList.jumpToRowItem = [0, no.indice]
        end if
    else if no.rawItem <> invalid then
        m.top.itemSelected = no.rawItem
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "up" then
        m.top.focusUpRequested = true
        return true
    end if
    return false
end function

sub cleanUp()
end sub
#!/usr/bin/env python3
"""Static integrity checks for the Saimo TV Roku project."""
from __future__ import annotations

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "SaimoTV"
ERRORS: list[str] = []
CHECKS = 0


def check(condition: bool, message: str) -> None:
    global CHECKS
    CHECKS += 1
    if not condition:
        ERRORS.append(message)


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception as exc:  # noqa: BLE001
        ERRORS.append(f"Não foi possível ler {path.relative_to(ROOT)}: {exc}")
        return ""


def main() -> int:
    required = [
        APP / "manifest",
        APP / "source/main.brs",
        APP / "source/bslib.brs",
        APP / "components/MainScene.xml",
        APP / "components/MainScene.brs",
        APP / "components/tasks/DataLoaderTask.xml",
        APP / "components/tasks/DataLoaderTask.brs",
        APP / "components/tasks/MinhasListasTask.xml",
        APP / "components/tasks/MinhasListasTask.brs",
        APP / "components/tasks/StreamResolverTask.xml",
        APP / "components/tasks/StreamResolverTask.brs",
        APP / "components/views/PlayerOSD.xml",
        APP / "components/views/PlayerOSD.brs",
        APP / "source/utils/Format.brs",
        APP / "source/utils/LeitorM3u.brs",
        APP / "source/utils/Storage.brs",
        APP / "source/utils/Rows.brs",
        APP / "components/views/TopNavBar.xml",
        APP / "components/views/TopNavBar.brs",
        APP / "components/items/PosterItem.xml",
        APP / "components/items/PosterItem.brs",
        APP / "components/items/LetraItem.xml",
        APP / "components/items/AjusteItem.xml",
        APP / "components/items/EpisodeItem.xml",
        APP / "components/items/EpisodeItem.brs",
        APP / "components/views/HeroBanner.xml",
        APP / "components/views/HeroBanner.brs",
        APP / "components/screens/HomeScreen.xml",
        APP / "components/screens/HomeScreen.brs",
        APP / "components/screens/LiveScreen.xml",
        APP / "components/screens/LiveScreen.brs",
        APP / "components/screens/VodScreen.xml",
        APP / "components/screens/VodScreen.brs",
        APP / "components/screens/FavoritesScreen.xml",
        APP / "components/screens/FavoritesScreen.brs",
        APP / "components/screens/FichaScreen.xml",
        APP / "components/screens/FichaScreen.brs",
        APP / "components/screens/PlayerScreen.xml",
        APP / "components/screens/PlayerScreen.brs",
        APP / "components/screens/GuideScreen.xml",
        APP / "components/screens/GuideScreen.brs",
        APP / "components/views/ChannelDrawer.xml",
        APP / "components/views/ChannelDrawer.brs",
        APP / "components/views/ZapHUD.xml",
        APP / "components/views/ZapHUD.brs",
        APP / "components/views/PinModal.xml",
        APP / "components/views/PinModal.brs",
        APP / "components/views/PainelLateral.xml",
        APP / "components/items/CanalItem.xml",
        APP / "components/items/ProgramaItem.xml",
        APP / "components/items/FonteItem.xml",
        APP / "components/screens/EventsScreen.xml",
        APP / "components/screens/EventsScreen.brs",
        APP / "components/screens/RadiosScreen.xml",
        APP / "components/screens/RadiosScreen.brs",
        APP / "components/screens/SearchScreen.xml",
        APP / "components/screens/SearchScreen.brs",
        APP / "components/screens/SettingsScreen.xml",
        APP / "components/screens/SettingsScreen.brs",
        APP / "components/screens/MinhasListasScreen.xml",
        APP / "components/screens/MinhasListasScreen.brs",
        ROOT / "docs/TESTE_ROKU.md",
        APP / "components/tasks/ConnectTask.xml",
        APP / "components/tasks/ConnectTask.brs",
        APP / "components/tasks/AcervoTask.xml",
        APP / "components/tasks/AcervoTask.brs",
        APP / "components/tasks/ArvoreCanaisTask.xml",
        APP / "components/tasks/ArvoreCanaisTask.brs",
        APP / "images/icon_focus_fhd.png",
        APP / "images/splash_fhd.png",
        APP / "images/bg_app.png",
        APP / "images/bg_sidebar.png",
        APP / "images/logo.png",
        APP / "images/nav_focus.png",
        APP / "images/list_focus.png",
        APP / "images/item_focus.png",
        APP / "images/guide_focus.png",
        APP / "images/focus_grid.png",
        APP / "images/nav_live.png",
        APP / "images/ficha_veil_side.png",
        APP / "images/ficha_veil_bottom.png",
        APP / "images/focus_episode.png",
        APP / "images/focus_chip.png",
        APP / "images/focus_shelf.png",
        APP / "images/action_pill_normal.png",
        APP / "images/action_pill_focus.png",
        ROOT / "tools/test_parsers.py",
        ROOT / "tools/tests/parsers_test.brs",
        ROOT / "tools/tests/fixtures/indice.txt",
        ROOT / "tools/tests/fixtures/filmes-A.txt",
        ROOT / "tools/tests/fixtures/series-A.txt",
        ROOT / "tools/tests/fixtures/acervo-indice.txt",
        ROOT / "tools/tests/fixtures/acervo-pagina.txt",
    ]
    for path in required:
        check(path.is_file() and path.stat().st_size > 0,
              f"Arquivo obrigatório ausente/vazio: {path.relative_to(ROOT)}")

    try:
        package = json.loads(read(ROOT / "package.json"))
        config = json.loads(read(ROOT / "bsconfig.json"))
    except json.JSONDecodeError as exc:
        ERRORS.append(f"JSON inválido: {exc}")
        package, config = {}, {}
    check(package.get("version") == "2.6.0", "package.json deve apontar para 2.6.0")
    try:
        lock = json.loads(read(ROOT / "package-lock.json"))
    except json.JSONDecodeError:
        lock = {}
    check(lock.get("version") == "2.6.0" and lock.get("packages", {}).get("", {}).get("version") == "2.6.0",
          "package-lock.json deve apontar para 2.6.0")
    check(package.get("scripts", {}).get("test") == "python3 tools/test_parsers.py",
          "package.json deve expor npm test para a suíte de parsers")
    check("brighterscript" in package.get("devDependencies", {}), "Dependência brighterscript ausente")
    check("brs" in package.get("devDependencies", {}), "Dependência brs ausente")
    check(config.get("rootDir") == "SaimoTV", "bsconfig.json deve usar SaimoTV como rootDir")

    manifest = read(APP / "manifest")
    version_fields = dict(line.split("=", 1) for line in manifest.splitlines() if "=" in line)
    check((version_fields.get("major_version"), version_fields.get("minor_version"), version_fields.get("build_version")) == ("2", "6", "0"),
          "Versão do manifest não corresponde a 2.6.0")
    check("ui_resolutions=fhd" in manifest, "Resolução FHD do manifest deve permanecer definida")
    check("subtitle=Canais ao Vivo e Acervo" in manifest, "Manifest deve manter subtitle de ref")
    check("splash_color=#0b0e14" in manifest, "Manifest deve manter splash_color de ref")
    check("splash_min_time=1200" in manifest, "Manifest deve manter splash_min_time de ref")
    check("requires_audioperf=5.1" in manifest, "Manifest deve manter requires_audioperf de ref")
    check("mm_icon_side_hd=pkg:/images/icon_hd.png" in manifest, "Manifest deve manter mm_icon_side_hd")
    check("mm_icon_side_fhd=pkg:/images/icon_fhd.png" in manifest, "Manifest deve manter mm_icon_side_fhd")

    main_brs = read(APP / "components/MainScene.brs")
    main_xml_text = read(APP / "components/MainScene.xml")
    data_loader_brs = read(APP / "components/tasks/DataLoaderTask.brs")
    data_loader_xml = read(APP / "components/tasks/DataLoaderTask.xml")
    bslib = read(APP / "source/bslib.brs")
    check('function readCacheAscii(path as string)' in bslib and 'fs.Exists(path)' in bslib
          and 'readCacheAscii("cachefs:/' in data_loader_brs,
          "Leituras de cache devem verificar a existência dos arquivos antes de abrir")
    readme = read(ROOT / "README.md")
    tests = read(ROOT / "tools/tests/parsers_test.brs")

    check('https://saimo-canais.pages.dev/catalogo.txt' in main_brs, "URL padrão canônica dos canais ausente")
    check('https://filmes-saimo.pages.dev/' in main_brs, "URL padrão canônica do VOD ausente")
    check('Instr(1, lowVod, "filmes-saimo.pages.dev") > 0' in main_brs
          and 'Instr(1, lowVod, "saimoplayer/main/vod") > 0' in main_brs,
          "Migração dos endereços antigos do VOD ausente")
    check('Instr(1, lowPlaylist, "canais-saimo.pages.dev") > 0' in main_brs,
          "Migração do endereço antigo dos canais ausente")
    check('isSaimoVodUrl(m.vodUrl)' in main_brs and 'isSaimoCatalogUrl' in bslib,
          "Detecção das fontes Saimo ausente")
    check('m.vodUrl = ReadSaimoKey("vodUrl")' in main_brs, "URL independente do catálogo VOD ausente")
    check('startLoader("saimo_index"' in main_brs and 'mode = "saimo_index"' in data_loader_brs,
          "Fluxo do índice VOD por letras ausente")

    check('id="vodRefreshTimer" duration="900" repeat="true"' in main_xml_text,
          "Verificação periódica de 15 minutos não está configurada")
    check("sub onVodRefreshTimer()" in main_brs and "runScheduledSync()" in main_brs,
          "Timer de 15 minutos não está conectado à sincronização")
    check("return (nowSeconds - lastSync) >= 21600" in main_brs,
          "Cache deve ser considerado antigo somente após 6 horas")
    check('refreshPlaylist(false)' in main_brs and 'refreshVodCatalog(false)' in main_brs,
          "Sincronização agendada deve rodar em segundo plano sem trocar a tela")
    check('m.vodInitPending = true' in main_brs, "Encadeamento das sincronizações de canais e VOD ausente")


    check("parseSaimoIndexLetters" in bslib and "parseSaimoMovieItems" in bslib
          and "parseSaimoSeriesItems" in bslib, "Parsers puros do catálogo Saimo ausentes")
    check("parseSaimoEpisodeItems" in bslib and "parseSaimoSearchItems" in bslib,
          "Parsers de episódios/busca ausentes")
    check("parseVodM3u" in bslib and "episodeInfo" in bslib, "Parser de M3U VOD/episódios ausente")
    check("isRestrictedVod" in bslib and "maxEntries = 25000" in bslib,
          "Filtro de conteúdo adulto/limite de memória ausente")
    check("not isRestrictedVod(title, groupName)" in bslib,
          "O filtro de conteúdo adulto também deve ser aplicado aos destaques")
    check("function isSaimoComment" in bslib and 'second = " " or second = Chr(9)' in bslib,
          "Títulos iniciados por # devem ser aceitos como dados")
    check("function saimoIndexSignature" in bslib and "function saimoLetterCacheMarker" in bslib
          and "function saimoLetterCachePath" in bslib, "Assinatura/invalidacão dos caches por letra ausentes")
    check("function pickSaimoHighlights" in bslib and "function saimoItemSubtitle" in bslib
          and "function saimoGridSubtitle" in bslib,
          "Seleção de destaques/legendas dos cartões ausente")
    check("function foldText" in bslib and "function buildSaimoSearchIndex" in bslib
          and "function searchSaimoIndex" in bslib and "Instr(1, folded[i], q) > 0" in bslib,
          "Busca sem acento/índice local ausente")

    check('mode = "saimo_letter"' in data_loader_brs and "loadSaimoLetter" in data_loader_brs,
          "Carregamento de uma letra por vez ausente")
    check('mode = "saimo_search_index"' in data_loader_brs and "loadSaimoSearchIndex" in data_loader_brs
          and 'cachefs:/saimo_search_index.json' in data_loader_brs,
          "Índice local de busca deve ser preparado na tarefa")

    main_xml_text = read(APP / "components" / "MainScene.xml")
    declared_fonts = set(re.findall(r'<Font\s+id="([^"]+)"', main_xml_text))
    referenced_fonts = set(re.findall(r'font="dictionary:([^"]+)"', main_xml_text))
    missing_fonts = sorted(referenced_fonts - declared_fonts)
    check(not missing_fonts,
          "Fontes sem declaração em MainScene.xml: " + ", ".join(missing_fonts))
    check('saimoLetterCachePath(filter, letter)' in data_loader_brs
          and 'saimoLetterCacheMarker(base, m.top.signature)' in data_loader_brs,
          "Cache por letra/assinatura ausente na tarefa")
    check("applySaimoArtwork(items, fichas, fallbackCovers)" in data_loader_brs,
          "Capas e gêneros devem ser aplicados dentro da FetchTask")
    check("function isStringValue(value as dynamic) as boolean" in bslib
          and "not isStringValue(fichas)" in data_loader_brs,
          "A resposta de fichas deve aceitar strings do Roku e do simulador")
    check('readCacheAscii("cachefs:/saimo_vod_fichas.txt")' not in main_brs,
          "fichas.txt não deve ser lido na linha principal")
    check('WriteAsciiFile("cachefs:/saimo_vod_fichas.ready", "1")' in data_loader_brs
          and 'readCacheAscii("cachefs:/saimo_vod_fichas.ready")' in data_loader_brs
          and 'httpGet(base + "fichas.txt"' in data_loader_brs
          and 'startSaimoArtworkFetch(base)' not in main_brs,
          "Fichas completas devem ser carregadas sob demanda em segundo plano")

    check('field id="signature" type="string"' in data_loader_xml and "task.signature = signature" in main_brs,
          "Assinatura do índice não é repassada à FetchTask")
    check("function isSaimoSeriesKind" in bslib and 'k = "s" or k = "d" or k = "a"' in bslib,
          "Destaques/busca devem tratar s, d e a como séries")

    check('"destaques.txt"' in data_loader_brs and "parseHighlights(highlights.body)" in data_loader_brs,
          "Destaques VOD da fonte pública não são carregados")
    check('"busca.txt"' in data_loader_brs and '"fichas.txt"' in data_loader_brs,
          "Busca e capas completas não usam os fragmentos esperados")
    check('"indice.txt"' in data_loader_brs and '"filmes-" + fileLetter' in data_loader_brs
          and '"series-" + fileLetter' in data_loader_brs, "Fragmentos do catálogo não são montados por letra")
    check('w7.embedtv.cc' not in bslib and 'dadinhodetapioca.fun' not in bslib and 'embedplayer2.xyz' not in bslib,
          "Há cabeçalhos/referers específicos de serviços de terceiros embutidos")

    check("TESTS_PASS" in tests and "testMovieParser" in tests and "testEpisodeParser" in tests
          and "saimoGridSubtitle" in tests,
          "Suíte BRS de parsers incompleta")
    test_runner = read(ROOT / "tools/test_parsers.py")
    check("TESTS_FAILED" in test_runner and "TESTS_PASS" in test_runner,
          "O runner de testes deve falhar quando TESTS_FAILED for emitido")

    check("2.6.0" in readme and "sob demanda" in readme,
          "README precisa documentar a versão 2.5.17 e o carregamento sob demanda")
    check("identidade visual" in readme.lower() or "interface" in readme.lower(),
          "README precisa documentar a renovação visual")
    check("Roboto" in readme and "SaimoTV/fonts" in readme,
          "README precisa documentar a tipografia Roboto e a pasta de fontes")
    check("filmes-saimo.pages.dev" in readme and "saimo-canais.pages.dev" in readme,
          "README precisa documentar as fontes canônicas")
    check("15 minutos" in readme and "6 horas" in readme,
          "README precisa documentar a verificação e a validade do cache")
    check("indice.txt" in readme and "fichas.txt" in readme,
          "README precisa documentar o catálogo por fragmentos e as capas")
    check("fileiras editoriais" in readme and "6 colunas" in readme,
          "README precisa documentar as fileiras e densidade do catálogo")
    check("npm install" in readme and "npm run package" in readme and "npm test" in readme,
          "Comandos de build/teste ausentes no README")
    check("/tmp/opencode" not in read(ROOT / "package.json"), "package.json ainda depende de caminho local da sessão")

    favorites_brs = read(APP / "components/screens/FavoritesScreen.brs")
    favorites_xml = read(APP / "components/screens/FavoritesScreen.xml")
    check('LoadFavoriteChannels()' in favorites_brs and 'LoadFavoriteVOD()' in favorites_brs,
          "Favoritos deve carregar favoritos persistidos via LoadFavoriteChannels/LoadFavoriteVOD")
    check('itemType = "channel"' in favorites_brs and 'itemType = "vod"' in favorites_brs,
          "Favoritos deve distinguir canal e VOD nos itens")
    check('id="emptyState"' in favorites_xml and 'id="countLabel"' in favorites_xml,
          "Favoritos deve ter estado vazio e contagem")
    check('" títulos"' in favorites_brs, "Favoritos deve exibir contagem de títulos")

    search_screen_brs = read(APP / "components/screens/SearchScreen.brs")
    search_screen_xml = read(APP / "components/screens/SearchScreen.xml")

    home_screen_brs = read(APP / "components/screens/HomeScreen.brs")
    home_screen_xml = read(APP / "components/screens/HomeScreen.xml")
    vod_screen_brs = read(APP / "components/screens/VodScreen.brs")
    vod_screen_xml = read(APP / "components/screens/VodScreen.xml")
    hero_banner_brs = read(APP / "components/views/HeroBanner.brs")
    hero_banner_xml = read(APP / "components/views/HeroBanner.xml")
    check('carregarIndice' in search_screen_brs, "SearchScreen deve carregar o indice local via carregarIndice")
    check('agendarBusca' in search_screen_brs, "SearchScreen deve agendar busca remota via agendarBusca")
    check('buscaTimer' in search_screen_xml and 'duration="0.3"' in search_screen_xml,
          "SearchScreen deve ter Timer buscaTimer com debounce remoto de 0.3s")
    check('foldText(' in search_screen_brs, "SearchScreen deve normalizar texto dos canais com foldText")
    check('busca.txt' in read(APP / "components/tasks/DataLoaderTask.brs"),
          "Busca remota deve usar o fragmento busca.txt")
    check('cachefs:/saimo_search_index.json' in search_screen_brs
          and 'searchSaimoIndex(m.searchIndex, query, 160)' in search_screen_brs,
          "Indice local de busca deve ser preparado na tarefa e consultado em memoria")

    check('GetInProgressList()' in home_screen_brs, "HomeScreen deve carregar progresso via GetInProgressList")
    check('LoadFavoriteVOD()' in home_screen_brs, "HomeScreen deve carregar favoritos VOD")
    check('epgMap' in home_screen_brs and 'railsData' in home_screen_brs, "HomeScreen deve consumir epgMap e railsData")
    check('montarTimer' in home_screen_xml and 'duration="0.15"' in home_screen_xml, "HomeScreen deve ter montarTimer")
    check('itemType = "vod"' in home_screen_brs and 'itemType = "channel"' in home_screen_brs, "HomeScreen deve distinguir vod e channel")
    check('HeroBanner' in home_screen_xml and 'PosterItem' in home_screen_xml, "HomeScreen deve usar HeroBanner e PosterItem")

    check('separar' in vod_screen_brs, "VodScreen deve separar itens por categoria")
    check('mostrarCategoria' in vod_screen_brs, "VodScreen deve mostrar categoria")
    check('pkg:/images/icons/' in vod_screen_brs, "VodScreen deve usar icones de categoria")
    check('HeroBanner' in vod_screen_xml, "VodScreen deve usar HeroBanner")

    check('semFundo' in hero_banner_brs, "HeroBanner deve suportar semFundo")
    check('backdropPoster' in hero_banner_xml and 'overviewLabel' in hero_banner_xml, "HeroBanner deve ter backdrop e overview")

    radios_screen_brs = read(APP / "components/screens/RadiosScreen.brs")
    radios_screen_xml = read(APP / "components/screens/RadiosScreen.xml")
    check('onRadiosChange' in radios_screen_brs, "RadiosScreen deve reagir a mudanca via onRadiosChange")
    check('AjustarFileiras' in radios_screen_brs, "RadiosScreen deve ajustar fileiras via AjustarFileiras")
    check('grupos[g]' in radios_screen_brs, "RadiosScreen deve agrupar radios por genero")
    check('"Outras"' in radios_screen_brs, "RadiosScreen deve colocar Outras por ultimo")
    check('streamFormat = "mp3"' in radios_screen_brs and 'm.radioAudio.control = "stop"' in radios_screen_brs,
          "RadiosScreen deve parar o audio antes de tocar com streamFormat mp3")
    check('m.radioAudio.control = "stop"' in radios_screen_brs and 'm.radioAudio.content = invalid' in radios_screen_brs,
          "RadiosScreen cleanUp deve parar e invalidar o audio")
    check('m.barrasTimer' in radios_screen_brs, "RadiosScreen deve controlar o barrasTimer")
    check('m.rows.setFocus(true)' in radios_screen_brs, "RadiosScreen fechar deve restaurar o foco na lista")
    check('observeField("telaCheia", "onRadioTelaCheia")' in main_brs,
          "MainScene deve observar telaCheia de Radios via onRadioTelaCheia")
    check('sub onRadioTelaCheia(evt as Object)' in main_brs, "MainScene deve implementar onRadioTelaCheia")
    check('task.responseRadios <> invalid' in main_brs and 'm.currentScreenNode.radios = m.cachedRadios' in main_brs,
          "MainScene deve atualizar Radios montado na entrega tardia de radios")

    events_screen_brs = read(APP / "components/screens/EventsScreen.brs")
    events_screen_xml = read(APP / "components/screens/EventsScreen.xml")
    minhas_screen_brs = read(APP / "components/screens/MinhasListasScreen.brs")
    minhas_screen_xml = read(APP / "components/screens/MinhasListasScreen.xml")
    check('onEventsChange' in events_screen_brs, "EventsScreen deve reagir a mudanca via onEventsChange")
    check('onEventSelected' in events_screen_brs, "EventsScreen deve selecionar evento via onEventSelected")
    check('visible = events.Count() = 0' in events_screen_brs, "EventsScreen deve exibir vazio quando nao ha eventos resolvidos")
    check('m.top.tuneRequested = no.rawEvent.channelName' in events_screen_brs,
          "EventsScreen deve sintonizar pelo canal resolvido do jogo")
    check('HeroBanner' in events_screen_xml and 'PosterItem' in events_screen_xml,
          "EventsScreen deve usar HeroBanner e PosterItem")
    check('mostrarListas' in minhas_screen_brs, "MinhasListasScreen deve listar listas via mostrarListas")
    check('onPronto' in minhas_screen_brs, "MinhasListasScreen deve concluir tarefa via onPronto")
    check('m.top.listasMudaram = { canais: t.canais }' in minhas_screen_brs,
          "MinhasListasScreen deve emitir listasMudaram com canais")
    check('AjusteItem' in minhas_screen_xml, "MinhasListasScreen deve usar AjusteItem")
    check('observeField("listasMudaram", "onListasMudaram")' in main_brs,
          "MainScene deve observar listasMudaram de Minhas via onListasMudaram")
    check('observeField("tuneRequested", "onEventsTune")' in main_brs,
          "MainScene deve observar tuneRequested de Events via onEventsTune")
    check('function canalDoJogo(players as Object) as String' in main_brs,
          "MainScene deve implementar canalDoJogo")
    check('sub juntarEventos()' in main_brs, "MainScene deve implementar juntarEventos")
    check('task.responseEvents <> invalid' in main_brs and 'm.eventosCrus = task.responseEvents' in main_brs,
          "MainScene deve guardar eventos crus na entrega de events")
    check('m.cachedCatalogChannels = task.responseChannels' in main_brs,
          "MainScene deve manter canais do catalogo em faixa separada")
    check('m.cachedMinhasChannels' in main_brs, "MainScene deve manter canais de Minhas em faixa separada")

    stream_resolver_brs = read(APP / "components/tasks/StreamResolverTask.brs")
    stream_resolver_xml = read(APP / "components/tasks/StreamResolverTask.xml")
    player_screen_brs = read(APP / "components/screens/PlayerScreen.brs")
    player_screen_xml = read(APP / "components/screens/PlayerScreen.xml")
    player_osd_brs = read(APP / "components/views/PlayerOSD.brs")
    player_osd_xml = read(APP / "components/views/PlayerOSD.xml")

    check('field id="requestItem"' in stream_resolver_xml and 'field id="resolvedItem"' in stream_resolver_xml,
          "StreamResolverTask deve expor requestItem/resolvedItem")
    check('sub resolveStream()' in stream_resolver_brs and 'function getLetterGaveta' in stream_resolver_brs
          and 'function getIndiceBases' in stream_resolver_brs and 'function buildCandidateUrl' in stream_resolver_brs,
          "StreamResolverTask deve implementar resolução de streams")
    check('SaimoTV/2.6.0 (RokuOS)' in stream_resolver_brs,
          "StreamResolverTask deve manter constante UA 2.6.0")
    check('Instr(1, cand, "desativado.invalid")' in stream_resolver_brs,
          "StreamResolverTask deve descartar urls desativado.invalid")
    check('buildCandidateUrl' in stream_resolver_brs, "buildCandidateUrl ausente no resolver")
    check('field id="playItem" type="assocarray"' in player_screen_xml and 'field id="exitRequested"' in player_screen_xml,
          "PlayerScreen deve expor playItem/exitRequested")
    check('onPlayItemChange' in player_screen_brs and 'onStreamResolved' in player_screen_brs
          and 'playCandidate' in player_screen_brs and 'tryNextCandidate' in player_screen_brs
          and 'saveCurrentProgress' in player_screen_brs, "PlayerScreen deve implementar pipeline de candidatos")
    check('SaveVODProgress(' in player_screen_brs, "PlayerScreen deve salvar progresso via SaveVODProgress")
    check('nextEp = item.episode + 1' in player_screen_brs, "PlayerScreen deve avançar episódio automaticamente")
    check('ReadSaimoKey("userAgent")' in player_screen_brs, "PlayerScreen deve usar userAgent do storage")

    check('seekRequested' in player_osd_xml and 'FormatSecondsToTime' in player_osd_brs,
          "PlayerOSD deve buscar e formatar tempo via Format.brs")
    check('field id="exitRequested" type="boolean"' in player_screen_xml,
          "PlayerScreen deve expor exitRequested")
    check('node.playItem = params' in main_brs, "MainScene deve repassar playItem ao PlayerScreen")
    check('node.observeField("exitRequested", "onPlayerExitRequested")' in main_brs,
          "MainScene deve observar exitRequested")
    check('switchScreen("player", data)' in main_brs,
          "MainScene deve encaminhar playRequested direto ao player")
    check('sub onPlayerExitRequested()' in main_brs, "MainScene deve implementar onPlayerExitRequested")
    check('previousScreenName' in main_brs and 'previousScreenParams' in main_brs,
          "MainScene deve manter tela anterior para retorno do player")
    check('screenName = "guide" or screenName = "player"' in main_brs,
          "MainScene deve ocultar TopNav no player")

    ficha_screen_brs = read(APP / "components/screens/FichaScreen.brs")
    episode_item_brs = read(APP / "components/items/EpisodeItem.brs")
    settings_screen_brs = read(APP / "components/screens/SettingsScreen.brs")
    settings_screen_xml = read(APP / "components/screens/SettingsScreen.xml")

    check('carregarEpisodios' in ficha_screen_brs and 'montarTemporadas' in ficha_screen_brs
          and 'selecionarTemporada' in ficha_screen_brs,
          "FichaScreen deve implementar carregarEpisodios, montarTemporadas e selecionarTemporada")
    check('IsEpisodeWatched' in ficha_screen_brs and 'MarkWatched' in ficha_screen_brs
          and 'GetVODProgress' in ficha_screen_brs,
          "FichaScreen deve consultar assistidos e progresso")
    check('saimo_episodes' in main_brs, "MainScene deve acionar spawn de episodios saimo_episodes")
    check('onItemContentChange' in episode_item_brs and 'itemContent.hdPosterUrl' in episode_item_brs
          and 'itemContent.episodeNum' in episode_item_brs and 'focusBorder' in episode_item_brs,
          "EpisodeItem deve renderizar poster, numero e foco")

    check('populateSettings' in settings_screen_brs and 'addSettingItem' in settings_screen_brs
          and 'abrirCampo' in settings_screen_brs and 'testarUrls' in settings_screen_brs
          and 'limparCache' in settings_screen_brs and 'abrirSobre' in settings_screen_brs
          and 'formatBool' in settings_screen_brs,
          "SettingsScreen deve implementar metodos de ajustes")
    check('observeField("minhasListasRequested", "onSettingsMinhas")' in main_brs,
          "MainScene deve observar minhasListasRequested das configuracoes")
    check('reloadRequested' in settings_screen_brs and 'm.top.reloadRequested' in settings_screen_brs,
          "SettingsScreen deve disparar reloadRequested")
    check('epgUrl' not in settings_screen_brs and 'epgUrl' not in settings_screen_xml
          and 'epgUrl' not in readme,
          "epgUrl nao deve aparecer nas configuracoes nem no README")

    check('ConnectTask id="connectServer"' in main_xml_text,
          "MainScene.xml deve instanciar ConnectTask connectServer")
    check('m.connectServer = m.top.findNode("connectServer")' in main_brs,
          "MainScene deve resolver connectServer")
    check('observeField("receivedCommand", "onConnectCommand")' in main_brs,
          "MainScene deve observar receivedCommand")
    check('m.connectServer.control = "RUN"' in main_brs, "MainScene deve iniciar ConnectTask")
    check('sub onConnectCommand(evt as Object)' in main_brs, "MainScene deve implementar onConnectCommand")
    check('sub avisarCelular()' in main_brs, "MainScene deve implementar avisarCelular")
    check('avisarCelular()' in main_brs and main_brs.count('avisarCelular()') >= 2,
          "MainScene deve chamar avisarCelular no final de switchScreen")

    connect_task_brs = read(APP / "components/tasks/ConnectTask.brs")
    connect_task_xml = read(APP / "components/tasks/ConnectTask.xml")

    check('version: "2.6.0"' in connect_task_brs, "ConnectTask deve retornar version 2.6.0")
    check('app: "saimo-tv"' in connect_task_brs, "ConnectTask deve expor app saimo-tv")
    check('port = m.top.port' in connect_task_brs, "ConnectTask deve usar port do campo")
    check('listen(4)' in connect_task_brs, "ConnectTask deve escutar backlog 4")
    check('field id="receivedCommand"' in connect_task_xml, "ConnectTask deve expor receivedCommand")

    retired = ["seekHoldTimer", "failoverTimer", "onFailoverTimer", "playerLive", "seekHold", "failover", "progressFill"]
    combined_player = main_brs + player_screen_brs + player_screen_xml + player_osd_brs + player_osd_xml + stream_resolver_brs + stream_resolver_xml
    for token in retired:
        check(token not in combined_player, "Comportamento aposentado reintroduzido: " + token)
    parsed_xml: dict[Path, ET.Element] = {}
    for xml_file in sorted(APP.rglob("*.xml")):
        try:
            parsed_xml[xml_file] = ET.parse(xml_file).getroot()
            check(True, f"XML válido: {xml_file.relative_to(ROOT)}")
        except ET.ParseError as exc:
            check(False, f"XML inválido em {xml_file.relative_to(ROOT)}: {exc}")

    main_xml = parsed_xml.get(APP / "components/MainScene.xml")
    if main_xml is not None:
        node_ids = {node.attrib["id"] for node in main_xml.iter() if "id" in node.attrib}
        node_refs = set(re.findall(r'm\.top\.findNode\("([^" ]+)"\)', main_brs))
        missing_nodes = sorted(node_refs - node_ids)
        check(not missing_nodes, "MainScene.brs referencia IDs ausentes no XML: " + ", ".join(missing_nodes))

    for xml_file, xml_root in parsed_xml.items():
        for element in xml_root.iter():
            uri = element.attrib.get("uri", "")
            if uri.startswith("pkg:/"):
                target = APP / uri[len("pkg:/"):]
                check(target.is_file(), f"URI pkg:/ sem arquivo: {xml_file.relative_to(ROOT)} -> {uri}")

    check("handleHighlightsResult" not in main_brs and "loadMovieSources" not in main_brs,
          "Ainda existe referência ao antigo carregador VOD")
    check(not (APP / "session-3cfa976b-ad44-404c-bbe3-6157231feb43.md").exists(),
          "A transcrição da sessão não deve estar dentro do aplicativo")

    # E13 — AcervoTask (navegador do catálogo VOD)
    acervo_xml = read(APP / "components/tasks/AcervoTask.xml")
    acervo_brs = read(APP / "components/tasks/AcervoTask.brs")
    storage_brs = read(APP / "source/utils/Storage.brs")
    check('field id="baseUrl"' in acervo_xml, "AcervoTask deve expor baseUrl opcional")
    check('field id="error"' in acervo_xml, "AcervoTask deve expor o campo error")
    check('roku/indice.txt' in acervo_brs, "AcervoTask deve baixar o indice roku/indice.txt")
    check('LoadPreferences()' in acervo_brs and 'pkg:/source/utils/Storage.brs' in acervo_xml,
          "AcervoTask deve cair em LoadPreferences quando baseUrl esta vazio")
    check('normalizeSaimoBase(base)' in acervo_brs, "AcervoTask deve normalizar a base com normalizeSaimoBase")
    check('m.top.error' in acervo_brs, "AcervoTask deve reportar falha pelo campo error")

    check('function LoadPreferences() as Object' in storage_brs, "Storage deve expor o alias LoadPreferences")
    load_prefs = re.search(r"function LoadPreferences\(\) as Object.*?end function", storage_brs, re.S)
    check(load_prefs is not None and 'ReadSaimoKey("vodUrl")' in load_prefs.group(0),
          "LoadPreferences deve ler a chave vodUrl existente")
    registry_sections = set(re.findall(r'roRegistrySection",\s*"([^"]+)"', storage_brs))
    check(registry_sections == {"SaimoTV"}, "Storage deve abrir apenas a secao de registro SaimoTV")

    check('AcervoTask' in vod_screen_brs and 'm.chaves' in vod_screen_brs and 'totalDaCategoria' in vod_screen_brs,
          "VodScreen deve montar o indice do Acervo por categoria")
    check('carregarPerto' in vod_screen_brs and 'carregarPagina' in vod_screen_brs,
          "VodScreen deve carregar as paginas perto do foco")
    check('adaptarAcervo' in vod_screen_brs and 'isRestrictedVod(' in vod_screen_brs,
          "VodScreen deve adaptar os itens crus do Acervo e filtrar os restritos")
    check('itemType: "erro"' in vod_screen_brs and 'onLinhaFalha' in vod_screen_brs,
          "VodScreen deve expor a falha de pagina com retry")

    check('function parseAcervoIndice' in bslib and 'function parseAcervoPagina' in bslib,
          "Parsers puros do Acervo ausentes no bslib")
    check('testAcervoIndice' in tests and 'testAcervoPagina' in tests,
          "Suíte BRS deve registrar os testes do Acervo")

    # E14 — ArvoreCanaisTask (arvore do Ao vivo) + EPG
    arvore_xml = read(APP / "components/tasks/ArvoreCanaisTask.xml")
    arvore_brs = read(APP / "components/tasks/ArvoreCanaisTask.brs")
    live_xml = read(APP / "components/screens/LiveScreen.xml")
    live_brs = read(APP / "components/screens/LiveScreen.brs")
    drawer_xml = read(APP / "components/views/ChannelDrawer.xml")
    drawer_brs = read(APP / "components/views/ChannelDrawer.brs")

    check('field id="arvore" type="node" alwaysNotify="true"' in arvore_xml,
          "ArvoreCanaisTask deve expor o campo arvore como node alwaysNotify")
    check('field id="error"' in arvore_xml, "ArvoreCanaisTask deve expor o campo error")
    check('sub montar()' in arvore_brs and 'm.top.arvore = raiz' in arvore_brs,
          "ArvoreCanaisTask deve montar a arvore de secoes")
    check('m.top.error = "SemCanais"' in arvore_brs,
          "ArvoreCanaisTask deve recusar canais vazios com error SemCanais")

    check('sub montarArvore()' in main_brs, "MainScene deve implementar o fornecedor montarArvore")
    check('sub onArvorePronta(evt as Object)' in main_brs,
          "MainScene deve receber a arvore pronta em onArvorePronta")
    check('CreateObject("roSGNode", "ArvoreCanaisTask")' in main_brs,
          "MainScene deve criar a ArvoreCanaisTask")
    check('m.tarefaArvore.control = "STOP"' in main_brs,
          "MainScene deve cancelar a arvore em voo antes de recriar")
    check('m.currentScreenNode.arvore = m.arvoreCanais' in main_brs and 'node.arvore = m.arvoreCanais' in main_brs,
          "MainScene deve entregar a arvore em cache e na conclusao")
    check('startLoader("epg")' in main_brs, "MainScene deve pedir a grade no boot e na sincronizacao")

    check('field id="arvore"' in live_xml, "LiveScreen deve expor o campo arvore")
    check('sub onArvore()' in live_brs, "LiveScreen deve encaminhar a arvore ao drawer")
    check('channels[i].name = sel.name' in live_brs,
          "LiveScreen deve casar a selecao do drawer pelo nome do canal")
    check('m.channelDrawer.channels' not in live_brs,
          "LiveScreen nao deve passar a lista de canais ao drawer")

    check('field id="arvore"' in drawer_xml, "ChannelDrawer deve receber a arvore")
    check('field id="channels"' not in drawer_xml, "ChannelDrawer nao deve expor o campo channels")
    check('noDosFavoritos' in drawer_brs, "ChannelDrawer deve montar Favoritos em tempo de render")
    check('atualizarSecoes' in drawer_brs, "ChannelDrawer deve atualizar as secoes a partir da arvore")
    check('totalDeCanais' in drawer_brs, "ChannelDrawer deve contar os canais da arvore")
    check('canalEm(' in drawer_brs, "ChannelDrawer deve resolver o canal pelo indice da lista")

    # E15 — coerencia entre os dois epicos e pins de versao
    check((APP / "components/tasks/AcervoTask.xml").is_file()
          and (APP / "components/tasks/AcervoTask.brs").is_file()
          and (APP / "components/tasks/ArvoreCanaisTask.xml").is_file()
          and (APP / "components/tasks/ArvoreCanaisTask.brs").is_file(),
          "Os dois pares de tarefas novas devem estar presentes juntos")
    check('pkg:/components/tasks/AcervoTask.brs' in acervo_xml
          and 'pkg:/source/bslib.brs' in acervo_xml,
          "AcervoTask.xml deve registrar os scripts que usa")
    check('pkg:/components/tasks/ArvoreCanaisTask.brs' in arvore_xml,
          "ArvoreCanaisTask.xml deve registrar o proprio script")
    check('CreateObject("roSGNode", "AcervoTask")' in vod_screen_brs,
          "VodScreen deve instanciar a AcervoTask")
    check('CreateObject("roSGNode", "ArvoreCanaisTask")' in main_brs,
          "MainScene deve instanciar a ArvoreCanaisTask")
    check('m.top.error' in acervo_brs and 'm.top.error' in arvore_brs
          and 'field id="error"' in acervo_xml and 'field id="error"' in arvore_xml,
          "As duas tarefas devem expor e preencher o campo error")
    check(package.get("version") == "2.6.0"
          and lock.get("version") == "2.6.0"
          and (version_fields.get("major_version"), version_fields.get("minor_version"), version_fields.get("build_version")) == ("2", "6", "0")
          and 'SaimoTV/2.6.0 (RokuOS)' in stream_resolver_brs
          and 'version: "2.6.0"' in connect_task_brs
          and "2.6.0" in readme,
          "E15 deve manter a versao 2.6.0 nas fontes de versao")

    if ERRORS:
        print(f"FALHOU: {len(ERRORS)} problema(s) em {CHECKS} verificações.", file=sys.stderr)
        for error in ERRORS:
            print(f" - {error}", file=sys.stderr)
        return 1
    print(f"OK: {CHECKS} verificações passaram.")
    print("Estrutura, versão, XML, fontes canônicas, catálogo por letras, capas, cache, sincronização e testes coerentes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

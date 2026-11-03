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
        APP / "source/utils/LeitorM3u.brs",
        APP / "source/utils/Storage.brs",
        APP / "source/utils/Rows.brs",
        APP / "components/views/TopNavBar.xml",
        APP / "components/views/TopNavBar.brs",
        APP / "components/items/PosterItem.xml",
        APP / "components/items/PosterItem.brs",
        APP / "components/items/LetraItem.xml",
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
        APP / "components/views/ZapHUD.xml",
        APP / "components/views/ZapHUD.brs",
        APP / "components/views/PinModal.xml",
        APP / "components/views/PinModal.brs",
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
    check(package.get("version") == "2.5.17", "package.json deve apontar para 2.5.17")
    try:
        lock = json.loads(read(ROOT / "package-lock.json"))
    except json.JSONDecodeError:
        lock = {}
    check(lock.get("version") == "2.5.17" and lock.get("packages", {}).get("", {}).get("version") == "2.5.17",
          "package-lock.json deve apontar para 2.5.17")
    check(package.get("scripts", {}).get("test") == "python3 tools/test_parsers.py",
          "package.json deve expor npm test para a suíte de parsers")
    check("brighterscript" in package.get("devDependencies", {}), "Dependência brighterscript ausente")
    check("brs" in package.get("devDependencies", {}), "Dependência brs ausente")
    check(config.get("rootDir") == "SaimoTV", "bsconfig.json deve usar SaimoTV como rootDir")

    manifest = read(APP / "manifest")
    version_fields = dict(line.split("=", 1) for line in manifest.splitlines() if "=" in line)
    check((version_fields.get("major_version"), version_fields.get("minor_version"), version_fields.get("build_version")) == ("2", "5", "17"),
          "Versão do manifest não corresponde a 2.5.17")
    check("ui_resolutions=fhd" in manifest, "Resolução FHD do manifest deve permanecer definida")

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

    check("2.5.17" in readme and "sob demanda" in readme,
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

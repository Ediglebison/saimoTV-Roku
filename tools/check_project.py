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
        APP / "components/VodCard.xml",
        APP / "components/VodCard.brs",
        APP / "components/EpisodeCard.xml",
        APP / "components/EpisodeCard.brs",
        APP / "components/FetchTask.xml",
        APP / "components/FetchTask.brs",
        APP / "components/EpgTask.xml",
        APP / "components/EpgTask.brs",
        APP / "components/ActionPill.xml",
        APP / "components/ActionPill.brs",
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
    check(package.get("version") == "2.5.12", "package.json deve apontar para 2.5.12")
    try:
        lock = json.loads(read(ROOT / "package-lock.json"))
    except json.JSONDecodeError:
        lock = {}
    check(lock.get("version") == "2.5.12" and lock.get("packages", {}).get("", {}).get("version") == "2.5.12",
          "package-lock.json deve apontar para 2.5.12")
    check(package.get("scripts", {}).get("test") == "python3 tools/test_parsers.py",
          "package.json deve expor npm test para a suíte de parsers")
    check("brighterscript" in package.get("devDependencies", {}), "Dependência brighterscript ausente")
    check("brs" in package.get("devDependencies", {}), "Dependência brs ausente")
    check(config.get("rootDir") == "SaimoTV", "bsconfig.json deve usar SaimoTV como rootDir")

    manifest = read(APP / "manifest")
    version_fields = dict(line.split("=", 1) for line in manifest.splitlines() if "=" in line)
    check((version_fields.get("major_version"), version_fields.get("minor_version"), version_fields.get("build_version")) == ("2", "5", "12"),
          "Versão do manifest não corresponde a 2.5.12")
    check("ui_resolutions=fhd" in manifest, "Resolução FHD do manifest deve permanecer definida")

    main_brs = read(APP / "components/MainScene.brs")
    main_xml_text = read(APP / "components/MainScene.xml")
    fetch_brs = read(APP / "components/FetchTask.brs")
    fetch_xml = read(APP / "components/FetchTask.xml")
    bslib = read(APP / "source/bslib.brs")
    check('function readCacheAscii(path as string)' in bslib and 'fs.Exists(path)' in bslib
          and 'readCacheAscii("cachefs:/' in main_brs and 'readCacheAscii("cachefs:/' in fetch_brs,
          "Leituras de cache devem verificar a existência dos arquivos antes de abrir")
    readme = read(ROOT / "README.md")
    tests = read(ROOT / "tools/tests/parsers_test.brs")

    check('https://saimo-canais.pages.dev/catalogo.txt' in main_brs, "URL padrão canônica dos canais ausente")
    check('https://saimo-filmes.pages.dev/' in main_brs, "URL padrão canônica do VOD ausente")
    check('Instr(1, lowVod, "filmes-saimo.pages.dev") > 0' in main_brs
          and 'Instr(1, lowVod, "saimoplayer/main/vod") > 0' in main_brs,
          "Migração dos endereços antigos do VOD ausente")
    check('Instr(1, lowPlaylist, "canais-saimo.pages.dev") > 0' in main_brs,
          "Migração do endereço antigo dos canais ausente")
    check('isSaimoVodUrl(m.vodUrl)' in main_brs and 'isSaimoCatalogUrl' in bslib,
          "Detecção das fontes Saimo ausente")
    check('m.vodUrl = readSetting("vodUrl")' in main_brs, "URL independente do catálogo VOD ausente")
    check('startFetch("saimo_index"' in main_brs and 'mode = "saimo_index"' in fetch_brs,
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

    check('id="vodGrid"' in main_xml_text and 'itemSelected", "onVodItemSelected"' in main_brs,
          "Grade de pôsteres não conectada ao handler")
    vod_card_xml = read(APP / "components/VodCard.xml")
    vod_card_brs = read(APP / "components/VodCard.brs")
    check('itemComponentName="VodCard"' in main_xml_text and 'itemSize="[210, 362]"' in main_xml_text
          and 'numColumns="6"' in main_xml_text and 'm.vodGrid.numColumns = 6' in main_brs,
          "Catálogo deve usar cartões próprios em seis colunas")
    check('id="poster"' in vod_card_xml and 'itemHasFocus' in vod_card_brs
          and 'sub showItem()' in vod_card_brs and 'loadPoster()' in vod_card_brs
          and 'sub loadPoster()' in vod_card_brs and 'pkg:/images/placeholder.png' in vod_card_brs,
          "Pôsteres do catálogo devem começar a carregar ao renderizar cada card")
    check('id="appBg"' in main_xml_text and 'uri="pkg:/images/bg_app.png"' in main_xml_text
          and 'id="sidebarBg"' in main_xml_text and 'uri="pkg:/images/bg_sidebar.png"' in main_xml_text,
          "Fundos da identidade visual 2.5.2 ausentes")
    check('id="logo"' in main_xml_text and 'uri="pkg:/images/logo.png"' in main_xml_text,
          "Logotipo oficial Saimo ausente na barra lateral")
    check('id="clock"' in main_xml_text and 'id="syncHint"' in main_xml_text
          and "sub updateClock()" in main_brs and "sub updateSyncHint()" in main_brs,
          "Relógio/indicador de sincronização ausentes")
    preview_tokens = ("previewPanel", "previewPoster", "previewBackdrop", "previewBadge",
                      "previewTitle", "previewMeta", "previewDesc", "previewCta",
                      "clearPreview", "previewEntry", "previewChannel", "previewMovie",
                      "setPreviewBadge", "setPreviewCta", "showPreviewBackdrop",
                      "hidePreviewBackdrop", "onPreviewPosterLoadStatus")
    preview_leftovers = [token for token in preview_tokens if token in main_brs or token in main_xml_text]
    check(not preview_leftovers,
          "Trilho de prévia (B9) deve estar ausente do XML/BRS, sem referências órfãs: "
          + ", ".join(preview_leftovers))
    check('id="playerLive"' in main_xml_text and 'id="toastAccent"' in main_xml_text
          and "m.playerLive.visible = m.currentIsLive" in main_brs,
          "Sobreposição do player/toast 2.5.2 incompleta")
    check('focusBitmapUri="pkg:/images/nav_focus.png"' in main_xml_text
          and 'HDListItemIconUrl' in main_brs, "Navegação com pílula de foco/ícones ausente")
    check('numColumns="6"' in main_xml_text and "m.vodGrid.numColumns = 6" in main_brs,
          "Catálogo completo deve usar seis colunas")
    check('id="shelfList"' in main_xml_text and 'itemComponentName="ShelfCard"' in main_xml_text
          and "sub showSaimoShelves" in main_brs
          and 'if type(parsed.shelves) = "roArray" then m.saimoShelves = parsed.shelves' in main_brs,
          "Tela Descobrir deve manter suas fileiras editoriais")
    check('if k = "left" and m.shelfList.hasFocus() then' in main_brs
          and 'focus[1] = 0 then' in main_brs,
          "Navegação horizontal das fileiras deve manter o foco entre capas")
    check("sub onShelfItemFocused()" in main_brs
          and "m.listTitle.text = title" in main_brs
          and "m.listSub.text = saimoItemSubtitle(entry)" in main_brs,
          "Foco das fileiras deve atualizar o herói textual (título e metadados)")
    check("focusScale = 1.0" in read(APP / "components/ShelfCard.brs"),
          "Cartões das fileiras devem destacar o foco sem ampliar a capa")
    episode_xml = read(APP / "components/EpisodeCard.xml")
    episode_brs = read(APP / "components/EpisodeCard.brs")
    check('id="episodeGrid"' in main_xml_text and 'itemComponentName="EpisodeCard"' in main_xml_text
          and 'itemSize="[396, 310]"' in main_xml_text,
          "Episódios devem usar cartões 396x310 com componente próprio")
    check('sub buildEpisodeGrid(items as object)' in main_brs
          and 'node.episodeSynopsis = synopsis' in main_brs
          and 'm.episodeGrid.setFocus(true)' in main_brs,
          "Grade de episódios deve informar título, número e sinopse")
    check('m.video.control = "resume"' in main_brs
          and 'm.video.control = "play"' in main_brs,
          "Retomada deve preservar a posição atual e play iniciar novas fontes")
    check('sub focusListOrNav()' in main_brs
          and 'if m.activeView = "vod_episodes" or m.activeView = "saimo_episodes" then' in main_brs
          and 'm.episodeGrid.setFocus(true)' in main_brs,
          "Ao fechar o player, o foco deve voltar à lista de episódios")
    check('if m.pendingSaimoLetter <> "" then' in main_brs
          and 'kind <> "saimo_letter" and m.pendingSaimoLetter' not in main_brs,
          "Atualizacao de capas nao deve perder a letra pendente durante carregamento do catalogo")
    check('id="tmdbId"' not in fetch_xml
          and 'enrichSaimoEpisodes' not in fetch_brs
          and '/api/tmdb/tv/' not in fetch_brs,
          "Episódios não devem enriquecer por Worker TMDB (contrato de dados preservado)")
    check('id="poster"' in episode_xml and 'id="episodeCode"' in episode_xml
          and 'id="synopsis"' in episode_xml and 'sub updateFocus()' in episode_brs
          and 'sub showItem()' in episode_brs and 'loadPoster()' in episode_brs,
          "Cartão de episódio deve carregar a arte ao renderizar, além do foco personalizado")
    check('id="playerSpinner"' in main_xml_text and 'id="playerAutoHideTimer"' in main_xml_text
          and 'uri="pkg:/images/player_veil_top.png"' in main_xml_text,
          "Player deve usar spinner, auto-hide e gradientes")
    check('id="toastIcon"' in main_xml_text and "sub showToastType" in main_brs,
          "Toasts devem diferenciar estados semânticos")
    check('id="emptyIcon"' in main_xml_text and 'id="emptyAction"' in main_xml_text,
          "Estado vazio deve incluir ícone e uma ação")
    action_xml = read(APP / "components/ActionPill.xml")
    action_brs = read(APP / "components/ActionPill.brs")
    chip_xml = read(APP / "components/SeasonChip.xml")
    group_start = main_xml_text.find('<Group id="vodDetailGroup"')
    group_open = ""
    if group_start >= 0:
        group_open = main_xml_text[group_start:main_xml_text.find(">", group_start) + 1]
    check('translation="[400, 0]"' in group_open,
          "vodDetailGroup deve começar na área de conteúdo (translation [400, 0])")
    check('id="fichaBackdrop"' in main_xml_text and 'id="fichaVeilSide"' in main_xml_text
          and 'id="fichaVeilBottom"' in main_xml_text
          and 'uri="pkg:/images/ficha_veil_side.png"' in main_xml_text
          and 'uri="pkg:/images/ficha_veil_bottom.png"' in main_xml_text,
          "Ficha deve usar backdrop próprio e os dois véus PNG")
    check('id="vodDetailTipo"' in main_xml_text and 'id="vodDetailFrase"' in main_xml_text
          and 'm.vodDetailTipo.text' in main_brs and 'm.vodDetailFrase.text' in main_brs,
          "Tipo e frase da ficha devem existir no XML e ser preenchidos")
    check('itemComponentName="ActionPill"' in main_xml_text
          and 'sub showItem()' in action_brs and 'sub updateFocus()' in action_brs
          and 'action_pill_normal.png' in action_xml and 'action_pill_focus.png' in action_xml
          and 'm.pillFocus.opacity' in action_brs and 'm.pillLabel.color' in action_brs,
          "Ações da ficha devem usar ActionPill com inversão de foco")
    check('sub showFichaBackdrop(cover as string)' in main_brs
          and main_brs.count("showFichaBackdrop(") >= 2,
          "As telas de ficha devem compartilhar showFichaBackdrop")
    check('node.addFields({ kind: entry.kind })' in main_brs,
          "Ações da ficha devem carregar title e kind no node emitido")
    check('id="episodeNumber"' in episode_xml and 'uri="pkg:/images/focus_episode.png"' in episode_xml
          and 'm.focusHalo.opacity = m.top.focusPercent' in episode_brs,
          "Cartão de episódio deve ter numeral, thumb 16:9 e foco interpolado")
    check('uri="pkg:/images/focus_chip.png"' in chip_xml and 'chipEdge' not in chip_xml,
          "Chip de temporada deve usar o bitmap de foco no lugar da borda retangular")
    check('node.episodeArt =' in main_brs and 'node.episodeNumber =' in main_brs,
          "Grade de episódios deve emitir arte e numeral para cada card")
    check('uri="pkg:/fonts/Roboto-Regular.ttf"' in main_xml_text
          and 'uri="pkg:/fonts/Roboto-Medium.ttf"' in main_xml_text
          and 'uri="pkg:/fonts/Roboto-Bold.ttf"' in main_xml_text
          and 'uri="pkg:/fonts/Roboto-Italic.ttf"' in main_xml_text,
          "Papéis tipográficos Roboto devem estar definidos na cena")
    check((APP / "fonts/Roboto-LICENSE.txt").is_file()
          and (APP / "fonts/Roboto-Regular.ttf").is_file()
          and (APP / "fonts/Roboto-Medium.ttf").is_file()
          and (APP / "fonts/Roboto-Bold.ttf").is_file()
          and (APP / "fonts/Roboto-Black.ttf").is_file()
          and (APP / "fonts/Roboto-Italic.ttf").is_file()
          and not (APP / "fonts/OFL.txt").exists()
          and not any((APP / "fonts").glob("Inter-*.ttf")),
          "Fontes Roboto e licença devem estar empacotadas sem Inter/OFL")
    inter_xml = [path for path in sorted(APP.rglob("*.xml")) if "Inter-" in read(path)]
    check(not inter_xml,
          "Nenhuma uri Inter pode restar em XML: " + ", ".join(str(path.relative_to(ROOT)) for path in inter_xml))
    check('kind: "saimo_letter"' in main_brs
          and "sub loadSaimoLetter(letter as string)" in main_brs
          and "preview" not in main_brs,
          "Catálogo por letras deve abrir a letra via loadSaimoLetter sem trilho de prévia")
    check('id="title"' in vod_card_xml and 'id="meta"' in vod_card_xml
          and 'maxLines="1"' in vod_card_xml,
          "Cartões do catálogo devem exibir título e metadados em linhas compactas")
    check('numRows="12"' in main_xml_text, "A lista de ajustes não exibe as 12 opções configuradas")

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
    check("function foldText" in bslib and "Instr(1, foldText(title), q) > 0" in bslib,
          "Busca sem acento ausente")

    check('mode = "saimo_letter"' in fetch_brs and "loadSaimoLetter" in fetch_brs,
          "Carregamento de uma letra por vez ausente")
    check('saimoLetterCachePath(filter, letter)' in fetch_brs
          and 'saimoLetterCacheMarker(base, m.top.signature)' in fetch_brs,
          "Cache por letra/assinatura ausente na tarefa")
    check("applySaimoArtwork(items, fichas, fallbackCovers)" in fetch_brs,
          "Capas e gêneros devem ser aplicados dentro da FetchTask")
    check("function isStringValue(value as dynamic) as boolean" in bslib
          and "not isStringValue(fichas)" in fetch_brs,
          "A resposta de fichas deve aceitar strings do Roku e do simulador")
    check('readCacheAscii("cachefs:/saimo_vod_fichas.txt")' not in main_brs,
          "fichas.txt não deve ser lido na linha principal")
    check('WriteAsciiFile("cachefs:/saimo_vod_fichas.ready", "1")' in fetch_brs
          and 'readCacheAscii("cachefs:/saimo_vod_fichas.ready")' in fetch_brs
          and 'httpGet(base + "fichas.txt"' in fetch_brs
          and 'startSaimoArtworkFetch(base)' not in main_brs,
          "Fichas completas devem ser carregadas sob demanda em segundo plano")
    check("invalidateSaimoDerivedCaches()" in main_brs
          and 'DeleteFile("cachefs:/saimo_vod_letters.url")' in main_brs
          and 'DeleteFile("cachefs:/saimo_vod_search.txt")' in main_brs,
          "Caches derivados não são invalidados quando o índice muda")
    check("if indexChanged then invalidateSaimoDerivedCaches()" in main_brs,
          "Mudança de índice não dispara limpeza dos caches derivados")
    check('saimoLetterCacheMarker(saimoBaseUrl(m.vodUrl), m.saimoIndexSignature)' in main_brs,
          "Leitura do cache por letra não valida a assinatura atual")

    check('field id="signature" type="string"' in fetch_xml and "task.signature = signature" in main_brs,
          "Assinatura do índice não é repassada à FetchTask")
    check("function isSaimoSeriesKind" in bslib and 'k = "s" or k = "d" or k = "a"' in bslib,
          "Destaques/busca devem tratar s, d e a como séries")
    check("if m.currentIsLive then" in main_brs and 'pausa indisponível' in main_brs,
          "Transmissão ao vivo não deve permitir pausa")
    check('Ao vivo: busca indisponível' in main_brs, "Transmissão ao vivo não deve permitir busca")
    check("if m.currentIsLive then\n        m.progressFill.width = 0" in main_brs,
          "Barra de progresso deve ficar desativada no ao vivo")
    check("not m.saimoIndexLoaded and (m.activeView" in main_brs,
          "Atualizações em segundo plano devem preservar a tela atual")
    check("hadGridFocus = m.vodGrid.hasFocus()" in main_brs
          and "if not hadGridFocus then m.navList.setFocus(true)" in main_brs,
          "Atualização do índice deve preservar o foco do usuário")

    check('"destaques.txt"' in fetch_brs and "parseHighlights(highlights.body)" in fetch_brs,
          "Destaques VOD da fonte pública não são carregados")
    check('sub showSaimoHome(filter as string)' in main_brs and 'value: "discover"' in main_brs,
          "Tela de destaques não está conectada à navegação")
    check('"busca.txt"' in fetch_brs and '"fichas.txt"' in fetch_brs,
          "Busca e capas completas não usam os fragmentos esperados")
    check('"indice.txt"' in fetch_brs and '"filmes-" + fileLetter' in fetch_brs
          and '"series-" + fileLetter' in fetch_brs, "Fragmentos do catálogo não são montados por letra")
    check('w7.embedtv.cc' not in bslib and 'dadinhodetapioca.fun' not in bslib and 'embedplayer2.xyz' not in bslib,
          "Há cabeçalhos/referers específicos de serviços de terceiros embutidos")

    check("TESTS_PASS" in tests and "testMovieParser" in tests and "testEpisodeParser" in tests
          and "saimoGridSubtitle" in tests,
          "Suíte BRS de parsers incompleta")
    test_runner = read(ROOT / "tools/test_parsers.py")
    check("TESTS_FAILED" in test_runner and "TESTS_PASS" in test_runner,
          "O runner de testes deve falhar quando TESTS_FAILED for emitido")

    check("2.5.12" in readme and "sob demanda" in readme,
          "README precisa documentar a versão 2.5.12 e o carregamento sob demanda")
    check("identidade visual" in readme.lower() or "interface" in readme.lower(),
          "README precisa documentar a renovação visual")
    check("Roboto" in readme and "SaimoTV/fonts" in readme,
          "README precisa documentar a tipografia Roboto e a pasta de fontes")
    check("saimo-filmes.pages.dev" in readme and "saimo-canais.pages.dev" in readme,
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

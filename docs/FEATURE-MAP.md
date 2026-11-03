# Feature Map

> Auto-maintained index of every user-facing feature and the code path that implements it. Updated alongside the code — not after the fact.

## App Startup

Launching the channel creates the SceneGraph scene, restores settings and favorites, shows cached content, and starts background sync timers.

**Flow:**

1. `SaimoTV/manifest` — supplies the channel title, version 2.6.0, icon, splash, and FHD resolution.
2. `SaimoTV/source/main.brs` — creates `roSGScreen`, opens `MainScene`, and waits for the screen to close.
3. `SaimoTV/components/MainScene.xml` — defines the layout, video node, and 15-minute refresh timer.
   - The scene defines Roboto Regular, Medium, Italic, Bold, and Black font roles from bundled Apache License 2.0 assets under `SaimoTV/fonts/`.
4. `SaimoTV/components/MainScene.brs` — `init` reads registry settings, applies canonical URL defaults, loads favorites and cached content, starts timers and scheduled sync, and loads EPG when configured.
5. `SaimoTV/source/bslib.brs` — provides URL detection, cache signatures, and parser helpers used during restoration.
6. `SaimoTV/components/tasks/DataLoaderTask.brs` — performs the first background playlist or catalog refresh when a cached source is stale.

---

## Live TV Browsing

The user browses live channels by category, sees the channel list with status, and selects a channel to watch.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `(legacy)` reads the cached playlist before any network call.
2. `SaimoTV/components/tasks/DataLoaderTask.brs` — `(legacy)` downloads the configured channel list.
3. `SaimoTV/source/bslib.brs` — `parsePlaylist` selects `parseCustom` or `parseM3u` and returns normalized channels.
4. `SaimoTV/components/MainScene.brs` — `(legacy)` applies the channels, saves the cache, and records the sync time.
5. `SaimoTV/components/MainScene.brs` — `(legacy)`, `(legacy)`, `buildNav`, and `(legacy)` build the category navigation and channel rows.
6. `SaimoTV/components/MainScene.brs` — `(legacy)` updates the header, counts, and empty state; `onItemSelected` starts playback.

---

## Live TV Playback

Live channels open in the full-screen player, with multiple sources tried in order and no pause or seek controls. The player uses gradient veils, a loading spinner, a paused state, and a three-second control overlay timeout.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `onItemSelected` sends the selected channel to `playChannel`.
2. `SaimoTV/components/MainScene.brs` — `playChannel` initializes the source list, live flag, overlay, and player text.
3. `SaimoTV/components/MainScene.brs` — `(legacy)` builds the Roku `ContentNode`, applies headers and stream format, and starts the `Video` node.
4. `SaimoTV/source/bslib.brs` — `buildVideoHeaders` adds only the source-declared referer and user agent.
5. `SaimoTV/components/MainScene.brs` — `onVideoState`, `(legacy)`, and `(legacy)` try the next source after an error or timeout; live playback rejects pause and seek.

---

## Discover Highlights

The Discover view preserves the editorial shelves from the Saimo index and opens the matching catalog letter.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `buildNav` and `onNavSelected` route the Discover entry to `openVodHome("all")`.
2. `SaimoTV/components/MainScene.brs` — `showSaimoHome` renders cached highlights or falls back to the letter list.
3. `SaimoTV/components/tasks/DataLoaderTask.brs` — `(legacy)` downloads `destaques.txt` and parses its shelves; `MainScene.brs` preserves them in fresh downloads and cache restores before showing the `RowList`.
4. `SaimoTV/source/bslib.brs` — `parseHighlights` and `pickSaimoHighlights` normalize, filter, and mix the shelf entries.
5. `SaimoTV/components/MainScene.brs` — `handleSaimoIndexResult` stores the highlights and artwork.
6. `SaimoTV/components/tasks/DataLoaderTask.brs` — returns both the flattened compatibility list and the original shelf groups.
7. `SaimoTV/components/MainScene.brs` — `(legacy)`, `(legacy)`, and `(legacy)` render and navigate the shelf rows; the focused title updates the top hero, poster, backdrop, and metadata.
8. `SaimoTV/components/items/PosterItem.xml` — renders each poster and its focus state.
9. `SaimoTV/components/MainScene.brs` — horizontal shelf movement stays within the row; left enters the sidebar only from the first card.

---

## VOD Catalog Browsing

The user browses the Saimo catalog by letter, sees six-column poster grids, and drills into the cinematic detail view with 396x310 episode cards. Authorized M3U catalogs use a separate branch.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `onNavSelected` and `openVod` route the A–Z, Movies, and Series entries.
2. `SaimoTV/components/MainScene.brs` — `(legacy)` restores the cached index; `(legacy)` builds the letter list.
3. `SaimoTV/components/tasks/DataLoaderTask.brs` — `(legacy)` downloads `indice.txt` and `destaques.txt`.
4. `SaimoTV/source/bslib.brs` — `parseSaimoIndexLetters` and `parseBases` parse letter counts and video bases.
5. `SaimoTV/components/MainScene.brs` — `handleSaimoIndexResult` stores the index, detects signature changes, and invalidates derived caches.
6. `SaimoTV/components/MainScene.brs` — `(legacy)` shows a cached letter immediately and starts a `saimo_letter` task.
7. `SaimoTV/components/tasks/DataLoaderTask.brs` — `(legacy)` downloads the requested letter and loads full artwork fichas only when the catalog is opened.
8. `SaimoTV/source/bslib.brs` — `parseSaimoMovieItems`, `parseSaimoSeriesItems`, `applySaimoArtwork`, and `sortSaimoItems` produce the sorted grid items.
9. `SaimoTV/components/MainScene.brs` — `handleSaimoLetterResult`, `showSaimoGrid`, and `buildVodGrid` render the six-column poster grid.
10. `SaimoTV/components/MainScene.brs` — `(legacy)` starts the episode task and `handleSaimoEpisodesResult` receives the result.
11. `SaimoTV/components/tasks/DataLoaderTask.brs` — `(legacy)` downloads the selected series fragment.
12. `SaimoTV/source/bslib.brs` — `parseSaimoEpisodeItems` groups and sorts the episode sources.
13. `SaimoTV/components/MainScene.brs` — `onVodItemSelected` opens a movie detail screen or a series detail screen; series details group episodes by season and keep the 396x310 episode grid beside the selector.
14. `SaimoTV/components/MainScene.brs` — `updateVodDetailContent`, `showFichaBackdrop`, `vodDetailTypeLabel`, `vodDetailsMeta`, `vodDetailFrase`, and `renderVodDetailActions` show the backdrop with veils, type label, frase, metadata, synopsis, and the horizontal action pills (play, favorite, seasons) tagged with `kind`.
15. `SaimoTV/components/MainScene.brs` — `showSeriesDetails`, `buildSeriesSeasonList`, and `onSeriesSeasonFocused` filter episodes as the season selector moves; directional key handling links the action pills, seasons, episode grid, and sidebar.
16. `SaimoTV/components/items/PosterItem.xml` — renders each poster card and its focus state in the catalog, Discover, and favorites grids.
17. `SaimoTV/components/items/EpisodeItem.xml` — renders each season chip in the series season selector.
18. `SaimoTV/components/items/EpisodeItem.xml` — renders each 396x310 episode card beside the season selector, with a 16:9 thumbnail, episode-number fallback art, code badge, title, and meta.
19. `SaimoTV/components/items/AjusteItem.xml` — renders each detail action button and its focus overlay.

**Branch — M3U VOD:**

1. `SaimoTV/components/MainScene.brs` — `refreshVodCatalog` sends a non-Saimo source to the `vod_catalog` task.
2. `SaimoTV/components/tasks/DataLoaderTask.brs` — `(legacy)` downloads the M3U/M3U8 text.
3. `SaimoTV/source/bslib.brs` — `parseVodM3u` groups series episodes and filters invalid entries.
4. `SaimoTV/components/MainScene.brs` — `handleVodCatalogResult` and `showVod` render the resulting grid.

---

## VOD Playback

Films and episodes play from the selected source. Series selections open episode lists before playback.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `onVodItemSelected` sends films and episodes to `playVodEntry`; series go to episode loading.
2. `SaimoTV/components/MainScene.brs` — `playVodEntry` converts the catalog item into a player channel with `isLive` false.
3. `SaimoTV/components/MainScene.brs` — `playChannel` and `(legacy)` load the first source into the `Video` node.
4. `SaimoTV/source/bslib.brs` — `streamFormatFor` and `buildVideoHeaders` prepare format and HTTP headers.
5. `SaimoTV/components/MainScene.brs` — `onVideoState` handles pause, resume with position preservation, seek, progress, completion, and source failover.
6. `SaimoTV/components/MainScene.brs` — `onKeyEvent` handles `play`, `pause`, and `playpause` through `togglePlayback`, plus accelerated seek while holding `left`, `right`, `rev`, or `fwd`.

---

## Search

Search covers live channels and the VOD catalog. The public catalog path uses an accent-insensitive in-memory search index.

**Flow:**

1. `SaimoTV/components/screens/SearchScreen.brs` — opens the SearchScreen and calls `carregarIndice` to load the in-memory index from `cachefs:/saimo_search_index.json`.
2. `SaimoTV/components/screens/SearchScreen.brs` — local search calls `searchSaimoIndex(m.searchIndex, query, 160)` and shows instant in-memory results; `agendarBusca` schedules remote fetch with a 0.3 s `buscaTimer` debounce only when the index is missing or stale.
3. `SaimoTV/components/tasks/DataLoaderTask.brs` — the `saimo_search_index` mode downloads `busca.txt`, rebuilds the normalized index, and stores it under `cachefs:/saimo_search_index.json`; the freshness gate keeps it fresh for 24 h.
4. `SaimoTV/source/bslib.brs` — `buildSaimoSearchIndex` folds accents once; `searchSaimoIndex` is a plain `Instr` over pre-normalized titles (limit 160) and filters restricted titles.
5. `SaimoTV/components/screens/SearchScreen.brs` — selection routes to `openFicha` or `tuneChannel`.
6. `SaimoTV/components/MainScene.brs` — scheduled sync spawns the `saimo_search_index` task in the background chain every 15 minutes when the cache is older than 6 hours.

---

## Favorites

Live channel favorites remain separate from movie and series favorites. VOD favorites have a dedicated navigation entry and persist in the device registry.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `init` calls `loadFavorites`, which reads the `favorites` registry entry.
2. `SaimoTV/components/MainScene.brs` — `onKeyEvent` maps Options, Info, and `*` to `toggleFavorite`.
3. `SaimoTV/components/MainScene.brs` — `toggleFavorite` updates the title list and `saveFavorites` writes it back as JSON.
4. `SaimoTV/components/MainScene.brs` — `renderEntries` prefixes favorite channels with `★`; `onItemSelected` keeps the list state in sync.
5. `SaimoTV/components/MainScene.brs` — `toggleVodFavorite` stores/removes films and series by normalized type, title, and year; `saveVodFavorites` writes the VOD list to the registry.
6. `SaimoTV/components/MainScene.brs` — `buildNav`, `showVodFavorites`, and `onVodItemSelected` expose the Favoritos tab and open saved titles through the same details flow.

---

## Settings

Settings edits channel, VOD, EPG, and HTTP settings, and provides refresh, cache, test, and About actions.

**Flow:**

1. `SaimoTV/components/screens/SettingsScreen.brs` — displays settings rows for playlist URL, VOD URL, user agent, audio preferences, cache, and About.
2. `SaimoTV/components/screens/SettingsScreen.xml` — defines the settings title, version 2.6.0 subtitle, MarkupList, and keyboard editing panel.
3. `SaimoTV/components/screens/SettingsScreen.brs` — `onSettingSelected` routes editable URLs to `abrirCampo`, toggles audio preferences, and triggers tests, cache clearing, and About.
4. `SaimoTV/components/MainScene.brs` — `onSettingsReload` refreshes channels and VOD catalog after edits or cache clearing.
5. `SaimoTV/components/screens/SettingsScreen.brs` — uses `ReadSaimoKey`/`WriteSaimoKey` for `playlistUrl`, `vodUrl`, `userAgent`, and `prefs`; the `epgUrl` registry key remains a legacy compatibility read and is not a Settings item.
6. `SaimoTV/components/screens/SettingsScreen.brs` — `limparCache` deletes derived caches and `vod_progress`, resets sync markers to 0, and sets `reloadRequested`.

---

## Automatic Sync and Cache

The app checks for updates every 15 minutes, downloads only when the cache is older than six hours, and preserves content on failure.

**Flow:**

1. `SaimoTV/components/MainScene.xml` — `vodRefreshTimer` fires every 900 seconds.
2. `SaimoTV/components/MainScene.brs` — `onVodRefreshTimer` calls `runScheduledSync`; `isSyncStale` applies the 21,600-second threshold.
3. `SaimoTV/components/MainScene.brs` — `refreshPlaylist` and `refreshVodCatalog` start the appropriate background task without changing the active screen.
4. `SaimoTV/components/tasks/DataLoaderTask.brs` — `(legacy)`, `(legacy)`, `(legacy)`, and `(legacy)` write raw and derived data under `cachefs:`; full artwork fichas load on catalog demand.
5. `SaimoTV/components/MainScene.brs` — result handlers update in-memory state and registry sync times; failures keep the existing cache.
6. `SaimoTV/components/MainScene.brs` — `(legacy)`, `(legacy)`, and `(legacy)` restore cached data on the next start.
7. `SaimoTV/components/MainScene.brs` — `invalidateSaimoDerivedCaches` clears letter and search caches when the index signature changes.
8. `SaimoTV/source/bslib.brs` — `saimoIndexSignature`, `saimoLetterCacheMarker`, and `saimoLetterCachePath` define cache validity and filenames.

---

## TV Guide

The TV guide lists loaded channels with the current and next programme from an optional XMLTV feed, including current-programme progress. Live channel rows also show programme progress and now/next details when available.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `switchScreen("guide")` via the live channel's guide entry; injects `channels` + `epgMap`.
2. `SaimoTV/components/screens/GuideScreen.brs` — lazy paging (50 + 40), schedule rendering, `tuneRequested`.
3. `SaimoTV/components/tasks/DataLoaderTask.brs` — `fetchEpg` (guia.txt from `saimo-canais.pages.dev`) + meuguia scraping, `cachefs:` cache with 6 h staleness per E2, no `epgUrl` setting.
4. `SaimoTV/components/tasks/StreamResolverTask.brs` is not used by Guide.
5. Guide state: guide opened from Live via `switchScreen("guide")` and returns to the live entry without leaving the top-nav contract.


---

## Toast Feedback

Toasts use distinct success, error, and information colors with a matching icon.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `showToast` defaults to information; `showToastType` selects the semantic style.
2. `SaimoTV/components/MainScene.xml` — `toastIcon`, `toastAccent`, and `toastBg` render the feedback state.

---

## About

The About panel identifies the unofficial client and lists its features and limitations.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `openSettings` and `onSettingsSelected` route the About action to `openAbout`.
2. `SaimoTV/components/MainScene.xml` — provides the About overlay and text label.
3. `SaimoTV/components/MainScene.brs` — `openAbout` writes the version, feature, and limitation text; `closeAbout` returns to the channel list.

## Saimo Connect

The TV runs a local control server (HTTP/WebSocket, port 8999) on the same Wi-Fi, so a phone can discover the TV, tune channels, open VOD, send ECP keys and text, and observe anonymized state.

**Flow:**

1. `SaimoTV/components/MainScene.xml` — `<ConnectTask id="connectServer" />`.
2. `SaimoTV/components/MainScene.brs` — `startConnect()` resolves `connectServer`, observes `receivedCommand`, and starts the task once in `init()`; calls `avisarCelular()` at the end of `switchScreen()`.
3. `SaimoTV/components/tasks/ConnectTask.brs` — binds port 8999 with backlog 4, serves `/info` (`app`, `id`, `name`, `version`, `port`, `multi`), upgrades `/ws` via the WebSocket handshake, decodes masked frames, handles `hello`/`ping`/`key`, and promotes other `t` values to `receivedCommand`.
4. `SaimoTV/components/MainScene.brs` — `onConnectCommand` allow-lists `tune` (channel-name validated against `m.cachedChannels`), `playVod` (non-empty title and URL, `resumePos: 0`, no headers/UA), `playPause` (no-op), `seek` (delta guarded), `text` (only while Minhas Listas is mounted), `fonte`/`sync` (`avisarCelular`).
5. `SaimoTV/components/MainScene.brs` — `tune` opens Live via `tuneChannel`; `playVod` opens Player directly; ECP `key` maps only the eight fixed codes to `http://127.0.0.1:8060/keypress/...`.
6. `SaimoTV/components/screens/SettingsScreen.brs` — shows port 8999, allow-list wording, and the trusted-LAN security note (`connectLabel`/About).
7. `SaimoTV/components/tasks/ConnectTask.brs` — `avisarCelular` payload leaves URLs, User-Agent, registry values, and device serial out of the state broadcast.

Security model (accepted/design): no TLS/pairing secret; Trusted-LAN; `/info` CORS `*` but only the discovery document; bind all interfaces on 8999, backlog 4; client retry on failures. Proxy/UA/path-debt and the hardcoded `http://saimo-tv.pages.dev/api/proxy` host remain out of scope for E12 and are tracked separately.

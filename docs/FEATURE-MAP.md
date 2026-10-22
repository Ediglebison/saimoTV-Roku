# Feature Map

> Auto-maintained index of every user-facing feature and the code path that implements it. Updated alongside the code — not after the fact.

## App Startup

Launching the channel creates the SceneGraph scene, restores settings and favorites, shows cached content, and starts background sync timers.

**Flow:**

1. `SaimoTV/manifest` — supplies the channel title, version 2.5.2, icon, splash, and FHD resolution.
2. `SaimoTV/source/main.brs` — creates `roSGScreen`, opens `MainScene`, and waits for the screen to close.
3. `SaimoTV/components/MainScene.xml` — defines the layout, video node, and 15-minute refresh timer.
   - The scene defines Inter Regular, SemiBold, and Bold font roles from bundled SIL Open Font License assets.
4. `SaimoTV/components/MainScene.brs` — `init` reads registry settings, applies canonical URL defaults, loads favorites and cached content, starts timers and scheduled sync, and loads EPG when configured.
5. `SaimoTV/source/bslib.brs` — provides URL detection, cache signatures, and parser helpers used during restoration.
6. `SaimoTV/components/FetchTask.brs` — performs the first background playlist or catalog refresh when a cached source is stale.

---

## Live TV Browsing

The user browses live channels by category, sees a preview, and selects a channel to watch.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `loadCachedPlaylist` reads the cached playlist before any network call.
2. `SaimoTV/components/FetchTask.brs` — `loadPlaylist` downloads the configured channel list.
3. `SaimoTV/source/bslib.brs` — `parsePlaylist` selects `parseCustom` or `parseM3u` and returns normalized channels.
4. `SaimoTV/components/MainScene.brs` — `handlePlaylistResult` applies the channels, saves the cache, and records the sync time.
5. `SaimoTV/components/MainScene.brs` — `applyChannels`, `buildGroups`, `buildNav`, and `populateChannels` build the category navigation and channel rows.
6. `SaimoTV/components/MainScene.brs` — `previewChannel` shows the logo, group, and source count; `onItemSelected` starts playback.

---

## Live TV Playback

Live channels open in the full-screen player, with multiple sources tried in order and no pause or seek controls. The player uses gradient veils, a loading spinner, a paused state, and a three-second control overlay timeout.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `onItemSelected` sends the selected channel to `playChannel`.
2. `SaimoTV/components/MainScene.brs` — `playChannel` initializes the source list, live flag, overlay, and player text.
3. `SaimoTV/components/MainScene.brs` — `startSource` builds the Roku `ContentNode`, applies headers and stream format, and starts the `Video` node.
4. `SaimoTV/source/bslib.brs` — `buildVideoHeaders` adds only the source-declared referer and user agent.
5. `SaimoTV/components/MainScene.brs` — `onVideoState`, `onFailoverTimer`, and `nextSource` try the next source after an error or timeout; live playback rejects pause and seek.

---

## Discover Highlights

The Discover view preserves the editorial shelves from the Saimo index and opens the matching catalog letter.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `buildNav` and `onNavSelected` route the Discover entry to `openVodHome("all")`.
2. `SaimoTV/components/MainScene.brs` — `showSaimoHome` renders cached highlights or falls back to the letter list.
3. `SaimoTV/components/FetchTask.brs` — `loadSaimoIndex` downloads `destaques.txt` and parses its shelves.
4. `SaimoTV/source/bslib.brs` — `parseHighlights` and `pickSaimoHighlights` normalize, filter, and mix the shelf entries.
5. `SaimoTV/components/MainScene.brs` — `handleSaimoIndexResult` stores the highlights and artwork.
6. `SaimoTV/components/FetchTask.brs` — returns both the flattened compatibility list and the original shelf groups.
7. `SaimoTV/components/MainScene.brs` — `showSaimoShelves`, `onShelfItemFocused`, and `onShelfItemSelected` render and navigate the shelf rows; the focused title updates the top hero, poster, backdrop, and metadata.
8. `SaimoTV/components/ShelfCard.xml` — renders each poster and its focus state.
9. `SaimoTV/components/MainScene.brs` — horizontal shelf movement stays within the row; left enters the sidebar only from the first card.

---

## VOD Catalog Browsing

The user browses the Saimo catalog by letter, sees six-column poster grids, and drills into 16:9 episode cards. Authorized M3U catalogs use a separate branch.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `onNavSelected` and `openVod` route the A–Z, Movies, and Series entries.
2. `SaimoTV/components/MainScene.brs` — `loadCachedSaimoIndex` restores the cached index; `showSaimoLetters` builds the letter list.
3. `SaimoTV/components/FetchTask.brs` — `loadSaimoIndex` downloads `indice.txt` and `destaques.txt`.
4. `SaimoTV/source/bslib.brs` — `parseSaimoIndexLetters` and `parseBases` parse letter counts and video bases.
5. `SaimoTV/components/MainScene.brs` — `handleSaimoIndexResult` stores the index, detects signature changes, and invalidates derived caches.
6. `SaimoTV/components/MainScene.brs` — `loadSaimoLetter` shows a cached letter immediately and starts a `saimo_letter` task.
7. `SaimoTV/components/FetchTask.brs` — `loadSaimoLetter` downloads `filmes-LETTER.txt` and `series-LETTER.txt` and applies artwork inside the task.
8. `SaimoTV/source/bslib.brs` — `parseSaimoMovieItems`, `parseSaimoSeriesItems`, `applySaimoArtwork`, and `sortSaimoItems` produce the sorted grid items.
9. `SaimoTV/components/MainScene.brs` — `handleSaimoLetterResult`, `showSaimoGrid`, and `buildVodGrid` render the six-column poster grid.
10. `SaimoTV/components/MainScene.brs` — `loadSaimoEpisodes` starts the episode task and `handleSaimoEpisodesResult` receives the result.
11. `SaimoTV/components/FetchTask.brs` — `loadSaimoEpisodes` downloads the selected series fragment.
12. `SaimoTV/source/bslib.brs` — `parseSaimoEpisodeItems` groups and sorts the episode sources.
13. `SaimoTV/components/MainScene.brs` — `showSaimoEpisodes` and `showSeriesEpisodes` render 16:9 episode cards; `buildVodGrid` fits inherited portrait covers without cropping them and gives each card episode title, season, and source count.

**Branch — M3U VOD:**

1. `SaimoTV/components/MainScene.brs` — `refreshVodCatalog` sends a non-Saimo source to the `vod_catalog` task.
2. `SaimoTV/components/FetchTask.brs` — `loadVodCatalog` downloads the M3U/M3U8 text.
3. `SaimoTV/source/bslib.brs` — `parseVodM3u` groups series episodes and filters invalid entries.
4. `SaimoTV/components/MainScene.brs` — `handleVodCatalogResult` and `showVod` render the resulting grid.

---

## VOD Playback

Films and episodes play from the selected source. Series selections open episode lists before playback.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `onVodItemSelected` sends films and episodes to `playVodEntry`; series go to episode loading.
2. `SaimoTV/components/MainScene.brs` — `playVodEntry` converts the catalog item into a player channel with `isLive` false.
3. `SaimoTV/components/MainScene.brs` — `playChannel` and `startSource` load the first source into the `Video` node.
4. `SaimoTV/source/bslib.brs` — `streamFormatFor` and `buildVideoHeaders` prepare format and HTTP headers.
5. `SaimoTV/components/MainScene.brs` — `onVideoState` handles pause, resume, progress, completion, and source failover.

---

## Search

Search covers live channels and the VOD catalog. The public catalog path uses an accent-insensitive search index.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `openSearchDialog` opens a Roku `KeyboardDialog`.
2. `SaimoTV/components/MainScene.brs` — `onSearchButtonSelected` and `runSearch` scan loaded channels and cached VOD entries first.
3. `SaimoTV/components/MainScene.brs` — `startSaimoSearch` starts the catalog search task when the VOD source is Saimo.
4. `SaimoTV/components/FetchTask.brs` — `loadSaimoSearch` downloads and caches `busca.txt`.
5. `SaimoTV/source/bslib.brs` — `foldText` and `parseSaimoSearchItems` ignore accents, filter restricted titles, and limit results to 160.
6. `SaimoTV/components/MainScene.brs` — `handleSaimoSearchResult` and `renderEntries` combine local and catalog results.
7. `SaimoTV/components/MainScene.brs` — `onItemSelected` opens the result's catalog letter and `focusSaimoTitle` restores focus.

---

## Favorites

Favorites apply to live channels. The app stores channel titles in the device registry and marks them with a star.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `init` calls `loadFavorites`, which reads the `favorites` registry entry.
2. `SaimoTV/components/MainScene.brs` — `onKeyEvent` maps Options, Info, and `*` to `toggleFavorite`.
3. `SaimoTV/components/MainScene.brs` — `toggleFavorite` updates the title list and `saveFavorites` writes it back as JSON.
4. `SaimoTV/components/MainScene.brs` — `renderEntries` prefixes favorite channels with `★`; `previewChannel` keeps the preview in sync.

---

## Settings

Settings edits channel, VOD, EPG, and HTTP settings, and provides refresh, cache, test, and About actions.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `openSettings` shows the settings group and `buildSettings` creates the action list.
2. `SaimoTV/components/MainScene.xml` — defines the settings panel, list, help text, and focus styling.
3. `SaimoTV/components/MainScene.brs` — `onSettingsSelected` routes URL fields to `editSetting` and action fields to their handlers.
4. `SaimoTV/components/MainScene.brs` — `onEditSettingButton` saves `playlistUrl`, `vodUrl`, `epgUrl`, and `userAgent` through `writeSetting`.
5. `SaimoTV/components/MainScene.brs` — changing the VOD source resets its sync time and cache state; changing the EPG starts `loadEpg`; preset and refresh call playlist loading.
6. `SaimoTV/components/MainScene.brs` — `clearCache` deletes channel, VOD, EPG, letter, search, and artwork caches; `playTest` opens diagnostic streams; `openAbout` shows the About panel.

---

## Automatic Sync and Cache

The app checks for updates every 15 minutes, downloads only when the cache is older than six hours, and preserves content on failure.

**Flow:**

1. `SaimoTV/components/MainScene.xml` — `vodRefreshTimer` fires every 900 seconds.
2. `SaimoTV/components/MainScene.brs` — `onVodRefreshTimer` calls `runScheduledSync`; `isSyncStale` applies the 21,600-second threshold.
3. `SaimoTV/components/MainScene.brs` — `refreshPlaylist` and `refreshVodCatalog` start the appropriate background task without changing the active screen.
4. `SaimoTV/components/FetchTask.brs` — `loadPlaylist`, `loadSaimoIndex`, `loadSaimoLetter`, `loadSaimoArtwork`, and `loadSaimoSearch` write raw and derived data under `cachefs:`.
5. `SaimoTV/components/MainScene.brs` — result handlers update in-memory state and registry sync times; failures keep the existing cache.
6. `SaimoTV/components/MainScene.brs` — `loadCachedPlaylist`, `loadCachedVodCatalog`, and `loadCachedSaimoIndex` restore cached data on the next start.
7. `SaimoTV/components/MainScene.brs` — `invalidateSaimoDerivedCaches` clears letter and search caches when the index signature changes.
8. `SaimoTV/source/bslib.brs` — `saimoIndexSignature`, `saimoLetterCacheMarker`, and `saimoLetterCachePath` define cache validity and filenames.

---

## TV Guide

The TV guide lists loaded channels with the current and next programme from an optional XMLTV feed, including current-programme progress. Live channel rows also show programme progress and now/next details when available.

**Flow:**

1. `SaimoTV/components/MainScene.brs` — `openGuide` requires loaded channels and calls `buildGuide`.
2. `SaimoTV/components/MainScene.brs` — `buildGuide` joins each channel's `tvgId` to the parsed EPG and renders the guide list.
3. `SaimoTV/components/MainScene.brs` — `loadEpg` starts `EpgTask` when an EPG URL is configured.
4. `SaimoTV/components/EpgTask.brs` — downloads XMLTV and `storeProgram` keeps the current and next programme per channel.
5. `SaimoTV/source/bslib.brs` — `xmltvEpoch`, `epgTagAttr`, and `xmltvTagValue` parse XMLTV timestamps and values.
6. `SaimoTV/components/MainScene.brs` — `onEpgState` stores the EPG and rebuilds the guide; `onGuideSelected` starts the selected channel.

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

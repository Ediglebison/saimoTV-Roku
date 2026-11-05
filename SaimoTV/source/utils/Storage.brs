' ====================================================================
' Saimo TV - Storage (Roku Registry Section "SaimoTV")
' ====================================================================

function GetRegistry() as Object
    if m.registry = invalid then
        m.registry = CreateObject("roRegistrySection", "SaimoTV")
    end if
    return m.registry
end function

function ReadSaimoKey(key as String) as String
    reg = GetRegistry()
    value = reg.Read(key)
    if value = invalid then return ""
    return value
end function

sub WriteSaimoKey(key as String, value as String)
    reg = GetRegistry()
    reg.Write(key, value)
    reg.Flush()
end sub

function LoadPreferences() as Object
    return { urlFilmes: ReadSaimoKey("vodUrl"), playlistUrl: ReadSaimoKey("playlistUrl") }
end function

function LoadFavoriteChannels() as Object
    raw = ReadSaimoKey("favorites")
    if raw = "" then return []
    parsed = ParseJson(raw)
    if type(parsed) <> "roArray" then return []
    return parsed
end function

function ToggleFavoriteChannel(channelName as String) as Boolean
    if channelName = "" then return false
    favs = LoadFavoriteChannels()
    indexFound = -1
    for i = 0 to favs.Count() - 1
        if favs[i] = channelName then
            indexFound = i
            exit for
        end if
    end for
    isFavorite = false
    if indexFound >= 0 then
        favs.Delete(indexFound)
    else
        favs.Push(channelName)
        isFavorite = true
    end if
    WriteSaimoKey("favorites", FormatJson(favs))
    return isFavorite
end function

function LoadFavoriteVOD() as Object
    raw = ReadSaimoKey("vodFavorites")
    if raw = "" then return []
    parsed = ParseJson(raw)
    if type(parsed) <> "roArray" then return []
    return parsed
end function

function ToggleFavoriteVOD(item as Object) as Boolean
    if item = invalid then return false
    title = ""
    if item.title <> invalid then title = item.title
    if title = "" then return false
    favs = LoadFavoriteVOD()
    itemKey = LCase(strFieldSafe(item, "type")) + "|" + saimoArtworkTitleKey(title) + "|" + LCase(strFieldSafe(item, "year"))
    if LCase(strFieldSafe(item, "title")) <> "" and saimoArtworkTitleKey(strFieldSafe(item, "title")) = "" then itemKey = LCase(strFieldSafe(item, "type")) + "|" + LCase(title) + "|" + LCase(strFieldSafe(item, "year"))
    indexFound = -1
    for i = 0 to favs.Count() - 1
        existingKey = LCase(vodField(favs[i], "type")) + "|" + saimoArtworkTitleKey(vodField(favs[i], "title")) + "|" + LCase(vodField(favs[i], "year"))
        if existingKey = itemKey then
            indexFound = i
            exit for
        end if
    end for
    isFavorite = false
    if indexFound >= 0 then
        favs.Delete(indexFound)
    else
        favs.Push(item)
        isFavorite = true
    end if
    WriteSaimoKey("vodFavorites", FormatJson(favs))
    return isFavorite
end function

function vodField(item as Object, fieldName as String) as String
    if item = invalid then return ""
    if type(item) <> "roAssociativeArray" then return ""
    if item.DoesExist(fieldName) = false then return ""
    value = item[fieldName]
    if value = invalid then return ""
    return value.ToStr()
end function

function strFieldSafe(item as Object, fieldName as String) as String
    return vodField(item, fieldName)
end function

function watchedStorageKey(item as Object) as String
    if item = invalid then return ""
    title = vodField(item, "seriesTitle")
    if title = "" then title = vodField(item, "title")
    if title = "" then title = vodField(item, "name")
    if title = "" then return ""
    titleKey = saimoArtworkTitleKey(title)
    if titleKey = "" then titleKey = LCase(title)
    season = vodField(item, "season")
    episode = vodField(item, "episode")
    if season = "" then season = "0"
    if episode = "" then episode = "0"
    return titleKey + "|s" + season + "|e" + episode
end function

function IsEpisodeWatched(item as Object) as Boolean
    key = watchedStorageKey(item)
    if key = "" then return false
    raw = ReadSaimoKey("watchedEpisodes")
    if raw = "" then return false
    parsed = ParseJson(raw)
    if type(parsed) <> "roAssociativeArray" then return false
    if parsed.DoesExist(key) = false then return false
    return parsed[key] = true
end function

sub MarkWatched(item as Object)
    key = watchedStorageKey(item)
    if key = "" then return
    raw = ReadSaimoKey("watchedEpisodes")
    parsed = {}
    if raw <> "" then
        loaded = ParseJson(raw)
        if type(loaded) = "roAssociativeArray" then parsed = loaded
    end if
    parsed[key] = true
    WriteSaimoKey("watchedEpisodes", FormatJson(parsed))
end sub

function asIntegerValue(value as Dynamic) as Integer
    if value = invalid then return 0
    valueType = type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" then
        return value
    end if
    if valueType = "Float" or valueType = "Double" or valueType = "roFloat" or valueType = "roDouble" then
        return Int(value)
    end if
    if valueType = "String" or valueType = "roString" then
        converted = value.toInt()
        return converted
    end if
    return 0
end function

sub SaveVODProgress(entry as Object)
    if entry = invalid then return
    title = vodField(entry, "title")
    if title = "" then return
    posSec = asIntegerValue(entry.posSec)
    durSec = asIntegerValue(entry.durSec)
    if durSec <= 0 then return
    season = asIntegerValue(entry.season)
    episode = asIntegerValue(entry.episode)
    epTitle = vodField(entry, "epTitle")
    urlValue = vodField(entry, "url")
    posterValue = vodField(entry, "poster")
    all = LoadAllProgress()
    percent = Int((posSec / durSec) * 100)
    if percent >= 92 then
        if all[title] <> invalid then
            all.Delete(title)
            WriteSaimoKey("vod_progress", FormatJson(all))
        end if
        return
    end if
    if percent < 0 then percent = 0
    if percent > 100 then percent = 100
    all[title] = {
        title: title,
        posSec: posSec,
        durSec: durSec,
        percent: percent,
        season: season,
        episode: episode,
        epTitle: epTitle,
        url: urlValue,
        poster: posterValue,
        updatedAt: CreateObject("roDateTime").AsSeconds()
    }
    WriteSaimoKey("vod_progress", FormatJson(all))
end sub

function LoadAllProgress() as Object
    raw = ReadSaimoKey("vod_progress")
    if raw = "" then return {}
    parsed = ParseJson(raw)
    if type(parsed) <> "roAssociativeArray" then return {}
    return parsed
end function

function GetVODProgress(title as String) as Dynamic
    all = LoadAllProgress()
    if title = "" then return invalid
    if all[title] <> invalid then return all[title]
    return invalid
end function

function GetInProgressList() as Object
    all = LoadAllProgress()
    list = []
    for each key in all
        it = all[key]
        if type(it) <> "roAssociativeArray" then continue for
        title = vodField(it, "title")
        if title = "" then title = key
        posSec = asIntegerValue(it.posSec)
        durSec = asIntegerValue(it.durSec)
        percent = 0
        if it.percent <> invalid then percent = asIntegerValue(it.percent)
        if durSec > 0 and percent = 0 then percent = Int((posSec / durSec) * 100)
        if percent < 0 then percent = 0
        if percent > 100 then percent = 100
        if percent > 2 and percent < 92 then
            it.percent = percent
            it.posSec = posSec
            it.durSec = durSec
            list.Push(it)
        end if
    end for
    return list
end function

function LoadMinhasListas() as Object
    raw = ReadSaimoKey("minhasListas")
    if raw = "" then return []
    parsed = ParseJson(raw)
    if type(parsed) <> "roArray" then return []
    return parsed
end function

sub SaveMinhasListas(listas as Object)
    if listas = invalid then return
    WriteSaimoKey("minhasListas", FormatJson(listas))
end sub

function GetParentalPin() as String
    value = ReadSaimoKey("pinParental")
    if value = "" then return "1010"
    return value
end function

function GetEventosUrl() as String
    value = ReadSaimoKey("eventosUrl")
    if value = "" then return "https://embedtv.cc/api/events"
    return value
end function
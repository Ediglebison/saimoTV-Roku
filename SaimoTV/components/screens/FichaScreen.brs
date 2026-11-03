sub init()
    m.backdropPoster = m.top.findNode("backdropPoster")
    m.posterNode = m.top.findNode("posterNode")
    m.titleLabel = m.top.findNode("titleLabel")
    m.metaLabel = m.top.findNode("metaLabel")
    m.genresLabel = m.top.findNode("genresLabel")
    m.top.observeField("focusedChild", "onFocusedChildChange")
end sub

sub onFocusedChildChange()
end sub

sub onItemChange()
    item = m.top.item
    if item = invalid then return

    title = ""
    if item.title <> invalid then title = item.title.ToStr()
    m.titleLabel.text = title

    if item.backdrop <> invalid and item.backdrop <> "" then
        m.backdropPoster.uri = item.backdrop
    else if item.poster <> invalid and item.poster <> "" then
        m.backdropPoster.uri = item.poster
    end if
    if item.poster <> invalid and item.poster <> "" then
        m.posterNode.uri = item.poster
    end if

    meta = []
    if item.rating <> invalid and item.rating.ToStr() <> "" then meta.Push("★ " + item.rating.ToStr())
    if item.year <> invalid and item.year.ToStr() <> "" then meta.Push(item.year.ToStr())
    m.metaLabel.text = meta.Join("  ·  ")

    if item.genres <> invalid and item.genres <> "" then
        m.genresLabel.text = item.genres.ToStr()
    else if item.overview <> invalid and item.overview <> "" then
        m.genresLabel.text = item.overview.ToStr()
    end if
end sub

sub tocar()
    item = m.top.item
    if item = invalid then return

    itemId = ""
    if item.id <> invalid then itemId = item.id.ToStr()
    letter = ""
    if item.letter <> invalid then letter = item.letter.ToStr()
    year = ""
    if item.year <> invalid then year = item.year.ToStr()
    isSeries = false
    if item.isSeries <> invalid then isSeries = item.isSeries

    m.top.playRequested = {
        title: item.title,
        letter: letter,
        year: year,
        resumePos: 0,
        isSeries: isSeries,
        season: 1,
        episode: 1,
        id: itemId
    }
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "select" or key = "OK" or key = "play" then
        tocar()
        return true
    end if
    if key = "up" then
        m.top.focusUpRequested = true
        return true
    end if
    return false
end function

sub cleanUp()
end sub
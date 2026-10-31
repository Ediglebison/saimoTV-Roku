' Cartao de episodio no estilo item_episodio.xml: thumb 16:9 com selo de
' codigo, numeral grande quando nao ha arte, titulo, meta e sinopse.
sub init()
    m.poster = m.top.findNode("poster")
    m.episodeCode = m.top.findNode("episodeCode")
    m.episodeNumber = m.top.findNode("episodeNumber")
    m.title = m.top.findNode("title")
    m.meta = m.top.findNode("meta")
    m.synopsis = m.top.findNode("synopsis")
    m.focusHalo = m.top.findNode("focusHalo")
    m.posterUri = ""
    m.poster.observeField("loadStatus", "onPosterLoadStatus")
end sub

sub showItem()
    item = m.top.itemContent
    if item = invalid then return
    art = strField(item, "episodeArt")
    hasArt = art <> ""
    if not hasArt then art = "pkg:/images/placeholder.png"
    m.posterUri = art
    m.poster.uri = "pkg:/images/placeholder.png"
    loadPoster()
    m.episodeNumber.text = strField(item, "episodeNumber")
    m.episodeNumber.visible = not hasArt
    m.episodeCode.text = strField(item, "episodeCode")
    m.title.text = strField(item, "episodeTitle")
    m.meta.text = strField(item, "episodeMeta")
    m.synopsis.text = strField(item, "episodeSynopsis")
end sub

sub updateFocus()
    m.focusHalo.opacity = m.top.focusPercent
end sub

sub loadPoster()
    if m.poster.uri <> m.posterUri then m.poster.uri = m.posterUri
end sub

sub onPosterLoadStatus()
    status = m.poster.loadStatus
    uri = m.poster.uri
    if Left(LCase(uri), 7) <> "http://" and Left(LCase(uri), 8) <> "https://" then return
    ' Image loading is intentionally silent; Roku console must not be flooded.
end sub

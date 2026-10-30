sub init()
    m.statusLabel = m.top.findNode("statusLabel")
    m.poster = m.top.findNode("poster")
    m.metadataTask = m.top.findNode("metadataTask")
    
    m.metadataTask.observeField("response", "onMetadataResponse")
end sub

sub onContentChange()
    content = m.top.itemContent
    if content <> invalid then
        m.statusLabel.text = content.description
        
        ' Check if it's a request or search item
        req = content.requestData
        if req = invalid then req = content.mediaData
        
        if req <> invalid then
            ' If it's a request, use media object, otherwise use req itself
            mediaObj = req
            if req.media <> invalid then mediaObj = req.media
            
            mediaType = mediaObj.mediaType
            tmdbId = mediaObj.tmdbId
            
            ' For search items, poster might already be present
            if content.isCast = true then
                if mediaObj.profilePath <> invalid then
                    m.poster.uri = "https://image.tmdb.org/t/p/w500" + mediaObj.profilePath
                    m.statusLabel.text = mediaObj.name
                end if
            else if mediaObj.posterPath <> invalid then
                m.poster.uri = "https://image.tmdb.org/t/p/w500" + mediaObj.posterPath
            end if
            
            if content.isCast <> true then
                if tmdbId <> invalid then
                    if mediaObj.posterPath = invalid then
                        ' We need to fetch metadata
                        sec = CreateObject("roRegistrySection", "SeerrAuth")
                        serverUrl = ""
                        if sec.Exists("serverUrl") then
                            serverUrl = sec.Read("serverUrl")
                        end if
                        if serverUrl <> "" then
                            url = serverUrl + "/api/v1/" + mediaType + "/" + tmdbId.toStr()
                            m.metadataTask.requestData = {
                                url: url,
                                method: "GET"
                            }
                            m.metadataTask.control = "RUN"
                        end if
                    end if
                end if
            end if
        end if
    end if
end sub

sub onMetadataResponse()
    resp = m.metadataTask.response
    if resp <> invalid then
        if resp.code = 200 then
            data = ParseJson(resp.body)
            if data <> invalid then
                if data.posterPath <> invalid then
                    m.poster.uri = "https://image.tmdb.org/t/p/w500" + data.posterPath
                end if
            end if
        end if
    end if
end sub

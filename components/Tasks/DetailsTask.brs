sub init()
    m.top.functionName = "fetchExtraDetails"
end sub

function fetchApi(url as String) as Object
    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()
    
    sec = CreateObject("roRegistrySection", "SeerrAuth")
    if sec.Exists("connectSid") then
        cookieStr = sec.Read("connectSid")
        if cookieStr <> "" then 
            request.AddHeader("Cookie", cookieStr)
        end if
    end if
    
    response = request.GetToString()
    return ParseJson(response)
end function

sub fetchExtraDetails()
    results = []
    mId = m.top.mediaId.toStr()
    mType = m.top.mediaType
    
    sec = CreateObject("roRegistrySection", "SeerrAuth")
    serverUrl = ""
    if sec.Exists("serverUrl") then
        serverUrl = sec.Read("serverUrl")
    end if
    
    baseUrl = serverUrl + "/api/v1/" + mType + "/" + mId
    
    cast = fetchApi(baseUrl + "/cast")
    if cast <> invalid then
        if cast.Count() > 0 then
            results.Push({title: "Cast", data: cast, isCast: true})
        end if
    end if
    
    recs = fetchApi(baseUrl + "/recommendations?page=1")
    if recs <> invalid then
        if recs.results <> invalid then
            if recs.results.Count() > 0 then
                results.Push({title: "Recommendations", data: recs.results, isCast: false})
            end if
        end if
    end if
    
    similar = fetchApi(baseUrl + "/similar?page=1")
    if similar <> invalid then
        if similar.results <> invalid then
            if similar.results.Count() > 0 then
                results.Push({title: "Similar Titles", data: similar.results, isCast: false})
            end if
        end if
    end if
    
    m.top.response = { sections: results }
end sub

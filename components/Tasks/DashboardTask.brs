sub init()
    m.top.functionName = "fetchDashboard"
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

sub fetchDashboard()
    results = []
    activeTab = m.top.activeTab
    
    sec = CreateObject("roRegistrySection", "SeerrAuth")
    serverUrl = ""
    if sec.Exists("serverUrl") then
        serverUrl = sec.Read("serverUrl")
    end if
    
    if activeTab = "discover" then
        reqs = fetchApi(serverUrl + "/api/v1/request?take=20&filter=pending")
        if reqs <> invalid then
            if reqs.results <> invalid then
                if reqs.results.Count() > 0 then
                    results.Push({title: "Pending Requests", data: reqs.results, isRequest: true})
                else
                    reqsAll = fetchApi(serverUrl + "/api/v1/request?take=20")
                    if reqsAll <> invalid then
                        if reqsAll.results <> invalid then
                            if reqsAll.results.Count() > 0 then
                                results.Push({title: "Recent Requests", data: reqsAll.results, isRequest: true})
                            end if
                        end if
                    end if
                end if
            else
                reqsAll = fetchApi(serverUrl + "/api/v1/request?take=20")
                if reqsAll <> invalid then
                    if reqsAll.results <> invalid then
                        if reqsAll.results.Count() > 0 then
                            results.Push({title: "Recent Requests", data: reqsAll.results, isRequest: true})
                        end if
                    end if
                end if
            end if
        else
            reqsAll = fetchApi(serverUrl + "/api/v1/request?take=20")
            if reqsAll <> invalid then
                if reqsAll.results <> invalid then
                    if reqsAll.results.Count() > 0 then
                        results.Push({title: "Recent Requests", data: reqsAll.results, isRequest: true})
                    end if
                end if
            end if
        end if
        
        trending = fetchApi(serverUrl + "/api/v1/discover/trending?page=1")
        if trending <> invalid then
            if trending.results <> invalid then
                results.Push({title: "Trending", data: trending.results, isRequest: false})
            end if
        end if
        
        sortParam = ""
        if m.top.sortBy <> "" then sortParam = "&sortBy=" + m.top.sortBy
        
        movies = fetchApi(serverUrl + "/api/v1/discover/movies?page=1" + sortParam)
        if movies <> invalid then
            if movies.results <> invalid then
                results.Push({title: "Popular Movies", data: movies.results, isRequest: false})
            end if
        end if
        
        tv = fetchApi(serverUrl + "/api/v1/discover/tv?page=1" + sortParam)
        if tv <> invalid then
            if tv.results <> invalid then
                results.Push({title: "Popular TV", data: tv.results, isRequest: false})
            end if
        end if
    elseif activeTab = "movies" then
        sortParam = ""
        if m.top.sortBy <> "" then sortParam = "&sortBy=" + m.top.sortBy
        
        popular = fetchApi(serverUrl + "/api/v1/discover/movies?page=1" + sortParam)
        if popular <> invalid then
            if popular.results <> invalid then 
                results.Push({title: "Popular Movies", data: popular.results, isRequest: false})
            end if
        end if
        
        upcoming = fetchApi(serverUrl + "/api/v1/discover/movies/upcoming?page=1")
        if upcoming <> invalid then
            if upcoming.results <> invalid then 
                results.Push({title: "Upcoming Movies", data: upcoming.results, isRequest: false})
            end if
        end if
    elseif activeTab = "series" then
        sortParam = ""
        if m.top.sortBy <> "" then sortParam = "&sortBy=" + m.top.sortBy
        
        popular = fetchApi(serverUrl + "/api/v1/discover/tv?page=1" + sortParam)
        if popular <> invalid then
            if popular.results <> invalid then 
                results.Push({title: "Popular TV", data: popular.results, isRequest: false})
            end if
        end if
        
        upcoming = fetchApi(serverUrl + "/api/v1/discover/tv/upcoming?page=1")
        if upcoming <> invalid then
            if upcoming.results <> invalid then 
                results.Push({title: "Upcoming TV", data: upcoming.results, isRequest: false})
            end if
        end if
    elseif activeTab = "requests" then
        reqs = fetchApi(serverUrl + "/api/v1/request?take=40")
        if reqs <> invalid then
            if reqs.results <> invalid then 
                results.Push({title: "All Requests", data: reqs.results, isRequest: true, isIssue: false})
            end if
        end if
    elseif activeTab = "issues" then
        issues = fetchApi(serverUrl + "/api/v1/issue?take=40")
        if issues <> invalid then
            if issues.results <> invalid then 
                results.Push({title: "All Issues", data: issues.results, isRequest: false, isIssue: true})
            end if
        end if
    elseif activeTab = "users" then
        users = fetchApi(serverUrl + "/api/v1/user?take=40")
        if users <> invalid then
            if users.results <> invalid then 
                results.Push({title: "Users", data: users.results, isRequest: false, isIssue: false})
            end if
        end if
    end if
    
    m.top.response = { sections: results }
end sub

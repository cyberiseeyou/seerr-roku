sub init()
    m.navList = m.top.findNode("navList")
    m.requestList = m.top.findNode("requestList")
    m.discoverList = m.top.findNode("discoverList")
    m.statusLabel = m.top.findNode("statusLabel")
    m.fetchDashboardTask = m.top.findNode("fetchDashboardTask")
    
    m.userAvatar = m.top.findNode("userAvatar")
    m.userNameLabel = m.top.findNode("userNameLabel")
    m.authMeTask = m.top.findNode("authMeTask")
    m.authMeTask.observeField("response", "onAuthMeResponse")
    
    m.fetchDashboardTask.observeField("response", "onDashboardResponse")
    m.requestList.observeField("itemSelected", "onItemSelected")
    m.discoverList.observeField("itemSelected", "onDiscoverItemSelected")
    m.navList.observeField("itemSelected", "onNavSelected")
    
    setupNavList()
    
    sec = CreateObject("roRegistrySection", "SeerrAuth")
    serverUrl = ""
    if sec.Exists("serverUrl") then serverUrl = sec.Read("serverUrl")

    m.authMeTask.requestData = {
        url: serverUrl + "/api/v1/auth/me"
        method: "GET"
    }
    m.authMeTask.control = "RUN"
    
    m.currentTab = "discover"
    loadDashboard()
end sub

sub setupNavList()
    content = CreateObject("roSGNode", "ContentNode")
    
    items = [
        {title: "Discover", id: "discover"},
        {title: "Movies", id: "movies"},
        {title: "Series", id: "series"},
        {title: "Requests", id: "requests"},
        {title: "Issues", id: "issues"},
        {title: "Users", id: "users"},
        {title: "Search", id: "search"},
        {title: "Logout", id: "logout"}
    ]
    
    for each item in items
        node = CreateObject("roSGNode", "ContentNode")
        node.title = item.title
        node.id = item.id
        content.appendChild(node)
    end for
    
    m.navList.content = content
end sub

sub onAuthMeResponse()
    resp = m.authMeTask.response
    if resp <> invalid and resp.code = 200 then
        data = ParseJson(resp.body)
        if data <> invalid then
            if data.displayName <> invalid then
                m.userNameLabel.text = data.displayName
            else if data.username <> invalid then
                m.userNameLabel.text = data.username
            end if
            
            if data.avatar <> invalid and data.avatar <> "" then
                avatarUrl = data.avatar
                if avatarUrl.StartsWith("/") then
                    sec = CreateObject("roRegistrySection", "SeerrAuth")
                    serverUrl = ""
                    if sec.Exists("serverUrl") then serverUrl = sec.Read("serverUrl")
                    if serverUrl <> "" then avatarUrl = serverUrl + avatarUrl
                end if
                m.userAvatar.uri = avatarUrl
            end if
        end if
    else
        ' A failed/unreachable auth check means the saved session is no longer valid --
        ' treat it exactly like a logout (AppScene.onLogout clears the stale registry
        ' entries) instead of sitting on a half-broken Dashboard with no real user data.
        m.top.logout = true
    end if
end sub

sub onNavSelected()
    idx = m.navList.itemSelected
    selectedNode = m.navList.content.getChild(idx)
    
    if selectedNode.id = "logout" then
        sec = CreateObject("roRegistrySection", "SeerrAuth")
        sec.Delete("connectSid")
        sec.Flush()
        m.top.logout = true
        return
    end if
    
    if selectedNode.id = "search" then
        m.searchView = CreateObject("roSGNode", "SearchScreen")
        m.searchView.observeField("backSelected", "onSearchBackSelected")
        m.top.appendChild(m.searchView)
        m.searchView.setFocus(true)
        m.searchView.triggerSearch = true
        return
    end if
    
    m.currentTab = selectedNode.id
    
    m.requestList.content = invalid
    loadDashboard()
end sub

sub onSearchBackSelected()
    if m.searchView <> invalid then
        m.top.removeChild(m.searchView)
        m.searchView = invalid
        m.navList.setFocus(true)
    end if
end sub

sub loadDashboard()
    m.statusLabel.visible = true
    m.statusLabel.text = "Loading " + m.currentTab + "..."
    m.requestList.visible = false
    m.discoverList.visible = false
    
    m.fetchDashboardTask.activeTab = m.currentTab
    if m.currentSortBy = invalid then m.currentSortBy = ""
    m.fetchDashboardTask.sortBy = m.currentSortBy
    m.fetchDashboardTask.control = "RUN"
end sub

sub onDashboardResponse()
    resp = m.fetchDashboardTask.response
    m.statusLabel.text = ""
    m.statusLabel.visible = false
    if m.currentTab = "discover" then
        m.discoverList.visible = true
        m.requestList.visible = false
    else
        m.discoverList.visible = false
        m.requestList.visible = true
    end if
    
    content = CreateObject("roSGNode", "ContentNode")
    
    if resp <> invalid then
        if resp.sections <> invalid then
            for each section in resp.sections
                if m.currentTab = "discover" then
                    row = CreateObject("roSGNode", "ContentNode")
                    row.title = section.title
                end if
                
                for each itemData in section.data
                    itemNode = CreateObject("roSGNode", "ContentNode")
                    itemNode.addField("requestData", "assocarray", false)
                    itemNode.addField("mediaData", "assocarray", false)
                    itemNode.addField("isRequest", "boolean", false)
                    itemNode.addField("isIssue", "boolean", false)
                    
                    if section.isRequest = true then
                        itemNode.requestData = itemData
                        itemNode.isRequest = true
                        itemNode.isIssue = false
                    elseif section.isIssue = true then
                        itemNode.requestData = itemData ' We pass issue data as requestData to use media object
                        itemNode.isRequest = false
                        itemNode.isIssue = true
                    else
                        itemNode.mediaData = itemData
                        itemNode.isRequest = false
                        itemNode.isIssue = false
                    end if
                    
                    if m.currentTab = "discover" then
                        row.appendChild(itemNode)
                    else
                        content.appendChild(itemNode)
                    end if
                end for
                
                if m.currentTab = "discover" then
                    content.appendChild(row)
                end if
            end for
        end if
    end if
    
    if m.currentTab = "discover" then
        m.discoverList.itemSize = [1500, 440]
        m.discoverList.content = content
        if not m.navList.hasFocus() then m.discoverList.setFocus(true)
    else
        if m.currentTab = "users" then
            m.requestList.itemComponentName = "UserItem"
            m.requestList.itemSize = [250, 250]
        else
            m.requestList.itemComponentName = "RequestItem"
            m.requestList.itemSize = [250, 400]
        end if
        m.requestList.content = content
        if not m.navList.hasFocus() then m.requestList.setFocus(true)
    end if
end sub

sub onDiscoverItemSelected()
    row = m.discoverList.rowItemSelected[0]
    col = m.discoverList.rowItemSelected[1]
    selectedItem = m.discoverList.content.getChild(row).getChild(col)
    
    openDetailsView(selectedItem)
end sub

sub onItemSelected()
    idx = m.requestList.itemSelected
    selectedItem = m.requestList.content.getChild(idx)
    
    openDetailsView(selectedItem)
end sub

sub openDetailsView(selectedItem as Object)
    if selectedItem <> invalid then
        if m.currentTab = "users" then return ' User details not fully implemented yet
        
        m.detailsView = CreateObject("roSGNode", "DetailsScreen")
        if selectedItem.isRequest and selectedItem.requestData <> invalid then
            m.detailsView.requestData = selectedItem.requestData
        elseif selectedItem.isIssue and selectedItem.requestData <> invalid then
            m.detailsView.isIssue = true
            m.detailsView.requestData = selectedItem.requestData
        else if not selectedItem.isRequest and not selectedItem.isIssue and selectedItem.mediaData <> invalid then
            m.detailsView.mediaData = selectedItem.mediaData
        end if
        
        m.detailsView.observeField("actionComplete", "onDetailsActionComplete")
        m.top.appendChild(m.detailsView)
        m.detailsView.setFocus(true)
    end if
end sub

sub onDetailsActionComplete()
    if m.detailsView <> invalid then
        m.top.removeChild(m.detailsView)
        m.detailsView = invalid
        if m.currentTab = "discover" then
            m.discoverList.setFocus(true)
        else
            m.requestList.setFocus(true)
        end if
        loadDashboard()
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if press then
        if key = "left" then
            if m.requestList.hasFocus() or m.discoverList.hasFocus() then
                m.navList.setFocus(true)
                handled = true
            end if
        else if key = "right" then
            if m.navList.hasFocus() then
                if m.currentTab = "discover" then
                    if m.discoverList.content <> invalid and m.discoverList.content.getChildCount() > 0 then
                        m.discoverList.setFocus(true)
                        handled = true
                    end if
                else
                    if m.requestList.content <> invalid and m.requestList.content.getChildCount() > 0 then
                        m.requestList.setFocus(true)
                        handled = true
                    end if
                end if
            end if
        end if
    end if
    return handled
end function

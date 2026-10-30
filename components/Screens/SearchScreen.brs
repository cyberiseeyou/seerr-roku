sub init()
    m.searchTask = m.top.findNode("searchTask")
    m.searchBtn = m.top.findNode("searchBtn")
    m.currentQueryLabel = m.top.findNode("currentQueryLabel")
    m.resultList = m.top.findNode("resultList")
    m.statusLabel = m.top.findNode("statusLabel")
    
    m.resultList.itemSize = [250, 400]
    m.resultList.itemSpacing = [50, 50]
    
    m.searchBtn.observeField("buttonSelected", "onSearchBtnSelected")
    m.resultList.observeField("itemSelected", "onItemSelected")
    
    m.top.observeField("focusedChild", "onFocusChange")
end sub

function getServerUrl() as String
    sec = CreateObject("roRegistrySection", "SeerrAuth")
    url = ""
    if sec.Exists("serverUrl") then url = sec.Read("serverUrl")
    return url
end function

sub onFocusChange()
    if m.top.hasFocus() then
        if m.resultList.content <> invalid then
            m.resultList.setFocus(true)
        else
            m.searchBtn.setFocus(true)
        end if
    end if
end sub

sub onSearchBtnSelected()
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    dialog.title = "Enter movie or TV show name"
    dialog.buttons = ["Search", "Cancel"]
    
    palette = CreateObject("roSGNode", "RSGPalette")
    palette.colors = {
        DialogBackgroundColor: "0x1E1E1EFF",
        DialogKeyboardColor: "0x252525FF",
        DialogFootprintColor: "0x665CB2FF",
        DialogTextColor: "0xFFFFFFFF",
        DialogSecondaryTextColor: "0xAAAAAAFF"
    }
    dialog.palette = palette
    
    dialog.observeFieldScoped("buttonSelected", "onSearchDialogComplete")
    m.top.getScene().dialog = dialog
end sub

sub onSearchDialogComplete(event)
    dialog = event.getRoSGNode()
    if dialog.buttonSelected = 0 then ' Search
        query = dialog.text
        if Len(query) > 0 then
            m.currentQueryLabel.text = "Results for: " + query
            m.statusLabel.text = "Searching..."
            
            if m.searchTask <> invalid then
                m.searchTask.control = "STOP"
                m.searchTask.unobserveField("response")
                if m.searchTask.getParent() <> invalid then
                    m.top.removeChild(m.searchTask)
                end if
            end if
            
            m.searchTask = CreateObject("roSGNode", "ApiTask")
            m.top.appendChild(m.searchTask)
            m.searchTask.observeField("response", "onSearchResponse")
            m.searchTask.requestData = {
                url: getServerUrl() + "/api/v1/search"
                query: query
                method: "GET"
            }
            m.searchTask.control = "RUN"
        end if
    end if
    m.top.getScene().dialog = invalid
    m.searchBtn.setFocus(true)
end sub

sub onSearchResponse(event as Object)
    resp = m.searchTask.response
    m.statusLabel.text = ""
    
    if resp <> invalid then
        if resp.code = 200 then
            data = ParseJson(resp.body)
            if data <> invalid and data.results <> invalid then
                content = CreateObject("roSGNode", "ContentNode")
                
                for each item in data.results
                    itemNode = CreateObject("roSGNode", "ContentNode")
                    itemNode.addField("requestData", "assocarray", false)
                    itemNode.addField("mediaData", "assocarray", false)
                    itemNode.addField("isRequest", "boolean", false)
                    itemNode.addField("isIssue", "boolean", false)
                    
                    itemNode.mediaData = item
                    itemNode.isRequest = false
                    itemNode.isIssue = false
                    
                    content.appendChild(itemNode)
                end for
                
                m.resultList.content = content
                
                if content.getChildCount() > 0 then
                    m.resultList.setFocus(true)
                else
                    m.statusLabel.text = "No results found for query."
                end if
            else
                m.statusLabel.text = "Search failed: JSON parse error or no results array."
            end if
        else
            m.statusLabel.text = "Search failed. HTTP Code: " + resp.code.toStr() + " Body: " + left(resp.body, 30)
        end if
    else
        m.statusLabel.text = "Search failed (Network Error/Timeout)."
    end if
end sub

sub onItemSelected()
    idx = m.resultList.itemSelected
    selectedItem = m.resultList.content.getChild(idx)
    
    if selectedItem <> invalid then
        m.detailsView = CreateObject("roSGNode", "DetailsScreen")
        m.detailsView.mediaData = selectedItem.mediaData
        m.detailsView.observeField("actionComplete", "onDetailsActionComplete")
        m.top.appendChild(m.detailsView)
        m.detailsView.setFocus(true)
    end if
end sub

sub onDetailsActionComplete()
    if m.detailsView <> invalid then
        m.top.removeChild(m.detailsView)
        m.detailsView = invalid
        m.resultList.setFocus(true)
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if press then
        if key = "down" then
            if m.searchBtn.hasFocus() then
                if m.resultList.content <> invalid and m.resultList.content.getChildCount() > 0 then
                    m.resultList.setFocus(true)
                end if
                handled = true
            end if
        else if key = "up" then
            if m.resultList.hasFocus() then
                m.searchBtn.setFocus(true)
                handled = true
            end if
        else if key = "back" then
            if m.resultList.hasFocus() then
                m.searchBtn.setFocus(true)
                handled = true
            else
                m.top.backSelected = true
                handled = true
            end if
        end if
    end if
    return handled
end function

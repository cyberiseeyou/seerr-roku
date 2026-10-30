sub init()
    m.backdrop = m.top.findNode("backdrop")
    m.poster = m.top.findNode("poster")
    m.titleLabel = m.top.findNode("titleLabel")
    m.metaLabel = m.top.findNode("metaLabel")
    m.overviewLabel = m.top.findNode("overviewLabel")
    m.requestInfoLabel = m.top.findNode("requestInfoLabel")
    m.requestStatusLabel = m.top.findNode("requestStatusLabel")
    
    m.requestBtn = m.top.findNode("requestBtn")
    m.approveBtn = m.top.findNode("approveBtn")
    m.denyBtn = m.top.findNode("denyBtn")
    m.resolveBtn = m.top.findNode("resolveBtn")
    m.issueBtn = m.top.findNode("issueBtn")
    m.backBtn = m.top.findNode("backBtn")
    m.actionStatus = m.top.findNode("actionStatus")
    
    m.metadataTask = m.top.findNode("metadataTask")
    m.actionTask = m.top.findNode("actionTask")
    
    m.extraList = m.top.findNode("extraList")
    m.detailsTask = m.top.findNode("detailsTask")
    
    m.requestBtn.observeField("buttonSelected", "onRequestSelected")
    m.approveBtn.observeField("buttonSelected", "onApproveSelected")
    m.denyBtn.observeField("buttonSelected", "onDenySelected")
    m.resolveBtn.observeField("buttonSelected", "onResolveSelected")
    m.issueBtn.observeField("buttonSelected", "onIssueSelected")
    m.backBtn.observeField("buttonSelected", "onBackSelected")
    
    m.metadataTask.observeField("response", "onMetadataResponse")
    m.actionTask.observeField("response", "onActionResponse")
    m.detailsTask.observeField("response", "onDetailsTaskResponse")
    m.extraList.observeField("itemSelected", "onExtraItemSelected")
    
    m.mediaId = invalid
    m.mediaType = "movie"
    m.requestId = invalid
end sub

function getServerUrl() as String
    sec = CreateObject("roRegistrySection", "SeerrAuth")
    url = ""
    if sec.Exists("serverUrl") then url = sec.Read("serverUrl")
    return url
end function

sub onMediaDataChange()
    data = m.top.mediaData
    if data <> invalid then
        m.mediaId = data.id
        if data.mediaType <> invalid then m.mediaType = data.mediaType
        
        m.requestBtn.visible = true
        m.approveBtn.visible = false
        m.denyBtn.visible = false
        m.resolveBtn.visible = false
        m.issueBtn.visible = true
        m.issueBtn.translation = [200, 0]
        m.backBtn.translation = [460, 0]
        
        fetchMetadata()
    end if
end sub

sub onRequestDataChange()
    req = m.top.requestData
    if req <> invalid then
        m.requestId = req.id
        if req.media <> invalid then
            m.mediaId = req.media.tmdbId
            m.mediaType = req.media.mediaType
        end if
        
        m.requestBtn.visible = false
        
        if req.requestedBy <> invalid then
            m.requestInfoLabel.visible = true
            m.requestInfoLabel.text = "Requested by: " + req.requestedBy.displayName
        end if
        
        m.requestStatusLabel.visible = true
        statusStr = "Unknown"
        if req.status = 1 then statusStr = "Pending"
        if req.status = 2 then statusStr = "Approved"
        if req.status = 3 then statusStr = "Declined"
        if req.status = 4 then statusStr = "Processing"
        if req.status = 5 then statusStr = "Available"
        m.requestStatusLabel.text = "Status: " + statusStr
        
        if m.top.isIssue then
            m.approveBtn.visible = false
            m.denyBtn.visible = false
            m.resolveBtn.visible = true
            m.issueBtn.visible = false
            m.resolveBtn.translation = [0, 0]
            m.backBtn.translation = [260, 0]
        else
            if req.status = 1 then
                m.approveBtn.visible = true
                m.denyBtn.visible = true
                m.resolveBtn.visible = false
                m.issueBtn.visible = true
                m.denyBtn.translation = [200, 0]
                m.issueBtn.translation = [360, 0]
                m.backBtn.translation = [620, 0]
            else
                m.approveBtn.visible = false
                m.denyBtn.visible = false
                m.resolveBtn.visible = false
                m.issueBtn.visible = true
                m.issueBtn.translation = [0, 0]
                m.backBtn.translation = [260, 0]
            end if
        end if
        
        fetchMetadata()
    end if
end sub

sub fetchMetadata()
    if m.mediaId <> invalid then
        m.metadataTask.requestData = {
            url: getServerUrl() + "/api/v1/" + m.mediaType + "/" + m.mediaId.toStr()
            method: "GET"
        }
        m.metadataTask.control = "RUN"
        
        m.detailsTask.mediaId = m.mediaId
        m.detailsTask.mediaType = m.mediaType
        m.detailsTask.control = "RUN"
    end if
end sub

sub onMetadataResponse()
    resp = m.metadataTask.response
    if resp <> invalid then
        if resp.code = 200 then
        data = ParseJson(resp.body)
        if data <> invalid then
            if data.title <> invalid then
                m.titleLabel.text = data.title
            else if data.name <> invalid then
                m.titleLabel.text = data.name
            end if
            
            if data.overview <> invalid then m.overviewLabel.text = data.overview
            
            metaStr = ""
            if data.releaseDate <> invalid then metaStr = metaStr + data.releaseDate.Left(4) + "  "
            if data.runtime <> invalid then metaStr = metaStr + data.runtime.toStr() + " min"
            m.metaLabel.text = metaStr
            
            if data.posterPath <> invalid then
                m.poster.uri = "https://image.tmdb.org/t/p/w500" + data.posterPath
            end if
            if data.backdropPath <> invalid then
                m.backdrop.uri = "https://image.tmdb.org/t/p/w1280" + data.backdropPath
            end if
        end if
        end if
    end if
    
    ' Set focus depending on visibility
    if m.approveBtn.visible then
        m.approveBtn.setFocus(true)
    else if m.requestBtn.visible then
        m.requestBtn.setFocus(true)
    else
        m.backBtn.setFocus(true)
    end if
end sub

sub onDetailsTaskResponse()
    resp = m.detailsTask.response
    if resp <> invalid then
        if resp.sections <> invalid then
        content = CreateObject("roSGNode", "ContentNode")
        
        for each section in resp.sections
            row = CreateObject("roSGNode", "ContentNode")
            row.title = section.title
            
            for each itemData in section.data
                itemNode = CreateObject("roSGNode", "ContentNode")
                itemNode.addField("mediaData", "assocarray", false)
                itemNode.addField("isRequest", "boolean", false)
                itemNode.addField("isCast", "boolean", false)
                
                itemNode.mediaData = itemData
                itemNode.isRequest = false
                itemNode.isCast = section.isCast
                
                row.appendChild(itemNode)
            end for
            
            content.appendChild(row)
        end for
        
        m.extraList.content = content
        m.extraList.visible = true
        end if
    end if
end sub

sub onExtraItemSelected()
    row = m.extraList.rowItemSelected[0]
    col = m.extraList.rowItemSelected[1]
    selectedItem = m.extraList.content.getChild(row).getChild(col)
    
    if selectedItem <> invalid then
        if not selectedItem.isCast then
            if selectedItem.mediaData <> invalid then
                ' Replace current mediaData with new one to reload screen
                m.extraList.visible = false
                m.extraList.content = invalid
                m.top.mediaData = selectedItem.mediaData
            end if
        end if
    end if
end sub

sub onRequestSelected()
    m.actionStatus.text = "Requesting..."
    
    body = { "mediaId": CInt(val(m.mediaId.toStr())), "mediaType": m.mediaType }
    if m.mediaType = "tv" then body["seasons"] = "all"
    
    m.actionTask.requestData = {
        url: getServerUrl() + "/api/v1/request"
        method: "POST"
        body: body
    }
    m.actionTask.control = "RUN"
end sub

sub onApproveSelected()
    if m.requestId = invalid then return
    m.actionStatus.text = "Approving..."
    m.actionTask.requestData = {
        url: getServerUrl() + "/api/v1/request/" + m.requestId.toStr() + "/approve"
        method: "POST"
    }
    m.actionTask.control = "RUN"
end sub

sub onDenySelected()
    if m.requestId = invalid then return
    m.actionStatus.text = "Denying..."
    m.actionTask.requestData = {
        url: getServerUrl() + "/api/v1/request/" + m.requestId.toStr() + "/deny"
        method: "POST"
    }
    m.actionTask.control = "RUN"
end sub

sub onResolveSelected()
    if m.requestId = invalid then return
    m.actionStatus.text = "Resolving..."
    m.actionTask.requestData = {
        url: getServerUrl() + "/api/v1/issue/" + m.requestId.toStr() + "/resolve"
        method: "POST"
    }
    m.actionTask.control = "RUN"
end sub

sub onIssueSelected()
    m.issueTypeDialog = CreateObject("roSGNode", "Dialog")
    m.issueTypeDialog.title = "Select Issue Type"
    m.issueTypeDialog.buttons = ["Video", "Audio", "Subtitles", "Other", "Cancel"]
    m.issueTypeDialog.observeField("buttonSelected", "onIssueTypeSelected")
    m.top.getScene().dialog = m.issueTypeDialog
end sub

sub onIssueTypeSelected(event)
    dialog = event.getRoSGNode()
    btnIdx = dialog.buttonSelected
    dialog.close = true
    
    if btnIdx = 4 then
        m.issueBtn.setFocus(true)
        return ' Cancelled
    end if
    
    ' issueType mapping: 1=Video, 2=Audio, 3=Subtitles, 4=Other
    m.selectedIssueType = btnIdx + 1
    
    keyboardDialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    keyboardDialog.title = "Describe the Issue"
    keyboardDialog.buttons = ["Submit", "Cancel"]
    keyboardDialog.observeFieldScoped("buttonSelected", "onIssueDialogComplete")
    m.top.getScene().dialog = keyboardDialog
end sub

sub onIssueDialogComplete(event)
    dialog = event.getRoSGNode()
    if dialog.buttonSelected = 0 then
        text = dialog.text
        m.actionStatus.text = "Submitting Issue..."
        m.actionTask.requestData = {
            url: getServerUrl() + "/api/v1/issue"
            method: "POST"
            body: {
                "mediaId": CInt(val(m.mediaId.toStr())),
                "issueType": m.selectedIssueType,
                "message": text
            }
        }
        m.actionTask.control = "RUN"
    end if
    m.top.getScene().dialog = invalid
    m.issueBtn.setFocus(true)
end sub

sub onBackSelected()
    m.top.actionComplete = true
end sub

sub onActionResponse()
    resp = m.actionTask.response
    if resp.code = 200 or resp.code = 201 then
        m.actionStatus.text = "Success!"
        m.top.actionComplete = true
    else if resp.code = 400 then
        m.actionStatus.text = "Error 400: " + Left(resp.body, 100)
    else
        m.actionStatus.text = "Failed (" + resp.code.toStr() + ")"
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if press then
        if key = "right" then
            if m.requestBtn.hasFocus() then
                m.issueBtn.setFocus(true)
                handled = true
            else if m.approveBtn.hasFocus() then
                m.denyBtn.setFocus(true)
                handled = true
            else if m.denyBtn.hasFocus() then
                m.issueBtn.setFocus(true)
                handled = true
            else if m.issueBtn.hasFocus() then
                m.backBtn.setFocus(true)
                handled = true
            else if m.resolveBtn.hasFocus() then
                m.backBtn.setFocus(true)
                handled = true
            end if
        else if key = "left" then
            if m.backBtn.hasFocus() then
                if m.resolveBtn.visible then
                    m.resolveBtn.setFocus(true)
                else
                    m.issueBtn.setFocus(true)
                end if
                handled = true
            else if m.issueBtn.hasFocus() then
                if m.denyBtn.visible then
                    m.denyBtn.setFocus(true)
                else if m.requestBtn.visible then
                    m.requestBtn.setFocus(true)
                end if
                handled = true
            else if m.denyBtn.hasFocus() then
                m.approveBtn.setFocus(true)
                handled = true
            end if
        else if key = "down" then
            if m.requestBtn.hasFocus() or m.approveBtn.hasFocus() or m.denyBtn.hasFocus() or m.issueBtn.hasFocus() or m.resolveBtn.hasFocus() or m.backBtn.hasFocus() then
                if m.extraList.visible then
                    if m.extraList.content <> invalid then
                        if m.extraList.content.getChildCount() > 0 then
                            m.extraList.setFocus(true)
                            handled = true
                        else
                            m.backBtn.setFocus(true)
                            handled = true
                        end if
                    else
                        m.backBtn.setFocus(true)
                        handled = true
                    end if
                else
                    m.backBtn.setFocus(true)
                    handled = true
                end if
            end if
        else if key = "up" then
            if m.extraList.hasFocus() then
                if m.requestBtn.visible then
                    m.requestBtn.setFocus(true)
                else if m.approveBtn.visible then
                    m.approveBtn.setFocus(true)
                else if m.resolveBtn.visible then
                    m.resolveBtn.setFocus(true)
                else
                    m.backBtn.setFocus(true)
                end if
                handled = true
            else if m.backBtn.hasFocus() then
                if m.approveBtn.visible then
                    m.approveBtn.setFocus(true)
                else if m.requestBtn.visible then
                    m.requestBtn.setFocus(true)
                else if m.resolveBtn.visible then
                    m.resolveBtn.setFocus(true)
                end if
                handled = true
            end if
        else if key = "back" then
            m.top.actionComplete = true
            handled = true
        end if
    end if
    return handled
end function

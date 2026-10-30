sub init()
    m.background = m.top.findNode("background")
    m.avatar = m.top.findNode("avatar")
    m.usernameLabel = m.top.findNode("usernameLabel")
    m.emailLabel = m.top.findNode("emailLabel")
end sub

sub onContentChange()
    content = m.top.itemContent
    if content <> invalid then
        user = content.mediaData
        if user <> invalid then
            if user.avatar <> invalid then
                if user.avatar <> "" then
                    avatarUrl = user.avatar
                    if avatarUrl.StartsWith("/") then
                        sec = CreateObject("roRegistrySection", "SeerrAuth")
                        serverUrl = ""
                        if sec.Exists("serverUrl") then serverUrl = sec.Read("serverUrl")
                        if serverUrl <> "" then avatarUrl = serverUrl + avatarUrl
                    end if
                    m.avatar.uri = avatarUrl
                else
                    m.avatar.uri = "pkg:/images/icon_focus_hd.png" ' fallback
                end if
            else
                m.avatar.uri = "pkg:/images/icon_focus_hd.png" ' fallback
            end if
            
            if user.displayName <> invalid then
                m.usernameLabel.text = user.displayName
            else if user.username <> invalid then
                m.usernameLabel.text = user.username
            else
                m.usernameLabel.text = "Unknown"
            end if
            
            if user.email <> invalid then
                m.emailLabel.text = user.email
            else
                m.emailLabel.text = ""
            end if
        end if
    end if
end sub

sub init()
    m.serverUrlRow = m.top.findNode("serverUrlRow")
    m.usernameRow = m.top.findNode("usernameRow")
    m.passwordRow = m.top.findNode("passwordRow")
    m.saveCredentialsList = m.top.findNode("saveCredentials")
    m.loginRow = m.top.findNode("loginRow")
    m.statusLabel = m.top.findNode("statusLabel")
    m.authTask = m.top.findNode("authTask")

    m.serverUrlBg = m.top.findNode("serverUrlBg")
    m.usernameBg = m.top.findNode("usernameBg")
    m.passwordBg = m.top.findNode("passwordBg")
    m.loginBg = m.top.findNode("loginBg")

    m.serverUrlLabel = m.top.findNode("serverUrlLabel")
    m.usernameLabel = m.top.findNode("usernameLabel")
    m.passwordLabel = m.top.findNode("passwordLabel")

    ' Linear tab order for onKeyEvent's up/down/OK handling below. saveCredentialsList (a
    ' real CheckList) handles its own OK press internally; the custom Groups don't, so OK
    ' is handled explicitly for them in onKeyEvent.
    m.focusOrder = [m.serverUrlRow, m.usernameRow, m.passwordRow, m.saveCredentialsList, m.loginRow]
    m.focusBgs = [m.serverUrlBg, m.usernameBg, m.passwordBg, invalid, m.loginBg]
    ' Login gets its own resting/focused image pair since it's a permanently-colored
    ' primary button (login_bg.png), not a plain field that's only colored on focus.
    m.focusBgUnfocusedUris = [
        "pkg:/images/field_bg.png",
        "pkg:/images/field_bg.png",
        "pkg:/images/field_bg.png",
        "",
        "pkg:/images/login_bg.png"
    ]
    m.focusBgFocusedUris = [
        "pkg:/images/field_bg_focused.png",
        "pkg:/images/field_bg_focused.png",
        "pkg:/images/field_bg_focused.png",
        "",
        "pkg:/images/login_bg_focused.png"
    ]

    sec = CreateObject("roRegistrySection", "SeerrAuth")
    m.serverUrl = ""
    if sec.Exists("serverUrl") then m.serverUrl = sec.Read("serverUrl")
    m.username = ""
    if sec.Exists("lastUsername") then m.username = sec.Read("lastUsername")
    m.password = ""

    updateServerUrlLabel()
    updateUsernameLabel()
    updatePasswordLabel()

    saveCredsDefault = true
    if sec.Exists("saveCredentials") then saveCredsDefault = (sec.Read("saveCredentials") = "true")
    m.saveCredentialsList.checkedState = [saveCredsDefault]

    m.authTask.observeField("response", "onAuthResponse")
end sub

' Called explicitly by AppScene.showLogin() right after appendChild — i.e. after this
' node is actually attached to the live scene tree. setFocus() called any earlier (e.g.
' from init(), which runs during CreateObject() before attachment) doesn't reliably
' register with the platform focus manager. See CODING_NOTES.md's focus-timing note.
sub screenShown()
    if m.serverUrl = "" then
        focusItem(0)
    else if m.username = "" then
        focusItem(1)
    else
        focusItem(2)
    end if
end sub

' Sets focus on m.focusOrder[idx] and updates every row's background image to match --
' the custom Groups have no built-in focus visual of their own (unlike Button), so this
' has to be done by hand every time focus moves. Skips invalid entries in m.focusBgs
' (the CheckList slot manages its own visuals internally).
sub focusItem(idx as Integer)
    m.focusOrder[idx].setFocus(true)
    for i = 0 to m.focusBgs.Count() - 1
        bg = m.focusBgs[i]
        if bg <> invalid then
            if i = idx then
                bg.uri = m.focusBgFocusedUris[i]
            else
                bg.uri = m.focusBgUnfocusedUris[i]
            end if
        end if
    end for
end sub

' Plain "Server URL" / "Username" / "Password" as the empty-field placeholder -- once a
' value is set, the label switches to "Label: value" so you can still see what's entered.
sub updateServerUrlLabel()
    if m.serverUrl = "" then
        m.serverUrlLabel.text = "Server URL"
    else
        m.serverUrlLabel.text = "Server URL: " + m.serverUrl
    end if
end sub

sub updateUsernameLabel()
    if m.username = "" then
        m.usernameLabel.text = "Username"
    else
        m.usernameLabel.text = "Username: " + m.username
    end if
end sub

sub updatePasswordLabel()
    if m.password = "" then
        m.passwordLabel.text = "Password"
    else
        m.passwordLabel.text = "Password: " + String(Len(m.password), "*")
    end if
end sub

sub onServerUrlSelected()
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    dialog.title = "Enter Server URL (e.g. https://seerr.example.com)"
    dialog.text = m.serverUrl
    dialog.buttons = ["OK", "Cancel"]
    dialog.observeField("buttonSelected", "onServerUrlDialogComplete")
    m.top.getScene().dialog = dialog
end sub

sub onServerUrlDialogComplete(event)
    dialog = event.getRoSGNode()
    if dialog.buttonSelected = 0 then ' OK
        m.serverUrl = dialog.text
        ' Simple cleanup of trailing slash
        if Right(m.serverUrl, 1) = "/" then
            m.serverUrl = Left(m.serverUrl, Len(m.serverUrl) - 1)
        end if
    end if
    updateServerUrlLabel()
    dialog.close = true
    focusItem(1)
end sub

sub onUsernameSelected()
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    dialog.title = "Enter Username"
    dialog.text = m.username
    dialog.buttons = ["OK", "Cancel"]
    dialog.observeField("buttonSelected", "onUsernameDialogComplete")
    m.top.getScene().dialog = dialog
end sub

sub onUsernameDialogComplete(event)
    dialog = event.getRoSGNode()
    if dialog.buttonSelected = 0 then ' OK
        m.username = dialog.text
    end if
    updateUsernameLabel()
    dialog.close = true
    focusItem(2)
end sub

sub onPasswordSelected()
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    dialog.title = "Enter Password"
    dialog.secureMode = true
    dialog.buttons = ["OK", "Cancel"]
    dialog.observeField("buttonSelected", "onPasswordDialogComplete")
    m.top.getScene().dialog = dialog
end sub

sub onPasswordDialogComplete(event)
    dialog = event.getRoSGNode()
    if dialog.buttonSelected = 0 then ' OK
        m.password = dialog.text
    end if
    updatePasswordLabel()
    dialog.close = true
    focusItem(3)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    idx = -1
    for i = 0 to m.focusOrder.Count() - 1
        if m.focusOrder[i].hasFocus() then
            idx = i
            exit for
        end if
    end for
    if idx = -1 then return false

    if key = "down" and idx < m.focusOrder.Count() - 1
        focusItem(idx + 1)
        return true
    else if key = "up" and idx > 0
        focusItem(idx - 1)
        return true
    else if key = "OK" then
        if idx = 0 then
            onServerUrlSelected()
            return true
        else if idx = 1 then
            onUsernameSelected()
            return true
        else if idx = 2 then
            onPasswordSelected()
            return true
        else if idx = 4 then
            onLoginSelected()
            return true
        end if
        ' idx = 3 is the CheckList -- it handles its own OK press internally, so fall
        ' through and let the key event continue propagating rather than swallowing it.
    end if
    return false
end function

sub onLoginSelected()
    if m.serverUrl = "" or m.username = "" or m.password = "" then
        m.statusLabel.text = "Please enter server URL, username, and password"
        return
    end if

    if LCase(m.serverUrl).StartsWith("http://") then
        dialog = CreateObject("roSGNode", "Dialog")
        dialog.title = "Insecure Connection"
        dialog.message = "This server URL uses http://, not https://. Your username and password will be sent unencrypted. Continue anyway?"
        dialog.buttons = ["Continue", "Cancel"]
        dialog.observeField("buttonSelected", "onHttpWarningComplete")
        m.top.getScene().dialog = dialog
        return
    end if

    doLogin()
end sub

sub onHttpWarningComplete(event)
    dialog = event.getRoSGNode()
    proceed = (dialog.buttonSelected = 0) ' Continue
    dialog.close = true
    if proceed then doLogin()
end sub

sub doLogin()
    m.statusLabel.text = "Logging in..."
    m.authTask.requestData = {
        url: m.serverUrl + "/api/v1/auth/jellyfin" ' TODO: only Jellyfin-backed auth is supported; plain Overseerr local auth needs its own flow.
        method: "POST"
        body: {
            username: m.username,
            password: m.password
        }
    }
    m.authTask.control = "RUN"
end sub

sub onAuthResponse()
    resp = m.authTask.response
    if resp.code = 200 then
        cookieStr = ""
        if resp.headers <> invalid then
            if resp.headers["set-cookie"] <> invalid then
                fullCookie = resp.headers["set-cookie"]
                ' Extract up to the first semicolon
                semicolonIndex = fullCookie.Instr(";")
                if semicolonIndex > 0 then
                    cookieStr = fullCookie.Left(semicolonIndex)
                else
                    cookieStr = fullCookie
                end if
            end if
        end if

        ' connectSid/serverUrl are always written — they're the only cross-screen session
        ' store this app has, so every other screen breaks mid-session without them. The
        ' checkbox instead controls whether main.brs wipes them when the channel actually
        ' closes (see forgetSessionIfNotSaved), not whether they're written at all.
        sec = CreateObject("roRegistrySection", "SeerrAuth")
        sec.Write("connectSid", cookieStr)
        sec.Write("serverUrl", m.serverUrl)
        sec.Write("lastUsername", m.username)
        if m.saveCredentialsList.checkedState[0] then
            sec.Write("saveCredentials", "true")
        else
            sec.Write("saveCredentials", "false")
        end if
        sec.Flush()

        m.top.loginSuccess = true
    else
        m.statusLabel.text = "Login failed. Code: " + resp.code.toStr() + " Body: " + Left(resp.body, 200)
    end if
end sub

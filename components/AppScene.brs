sub init()
    m.contentGroup = m.top.findNode("contentGroup")
    m.eggPresses = 0
    m.eggLastPress = 0
    sec = CreateObject("roRegistrySection", "SeerrAuth")

    if sec.Exists("connectSid") and sec.Exists("serverUrl") then
        showDashboard()
    else
        showLogin()
    end if
end sub

' Undocumented: mash "rewind" 5x within 2s of each other, from anywhere in the
' app, for a small thank-you. See CODING_NOTES.md "Easter Eggs".
function onKeyEvent(key as String, press as Boolean) as Boolean
    if press and key = "rewind" then
        now = CreateObject("roDateTime").AsSeconds()
        if now - m.eggLastPress > 2 then m.eggPresses = 0
        m.eggLastPress = now
        m.eggPresses = m.eggPresses + 1
        if m.eggPresses >= 5 then
            m.eggPresses = 0
            showEasterEgg()
            return true
        end if
    end if
    return false
end function

sub showEasterEgg()
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "You found it"
    dialog.message = "Thanks for actually reading the source. Go request something good."
    dialog.buttons = ["Nice"]
    dialog.observeField("buttonSelected", "onEasterEggDismissed")
    m.top.dialog = dialog
end sub

sub onEasterEggDismissed()
    m.top.dialog.close = true
end sub

sub showLogin()
    m.contentGroup.removeChildren(m.contentGroup.getChildren(-1, 0))
    m.loginView = CreateObject("roSGNode", "LoginScreen")
    m.loginView.observeField("loginSuccess", "onLoginSuccess")
    m.contentGroup.appendChild(m.loginView)
    ' screenShown() (not setFocus() here, and not from LoginScreen's own init()) is what
    ' actually requests focus — init() runs during CreateObject(), before appendChild above
    ' has attached the node to the live tree, and Roku's focus manager doesn't reliably
    ' honor setFocus() on an unattached node. Calling it here guarantees attachment already
    ' happened. See CODING_NOTES.md's focus-timing note.
    '
    ' A custom <function> declared in a component's <interface> block is invoked from
    ' outside via callFunc(), not a direct method call -- direct dot-call syntax only
    ' resolves interface *fields*. Calling it as m.loginView.screenShown() crashed with
    ' "Function Call Operator ( ) attempted on non-function" on every single launch that
    ' reached showLogin(), confirmed via brs-node CLI emulation (fresh registry, no
    ' network involved) -- this was the real cause of every "stuck on splash" report.
    m.loginView.callFunc("screenShown")
end sub

sub showDashboard()
    m.contentGroup.removeChildren(m.contentGroup.getChildren(-1, 0))
    m.dashboardView = CreateObject("roSGNode", "DashboardScreen")
    m.dashboardView.observeField("logout", "onLogout")
    m.contentGroup.appendChild(m.dashboardView)
    m.dashboardView.setFocus(true)
end sub

' The Dashboard's "Logout" item only flipped m.top.logout to swap the current view back
' to LoginScreen — it never actually cleared SeerrAuth, so the session silently came back
' on the next app launch (AppScene.init()'s registry check would still find it). Logout
' needs to actually forget the session, not just navigate away from it.
sub onLogout()
    sec = CreateObject("roRegistrySection", "SeerrAuth")
    sec.Delete("connectSid")
    sec.Delete("serverUrl")
    sec.Delete("lastUsername")
    sec.Flush()
    showLogin()
end sub

sub onLoginSuccess()
    showDashboard()
end sub

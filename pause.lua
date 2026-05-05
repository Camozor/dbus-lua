local Dbus = require("dbus-lua.dbus")

local dbus = Dbus:new()
assert(dbus:connect())

dbus:call_method({
	path = "/org/mpris/MediaPlayer2",
	interface = "org.mpris.MediaPlayer2.Player",
	member = "Pause",
	destination = "org.mpris.MediaPlayer2.spotify",
})

local Dbus = require("dbus-lua.dbus")

local dbus = Dbus:new()
assert(dbus:connect())

print("PAUSE")
dbus:call_method({
	path = "/org/mpris/MediaPlayer2",
	interface = "org.mpris.MediaPlayer2.Player",
	member = "Pause",
	destination = "org.mpris.MediaPlayer2.spotify",
})

os.execute("sleep 1")

print("PLAY")
dbus:call_method({
	path = "/org/mpris/MediaPlayer2",
	interface = "org.mpris.MediaPlayer2.Player",
	member = "Play",
	destination = "org.mpris.MediaPlayer2.spotify",
})

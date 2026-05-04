local Dbus = require("dbus-lua.dbus")
local wire = require("dbus-lua.wire")

local dbus = Dbus:new()
assert(dbus:connect())

dbus:call_method({
	path = "/org/mpris/MediaPlayer2",
	interface = "org.mpris.MediaPlayer2.Player",
	member = "Seek",
	destination = "org.mpris.MediaPlayer2.spotify",
	body = { kind = wire.DbusKind.Int64, value = 60000000 },
})

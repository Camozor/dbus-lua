# D-Bus Lua

A D-Bus client for LuaJIT 5.1. Entirely written in lua, no dependencies.

This is a work in progress. DO NOT USE THIS IN PRODUCTION.

## Installation

Example with Lazy:

```lua
{ "Camozor/dbus-lua" },
```

## Usage

```lua
local Dbus = require("dbus-lua.dbus")
local dbus = Dbus:new()
assert(dbus:connect())

dbus:call_method({
    path = "/org/mpris/MediaPlayer2",
    interface = "org.mpris.MediaPlayer2.Player",
    member = "Play",
    destination = "org.mpris.MediaPlayer2.spotify",
})
```

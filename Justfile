pause:
		LUA_PATH="./lua/?.lua;;" luajit pause.lua

seek:
		LUA_PATH="./lua/?.lua;;" luajit seek.lua

fmt:
		stylua . --config-path=.stylua.toml

test:
		LUA_PATH="./lua/?.lua;;" busted lua/dbus-lua/test/

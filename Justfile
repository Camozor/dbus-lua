run:
		LUA_PATH="./lua/?.lua;;" luajit pause.lua

fmt:
		stylua . --config-path=.stylua.toml

test:
		LUA_PATH="./lua/?.lua;;" busted lua/

run:
		luajit src/socket.lua
socket:
		luajit src/test_socket.lua

test:
		busted test

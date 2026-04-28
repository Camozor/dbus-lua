run:
		luajit src/socket.lua
socket:
		luajit src/test_socket.lua

fmt:
		stylua .

test:
		busted test

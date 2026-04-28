local socket = require("src.socket")

local s = socket()

local err = s:connect("/tmp/test.sock")
if err then
	error(err)
end

err = s:send("Hello world")
if err then
	error(err)
end

local received, received_err = s:receive()
if received_err then
	error(received_err)
end

print("Received data: " .. received)
s:close()

print("Closed")

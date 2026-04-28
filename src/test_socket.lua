local socket = require("src.socket")

local s = socket()

s:connect("/tmp/test.sock")
s:send("Hello world")
local received = s:receive()
print("Received data: " .. received)
s:close()

print("Closed")

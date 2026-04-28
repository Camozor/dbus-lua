local socket = require("src.socket")

local s = assert(socket())
assert(s:connect("/tmp/test.sock"))

assert(s:send("Hello from lua"))

local received = assert(s:receive())
print("Received data: " .. received)

s:close()
print("Closed")

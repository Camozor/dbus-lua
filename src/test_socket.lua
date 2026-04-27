local socket = require("src.socket")

local s = socket()

s:connect("/tmp/test.sock")
s:send("Hello world")
s:close()

print("Closed")

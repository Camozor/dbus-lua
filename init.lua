local socket = require("socket.unix") -- Requires LuaSocket

-- 1. Configuration
-- The session bus address is usually found in $DBUS_SESSION_BUS_ADDRESS
-- Example path: /run/user/1000/bus
local bus_path = os.getenv("DBUS_SESSION_BUS_ADDRESS"):gsub("unix:path=", "")
local uid = tostring(os.execute("id -u") and "1000") -- Simplified UID lookup

-- 2. Connect to the Unix Domain Socket
local client = assert(socket())
assert(client:connect(bus_path))

-- 3. The "Null Byte" Handshake
-- This is required by the D-Bus spec as the very first byte
client:send("\0")

-- 4. Convert UID to Hex
-- D-Bus expects the UID in hex (e.g., "1000" becomes "31303030")
local function to_hex(str)
	return (str:gsub(".", function(c)
		return string.format("%02x", string.byte(c))
	end))
end

local hex_uid = to_hex(uid)

-- 5. The SASL AUTH Exchange
print("--> AUTH EXTERNAL " .. hex_uid)
client:send("AUTH EXTERNAL " .. hex_uid .. "\r\n")

local response = client:receive("*l")
print("<-- " .. response)

if response:match("^OK") then
	-- 6. Negotiate Unix File Descriptors
	-- We tell the daemon we are ready to proceed
	client:send("BEGIN\r\n")
	print("--> BEGIN")
	print("Authentication Successful!")
else
	print("Authentication Failed: " .. tostring(response))
	os.exit(1)
end

-- 7. Mandatory "Hello" Method Call
-- After auth, you MUST call Hello to get your Unique Name
-- Note: This requires building a binary D-Bus packet, which is the next step.
print("Connection is now open and authenticated.")

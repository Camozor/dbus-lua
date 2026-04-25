local socket = require("socket.unix") -- Requires LuaSocket

print("Connecting to: " .. tostring(os.getenv("DBUS_SESSION_BUS_ADDRESS")))

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

-- Helper to pack a 32-bit integer into a little-endian string (4 bytes)
local function pack_uint32(n)
	local b1 = n % 256
	n = (n - b1) / 256
	local b2 = n % 256
	n = (n - b2) / 256
	local b3 = n % 256
	n = (n - b3) / 256
	local b4 = n % 256
	return string.char(b1, b2, b3, b4)
end

-- Helper to pack a single byte
local function pack_byte(b)
	return string.char(b)
end

-- Helper to pack a D-Bus string (Length + String + Null Terminator)
local function pack_dbus_string(s)
	return pack_uint32(#s) .. s .. "\0"
end

-- 1. Fixed Header Constants
local IS_LITTLE_ENDIAN = 0x6c -- 'l' for little endian
local TYPE_METHOD_CALL = 0x01
local FLAGS_NONE = 0x00
local VERSION = 0x01
local SERIAL = 0x01 -- Our first message

-- 2. Variable Header Fields (The "Routing" info)
-- Each field is a 'struct' { byte: code, variant: value }
-- Field codes: 1=Path, 2=Interface, 3=Member, 6=Destination
local function pack_header_field(code, sig, value)
	local s = pack_byte(code)
	s = s .. pack_byte(#sig) .. sig .. "\0"

	-- Align value to 4-byte boundary (standard for D-Bus strings/paths)
	while #s % 4 ~= 0 do
		s = s .. "\0"
	end
	s = s .. pack_dbus_string(value)

	-- Align the whole field entry to 8-byte boundary
	while #s % 8 ~= 0 do
		s = s .. "\0"
	end
	return s
end

-- Build the fields for the Hello call
local fields = ""
fields = fields .. pack_header_field(1, "o", "/org/freedesktop/DBus") -- Path
fields = fields .. pack_header_field(2, "s", "org.freedesktop.DBus") -- Interface
fields = fields .. pack_header_field(3, "s", "Hello") -- Member
fields = fields .. pack_header_field(6, "s", "org.freedesktop.DBus") -- Destination

-- 3. Assemble the Final Packet
local body_length = 0
local fields_length = #fields

-- The fixed header is exactly 12 bytes
local fixed_header = pack_byte(IS_LITTLE_ENDIAN)
	.. pack_byte(TYPE_METHOD_CALL)
	.. pack_byte(FLAGS_NONE)
	.. pack_byte(VERSION)
	.. pack_uint32(body_length)
	.. pack_uint32(SERIAL)

-- The Full Header: Fixed (12) + Fields Length (4) + Fields + Padding
local full_header = fixed_header .. pack_uint32(fields_length) .. fields

-- Crucial: Pad the entire header to an 8-byte boundary before the body
while #full_header % 8 ~= 0 do
	full_header = full_header .. "\0"
end

-- Helper to unpack a 32-bit little-endian integer from a string at a specific position
local function unpack_uint32(str, pos)
	local b1, b2, b3, b4 = str:byte(pos, pos + 3)
	return b1 + (b2 * 256) + (b3 * 65536) + (b4 * 16777216)
end

-- 4. Send and Listen for our Unique Name
client:send(full_header)
print("--> Sent Binary Hello")

local response_header, err = client:receive(16) -- Read enough to get the lengths
if not response_header then
	print("Error receiving header: " .. tostring(err))
	return
end

-- In a real app, you'd parse the lengths here and read the rest
local full_response = client:receive(128)

print("<-- Received Unique Name response!")

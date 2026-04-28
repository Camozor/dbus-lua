local socket = require("src.socket")

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

local response = assert(client:receive())
print("<-- " .. response)

if response:match("^OK") then
	-- 6. Negotiate Unix File Descriptors
	-- We tell the daemon we are ready to proceed
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
-- local function pack_header_field(code, sig, value)
-- 	local s = pack_byte(code)
-- 	s = s .. pack_byte(#sig) .. sig .. "\0"
--
-- 	-- Align value to 4-byte boundary (standard for D-Bus strings/paths)
-- 	while #s % 4 ~= 0 do
-- 		s = s .. "\0"
-- 	end
-- 	s = s .. pack_dbus_string(value)
--
-- 	-- Align the whole field entry to 8-byte boundary
-- 	while #s % 8 ~= 0 do
-- 		s = s .. "\0"
-- 	end
-- 	return s
-- end
local function pack_header_field(code, sig, value)
	-- 1. The Struct starts with a byte (code)
	local s = pack_byte(code)
	-- 2. Then a signature (variant) which is: byte length + string + \0
	s = s .. pack_byte(#sig) .. sig .. "\0"

	-- 3. The value inside the variant must be 4-aligned (for strings/paths)
	while #s % 4 ~= 0 do
		s = s .. "\0"
	end
	s = s .. pack_dbus_string(value)

	-- 4. THE KEY: The entire field must be padded to 8 bytes
	-- so the NEXT field starts aligned.
	while #s % 8 ~= 0 do
		s = s .. "\0"
	end
	return s
end

-- Build the fields for the Hello call
-- -- 1. Build the fields string first to know its length
local fields = ""
fields = fields .. pack_header_field(1, "o", "/org/freedesktop/DBus")
fields = fields .. pack_header_field(2, "s", "org.freedesktop.DBus")
fields = fields .. pack_header_field(3, "s", "Hello")
fields = fields .. pack_header_field(6, "s", "org.freedesktop.DBus")

-- 2. Fixed Header (12 bytes)
local fixed_header = pack_byte(IS_LITTLE_ENDIAN) -- 0x6c
	.. pack_byte(TYPE_METHOD_CALL) -- 0x01
	.. pack_byte(FLAGS_NONE) -- 0x00
	.. pack_byte(VERSION) -- 0x01
	.. pack_uint32(0) -- Body Length (Hello has no body)
	.. pack_uint32(1) -- Serial

-- 3. The "Variable Header" must start with the length of the fields array
local fields_length = #fields
local hello_packet = fixed_header .. pack_uint32(fields_length) .. fields

-- 4. Final Alignment: The whole header must be padded to 8 bytes
while #hello_packet % 8 ~= 0 do
	hello_packet = hello_packet .. "\0"
end

client:send("BEGIN\r\n")
print("--> BEGIN")
print("Authentication Successful!")

local stream = "BEGIN\r\n" .. hello_packet

client:send(stream)
print("--> Sent Binary Hello")

local function hex_dump(str)
	local dump = {}
	for i = 1, #str do
		table.insert(dump, string.format("%02x", str:byte(i)))
	end
	return table.concat(dump, " ")
end

print("<-- Header Hex: " .. hex_dump(hello_packet))
print("Header length= " .. #fixed_header)
print("Sending packet of length: " .. #hello_packet)

local response_header, err = client:receive(16) -- Read enough to get the lengths
if not response_header then
	print("Error receiving header: " .. tostring(err))
	return
end

-- In a real app, you'd parse the lengths here and read the rest
local full_response = client:receive(128)

print("<-- Received Unique Name response!")

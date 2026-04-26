local dbus_send_hello =
	"\x6c\x01\x00\x01\x00\x00\x00\x00\x01\x00\x00\x00\x6e\x00\x00\x00\x01\x01\x6f\x00\x15\x00\x00\x00\x2f\x6f\x72\x67\x2f\x66\x72\x65\x65\x64\x65\x73\x6b\x74\x6f\x70\x2f\x44\x42\x75\x73\x00\x00\x00\x06\x01\x73\x00\x14\x00\x00\x00\x6f\x72\x67\x2e\x66\x72\x65\x65\x64\x65\x73\x6b\x74\x6f\x70\x2e\x44\x42\x75\x73\x00\x00\x00\x00\x02\x01\x73\x00\x14\x00\x00\x00\x6f\x72\x67\x2e\x66\x72\x65\x65\x64\x65\x73\x6b\x74\x6f\x70\x2e\x44\x42\x75\x73\x00\x00\x00\x00\x03\x01\x73\x00\x05\x00\x00\x00\x48\x65\x6c\x6c\x6f\x00\x00\x00"

local IS_LITTLE_ENDIAN = 0x6c -- 'l' for little endian
local METHOD_CALL = 0x01
local FLAGS_NONE = 0x00
local PROTOCOL_VERSION = 0x01

local SERIAL = 0x01

local function pack_byte(b)
	return string.char(b)
end

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

local function hex_dump(str)
	local dump = {}
	for i = 1, #str do
		table.insert(dump, string.format("%02x", str:byte(i)))
	end
	return table.concat(dump, " ")
end

local function compute_header()
	return pack_byte(IS_LITTLE_ENDIAN) .. pack_byte(METHOD_CALL) .. pack_byte(FLAGS_NONE) .. pack_byte(PROTOCOL_VERSION)
end

local header = compute_header()
print(hex_dump(header))
print(hex_dump(dbus_send_hello))

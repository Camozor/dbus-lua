---@enum DbusMessageType
local DbusMessageType = {
	Method = "method",
	Signal = "signal",
}

---@class DbusMessage
---@field message_type DbusMessageType

local M = {}

M.DbusMessageType = DbusMessageType

---@param n number
---@return string
M.encode_uint32 = function(n)
	local b1 = n % 256
	n = (n - b1) / 256
	local b2 = n % 256
	n = (n - b2) / 256
	local b3 = n % 256
	n = (n - b3) / 256
	local b4 = n % 256
	return string.char(b1, b2, b3, b4)
end

---@param b number
---@return string
M.encode_byte = function(b)
	return string.char(b)
end

---@param s string
---@return string
M.encode_string = function(s)
	return M.encode_uint32(#s) .. s .. "\0"
end

---@param s string
---@return string
M.pretty_hex_dump = function(s)
	local dump = {}
	for i = 1, #s do
		table.insert(dump, string.format("%02x", s:byte(i)))
	end
	return table.concat(dump, " ")
end

---@param n number
---@param marshaled string
---@return string
M.pack_byte = function(n, marshaled)
	return marshaled .. M.encode_byte(n)
end

---@param n number
---@param marshaled string
---@return string
M.pack_uint32 = function(n, marshaled)
	local padding = M.compute_padding(4, marshaled)
	return marshaled .. padding .. M.encode_uint32(n)
end

---@param max_padding number
---@param marshaled string
---@return string
M.compute_padding = function(max_padding, marshaled)
	local len = -#marshaled % max_padding
	local padding = ""
	for _ = 1, len do
		padding = padding .. "\0"
	end

	return padding
end

---@param s string
---@param marshaled string
---@return string
M.pack_string = function(s, marshaled)
	local padding = M.compute_padding(4, marshaled)
	return marshaled .. padding .. M.encode_string(s)
end

---@param dbus_message DbusMessage
---@return string
M.pack_message = function(dbus_message)
	local IS_LITTLE_ENDIAN = 0x6c -- 'l' for little endian
	local METHOD_CALL = 0x01
	local FLAGS_NONE = 0x00
	local PROTOCOL_VERSION = 0x01

	local SERIAL = 0x01

	local message = ""
	message = M.pack_byte(IS_LITTLE_ENDIAN, message)
	message = M.pack_byte(METHOD_CALL, message)
	message = M.pack_byte(FLAGS_NONE, message)
	message = M.pack_byte(PROTOCOL_VERSION, message)
	message = M.pack_uint32(0, message) -- Body length TODO
	message = M.pack_uint32(SERIAL, message) -- Serial cookie TODO

	return message
end

---@enum HeaderFieldCode
local HeaderFieldCode = {
	Path = 1,
	Interface = 2,
	Member = 3,
	Destination = 6,
}

---@alias ObjectPath string

---@alias HeaderFieldValue string | ObjectPath

---@class HeaderField
---@field code HeaderFieldCode
---@field value HeaderFieldValue

---@param field HeaderField
---@return string
M.encode_header_field = function(field)
	return ""
end

return M

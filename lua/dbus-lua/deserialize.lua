local utils = require("dbus-lua.utils")
local wire = require("dbus-lua.wire")
local DbusKind = wire.DbusKind

local M = {}

---@param s string
---@param number_bytes number
---@return number decoded, number bytes_read
local function decode_uint(s, number_bytes)
	local res = 0
	for i = 1, number_bytes do
		local byte = string.byte(s, i)
		res = res + (byte * math.pow(256, i - 1))
	end

	return res, number_bytes
end

---@param s string
---@return number decoded, number bytes_read
M.decode_uint16 = function(s)
	return decode_uint(s, 2)
end

---@param s string
---@return number decoded, number bytes_read
M.decode_uint32 = function(s)
	return decode_uint(s, 4)
end

---@param s string
---@return number decoded, number bytes_read
M.decode_uint64 = function(s)
	return decode_uint(s, 8)
end

---@param s string
---@return number decoded, number bytes_read
M.decode_byte = function(s)
	return string.byte(s), 1
end

---@param s string
---@return string deserialized, number bytes_read
M.decode_string = function(s)
	local length_str = s:sub(1, 4)
	local length = M.decode_uint32(length_str)
	local deserialized = s:sub(5, 5 + length - 1)

	return deserialized, (#length_str + length + 1)
end

---@param marshalled string
---@return DbusType type, number bytes_read
M.unpack_byte = function(marshalled)
	local s = marshalled:sub(1)
	local number, bytes_read = M.decode_byte(s)

	---@type DbusType
	local dbus_type = { kind = DbusKind.Byte, value = number }

	return dbus_type, bytes_read
end

---@param marshalled string
---@param current_pos number
---@return DbusType type, number bytes_read
M.unpack_uint32 = function(marshalled, current_pos)
	local padding = utils.compute_difference(current_pos - 1, wire.ALIGNMENT_INT32)

	local remainder = marshalled:sub(padding + current_pos)
	local number, bytes_read = M.decode_uint32(remainder)

	---@type DbusType
	local dbus_type = { kind = DbusKind.Uint32, value = number }

	return dbus_type, padding + bytes_read
end

---@param marshalled string
---@param current_pos number
---@param signature string
---@return DbusType type, number bytes_read
M.unpack_struct = function(marshalled, current_pos, signature)
	local elements_signature = signature:sub(2, #signature - 1)

	for i = 1, #elements_signature do
		local c = elements_signature:sub(i, i)
		M.unpack_type(marshalled, 
	end

	---@type DbusType
	local struct = { kind = DbusKind.Struct, value = {} }
	return struct, 0
end

---@param marshalled string
---@param current_pos number
---@param signature string
---@return DbusType type, number bytes_read
M.unpack_type = function(marshalled, current_pos, signature)
	return { kind = DbusKind.String, value = "TODO" }, 0
end

return M

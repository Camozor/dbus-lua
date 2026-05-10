local M = {}

---@param s string
---@param number_bytes number
---@return number
local function decode_uint(s, number_bytes)
	local res = 0
	for i = 1, number_bytes do
		local byte = string.byte(s, i)
		res = res + (byte * math.pow(256, i - 1))
	end

	return res
end

---@param s string
---@return number
M.decode_uint16 = function(s)
	return decode_uint(s, 2)
end

---@param s string
---@return number
M.decode_uint32 = function(s)
	return decode_uint(s, 4)
end

---@param s string
---@return number
M.decode_uint64 = function(s)
	return decode_uint(s, 8)
end

---@param s string
---@return string deserialized, number bytes_read
M.decode_string = function(s)
	local length_str = s:sub(1, 4)
	local length = M.decode_uint32(length_str)
	local deserialized = s:sub(5, 5 + length - 1)

	return deserialized, (#length_str + length + 1)
end

M.unpack_uint32 = function(marshalled, signature) end

return M

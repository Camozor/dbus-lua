local M = {}

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

---@param str string
---@return string
M.pretty_hex_dump = function(str)
	local dump = {}
	for i = 1, #str do
		table.insert(dump, string.format("%02x", str:byte(i)))
	end
	return table.concat(dump, " ")
end

return M

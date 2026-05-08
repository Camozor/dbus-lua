local M = {}

---@param s string
---@return number
M.decode_uint32 = function(s)
	local b1, b2, b3, b4 = string.byte(s, 1, 4)
	return b1 + 256 * b2 + math.pow(256, 2) * b3 + math.pow(256, 3) * b4
end

return M

local utils = {}

---@param array table
---@param e any
---@return boolean
utils.array_contains = function(array, e)
	for _, v in ipairs(array) do
		if v == e then
			return true
		end
	end
	return false
end

---@param table table
---@return boolean
utils.is_array = function(table)
	return type(table) == "table" and table[1] ~= nil
end

---@param table table
---@return boolean
utils.is_struct = function(table)
	return type(table) == "table" and table[1] == nil
end

---@param value number
---@param step number
---@return number
utils.compute_difference = function(value, step)
	return -value % step
end

return utils

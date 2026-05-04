local utils = {}

utils.array_contains = function(array, e)
	for _, v in ipairs(array) do
		if v == e then
			return true
		end
	end
	return false
end

return utils

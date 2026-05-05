local utils = require("lua.dbus-lua.utils")

describe("utils", function()
	it("is_array", function()
		assert.equals(true, utils.is_array({ 1, 2, 3 }))
		assert.equals(false, utils.is_array({ key = "value" }))
	end)

	it("is_struct", function()
		assert.equals(false, utils.is_struct({ 1, 2, 3 }))
		assert.equals(true, utils.is_struct({ key = "value" }))
	end)
end)

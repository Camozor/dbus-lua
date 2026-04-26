local numbers = require("src.numbers")

describe("Busted unit testing framework", function()
	it("should be hello world", function()
		assert.equals(numbers.hello_world(), "hello world")
	end)
end)

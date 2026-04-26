local numbers = require("src.numbers")

describe("numbers", function()
	it("pack_uint32", function()
		local first = numbers.pretty_hex_dump(numbers.pack_uint32(10))
		assert.equals(first, "0a 00 00 00")

		local second = numbers.pretty_hex_dump(numbers.pack_uint32(256))
		assert.equals(second, "00 01 00 00")
	end)
end)

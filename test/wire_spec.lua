local wire = require("src.wire")

describe("numbers", function()
	it("pack_uint32", function()
		local first = wire.pretty_hex_dump(wire.encode_uint32(10))
		assert.equals(first, "0a 00 00 00")

		local second = wire.pretty_hex_dump(wire.encode_uint32(256))
		assert.equals(second, "00 01 00 00")
	end)
end)

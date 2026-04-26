local wire = require("src.wire")

describe("numbers", function()
	it("encode_uint32", function()
		local first = wire.pretty_hex_dump(wire.encode_uint32(10))
		assert.equals(first, "0a 00 00 00")

		local second = wire.pretty_hex_dump(wire.encode_uint32(256))
		assert.equals(second, "00 01 00 00")
	end)

	it("pack_uint32", function()
		local m = wire.pack_byte(255, "")
		local packed = wire.pack_uint32(255, m)
		assert.equals(wire.pretty_hex_dump(packed), "ff 00 00 00 ff 00 00 00")
	end)
end)

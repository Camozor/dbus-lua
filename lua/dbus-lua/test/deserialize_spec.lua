local deserialize = require("lua.dbus-lua.deserialize")
local wire = require("lua.dbus-lua.wire")

describe("deserialize", function()
	describe("decode_uint32", function()
		it("basic number", function()
			local serialized = wire.encode_uint32(123456789)
			local n = deserialize.decode_uint32(serialized)
			assert.equals(123456789, n)
		end)
	end)

	describe("decode_string", function()
		it("basic string", function()
			local serialized = wire.encode_string("hello")
			local deserialized, bytes_read = deserialize.decode_string(serialized)

			assert.equals("hello", deserialized)
			assert.equals(10, bytes_read)
		end)
	end)

	describe("unpack_uint32", function()
		it("with some padding", function()
			local padding = "\0\0\0"
			local serialized = padding .. wire.encode_uint32(13433)

			local unpacked, read_bytes = deserialize.unpack_uint32(serialized, 2)
			assert.equals(wire.DbusKind.Uint32, unpacked.kind)
			assert.equals(13433, unpacked.value)
			assert.equals(7, read_bytes)
		end)
	end)
end)

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
			local serialized = wire.pack_fixed_byte(255, "")
			serialized = wire.pack_fixed_byte(14, serialized)
			serialized = wire.pack_fixed_byte(42, serialized)
			serialized = wire.pack_fixed_uint32(13433, serialized)

			local unpacked, read_bytes = deserialize.unpack_uint32(serialized, 4)
			assert.equals(wire.DbusKind.Uint32, unpacked.kind)
			assert.equals(13433, unpacked.value)
			assert.equals(5, read_bytes)
		end)
	end)

	describe("unpack_struct", function()
		it("unpack struct", function()
			local serialized = wire.pack_fixed_byte(255, "")

			---@type DbusType
			local struct = {
				kind = wire.DbusKind.Struct,
				value = { { kind = wire.DbusKind.Int32, value = 1 }, { kind = wire.DbusKind.Int32, value = 2 } },
			}

			serialized = wire.pack_struct(struct, serialized)

			local unpacked, _ = deserialize.unpack_struct(serialized, 2, "(ii)")
			assert.equals(wire.DbusKind.Struct, unpacked.kind)
		end)
	end)
end)

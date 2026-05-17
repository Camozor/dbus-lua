local wire = require("lua.dbus-lua.wire")
local DbusKind = wire.DbusKind

describe("numbers", function()
	describe("compute_padding", function()
		it("empty", function()
			local padding = wire.compute_padding(4, "")
			assert.equals("", wire.pretty_hex_dump(padding))
		end)

		it("non empty", function()
			local padding = wire.compute_padding(4, wire.pack_fixed_byte(255, ""))
			assert.equals("00 00 00", wire.pretty_hex_dump(padding))
		end)
	end)

	describe("encode_int32", function()
		it("positive number", function()
			local encoded = wire.encode_int32(6)
			assert.equals("06 00 00 00", wire.pretty_hex_dump(encoded))
		end)

		it("negative number", function()
			local encoded = wire.encode_int32(-6)
			assert.equals("fa ff ff ff", wire.pretty_hex_dump(encoded))
		end)
	end)

	it("encode_uint32", function()
		local first = wire.pretty_hex_dump(wire.encode_uint32(10))
		assert.equals("0a 00 00 00", first)

		local second = wire.pretty_hex_dump(wire.encode_uint32(256))
		assert.equals("00 01 00 00", second)
	end)

	it("encode_uint64", function()
		local first = wire.pretty_hex_dump(wire.encode_uint64(10))
		assert.equals("0a 00 00 00 00 00 00 00", first)

		local second = wire.pretty_hex_dump(wire.encode_uint64(256))
		assert.equals("00 01 00 00 00 00 00 00", second)
	end)

	it("encode_string", function()
		local s = "foo"
		local encoded = wire.encode_string(s)
		assert.equals("03 00 00 00 66 6f 6f 00", wire.pretty_hex_dump(encoded))
	end)

	it("pack_uint32", function()
		local m = wire.pack_fixed_byte(255, "")
		local packed = wire.pack_fixed_uint32(255, m)
		assert.equals("ff 00 00 00 ff 00 00 00", wire.pretty_hex_dump(packed))
	end)

	it("pack_uint64", function()
		local m = wire.pack_fixed_byte(255, "")
		local packed = wire.pack_fixed_uint64(255, m)
		assert.equals("ff 00 00 00 00 00 00 00 ff 00 00 00 00 00 00 00", wire.pretty_hex_dump(packed))
	end)

	it("pack_string", function()
		local s = "foo"
		local m = wire.pack_fixed_byte(255, "")
		local packed = wire.pack_fixed_string(s, m)
		assert.equals("ff 00 00 00 03 00 00 00 66 6f 6f 00", wire.pretty_hex_dump(packed))
	end)

	describe("pack_array", function()
		it("pack array of uint32", function()
			local m = wire.pack_fixed_uint32(10, "")

			---@type DbusType
			local array = { kind = DbusKind.Array, value = { { kind = DbusKind.Uint32, value = 5 } } }

			local packed = wire.pack_array(array, m)
			assert.equals("0a " .. "00 00 00 " .. "04 00 00 00 " .. "05 00 00 00", wire.pretty_hex_dump(packed))
		end)

		it("pack array of strings", function()
			---@type DbusType
			local array = {
				kind = DbusKind.Array,
				value = { { kind = DbusKind.String, value = "Hi" }, { kind = DbusKind.String, value = "Bye" } },
			}

			local packed = wire.pack_array(array, "")

			local hi = "02 00 00 00 " .. "48 69 00 "
			local padding = "00 "
			local bye = "03 00 00 00 " .. "42 79 65 00"
			assert.equals("10 00 00 00 " .. hi .. padding .. bye, wire.pretty_hex_dump(packed))
		end)
	end)

	describe("pack_variant", function()
		it("pack variant of uint64", function()
			---@type DbusVariant
			local variant = {
				signature = "t",
				content = { kind = DbusKind.Uint64, value = 5 },
			}

			local packed = wire.pack_variant(variant, "")

			local signature = "01 74 00 "
			local padding = "00 00 00 00 00 "
			assert.equals(signature .. padding .. "05 00 00 00 00 00 00 00", wire.pretty_hex_dump(packed))
		end)
	end)

	describe("pack_struct", function()
		it("pack struct", function()
			local m = wire.pack_fixed_byte(255, "")

			---@type DbusType
			local struct = {
				kind = DbusKind.Struct,
				value = { { kind = DbusKind.Byte, value = 0x03 }, { kind = DbusKind.String, value = "Hi" } },
			}

			local packed = wire.pack_struct(struct, m)

			local start = "ff "
			local padding_struct = "00 00 00 00 00 00 00 " -- structs are 8-aligned
			local byte = "03 "
			local padding_string = "00 00 00 "
			local hi = "02 00 00 00 " .. "48 69 00"
			assert.equals(start .. padding_struct .. byte .. padding_string .. hi, wire.pretty_hex_dump(packed))
		end)
	end)

	describe("pack_tuple", function()
		it("pack tuple", function()
			local m = wire.pack_fixed_byte(255, "")

			---@type DbusType
			local tuple = {
				kind = DbusKind.Tuple,
				value = {
					{ kind = DbusKind.ObjectPath, value = "foo" },
					{ kind = DbusKind.String, value = "bar" },
				},
			}

			local packed = wire.pack_tuple(tuple, m)
			assert.equals("ff 00 00 00 03 00 00 00 66 6f 6f 00 03 00 00 00 62 61 72 00", wire.pretty_hex_dump(packed))
		end)
	end)

	describe("compute_signature", function()
		it("single types", function()
			---@type DbusType
			local t = { kind = DbusKind.Int32, value = 1454 }

			assert.equals("i", wire.compute_signature(t))
		end)

		it("array", function()
			---@type DbusType
			local array = {
				kind = DbusKind.Array,
				value = { { kind = DbusKind.Int32, value = 1 }, { kind = DbusKind.Int32, value = 2 } },
			}

			assert.equals("ai", wire.compute_signature(array))
		end)

		it("struct", function()
			---@type DbusType
			local struct = {
				kind = DbusKind.Struct,
				value = { { kind = DbusKind.Uint32, value = 67 }, { kind = DbusKind.String, value = "Hello" } },
			}

			assert.equals("(us)", wire.compute_signature(struct))
		end)
	end)
end)

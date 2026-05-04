local utils = require("lua.dbus-lua.utils")
---@enum DbusMessageType
local DbusMessageType = {
	Method = "method",
	Signal = "signal",
}

---@class DbusMessage
---@field message_type DbusMessageType
---@field path string
---@field interface string?
---@field member string
---@field destination string
---@field serial number
---@field body? DbusType

local M = {}

M.DbusMessageType = DbusMessageType

---@param n number
---@return string
M.encode_int16 = function(n)
	local b1 = n % 256
	n = (n - b1) / 256
	local b2 = n % 256
	return string.char(b1, b2)
end

---@param n number
---@return string
M.encode_int32 = function(n)
	local b1 = n % 256
	n = (n - b1) / 256
	local b2 = n % 256
	n = (n - b2) / 256
	local b3 = n % 256
	n = (n - b3) / 256
	local b4 = n % 256
	return string.char(b1, b2, b3, b4)
end

---@param n number
---@return string
M.encode_int64 = function(n)
	local b1 = n % 256
	n = (n - b1) / 256
	local b2 = n % 256
	n = (n - b2) / 256
	local b3 = n % 256
	n = (n - b3) / 256
	local b4 = n % 256
	n = (n - b4) / 256
	local b5 = n % 256
	n = (n - b5) / 256
	local b6 = n % 256
	n = (n - b6) / 256
	local b7 = n % 256
	n = (n - b7) / 256
	local b8 = n % 256
	return string.char(b1, b2, b3, b4, b5, b6, b7, b8)
end

---@param n number
---@return string
M.encode_uint16 = function(n)
	local b1 = n % 256
	n = (n - b1) / 256
	local b2 = n % 256
	return string.char(b1, b2)
end

---@param n number
---@return string
M.encode_uint32 = function(n)
	local b1 = n % 256
	n = (n - b1) / 256
	local b2 = n % 256
	n = (n - b2) / 256
	local b3 = n % 256
	n = (n - b3) / 256
	local b4 = n % 256
	return string.char(b1, b2, b3, b4)
end

---@param n number
---@return string
M.encode_uint64 = function(n)
	local b1 = n % 256
	n = (n - b1) / 256
	local b2 = n % 256
	n = (n - b2) / 256
	local b3 = n % 256
	n = (n - b3) / 256
	local b4 = n % 256
	n = (n - b4) / 256
	local b5 = n % 256
	n = (n - b5) / 256
	local b6 = n % 256
	n = (n - b6) / 256
	local b7 = n % 256
	n = (n - b7) / 256
	local b8 = n % 256
	return string.char(b1, b2, b3, b4, b5, b6, b7, b8)
end

---@param b number
---@return string
M.encode_byte = function(b)
	return string.char(b)
end

---@param s string
---@return string
M.encode_string = function(s)
	return M.encode_uint32(#s) .. s .. "\0"
end

---@param s string
---@return string
M.encode_signature = function(s)
	return M.encode_byte(#s) .. s .. "\0"
end

---@param s string
---@return string
M.pretty_hex_dump = function(s)
	local dump = {}
	for i = 1, #s do
		table.insert(dump, string.format("%02x", s:byte(i)))
	end
	return table.concat(dump, " ")
end

---@param n number
---@param marshaled string
---@return string
M.pack_fixed_byte = function(n, marshaled)
	return marshaled .. M.encode_byte(n)
end

---@param n number
---@return string
M.pack_fixed_int16 = function(n, marshaled)
	local padding = M.compute_padding(2, marshaled)
	return marshaled .. padding .. M.encode_int16(n)
end

---@param n number
---@return string
M.pack_fixed_int32 = function(n, marshaled)
	local padding = M.compute_padding(4, marshaled)
	return marshaled .. padding .. M.encode_int32(n)
end

---@param n number
---@param marshaled string
---@return string
M.pack_fixed_int64 = function(n, marshaled)
	local padding = M.compute_padding(8, marshaled)
	return marshaled .. padding .. M.encode_int64(n)
end

---@param n number
---@return string
M.pack_fixed_uint16 = function(n, marshaled)
	local padding = M.compute_padding(2, marshaled)
	return marshaled .. padding .. M.encode_uint16(n)
end

---@param marshaled string
---@param n number
---@return string
M.pack_fixed_uint32 = function(n, marshaled)
	local padding = M.compute_padding(4, marshaled)
	return marshaled .. padding .. M.encode_uint32(n)
end

---@param n number
---@param marshaled string
---@return string
M.pack_fixed_uint64 = function(n, marshaled)
	local padding = M.compute_padding(8, marshaled)
	return marshaled .. padding .. M.encode_uint64(n)
end

---@param max_padding number
---@param marshaled string
---@return string
M.compute_padding = function(max_padding, marshaled)
	local len = -#marshaled % max_padding
	local padding = ""
	for _ = 1, len do
		padding = padding .. "\0"
	end

	return padding
end

---@param s string
---@param marshaled string
---@return string
M.pack_fixed_string = function(s, marshaled)
	local padding = M.compute_padding(4, marshaled)
	return marshaled .. padding .. M.encode_string(s)
end

---@param dbus_array DbusType[]
---@param marshaled string
---@return string
M.pack_array = function(dbus_array, marshaled)
	local marshaled_elements = ""
	for _, element in ipairs(dbus_array) do
		marshaled_elements = M.pack_type(element, marshaled_elements)
	end

	local marshaled_length = M.pack_fixed_uint32(#marshaled_elements, marshaled)

	return marshaled_length .. marshaled_elements
end

---@param dbus_type DbusType
---@param marshaled string
---@return string
M.pack_type = function(dbus_type, marshaled)
	local marshaled_result = marshaled
	if dbus_type.kind == M.DbusKind.Byte then
		marshaled_result = M.pack_fixed_byte(dbus_type.value --[[@as number]], marshaled_result)
	elseif dbus_type.kind == M.DbusKind.Int16 then
		marshaled_result = M.pack_fixed_int16(dbus_type.value --[[@as number]], marshaled_result)
	elseif dbus_type.kind == M.DbusKind.Int32 then
		marshaled_result = M.pack_fixed_int32(dbus_type.value --[[@as number]], marshaled_result)
	elseif dbus_type.kind == M.DbusKind.Int64 then
		marshaled_result = M.pack_fixed_int64(dbus_type.value --[[@as number]], marshaled_result)
	elseif dbus_type.kind == M.DbusKind.Uint16 then
		marshaled_result = M.pack_fixed_uint16(dbus_type.value --[[@as number]], marshaled_result)
	elseif dbus_type.kind == M.DbusKind.Uint32 then
		marshaled_result = M.pack_fixed_uint32(dbus_type.value --[[@as number]], marshaled_result)
	elseif dbus_type.kind == M.DbusKind.Uint64 then
		marshaled_result = M.pack_fixed_uint64(dbus_type.value --[[@as number]], marshaled_result)
	elseif dbus_type.kind == M.DbusKind.String or dbus_type.kind == M.DbusKind.ObjectPath then
		marshaled_result = M.pack_fixed_string(dbus_type.value --[[@as string]], marshaled_result)
	elseif dbus_type.kind == M.DbusKind.Array then
		marshaled_result = M.pack_array(dbus_type.value --[[@as DbusVariant]], marshaled_result)
	elseif dbus_type.kind == M.DbusKind.Struct then
		marshaled_result = M.pack_struct(dbus_type.value --[[@as DbusType[] ]], marshaled_result)
	elseif dbus_type.kind == M.DbusKind.Variant then
		marshaled_result = M.pack_variant(dbus_type.value --[[@as DbusVariant]], marshaled_result)
	elseif dbus_type.kind == M.DbusKind.Signature then
		marshaled_result = M.pack_signature(dbus_type.value --[[@as string]], marshaled_result)
	else
		print("Oops looks like I forgot a type")
	end

	return marshaled_result
end

---@param dbus_variant DbusVariant
---@param marshaled string
---@return string
M.pack_variant = function(dbus_variant, marshaled)
	local marshaled_with_signature = M.pack_signature(dbus_variant.signature, marshaled)
	local content = dbus_variant.content

	return M.pack_type(content, marshaled_with_signature)
end

---@param dbus_struct DbusType[]
---@param marshaled string
---@return string
M.pack_struct = function(dbus_struct, marshaled)
	local padding = M.compute_padding(8, marshaled)
	local marshaled_elements = marshaled .. padding

	for _, element in ipairs(dbus_struct) do
		marshaled_elements = M.pack_type(element, marshaled_elements)
	end

	return marshaled_elements
end

---@param signature string
---@param marshaled string
---@return string
M.pack_signature = function(signature, marshaled)
	return marshaled .. M.encode_signature(signature)
end

---@param dbus_message DbusMessage
---@return string
M.pack_message = function(dbus_message)
	if dbus_message.body then
		local dbus_body = dbus_message.body --[[@as DbusType]]
		local body = M.pack_message_body(dbus_body)
		local body_signature = M.compute_signature(dbus_body)

		local message = M.pack_message_header(dbus_message, { length = #body, signature = body_signature })

		return message .. body
	else
		return M.pack_message_header(dbus_message)
	end
end

---@param type DbusType
---@return string
M.compute_signature = function(type)
	local simple_types = {
		M.DbusKind.Byte,
		M.DbusKind.Boolean,
		M.DbusKind.Int16,
		M.DbusKind.Int32,
		M.DbusKind.Int64,
		M.DbusKind.Uint16,
		M.DbusKind.Uint32,
		M.DbusKind.Uint64,
		M.DbusKind.Double,
		M.DbusKind.UnixFd,
		M.DbusKind.String,
		M.DbusKind.ObjectPath,
	}
	if utils.array_contains(simple_types, type.kind) then
		return type.kind
	end

	if type.kind == M.DbusKind.Array then
	end

	if type.kind == M.DbusKind.Struct then
	end

	return ""
end

---@param dbus_body DbusType
---@return string
M.pack_message_body = function(dbus_body)
	return M.pack_type(dbus_body, "")
end

---@class BodyOpt
---@field length number
---@field signature string

---@param dbus_message DbusMessage
---@param body_opt? BodyOpt
---@return string
M.pack_message_header = function(dbus_message, body_opt)
	local LITTLE_ENDIAN = 0x6c
	local METHOD_CALL = 0x01
	local FLAGS_NONE = 0x00
	local PROTOCOL_VERSION = 0x01

	local body_option = body_opt or {}
	local body_length = body_option.length or 0

	local message = ""
	message = M.pack_fixed_byte(LITTLE_ENDIAN, message)
	message = M.pack_fixed_byte(METHOD_CALL, message)
	message = M.pack_fixed_byte(FLAGS_NONE, message)
	message = M.pack_fixed_byte(PROTOCOL_VERSION, message)
	message = M.pack_fixed_uint32(body_length, message)
	message = M.pack_fixed_uint32(dbus_message.serial, message)

	local header_fields = {}
	table.insert(header_fields, M.create_header_field({ code = M.HeaderFieldCode.Path, value = dbus_message.path }))

	if dbus_message.interface then
		table.insert(
			header_fields,
			M.create_header_field({ code = M.HeaderFieldCode.Interface, value = dbus_message.interface })
		)
	end

	table.insert(header_fields, M.create_header_field({ code = M.HeaderFieldCode.Member, value = dbus_message.member }))
	table.insert(
		header_fields,
		M.create_header_field({ code = M.HeaderFieldCode.Destination, value = dbus_message.destination })
	)

	if body_opt then
		table.insert(
			header_fields,
			M.create_header_field({ code = M.HeaderFieldCode.Signature, value = body_opt.signature })
		)
	end

	message = M.pack_array(header_fields, message)
	local end_padding = M.compute_padding(8, message)

	return message .. end_padding
end

---@enum DbusKind
M.DbusKind = {
	Byte = "y",
	Boolean = "b",
	Int16 = "n",
	Int32 = "u",
	Int64 = "x",
	Uint16 = "q",
	Uint32 = "i",
	Uint64 = "t",
	Double = "d",
	UnixFd = "h",
	String = "s",
	ObjectPath = "o",

	Signature = "g",

	Array = "a",
	Struct = "r",
	Variant = "v",
}

---@class DbusType
---@field kind DbusKind
---@field value number | boolean | string | ObjectPath | DbusType[] | DbusVariant

---@alias ObjectPath string

---@class DbusVariant
---@field signature string
---@field content DbusType

---@enum HeaderFieldCode
M.HeaderFieldCode = {
	Path = 1,
	Interface = 2,
	Member = 3,
	Destination = 6,
	Signature = 8,
}

---@class HeaderField
---@field code HeaderFieldCode
---@field value string | number

local header_type_by_code = {
	[M.HeaderFieldCode.Path] = M.DbusKind.ObjectPath,
	[M.HeaderFieldCode.Interface] = M.DbusKind.String,
	[M.HeaderFieldCode.Member] = M.DbusKind.String,
	[M.HeaderFieldCode.Destination] = M.DbusKind.String,
	[M.HeaderFieldCode.Signature] = M.DbusKind.Signature,
}

---@param field HeaderField
---@return DbusType
M.create_header_field = function(field)
	local header_type = header_type_by_code[field.code]

	return {
		kind = M.DbusKind.Struct,
		value = {
			{ kind = M.DbusKind.Byte, value = field.code },
			{
				kind = M.DbusKind.Variant,
				value = { signature = header_type, content = { kind = header_type, value = field.value } },
			},
		},
	}
end

return M

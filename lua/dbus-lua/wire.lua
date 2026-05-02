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

local M = {}

M.DbusMessageType = DbusMessageType

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
---@param marshaled string
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
		if element.kind == M.DbusKind.Byte then
			marshaled_elements = M.pack_fixed_byte(element.value --[[@as number]], marshaled_elements)
		end
		if element.kind == M.DbusKind.Uint32 then
			marshaled_elements = M.pack_fixed_uint32(element.value --[[@as number]], marshaled_elements)
		end
		if element.kind == M.DbusKind.Uint64 then
			marshaled_elements = M.pack_fixed_uint32(element.value --[[@as number]], marshaled_elements)
		end
		if element.kind == M.DbusKind.String then
			marshaled_elements = M.pack_fixed_string(element.value --[[@as string]], marshaled_elements)
		end
		if element.kind == M.DbusKind.Struct then
			marshaled_elements = M.pack_struct(element.value --[[@as DbusType[] ]], marshaled_elements)
		end
	end

	local marshaled_length = M.pack_fixed_uint32(#marshaled_elements, marshaled)

	return marshaled_length .. marshaled_elements
end

---@param dbus_variant DbusVariant
---@param marshaled string
---@return string
M.pack_variant = function(dbus_variant, marshaled)
	local marshaled_with_signature = marshaled .. M.encode_signature(dbus_variant.signature)

	local content = dbus_variant.content

	if content.kind == M.DbusKind.Byte then
		return M.pack_fixed_byte(content.value --[[@as number]], marshaled_with_signature)
	end
	if content.kind == M.DbusKind.Uint64 then
		return M.pack_fixed_uint64(content.value --[[@as number]], marshaled_with_signature)
	end
	if content.kind == M.DbusKind.Uint32 then
		return M.pack_fixed_uint32(content.value --[[@as number]], marshaled_with_signature)
	end
	if content.kind == M.DbusKind.String or content.kind == M.DbusKind.ObjectPath then
		return M.pack_fixed_string(content.value --[[@as string]], marshaled_with_signature)
	end

	return ""
end

---@param dbus_struct DbusType[]
---@param marshaled string
---@return string
M.pack_struct = function(dbus_struct, marshaled)
	local padding = M.compute_padding(8, marshaled)
	local marshaled_elements = marshaled .. padding

	for _, element in ipairs(dbus_struct) do
		if element.kind == M.DbusKind.Byte then
			marshaled_elements = M.pack_fixed_byte(element.value --[[@as number]], marshaled_elements)
		end
		if element.kind == M.DbusKind.Uint32 then
			marshaled_elements = M.pack_fixed_uint32(element.value --[[@as number]], marshaled_elements)
		end
		if element.kind == M.DbusKind.Uint64 then
			marshaled_elements = M.pack_fixed_uint32(element.value --[[@as number]], marshaled_elements)
		end
		if element.kind == M.DbusKind.String then
			marshaled_elements = M.pack_fixed_string(element.value --[[@as string]], marshaled_elements)
		end
		if element.kind == M.DbusKind.Struct then
			marshaled_elements = M.pack_struct(element.value --[[@as DbusType[] ]], marshaled_elements)
		end
		if element.kind == M.DbusKind.Variant then
			marshaled_elements = M.pack_variant(element.value --[[@as DbusVariant]], marshaled_elements)
		end
	end

	return marshaled_elements
end

---@param dbus_message DbusMessage
---@return string
M.pack_message = function(dbus_message)
	local LITTLE_ENDIAN = 0x6c
	local METHOD_CALL = 0x01
	local FLAGS_NONE = 0x00
	local PROTOCOL_VERSION = 0x01

	local message = ""
	message = M.pack_fixed_byte(LITTLE_ENDIAN, message)
	message = M.pack_fixed_byte(METHOD_CALL, message)
	message = M.pack_fixed_byte(FLAGS_NONE, message)
	message = M.pack_fixed_byte(PROTOCOL_VERSION, message)
	message = M.pack_fixed_uint32(0, message) -- Body length TODO
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

	message = M.pack_array(header_fields, message)

	local end_padding = M.compute_padding(8, message)

	return message .. end_padding
end

---@enum DbusKind
M.DbusKind = {
	Byte = "y",
	Boolean = "b",
	Int16 = "q",
	Int32 = "u",
	Uint32 = "i",
	Int64 = "x",
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
}

---@class HeaderField
---@field code HeaderFieldCode
---@field value string

---@param field HeaderField
---@return DbusType
M.create_header_field = function(field)
	local kind
	local signature

	if field.code == M.HeaderFieldCode.Path then
		kind = M.DbusKind.ObjectPath
		signature = "o"
	else
		kind = M.DbusKind.String
		signature = "s"
	end
	return {
		kind = M.DbusKind.Struct,
		value = {
			{ kind = M.DbusKind.Byte, value = field.code },
			{
				kind = M.DbusKind.Variant,
				value = { signature = signature, content = { kind = kind, value = field.value } },
			},
		},
	}
end

return M

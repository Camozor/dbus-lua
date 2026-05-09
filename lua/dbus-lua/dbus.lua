local socket = require("dbus-lua.socket")
local wire = require("dbus-lua.wire")
local deserialize = require("dbus-lua.deserialize")
local utils = require("dbus-lua.utils")

---@class DbusRawResponse
---@field header string
---@field body string?

---@class DbusMethodCallOpt
---@field path string
---@field interface string?
---@field member string
---@field destination string
---@field body DbusType?

---@class DbusConfig
---@field bus_address? string

---@class Dbus
---@field bus_address string
---@field hex_uid string
---@field client Socket
---@field serial number
local Dbus = {}

Dbus.__index = Dbus

local to_hex = function(uid)
	return (uid:gsub(".", function(c)
		return string.format("%02x", string.byte(c))
	end))
end

---@param config? DbusConfig
function Dbus:new(config)
	config = config or {}

	local bus_address = config.bus_address or os.getenv("DBUS_SESSION_BUS_ADDRESS")
	if bus_address then
		bus_address = bus_address:gsub("unix:path=", "")
	end

	local uid = "1000"
	local handle = io.popen("id -u")
	if handle then
		uid = tostring(handle:read("*l"))
		handle:close()
	end
	local hex_uid = to_hex(uid)

	return setmetatable({
		bus_address = bus_address,
		hex_uid = hex_uid,
		serial = 1,
	}, self)
end

---@return boolean success, string? error_message
function Dbus:connect()
	local client = assert(socket())
	self.client = client

	assert(client:connect(self.bus_address))

	client:send("\0")
	client:send("AUTH EXTERNAL " .. self.hex_uid .. "\r\n")

	local response = assert(client:receive())

	if not response:match("^OK") then
		print("Authentication Failed: " .. tostring(response))
		return false
	end

	client:send("BEGIN\r\n")

	self:send_hello_message()

	return true
end

function Dbus:send_hello_message()
	---@type DbusMessage
	local hello = {
		message_type = wire.DbusMessageType.Method,
		path = "/org/freedesktop/DBus",
		interface = "org.freedesktop.DBus",
		member = "Hello",
		destination = "org.freedesktop.DBus",
		serial = self.serial,
	}
	self:send_message(hello)
	self:receive_response() -- Temporary, discards signal
end

---@param opt DbusMethodCallOpt
function Dbus:call_method(opt)
	---@type DbusMessage
	local message = {
		message_type = wire.DbusMessageType.Method,
		path = opt.path,
		interface = opt.interface,
		member = opt.member,
		destination = opt.destination,
		serial = self.serial,
		body = opt.body,
	}
	self:send_message(message)
end

---@param message DbusMessage
function Dbus:send_message(message)
	local serialized_message = wire.pack_message(message)

	assert(self.client:send(serialized_message))
	self:receive_response()

	self.serial = self.serial + 1
end

---@return DbusRawResponse
function Dbus:receive_response()
	local header = self:receive_header()

	---@type DbusRawResponse
	local response = { header = header }

	local body_length_str = header:sub(5, 8)
	local body_length = deserialize.decode_uint32(body_length_str)
	if body_length > 0 then
		local body = assert(self.client:receive(body_length))
		response.body = body
	end

	return response
end

---@return string
function Dbus:receive_header()
	local first_part = assert(self.client:receive(16))
	local headers_length_str = first_part:sub(13)
	local headers_length = deserialize.decode_uint32(headers_length_str)

	local padding_length = utils.compute_difference(#first_part + headers_length, wire.ALIGNMENT_BODY)

	local last_part = assert(self.client:receive(headers_length + padding_length))
	local last_part_no_padding = last_part:sub(0, headers_length)

	return first_part .. last_part_no_padding
end

return Dbus

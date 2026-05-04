local socket = require("dbus-lua.socket")
local wire = require("dbus-lua.wire")

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

	return true
end

---@return string
function Dbus:pack_hello_message()
	---@type DbusMessage
	local message = {
		message_type = wire.DbusMessageType.Method,
		path = "/org/freedesktop/DBus",
		interface = "org.freedesktop.DBus",
		member = "Hello",
		destination = "org.freedesktop.DBus",
		serial = self.serial,
	}

	return wire.pack_message(message)
end

---@param opt DbusMethodCallOpt
function Dbus:call_method(opt)
	local hello = self:pack_hello_message()

	assert(self.client:send(hello))

	self.serial = self.serial + 1

	local response_header, err = self.client:receive(16)
	if not response_header then
		print("Error receiving header: " .. tostring(err))
		return
	end

	self.client:receive(128)

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
	local packed_message = wire.pack_message(message)

	assert(self.client:send(packed_message))

	self.serial = self.serial + 1

	local response_h, err_r = self.client:receive(16)
	if not response_h then
		print("Error receiving header: " .. tostring(err_r))
		return
	end
end

return Dbus

local ffi = require("ffi")

local AF_UNIX = 1
local SOCK_STREAM = 1

ffi.cdef([[
    typedef short sa_family_t;
    struct sockaddr_un {
        sa_family_t sun_family;
        char sun_path[108];
    };
    int socket(int domain, int type, int protocol);
    int connect(int sockfd, const struct sockaddr *addr, uint32_t addrlen);
	int read(int fd, const void *buf, size_t count);
    int write(int fd, const void *buf, size_t count);
    int close(int fd);
]])

---@class sockaddr_un: ffi.cdata*
---@field sun_family number
---@field sun_path ffi.cdata*

---@class Socket
---@field fd number
local Socket = {}
Socket.__index = Socket

---@return Socket | nil, string? error_message
local function socket()
	local s = setmetatable({}, Socket)

	s.fd = ffi.C.socket(AF_UNIX, SOCK_STREAM, 0)
	if s.fd < 0 then
		return nil, "Socket creation failed"
	end

	return s
end

---@param path string
---@return boolean success, string? error_message
function Socket:connect(path)
	local addr = ffi.new("struct sockaddr_un") --[[@as sockaddr_un]]
	addr.sun_family = AF_UNIX
	ffi.copy(addr.sun_path, path)

	if ffi.C.connect(self.fd, ffi.cast("struct sockaddr *", addr), ffi.sizeof(addr)) < 0 then
		local err = ffi.errno()
		ffi.C.close(self.fd)
		return false, "Connect failed, code: " .. tostring(err)
	end

	return true
end

---@param message string
---@return boolean success, string? error_message
function Socket:send(message)
	local bytes_written = ffi.C.write(self.fd, message, #message)

	if bytes_written > 0 then
		return true
	else
		return false, "Socket closed"
	end
end

---@param length? number
---@return string | nil received_message, string? error_message
function Socket:receive(length)
	local len = length or 1024
	local buf = ffi.new("char[?]", len)
	local bytes_read = ffi.C.read(self.fd, buf, len)

	if bytes_read > 0 then
		return ffi.string(buf, bytes_read)
	elseif bytes_read == 0 then
		return nil, "Socket closed"
	else
		local err = ffi.errno()
		return nil, "Error: " .. tostring(err)
	end
end

function Socket:close()
	ffi.C.close(self.fd)
end

return socket

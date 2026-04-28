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

---@class Socket
---@field fd number
local Socket = {}
Socket.__index = Socket

---@return Socket
local function socket()
	local s = setmetatable({}, Socket)

	local fd = ffi.C.socket(AF_UNIX, SOCK_STREAM, 0)
	if fd < 0 then
		print("Socket creation failed")
	end

	s.fd = fd

	return s
end

---@param path string
function Socket:connect(path)
	local addr = ffi.new("struct sockaddr_un")
	addr.sun_family = AF_UNIX
	ffi.copy(addr.sun_path, path)

	if ffi.C.connect(self.fd, ffi.cast("struct sockaddr *", addr), ffi.sizeof(addr)) < 0 then
		local err = ffi.errno()
		ffi.C.close(self.fd)
		print("Connect failed" .. tostring(err))
	end
end

---@param message string
function Socket:send(message)
	ffi.C.write(self.fd, message, #message)
end

---@param length? number
---@return string | nil, string?
function Socket:receive(length)
	local len = length or 1024
	local buf = ffi.new("char[?]", len)
	local bytes_read = ffi.C.read(self.fd, buf, len)

	if bytes_read > 0 then
		return ffi.string(buf, bytes_read)
	elseif bytes_read == 0 then
		return nil, "closed"
	else
		local err = ffi.errno()
		return nil, "error: " .. tostring(err)
	end
end

function Socket:close()
	ffi.C.close(self.fd)
end

return socket

local ffi = require("ffi")

ffi.cdef([[
    typedef short sa_family_t;
    struct sockaddr_un {
        sa_family_t sun_family;
        char sun_path[108];
    };
    int socket(int domain, int type, int protocol);
    int connect(int sockfd, const struct sockaddr *addr, uint32_t addrlen);
    int write(int fd, const void *buf, size_t count);
    int close(int fd);
]])

local AF_UNIX = 1
local SOCK_STREAM = 1

-- 1. Create the socket
local fd = ffi.C.socket(AF_UNIX, SOCK_STREAM, 0)
if fd < 0 then
	error("Socket creation failed")
end

-- 2. Prepare the address structure
local addr = ffi.new("struct sockaddr_un")
addr.sun_family = AF_UNIX
ffi.copy(addr.sun_path, "/tmp/test.sock")

-- 3. Connect
if ffi.C.connect(fd, ffi.cast("struct sockaddr *", addr), ffi.sizeof(addr)) < 0 then
	ffi.C.close(fd)
	error("Connect failed - is the server running?")
end

-- 4. Write data
local msg = "Hello from Lua FFI!"
ffi.C.write(fd, msg, #msg)

-- 5. Cleanup
ffi.C.close(fd)
print("Message sent successfully!")

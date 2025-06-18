local glb={}
local function read_uint32(file)
    --little endian
    local b1, b2, b3, b4 = file:read(1):byte(), file:read(1):byte(), file:read(1):byte(), file:read(1):byte()
    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

local function json_parser(json_str)
    local json_table={}
    return
end
function glb.read(file_name)
    local glb_data={}
    local f = assert(io.open(file_name,'rb'))
    local magic = f:read(4)
    local version = read_uint32(f)
    local length = read_uint32(f)
    print("model info: ",magic,version,length,f:seek())

    local data_length = read_uint32(f)
    local data_type = f:read(4)
    local data_content = f:read(data_length)
    print(data_type, data_length, data_content)

    data_length = read_uint32(f)
    data_type = f:read(4)
    data_content = f:read(data_length)
    print(data_type, data_length)
    return glb_data
end
return glb
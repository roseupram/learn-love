local json = require("json")
local glb={}
local function read_uint32(file)
    --little endian
    local b1, b2, b3, b4 = file:read(1):byte(), file:read(1):byte(), file:read(1):byte(), file:read(1):byte()
    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end
local function read_float(bytes)
    -- bytes={0,0,0x80,0x3f}
    local sign = bytes[4] > 0x7f and -1 or 1
    local exponent = bytes[4] % 0x80 * 2 + math.floor(bytes[3] / 0x80) - 127
    local matissa = bytes[3] % 0x80 * 2 ^ 16 + bytes[2] * 2 ^ 8 + bytes[1]
    return sign *(1+matissa/2^23)*2^exponent
end
local function read_uint16(bytes)
    return bytes[1]+bytes[2]*2^8
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
    local json_content = f:read(data_length)
    local json_data = json.read(json_content)
    
    print(data_type, data_length, json_content,"\n--")

    data_length = read_uint32(f)
    data_type = f:read(4)
    local bin_content = f:read(data_length)
    print(data_type, data_length)
    local vertex = {}
    local indexs = {}
    local new_index_start=0
    for a=1,(#json_data.accessors /4) do
        local accessor = json_data.accessors[-3+a*4]
        local bufferview = json_data.bufferViews[accessor.bufferView+1]
        local offset = bufferview.byteOffset
        local v = {}
        local material = json_data.materials[a]
        local color = material.pbrMetallicRoughness.baseColorFactor
        for i = 1, accessor.count * 3 do
            local float_number = read_float({ bin_content:byte(-3 + i * 4+offset, i * 4+offset) })
            table.insert(v, float_number)
            if i % 3 == 0 then
                for c=1,3 do
                    table.insert(v,color[c])
                end
                table.insert(vertex, v)
                v = {}
            end
        end
        accessor = json_data.accessors[a*4]
        bufferview = json_data.bufferViews[accessor.bufferView+1]
        offset = bufferview.byteOffset
        for i = 1, accessor.count do
            local u16 = read_uint16({ bin_content:byte(-1 + i * 2 + offset, i * 2 + offset) })
            table.insert(indexs, u16 + 1 + new_index_start)
        end
        new_index_start=#vertex
    end
    glb_data.vertex=vertex
    glb_data.index = indexs
    glb_data.json=json_data
    return glb_data
end
return glb
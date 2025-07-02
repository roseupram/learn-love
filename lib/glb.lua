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

local BYTE_LEN={}
BYTE_LEN[5126]=4
BYTE_LEN[5123]=2

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
    local vertices = {}
    local indexs = {}
    local images = {}
    for i,image in ipairs(json_data.images or {})do
        local bufferview=json_data.bufferViews[image.bufferView+1]
        local offset = bufferview.byteOffset+1
        local len=bufferview.byteLength
        local image_data = bin_content:sub(offset,offset+len)
        local file = love.filesystem.newFileData(image_data,image.name)
        local img_data = love.image.newImageData(file)
        table.insert(images,love.graphics.newImage(img_data))
    end
    local new_index_start=0
    for mesh_id,mesh in ipairs(json_data.meshes) do
        for primitive_id,p in ipairs(mesh.primitives) do
            for attr_id,attribute in ipairs{"POSITION","TEXCOORD_0","NORMAL"} do
                local accessor = json_data.accessors[p.attributes[attribute] + 1]
                local bufferview = json_data.bufferViews[accessor.bufferView + 1]
                local offset = bufferview.byteOffset
                local data_size = accessor.type:match("%d+") or 1 -- component number
                local byte_len = BYTE_LEN[accessor.componentType]
                for i = 1, accessor.count do
                    if not vertices[i] then
                        vertices[i] = {}
                    end
                    for d=1,data_size do
                        local index=  i * data_size - data_size + d - 1
                        local start = index * byte_len + 1 + offset
                        local float_number = read_float({ bin_content:byte(start, start + byte_len) })
                        table.insert(vertices[i], float_number)
                    end
                end
            end

            local material = json_data.materials[p.material + 1]
            local color = material.pbrMetallicRoughness.baseColorFactor or { 1, 1, 1, 1 }
            for i=new_index_start+1,#vertices do
                for c =1,3 do
                    table.insert(vertices[i],color[c])
                end
            end

            local accessor = json_data.accessors[p.indices+1]
            local bufferview = json_data.bufferViews[accessor.bufferView + 1]
            local offset = bufferview.byteOffset
            local data_size = accessor.type:match("%d+") or 1
            local byte_len = BYTE_LEN[accessor.componentType]
            for i = 1, accessor.count*data_size do
                local start = i * byte_len - byte_len + 1 + offset
                local u16 = read_uint16({ bin_content:byte(start, start+byte_len) })
                table.insert(indexs, u16 + 1 + new_index_start)
            end
            new_index_start = #vertices
        end
    end
    glb_data.vertices=vertices
    glb_data.index = indexs
    glb_data.vertex_format={
        {"VertexPosition","float",3},
        {"VertexTexCoord","float",2},
        {"a_normal","float",3},
        {"VertexColor","float",3},
    }
    glb_data.json=json_data
    glb_data.images=images
    return glb_data
end
return glb
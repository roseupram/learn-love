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

local TYPE_MAP={}
TYPE_MAP[5126]="<f"
TYPE_MAP[5123]="<H"
TYPE_MAP[5125]="<I"
local lsf=love.filesystem
local ld=love.data

---comment
---@param file_name any
---@return {meshes:{index:table,material:table,POSITION:table,TEXCOORD_0:table,NORMAL:table,max:table,min:table}[][],json:table,images:table}
function glb.read(file_name)
    local data ,size= assert(lsf.read('data',file_name))
    local pos = 1
    local magic,version,length,pos = ld.unpack("<c4II",data,pos)
    -- print("model info: ",magic,version,length)
    assert(size==length,"gld length error")

    local data_length,data_type,pos = ld.unpack("<Ic4",data,pos)
    assert(data_type=="JSON","json error")
    local json_str,pos = ld.unpack("c"..data_length,data,pos)
    local json_data = json.read(json_str)
    
    -- print(data_type, data_length, json_str,"\n--")

    data_length,data_type,pos = ld.unpack("<Ic4",data,pos)
    -- print(data_type, data_length)
    local bin_content,pos= ld.unpack("c"..data_length,data,pos)
    local meshes={}
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
    local offset,float_number,u16=1,0,0
    for mesh_id,mesh in ipairs(json_data.meshes) do
        local mesh_t={}
        meshes[mesh_id]=mesh_t
        for primitive_id,p in ipairs(mesh.primitives) do
            local primitive={}
            mesh_t[primitive_id]=primitive
            for attr_id,attribute in ipairs{"POSITION","TEXCOORD_0","NORMAL"} do
                local accessor = json_data.accessors[p.attributes[attribute] + 1]
                local bufferview = json_data.bufferViews[accessor.bufferView + 1]
                offset = bufferview.byteOffset+1
                local data_size = accessor.type:match("%d+") or 1 -- component number
                local fmt = TYPE_MAP[accessor.componentType]
                primitive[attribute] = {}
                for i = 1, accessor.count do
                    local attr={}
                    for d=1,data_size do
                        float_number ,offset= ld.unpack(fmt,bin_content,offset)
                        table.insert(attr, float_number)
                    end
                    primitive[attribute][i]=attr
                end
            end
            if p.material then
                primitive.material = json_data.materials[p.material + 1]
            end
            primitive.max=json_data.accessors[p.attributes.POSITION+1].max
            primitive.min=json_data.accessors[p.attributes.POSITION+1].min

            local accessor = json_data.accessors[p.indices+1]
            local bufferview = json_data.bufferViews[accessor.bufferView + 1]
            offset = bufferview.byteOffset+1
            local data_size = accessor.type:match("%d+") or 1
            local fmt = TYPE_MAP[accessor.componentType]
            local index={}
            for i = 1, accessor.count*data_size do
                u16,offset= ld.unpack(fmt,bin_content,offset)
                table.insert(index, u16 + 1 + new_index_start)
            end
            primitive.index=index
        end
    end
    local glb_data={}
    glb_data.meshes=meshes
    glb_data.json=json_data
    glb_data.images=images
    return glb_data
end
return glb
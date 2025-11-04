local pttype=require("prototype")
local _cache={}
local lg=love.graphics
local lfs=love.filesystem
local uniform_list=pttype{name="Uniform_List"}
function uniform_list:new()
    self.data={}
end
function uniform_list:set(...)
    local args={...}
    local name = table.remove(args,1)
    self.data[name]= args
end
function uniform_list:apply(shader)
    for name,params in pairs(self.data) do
        if shader:hasUniform(name) then
            shader:send(name, table.unpack(params))
        end
    end
end
local shader={path_prefix="shader/",path_suffix=".out.glsl"}
shader.uniform_list=uniform_list

function shader.full_path(name)
    return shader.path_prefix .. name .. shader.path_suffix
end
function shader.new(vert,frag)
    if not _cache[vert] then
        local path=shader.full_path(vert)
        if lfs.getInfo(path) then
            _cache[vert]=lfs.read(path)
        end
    end
    if frag and not _cache[frag] then
        local path=shader.full_path(frag)
        if lfs.getInfo(path) then
            _cache[frag]=lfs.read(path)
        end
    end
    if frag then
        return lg.newShader(_cache[frag], _cache[vert])
    else
        return lg.newShader(_cache[vert])
    end
end
return shader
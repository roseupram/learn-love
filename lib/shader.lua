local _cache={}
local lg=love.graphics
local lfs=love.filesystem
local shader={path_prefix="shader/",path_suffix=".out.glsl"}
    -- my_shader=lg.newShader('shader/frag.glsl','shader/isometric.out.glsl')
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
    if not _cache[frag] then
        local path=shader.full_path(frag)
        if lfs.getInfo(path) then
            _cache[frag]=lfs.read(path)
        end
    end
    return lg.newShader(_cache[frag],_cache[vert])
end
return shader
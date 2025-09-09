local pt=require('prototype')
local Color=require('color')
local Point=require('3d.point')
---@class Mesh
local mesh = pt{
    name = "Mesh",
}
local vformat = {
    { "VertexPosition", "float", 3 },
    { "VertexColor",    "float", 3 },
    { "VertexTexCoord", "float", 2 }
}
function mesh.circle()
    local v={{0,0,0,1,1,1,0,0}}
    local tau=math.pi*2
    local segment=24
    local step =tau/segment
    for angle=0,tau,step do
        local x=math.sin(angle)
        local z=math.cos(angle)
        local y=0
        table.insert(v,{x,y,z,1,1,1,0,0})
    end
    return mesh{vertex=v,mode='fan'}
end
function mesh.ring()
    local v={}
    local tau=math.pi*2
    local segment=24
    local step =tau/segment
    for angle=0,tau,step do
        local x=math.sin(angle)
        local z=math.cos(angle)
        local y=0
        table.insert(v,{x,y,z,1,1,1,0,0})
        table.insert(v,{.5*x,y,.5*z,1,1,1,0,0})
    end
    return mesh{vertex=v,mode='strip'}
end
function mesh:new(ops)
    self._mesh=love.graphics.newMesh(vformat,ops.vertex,ops.mode or 'fan')
    self.color=Color()
    self._tl=love.graphics.newMesh({{"a_tl","float",3}},{{0,0,0}},nil)
    self._scale=love.graphics.newMesh({{"a_sc","float",3}},{{1,1,1}},nil)
    self._mesh:attachAttribute("a_tl",self._tl,"perinstance")
    self._mesh:attachAttribute("a_sc",self._scale,"perinstance")
end
---@param p3d Point
function mesh:set_position(p3d)
    self._tl:setVertex(1,p3d:unpack())
end
---@return Point
function mesh:get_position()
    local pos=Point(self._tl:getVertex(1))
    return pos
end
function mesh:move(dv)
    local pos=self:get_position()
    self:set_position(pos:add(dv))
end
function mesh:set_scale(p3d,y,z)
    if type(p3d)=='number' then
        local x=p3d
        self._scale:setVertex(1,x,y,z)
    else
        self._scale:setVertex(1,p3d:unpack())
    end
end
function mesh:draw()
    love.graphics.setColor(self.color:table())
    love.graphics.draw(self._mesh)
end

return mesh
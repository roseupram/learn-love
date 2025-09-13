local protype=require('prototype')
local Color=require('color')
local path=(...):gsub("[^.]+$","") -- remove last name
---@type Point
local Point=require(path..'point')
---@class Mesh
local mesh = protype{
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
function mesh.line(ops)

    local _points={
    0,0,1,
    2,0,0,
    0,0,-1,
    1,0,.7,
    1,0,-.7,
    }
    local points={}
    local ps_type=type(ops.points[1])
    local ps = ops.points
    if ps_type=='number' then
        local len=#ops.points
        for i=1,len,3 do
            table.insert(points,Point(ps[i],ps[i+1],ps[i+2]))
        end
    elseif ps_type=='table' and ps[1].name~='Point' then
        for i,pt in ipairs(ps) do
            table.insert(points,Point(pt))
        end
    end
    
    local v={}
    local dir
    local lw=.2
    for i,point in ipairs(points) do
        local not_last_one=points[i+1]~=nil
        local r_angel=math.pi/2
        if i>1 and not_last_one then
            local perpendicu = dir:rotate(0, r_angel, 0):normal()
            local half_lw = lw / 2.0

            local x, y, z = (point + perpendicu * half_lw):unpack()
            table.insert(v, { x, y, z, 1, 1, 1, 0, 0 })
            x, y, z = (point - perpendicu * half_lw):unpack()
            table.insert(v, { x, y, z, 1, 1, 1, 0, 0 })
        end
        if not_last_one then
            dir = points[i+1]-points[i]
        end
        -- if i%2==0 then
        --     r_angel=-r_angel
        -- end
        local perpendicu=dir:rotate(0,r_angel,0):normal()
        local half_lw=lw/2.0

        local x,y,z=(point+perpendicu*half_lw):unpack()
        table.insert(v,{x,y,z,1,1,1,0,0})
        x,y,z=(point-perpendicu*half_lw):unpack()
        table.insert(v,{x,y,z,1,1,1,0,0})
    end
    -- return mesh{vertex=v,mode='triangles'}
    return mesh{vertex=v,mode='strip'}
end
function mesh:new(ops)
    self._mesh=love.graphics.newMesh(vformat,ops.vertex,ops.mode or 'fan')
    self.color=Color()
    self._tl=love.graphics.newMesh({{"a_tl","float",3}},{{0,0,0}},nil)
    self._scale=love.graphics.newMesh({{"a_sc","float",3}},{{1,1,1}},nil)
    self._color=love.graphics.newMesh({{'a_color',"float",4}},{{1,1,1,1}},nil)
    self._mesh:attachAttribute("a_tl",self._tl,"perinstance")
    self._mesh:attachAttribute("a_sc",self._scale,"perinstance")
    self._mesh:attachAttribute("a_color",self._color,"perinstance")
    if ops.map then
        self._mesh:setVertexMap(ops.map)
    end
    self.outline=ops.outline or 0
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
function mesh:color_tone(color)
    self._color:setVertex(1,color:unpack())
end
function mesh:draw()
    love.graphics.push('all')
    if self.shader then
         love.graphics.setShader(self.shader)
    end
    love.graphics.draw(self._mesh)
    love.graphics.pop()
end

return mesh
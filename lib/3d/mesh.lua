local protype=require('prototype')
local FP=require('FP')
local AABB=require("3d.aabb")
local Color=require('color')
local path=(...):gsub("[^.]+$","") -- remove last name
---@type Point
local Point=require(path..'point')
---@class Mesh
---@overload fun(ops:{vmap:table,vertex:table,mode:string}):Mesh
local mesh = protype{
    name = "Mesh",
}
local vformat = {
    { "VertexPosition", "float", 3 },
    { "VertexColor",    "float", 3 },
    { "VertexTexCoord", "float", 2 }
}
function mesh.cube(ops)
    local v={}
    local vmap={}
    local n3={
        Point(1,0,0),
        Point(0,1,0),
        Point(0,0,1),
        Point(-1,0,0),
        Point(0,-1,0),
        Point(0,0,-1),
    }
    local len=math.sqrt(2)
    local vm = { 1, 2, 3, 1, 3, 4 }
    local vmap_step = 4
    for i, n in ipairs(n3) do
        local offset=0
        if i>3 then
            offset=3
        end
        for vi=1,4 do
            local theta=math.rad(vi*90-45)
            local x=len*math.cos(theta)
            local y=len*math.sin(theta)
            local u_= n3[FP.cycle(i+1,1,3,1)+offset]
            local v_= n3[FP.cycle(i+2,1,3,1)+offset]
            local point=u_*x  + v_*y + n
            table.insert(v,{point.x,point.y,point.z,1,1,1,0,0})
        end
        for k,vmi in ipairs(vm) do
            table.insert(vmap,vmi+(i-1)*vmap_step)
        end
    end
    return mesh{vertex=v,mode='triangles',vmap=vmap,wireframe=ops.wireframe}
end
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
    ---@type Point[]
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
    local deg90 = math.pi / 2
    local rot=ops.normal or Point(0,1,0)
    rot:mul(deg90)
    local lw=.2
    for i,point in ipairs(points) do
        local not_last_one=points[i+1]~=nil
        if i>1 and not_last_one then
            -- for previous vertex
            local perpendicu = dir:rotate(rot:unpack()):normal()
            local half_lw = lw / 2.0

            local x, y, z = (point + perpendicu * half_lw):unpack()
            table.insert(v, { x, y, z, 1, 1, 1, 0, 0 })
            x, y, z = (point - perpendicu * half_lw):unpack()
            table.insert(v, { x, y, z, 1, 1, 1, 0, 0 })
        end
        if not_last_one then
            dir = points[i+1]-points[i]
        end
        -- for next vertex
        local perpendicu=dir:rotate(rot:unpack()):normal()
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
    self.vertex=ops.vertex
    self.mode=ops.mode  or 'fan'
    self.vformat=ops.vformat or vformat
    self.usage=ops.usage or 'static'
    self._mesh = love.graphics.newMesh(self.vformat, self.vertex, self.mode,self.usage)
    self.instance=ops.instance or 1
    self.wireframe=ops.wireframe or false
    self.anchor=ops.anchor or Point()
    local dfv = {
        sc={1,1,1},
        color =  { 1, 1, 1, 1 } ,
        fallback =  { 0, 0, 0 }
    }
    for i,k in ipairs{"tl","sc","color","rot"} do
        local key="_"..k
        local attribute="a_"..k
        local data = {}
        for inst = 1, self.instance do
            if ops[k] and ops[k][inst] then
                data[inst] = ops[k][inst]
            else
                data[inst] = dfv[k] or dfv["fallback"]
            end
        end
        self[key]=love.graphics.newMesh({{attribute,"float",3}},data,nil)
        self._mesh:attachAttribute(attribute, self[key], "perinstance")
    end
    if ops.tl then
        local t={}
        for i,tl in ipairs(ops.tl) do
            table.insert(t,Point(unpack(tl)))
        end
        self._position=t
    else
        self._position = { Point() }
    end
    if ops.vmap then
        self._mesh:setVertexMap(ops.vmap)
    end
    if ops.texture then
        self._mesh:setTexture(ops.texture)
    end
    self.outline=ops.outline or 0
end
function mesh:get_aabb(index)
    index = index or 1
    if not self._aabb then
        local low=Point()
        local high=Point()
        for i,v in ipairs(self.vertex) do
            local vp=Point(v[1],v[2],v[3]) -- one vertex
            low:each(function (value,key)
                low[key]= math.min(value,vp[key])
            end)
            high:each(function (value,key)
                high[key]= math.max(value,vp[key])
            end)
        end
        local aabbs = {}
        self._aabb= AABB{max=high,min=low}
    end
    return  self._aabb
end
local function resolve_index_data(index,data)
    if type(index)~="number" then
        data=index
        index=1
    end
    return index,data
end
---@param index Point|number
---@param p3d Point|nil
function mesh:set_position(index, p3d)
    index ,p3d=resolve_index_data(index,p3d)
    self._position[index] = p3d
    p3d=p3d-self.anchor -- move to origin
    self._tl:setVertex(index,p3d:unpack())
end
---@return Point
function mesh:get_position(index)
    index =index or 1
    return self._position[index]
end
function mesh:move(index,dv)
    index ,dv=resolve_index_data(index,dv)
    local pos=self:get_position()
    self:set_position(index,pos:add(dv))
end
function mesh:set_scale(index,p3d)
    index,p3d=resolve_index_data(index,p3d)
    self._sc:setVertex(index, p3d:unpack())
end
function mesh:color_tone(color)
    self._color:setVertex(1,color:unpack())
end
function mesh:set_rotate(index,p3d)
    index,p3d=resolve_index_data(index,p3d)
    self._rot:setVertex(index, p3d:unpack())
end
function mesh:draw()
    love.graphics.push('all')
    love.graphics.setWireframe(self.wireframe)
    if self.shader then
         love.graphics.setShader(self.shader)
    end
    if self.instance>1 then
        love.graphics.drawInstanced(self._mesh,self.instance)
    else
        love.graphics.draw(self._mesh)
    end
    love.graphics.pop()
end

return mesh
local pttype=require('prototype')
local Point=require('3d.point')
local Collision={}

---@class Ray
---@overload fun():Ray
local Ray=pttype{name="Ray"}
function Ray:new(ops)
    self.from=ops.from or Point()
    self.direction=(ops.direction or Point(0,0,1) ):normal()
    self.t=-1
    if ops.to then
        local AB=ops.to-self.from
        self.direction=AB:normal()
        self.t=AB:len()
    end
end
Collision.Ray=Ray

---@class Collision_World
---@overload fun():Collision_World
local World=pttype{name="Collision_World"}
function World:new()
    self.shapes={}
end
function World:push(shape)
    table.insert(self.shapes,shape)
end
---comment
---@param p Point
---@param dir Point
---@return Point? position
---@return Point? normal
function World:test_ray(p,dir)
    local dir_n=dir:normal()
    local t,pos,normal
    for i,shape in ipairs(self.shapes) do
        local new_pos,new_normal=shape:test_ray(p,dir)
        if new_pos then
            local new_t=(new_pos-p):len()
            if not t then
                t=new_t
                pos=new_pos
                normal=new_normal
            else
                if new_t<t then
                pos=new_pos
                normal=new_normal
                end
            end
        end
    end
    return pos,normal
end
Collision.World=World

return Collision
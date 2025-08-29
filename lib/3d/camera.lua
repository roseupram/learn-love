local prototype=require('prototype')
local Point=require('3d.point')
local Mat=require('3d.mat')
local FP=require('FP')

---@class Camera:prototype
---@overload fun(...):Camera
local camera=prototype{name="Camera"}

function camera:new(ops)
    self.radius=10
    self.x_rot=-30
    self.y_rot=45
    self.wh_ratio=1.0
    self.near=0.1
    self.far=100
    self.tl=Point()
    self:update(ops)
end
--- tl = tl + dv
---@param dv Point
function camera:move(dv)
    return self.tl:add(dv)
end
function camera:zoom(x)
    self.radius=FP.clamp(self.radius+x,2,30)
end
--- front vector's project on z axis
function camera:front_z()
    return Point(0,0,-1):rotate(0,math.rad(self.y_rot),0)
end
--- left vector's project on x axis
function camera:left_x()
    return Point(1,0,0):rotate(0,math.rad(self.y_rot),0)
end
---{ {x,y,z}, {x_rot,y_rot,radius},{near,far,wh_ratio} }
---@return table
function camera:param_mat()
    -- why -y_rot, I don't know
    return {
        {self.tl:unpack()},
        {math.rad(self.x_rot),math.rad(-self.y_rot),self.radius},
        {self.near,self.far,self.wh_ratio}
    }
end
function camera:rotate_mat()
    local rx,ry = math.rad(self.x_rot),math.rad(self.y_rot)
    local m1 = Mat.rotate_mat(rx,0,0)
    local m2 = Mat.rotate_mat(0,ry,0)
    local RyRx=m2*m1
    return RyRx
end
---@return Point
---@return Point
function camera:ray(x,y)
    -- local point_world = Point(x,y/self.wh_ratio,1):rotate(rx,0,0):rotate(0,ry,0)+self.tl
    -- local dir = Point(0,0,-1):rotate(rx,0,0):rotate(0,ry,0)
    local w,h=love.graphics.getDimensions()
    x=2*x/w-1; y=1-2*y/h;
    local RyRx=self:rotate_mat()
    local dir=RyRx*Point(0,0,-1)
    local point_world=RyRx*Point(x,y/self.wh_ratio,1)+self.tl
    point_world:mul(self.radius)
    return point_world,dir
end
return camera
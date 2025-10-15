local prototype=require('prototype')
local FP=require('FP')

local path=(...):gsub("[^.]+$","") -- remove last name
local Point=require(path..'point')
local Mat=require(path..'mat')
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
    self.radius=FP.clamp(self.radius+x,5,30)
end
--- front vector's project on z axis
function camera:front_z()
    return Point(0,0,-1):rotate(0,math.rad(self.y_rot),0)
end
--- left vector's project on x axis
function camera:left_x()
    return Point(1,0,0):rotate(0,math.rad(self.y_rot),0)
end
function camera:project_mat()
    local scale=1.0/self.radius
    local fn=self.far-self.near
    local mat=Mat{
        scale, 0, 0, 0,
        0, scale * self.wh_ratio, 0, 0,
        0, 0, scale / -fn, -self.near/fn,
        0, 0, 0, 1
    }
    return mat
end
---world to view
---@return Mat4
function camera:view_mat()
    local view_to_world=self:rotate_mat()
    local eye=view_to_world*Point(0,0,1)
    local mat=Mat.look_at(eye+self.tl,self.tl)
    return mat
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
    local point_world=RyRx*Point(x,y/self.wh_ratio,2)*self.radius+self.tl
    return point_world,dir
end
return camera
local prototype=require('prototype')
local Point=require('3d.point')
local FP=require('FP')

---@class Camera:prototype
---@overload fun(...):Camera
local camera=prototype{name="Camera"}

function camera:new(ops)
    self.radius=1
    self.x_rot=-30
    self.y_rot=-45
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
    self.radius=FP.clamp(self.radius+x,.2,3)
end
function camera:front()
    return Point(0,0,-1):rotate(0,math.rad(self.y_rot),0)
end
function camera:left()
    return Point(1,0,0):rotate(0,math.rad(self.y_rot),0)
end
---{ {x,y,z}, {x_rot,y_rot,radius},{near,far,wh_ratio} }
---@return table
function camera:param_mat()
    return {
        {self.tl:unpack()},
        {math.rad(self.x_rot),math.rad(self.y_rot),self.radius},
        {self.near,self.far,self.wh_ratio}
    }
end
return camera
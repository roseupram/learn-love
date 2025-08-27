local vp = require('vector')
---@class Point:Vector
---@overload fun(...):Point
---@operator add(any):Point
---@operator mul(any):Point
local point = vp {
    name = "Point",
    default = { x = 0, y = 0, z = 0 }
}
function point:new(x,y,z)
    self.x=x
    self.y=y
    self.z=z
end
function point:rotate(x,y,z)
    local sin,cos=math.sin,math.cos
    local sx,cx=sin(x),cos(x)
    local sy,cy=sin(y),cos(y)
    local sz,cz=sin(z),cos(z)
    ---rotate_mat * self
    local ax = point(cy, 0, -sy)
    local ay = point(0, 1, 0)
    local az = point(sy, 0, cy)
    return point(
        ax:dot(self),
        ay:dot(self),
        az:dot(self)
    )
end

return point

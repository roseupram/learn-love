local vp=require("vector")
--- 3D point
---@class Point :Vector
local Point = vp { name = "Point", default = { x = 0, y = 0, z = 0 } }
function Point:new(x,y,z)
    self.x=x
    self.y=y
    self.z=z
end
---@param p Point
function Point:cross(p)
    return Point(
        self.y * p.z - p.y * self.z,
        self.z * p.x - self.x * p.z,
        self.x * p.y - self.y * p.x
    )
end
return Point
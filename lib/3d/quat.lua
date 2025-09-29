local vtype=require('vector')
---@class Quat
local Quat = vtype { name = "Quat",
    default = { x = 0, y = 0, z = 0, w = 1 },
    keys = { 'x', 'y', 'z', 'w' }
}
---@param normal Point
---@param theta number
---@return Quat
function Quat.from_normal(normal,theta)
    local w=math.cos(theta/2)
    local sin=math.sin(theta/2)
    local x,y,z=(normal*sin):unpack()
    return Quat(x,y,z,w)
end
function Quat:new(x,y,z,w)
    self.x=x
    self.y=y
    self.z=z
    self.w=w
end
return Quat
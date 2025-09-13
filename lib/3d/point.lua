local vp = require('vector')
---@class Point:Vector
---@overload fun(...):Point
---@operator add(number|Point):Point
---@operator sub(number|Point):Point
---@operator mul(number|Point):Point
---@field mul fun(self:Point,v:number|Point):Point
---@field add fun(self:Point,v:number|Point):Point
local point = vp {
    name = "Point",
    default = { x = 0, y = 0, z = 0 },
}
function point:new(x,y,z)
    if type(x) =='table' then
        x,y,z=unpack(x)
    end
    self.x=x
    self.y=y
    self.z=z
end
function point:rotate(x,y,z)
    local zero_cnt=0;
    for i,v in ipairs{x,y,z} do
        if v==0 then
            zero_cnt=zero_cnt+1
        end
    end
    if(zero_cnt<=1) then
        print(string.format("Warning: (%.3f,%.3f,%.3f) rotating axis is not base axis ",x,y,z))
    end
    local sin,cos=math.sin,math.cos
    local sx,cx=sin(x),cos(x)
    local sy,cy=sin(y),cos(y)
    local sz,cz=sin(z),cos(z)
    ---rotate_mat * self
    local ax = point(cy, sx*sy, sy*cx)
    local ay = point(0, cx, -sx)
    local az = point(-sy, cy*sx, cx*cy)
    return point(
        ax:dot(self),
        ay:dot(self),
        az:dot(self)
    )
end

return point

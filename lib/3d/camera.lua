local prototype=require('prototype')
---@class Camera:prototype
local camera=prototype{name="Camera"}
function camera:new(ops)
    self.radius=1
    self.x_rot=-30
    self.y_rot=-45
    self.tl={0,0,0}
    self:update(ops)
end
--- tl=tl + dv
---@param dv [number,number,number]
function camera:move(dv)
    for i,v in ipairs(self.tl) do
        self.tl[i]=self.tl[i]+dv[i]
    end
end
---{ {x,y,z}, {x_rot,y_rot,radius} }
---@return table
function camera:param_mat()
    return {
        self.tl,
        {math.rad(self.x_rot),math.rad(self.y_rot),self.radius}
    }
end
return camera
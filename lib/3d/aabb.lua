local pttype = require('prototype')
local AABB = pttype{name='AABB'}
function AABB:new(ops)
    self.max=ops.max
    self.min=ops.min
end
function AABB:test_point(point)
    local is_in_range = function(value, key)
        return value > self.min[key] - .001 and value < self.max[key] + .001
    end
    return point:every(is_in_range)
end
function AABB:test_aabb(aabb)
    for i,k in ipairs{'x','y','z'} do
        local no_intersect= self.max[k]<aabb.min[k] or self.min[k]>aabb.max[k]
        if no_intersect then
            return false
        end
    end
    return true
end
function AABB:unpack()
    return self.max,self.min
end
---new place add
function AABB:__add(point)
    return self:clone():add(point)
end
---in place add
function AABB:add(point)
    self.max:add(point)
    self.min:add(point)
    return self
end
function AABB:clone()
    return AABB{max=self.max:clone(),min=self.min:clone()}
end
return AABB
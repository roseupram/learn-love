local pttype = require('prototype')
local Point=require('3d.point')
local FP=require('FP')
local Face=require('3d.face')

local AABB = pttype{name='AABB'}
function AABB:new(ops)
    self.max=ops.max
    self.min=ops.min
    local n6={
        Point(1,0,0),
        Point(0,1,0),
        Point(0,0,1),
        Point(-1,0,0),
        Point(0,-1,0),
        Point(0,0,-1),
    }
    self.faces={}
    for i,n in ipairs(n6) do
        local AB = self.max-self.min
        local offset=0
        local share_p=self.max
        local base_p = self.min
        if i>3 then
            offset=3
            share_p=self.min
            base_p=self.max
        end
        local points={share_p,AB*n+base_p}
        for d=1,2 do
            local m = FP.cycle(i + d, 1, 3, 1) + offset
            table.insert(points, base_p + AB * (n + n6[m]))
        end
        local face=Face{normal=n,points=points}
        table.insert(self.faces,face)
    end
end
function AABB:test_ray(point,direction)
    local pos,normal
    local t_min=9999
    for i,face in ipairs(self.faces) do
        local t = face:test_ray(point,direction)
        if t and t<t_min then
            t_min=t
            pos=point+direction*t
            normal=face.normal
        end
    end
    return pos,normal
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
    return AABB{max=self.max+point,min=self.min+point}
end
---in place add
function AABB:add(point)
    self.max:add(point)
    self.min:add(point)
    for i ,face in ipairs(self.faces) do
        face:add(point)
    end
    return self
end
function AABB:clone()
    return AABB{max=self.max:clone(),min=self.min:clone()}
end
return AABB
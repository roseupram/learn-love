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
    local t_min=1e10
    local dir_n=direction:normal()
    for i,face in ipairs(self.faces) do
        local t = face:test_ray(point,dir_n)
        if t and t<t_min then
            t_min=t
            pos=point+dir_n*t
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
--- max,min=AABB:unpack()
function AABB:unpack()
    return self.max,self.min
end
---new place add
function AABB:__add(point)
    return AABB{max=self.max+point,min=self.min+point}
end
---get a aabb bounding 2 aabb
function AABB:merge(aabb)
    local max_a,min_a=self:unpack()
    local max_b,min_b=aabb:unpack()
    local max_n,min_n=Point(),Point()
    max_n:each(function (v,i,ref)
        ref[i]=math.max(max_a[i],max_b[i])
    end)
    min_n:each(function (v,i,ref)
        ref[i]=math.min(min_a[i],min_b[i])
    end)
    return AABB{max=max_n,min=min_n}
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
function AABB:center()
    return (self.max+self.min)/2
end
function AABB:project(normal)
    local mask=Point(1,1,1)-normal:abs()
    local min=self.min*mask
    local max=self.max*mask
    local diag=max-min
    local dirs={}
    mask:each(function (v,k)
        if v==1 then
            local p = Point()
            p[k] = 1
            table.insert(dirs, p)
        end
    end)
    local res={min,nil,max}
    for i, d in ipairs(dirs) do
        local s = min + diag * d
        if d:cross(mask):dot(normal) > 0 then
            res[2] = s
            res[4] = min + diag * dirs[FP.cycle(i + 1, 1, #dirs)]
            break
        end
    end
    return res
end
function AABB:clone()
    return AABB{max=self.max:clone(),min=self.min:clone()}
end
return AABB
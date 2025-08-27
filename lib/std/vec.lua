local proto_vector=require('vector')
--- 2d vector
---@class Vec2 :Vector
---@overload fun(...):Vec2
---@operator add(any):Point
---@operator mul(any):Point
local Vec2 = proto_vector{name='Vec',default={x=0,y=0}}
local FP=require('FP')
local function degree2radian(degree)
    return degree/180*math.pi
end
function Vec2:new(x,y)
    self.x=x
    self.y=y
end
function  Vec2:project(vec)
    -- return the len of projected vec
    return self:dot(vec:normal())
    
end
function Vec2:set(vec,y)
    if type(y)=="number" then
        local x= vec
        self.x=x
        self.y=y
    else
        self.x = vec.x
        self.y = vec.y
    end
end
function Vec2:down2zero(vec)
    if type(vec) =="number" then
        vec=Vec2(vec,vec)
    end
    --[[
    -1--->---0---<---1
    --]]
    local sign=self:sign()
    local remain=self:abs()-vec:abs()
    local result=remain:map(FP.relu)*sign
    return result
end
function Vec2:__tostring()
    return string.format("Vec(%s, %s)",self.x,self.y)
end
function Vec2:unpack()
   return self.x,self.y
end
function Vec2:quadrant()
    local x,y=self:unpack()
    if x>0 then
        if y>0 then
            return 1
        else
            return 2
        end
    elseif x<0 then
        if y>0 then
            return 3
        else
            return 4
        end
    end
end
function Vec2:prep()
    -- x1*x2+y1*y2=0
    return Vec2(self.y,-self.x):normal()
end
function Vec2:theta(is_degree)
    local x,y=self:unpack()
    local basic_theta= math.atan2(y,x)
    if is_degree then
        basic_theta =degree2radian(basic_theta)
    end
    return basic_theta
end
function Vec2:rotate(theta,is_degree)
    if is_degree then
        theta=degree2radian(theta)
    end
    local current_theta = self:theta()
    theta=theta+current_theta
    local len=self:len()
    local v=Vec2(math.cos(theta),math.sin(theta))
   return v*len
end
local function test()
    local v = Vec2(1,3)
    local v2 = Vec2(4)
    print(v:dot(v2))
end
-- test()
return Vec2
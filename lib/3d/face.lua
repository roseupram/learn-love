local pttype=require('prototype')
local Face=pttype{name="Face"}
local FP=require('FP')
local Point=require('3d.point')
local function sort_points(points,normal)
    local center = Point()

    local u=(center-points[1]):cross(normal):normal()
    local v=u:cross(normal)
    for i,p in ipairs(points) do
        center:add(p)
    end
    center:mul(1/#points)
    local polar_coords={}
    for i,p in ipairs(points) do
        local cp = p-center
        local x = cp:dot(u)
        local y = cp:dot(v)
        local theta=math.atan2(y,x)
        local len = math.sqrt(x*x+y*y)
        table.insert(polar_coords,{theta,len})
    end
    table.sort(polar_coords,function (a, b)
        return a[1]<b[1]
    end)
    local res = {}
    for i ,polar in ipairs(polar_coords) do
        local theta,len=unpack(polar)
        local x=len*math.cos(theta)
        local y=len*math.sin(theta)
        table.insert(res,u*x+v*y+center)
    end
    local AB=res[2]-res[1]
    local BC=res[3]-res[2]
    local ori=AB:cross(BC)
    local ca = ori:dot(normal)
    if ca<0 then
        local left,right =1, #res
        while(left<right) do
            
            local t = res[left]
            res[left]=res[right]
            res[right]=t
            left=left+1
            right=right-1
        end
    end
    return res
end
---@class Face
---@field normal Point indicate orientation of face
---@field points Point[]
function Face:new(ops)
    self.normal = ops.normal
    if ops.sorted then
        self.points = ops.points
    else
        self.points = sort_points(ops.points, self.normal)
    end
end
---@param point Point from here
---@param dir Point cast ray along 
---@return number|nil t  if no intersect, return nil <br>
---else t is a number,  point + dir*t = point_on_face <br>
function Face:test_ray(point,dir)
    local n = self.normal
    local dir_n=dir:normal()

    local dist = self:distance(point)
    local m = dist * (dir_n:dot(n))
    if m>0 then
        return nil
    end
    local cos_n_d = dir_n:dot(n)
    local t=-dist/cos_n_d
    local size = #self.points
    local point_onface = point+dir*t
    for i=1,size do
        local A = self.points[i]
        local B = self.points[FP.cycle(i+1,1,size)]
        local AB=B-A
        local BP=point_onface-B
        if AB:cross(BP):dot(n)<0 then
            return nil
        end
    end
    return  t
end
---@param point Point
---@return number distance signed distance 
function Face:distance(point)
    local n = self.normal
    local HP = point-self.points[1]
    
    local dist = HP:dot(n)
    return dist
end
function Face:add(point)
    for i,p in ipairs(self.points) do
        p:add(point)
    end
end
function Face:clone()
    local n=self.normal:clone()
    local points ={}
    for i,p in ipairs(self.points) do
        table.insert(points,p:clone())
    end
    return Face{normal=n,points=points,sorted=true}
end
function Face:__add(point)
    local new_face = self:clone()
    new_face:add(point)
    return new_face
end
return Face
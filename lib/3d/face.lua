local pttype=require('prototype')
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
local Face=pttype{name="Face"}

function Face:new(ops)
    self.normal = ops.normal or Point(0,1,0)
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
function Face:triangulate()
    if self.tris_cache then
        return self.tris_cache
    end
    local tris={}
    local points={table.unpack(self.points)}
    while #points>3 do
        for i,point in ipairs(points) do
            local A=points[FP.cycle(i-1,1,#points)]
            local B=point
            local C=points[FP.cycle(i+1,1,#points)]
            local tri_face=Face{points={A,B,C},sorted=true}
            local is_ear=tri_face:is_convex() and tri_face:no_point_in(points)
            if  is_ear then
                table.remove(points,i)
                table.insert(tris,{A,B,C})
                break
            end
        end
    end
    table.insert(tris,{unpack(points)})
    self.tris_cache=tris
    return tris
end
function Face:is_convex()
    local normal = self.normal
    local points=self.points
    local size=#points
    if size==3 then
        size=1
    end
    for i=1,size do
        local A=points[i]
        local B=points[FP.cycle(i+1,1,#points)]
        local C=points[FP.cycle(i+2,1,#points)]
        local AB, BC = B - A, C - B
        local cross_dot=AB:cross(BC):dot(normal)
        local is_convex_vertex = false
        if #points == 3 then
            is_convex_vertex = cross_dot > 0
        else
            is_convex_vertex = cross_dot >= 0
        end
        if not is_convex_vertex then
            return false
        end
    end
    return true
end
function Face:has_point_in(point)
    return not self:no_point_in({point})
end
--- no point inside, all point outside or on edge
---@param points Point[]
---@return boolean
function Face:no_point_in(points)
    local polygon=self.points
    for i,point in ipairs(points) do
        local is_in=true
        for k,A in ipairs(polygon) do
            local B=polygon[FP.cycle(k+1,1,#polygon)]
            local AB,AP=B-A,point-A
            if AB:cross(AP):dot(self.normal)<=0  then
                is_in=false
                break
            end
        end
        if is_in then
            return false
        end
    end
    return true
end
local function remove_coline(points)
    local normal=Point(0,1,0)
    local to_remove={}
    for i,B in ipairs(points) do
        local A=points[FP.cycle(i-1,1,#points)]
        local C=points[FP.cycle(i+1,1,#points)]
        local is_coline=(B-A):cross(C-B):dot(normal)==0
        if is_coline then
            table.insert(to_remove, i)
        end
    end
    for i=#to_remove,1,-1 do
        table.remove(points,to_remove[i])
    end
end
function Face:convex_hull()
    ---https://swaminathanj.github.io/cg/ConvexHull.html
    local Normal=self.normal

    local hull={}
    for i,p in ipairs(self.points) do
        table.insert(hull,p)
        local is_last3_not_convex = true
        while #hull>=3 and is_last3_not_convex do
            ---check last 3
            local A = hull[#hull - 2]
            local B = hull[#hull - 1]
            local C = hull[#hull - 0]
            local AB, BC = B - A, C - B
            if AB:cross(BC):dot(Normal) > 0 then
                is_last3_not_convex = false
            else
                table.remove(hull, #hull - 1)
            end
        end
    end
    remove_coline(hull)
    return hull
end
return Face
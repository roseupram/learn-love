local pttype=require('prototype')
local Face=pttype{name="Face"}
---@class Face
---@field normal Point
---@field hl [Point,Point]
function Face:new(ops)
   self.normal=ops.normal
   self.hl=ops.hl
end
---@param point Point from here
---@param dir Point cast ray along 
---@return number|nil t  if no intersect, return nil <br>
---else t is a number,  point + dir*abs(t) = point_in_face <br>
---sign of `t` is sign of `cos<n,dir>`
function Face:raytest(point,dir)
    local h,l = self:get_hl()
    local n = self.normal
    local HP = point-h
    local LP= point - l
    local UP_V=point(0,1,0)
    local t_HP=HP:cross(n):dot(UP_V)
    local t_LP=LP:cross(n):dot(UP_V)
    if t_HP*t_LP >0 then
        return 
    end
    local dir_n=dir:normal()

    local dist = math.abs(self:distance(point))
    local cos_n_d = dir_n:dot(n)
    local t=dist/cos_n_d
    return  t
end
---@param point Point
---@return number distance signed distance 
function Face:distance(point)
    local h,l = self:get_hl()
    local n = self.normal
    local HP = point-h
    
    local dist = HP:dot(n)
    return dist
end
function Face:get_hl()
    return unpack(self.hl)
end
return Face
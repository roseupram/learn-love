local Vec=require('vec')
local proto=require('prototype')
local Transform2  = proto{name='Transform'}

function Transform2:new(a,b,c,d)
    self.data = {
        a or 1, b or 0,
        c or 0, d or 1 }
end
function Transform2:set(a,b,c,d)
    self.data = {
        a, b,
        c, d }
end
function Transform2:clone()
    local a,b,c,d =self:unpack()
    return Transform2(a,b,c,d)
end
function Transform2:__mul(n)
    -- n is number
    if type(n)=="number" then
        
    local tr=self:clone()
    for i=1,4 do
        tr.data[i]=tr.data[i]*n
    end
    return tr
    -- n is vector
    elseif n:is(Vec) then
        local a,b,c,d=self:unpack()
        local x,y=n:unpack()
        return Vec(a*x+b*y,c*x+d*y)
    end
    -- n is transform
end
function Transform2:inv()
    local a,b,c,d =self:unpack()
    local det = self:det()
    local tr=Transform2()
    if det~=0 then
        tr:set(d,-b,-c,a)
    end
    return tr*(1/det)
end
function Transform2:__tostring()
    local a,b,c,d=self:unpack()
    return string.format("Transform\n[%4s,%4s,\n %4s,%4s]",a,b,c,d)
end
function Transform2:unpack()
    return unpack(self.data)
end
function Transform2:det()
    -- a,b
    -- c,d
    local a,b,c,d =self:unpack()
    return a*d-c*b
end
return Transform2
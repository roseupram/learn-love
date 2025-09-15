local proto_vector=require('vector')
local Vec = require('vec')
local Array=require('array')
---@class Color:prototype
local Color = proto_vector{
    name = 'Color',
    default = {
        r = 1,
        b = 1,
        g = 1,
        a = 1, }
}
Color.keys=Array{'r','g','b','a'}
function Color:new(r,g,b,a)
    self.r=r
    self.g=g
    self.b=b
    self.a=a
end
function Color.hex(hex)
    if hex:find('#')==1 then
        hex=hex:sub(2)
    end
    local t={}
    for i=1,6,2 do
        table.insert(t,tonumber(hex:sub(i,i+1),16)/255)
    end
    return Color(unpack(t))
end
function Color:table()
    return {self.r,self.g,self.b,self.a}
end
return Color
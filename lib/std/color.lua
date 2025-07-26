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
Color.keys=Array{'r','g','b'}
function Color:new(r,g,b,a)
    self.r=r
    self.g=g
    self.b=b
    self.a=a
end
function Color:unpack()
    return {self.r,self.g,self.b,self.a}
end
return Color
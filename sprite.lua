local Vec = require('vec')
local prototype=require('prototype')
local pen=require('pen')
local Color=require('color')
local timer=require('timer')
---@class Sprite
---@field center Vec2
local Sprite =prototype{name='Sprite',center=Vec()}

function Sprite:new(ops)
    self.center=ops.center
    self.img_path=ops.img_path or 'assets/me.png'
    self.img=love.graphics.newImage(self.img_path)
    self.iw,self.ih=self.img:getWidth(),self.img:getHeight()
    self.width=ops.width  or self.iw
    self.rotation=0
    self.range=1
    self.color=Color()
end
function Sprite:draw()
    -- print('draw start')
    love.graphics.setColor(self.color:table())
    local x,y=self.center:unpack()
    -- print(x,y)
    local sclae=self.width/self.iw
    love.graphics.draw(self.img,
        x, y, self.rotation, sclae, sclae, self.iw / 2, self.ih / 2)
end
function Sprite:__tostring()
    return string.format('%s,%s',self.img_path,self.center)
end
return Sprite
local prototype=require('prototype')
local Vec=require('vec')
local sprite = require('sprite')
local pen=require("pen")
local sc1=pen.scene()
function sc1:new(t)
    sc1.super(self,t)
    local x,y,w,h=self:get_xywh()
    local wsize=Vec(w,h)/100
    self.player = sprite{img_path = "images/player.png",width=w*.2,center=Vec(30,20)*wsize}
    self.enemy = sprite{img_path="images/enemy.png",width=w*.2,center=Vec(60,40)*wsize}
end
function sc1:draw()
    love.graphics.push('all')
    local Width,Height= love.graphics.getDimensions()
    local x, y, w, h =self:get_xywh()
    love.graphics.setColor(1,.2,.4)
    love.graphics.rectangle('fill', x,y,w,h)
    love.graphics.pop()

    love.graphics.push()
    love.graphics.translate(x,y)
    love.graphics.print(string.format("FPS: %i",love.timer.getFPS()), 10, 10)
    love.graphics.stencil(function ()
        love.graphics.rectangle('fill', 0, 0, w, h)
    end,"replace",1)
    love.graphics.setStencilTest("greater",0)
    self.enemy:draw()
    self.player:draw()
    love.graphics.setStencilTest()
    love.graphics.pop()
end
function sc1:mouse_in()
    local x, y = love.mouse.getPosition()
    local ox, oy, w, h = self:get_xywh()
    x, y = x - ox, y - oy
    local inside = x > 0 and x < w and y > 0 and y < h
    if(inside)then
        return Vec(x, y)
    end
end
function sc1:update(dt)
    local inside_pos = self:mouse_in()
   if inside_pos and love.mouse.isDown(1) then
        self.player.center = inside_pos
   end
end
return sc1
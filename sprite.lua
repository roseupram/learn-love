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
    self.height = self.width/self.iw*self.ih
    self.rotation=0
    self.range=1
    self.color=Color()
    self.shader=love.graphics.newShader([[
    uniform float time;
        vec4 effect(vec4 base_color,Image tex,vec2 texture_coords,vec2 screen_coords){
        float c=.3;
            vec4 color= Texel(tex,texture_coords);
            vec4 neighbor = Texel(tex,texture_coords-vec2(.04,-0.01*sin(time)-0.02));
            if(color.a<.5 && neighbor.a>0){
                color=vec4(c,c,c,1);
            }
            return color;
        }
    ]])
end
function Sprite:draw()
    -- print('draw start')
    love.graphics.push('all')
    love.graphics.setColor(self.color:unpack())
    local x,y=self.center:unpack()
    love.graphics.setColor(.3,.4,.8)
    love.graphics.ellipse('fill',x,y+self.height/2-10,self.width/3,self.height/5)
    -- print(x,y)
    love.graphics.setColor(1,1,1)
    local sclae=self.width/self.iw
    self.shader:send('time',love.timer.getTime())
    love.graphics.setShader(self.shader)
    love.graphics.draw(self.img,
        x, y, self.rotation, sclae, sclae, self.iw / 2, self.ih / 2)
    love.graphics.setShader()
    love.graphics.pop()
end
function Sprite:__tostring()
    return string.format('%s,%s',self.img_path,self.center)
end
return Sprite
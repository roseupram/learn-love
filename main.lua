local rectsize = require "data.rectsize"
-- require('lldebugger').start()
-- print(_VERSION)
local vp=require("vector")
local Vec= require("vec")
local Shape = require("shape")
local Color=Shape.Color
local Array=require('array')
local FP=require('FP')
local Spire=require('spire')
local timer=require('timer')

local T=0
local font_size=30
-- local font=love.graphics.newFont('simhei.ttf',font_size)
local Point = vp { name = "Point", default = { x = 0, y = 0, z = 0 } }
function Point:new(x,y,z)
    self.x=x
    self.y=y
    self.z=z
end
local origin=Point(1)
-- local css = require('css')(require('style_class'))
-- local spire=Spire()

-- love.event.quit()
---comment
---@param v1 Vec2
---@param v2 Vec2
local function line(v1,v2)
    local x,y=v1:unpack()
    love.graphics.line(x,y,v2:unpack())
end
local myShader
function love.draw()
    love.graphics.setShader(myShader)

    local v1,v2=Vec(100,100),Vec(200,200)
    local Width,Height= love.graphics.getDimensions()
    line(v1,v2)
    line(v1+Vec(Width-v1.x*2),v2+Vec(Width-v2.x*2))
    love.graphics.circle("fill",200,350,100)
    love.graphics.circle("fill",Width-200,350,100)
    love.graphics.arc("fill",Width/2,Height-200,100,0,math.pi)
    love.graphics.print("Hello World!",400,400)
    love.graphics.print(v1:len(),400,450)
    love.graphics.print(tostring(origin),400,500)

    love.graphics.setShader()
    -- css:render(spire)
end
--- see https://www.love2d.org/wiki/love.run
--- after update, call origin,clear,draw
function love.update(dt)
    timer.update(dt)
    myShader:send("Time",love.timer.getTime())
end

function love.load()
    print('load')
    myShader=love.graphics.newShader[[
        uniform float Time=0.0;
        float freq=10.0;
        float A=0.3;
        vec4 effect(vec4 color, Image texture,vec2 texture_coords,vec2 screen_coords){
            vec4 pixel= Texel(texture,texture_coords);
            return pixel*color *vec4(.9,A*sin(freq*Time)+.8,.9,1.);
        }
    ]]
    -- timer.oneshot(function (t)
    --     print(t,'oneshot')
    -- end,1000)
    -- local w,h,_=love.window.getMode()
    -- love.mouse.setPosition(w/2,h/2)
    -- pen.size=Vec(200,200)
    -- pen:push(Shape.Line(pen.center,Vec(100,100)))
end
function love.resize(w,h)
    -- spire.content=rectsize(0,0,w,h)
end
function love.mousereleased(x,y)
end
function love.mousemoved(x,y)
    -- hexgon.center:set(x,y)
end
function love.mousepressed(x,y,button,istouch,times)
    -- print(button,times)
end
function love.textinput(t)
    -- print(t)
end
function love.keypressed(key,scancode,isrepeat)
    -- print(key)
    if key =='escape'then
        love.event.quit(0)
    end
end

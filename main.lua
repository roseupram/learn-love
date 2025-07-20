-- require('lldebugger').start()
-- print(_VERSION)
local Vec= require("vec")
local Point = require("point")
local Shape = require("shape")
local Color=Shape.Color
local Array=require('array')
local FP=require('FP')
local Spire=require('spire')
local timer=require('timer')
local Mat=require("mat")
local glb=require("glb")

local T=0
local font_size=30

local myShader,myImage,myMesh,instancemesh,model,myline
local origins = {
}
local z_t,y_t,x_t,y_rot=0,0,0,0
local focal_len=100
local up_v = 0
for i = 1, 10 do
    local o = { 30, -30, 10 + 10 * i }
    table.insert(origins, o)
    o = { -70, -30, 10 + 10 * i }
    table.insert(origins, o)
    o = {  -80 + 10 * i,-30,110 }
    table.insert(origins, o)
end
function love.draw()
    local bg_color = {0.3,0.3,0.3}
    love.graphics.clear(table.unpack(bg_color))

    local v1,v2=Vec(100,100),Vec(200,200)
    local Width,Height= love.graphics.getDimensions()
    -- line(v1,v2)
    -- line(v1+Vec(Width-v1.x*2),v2+Vec(Width-v2.x*2))
    -- love.graphics.circle("fill",200,350,100)
    -- love.graphics.circle("fill",Width-200,350,100)
    -- love.graphics.arc("fill",Width/2,Height-200,100,0,math.pi)
    -- love.graphics.print("Hello World!",400,400)
    local img_w,img_h = myImage:getDimensions()

    love.graphics.print(v1:len(),400,450)
    love.graphics.print(string.format("FPS: %i",love.timer.getFPS()), 10, 10)
    -- love.graphics.draw(model.images[1],Width/2-img_w/2,100)
    -- css:render(spire)
end
--- see https://www.love2d.org/wiki/love.run
--- after update, call origin,clear,draw
function love.update(dt)
    timer.update(dt)
    local time = love.timer.getTime()
end

function love.load()

    local font =love.graphics.newFont(18)
    love.graphics.setFont(font)
    print('load')
    myImage=love.graphics.newImage("th.jpg")
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

function love.wheelmoved(x,y) 
    local move_v=5
    focal_len=math.max(focal_len+y*move_v,0.1)
    print(focal_len)
end
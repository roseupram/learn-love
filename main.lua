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
-- local font=love.graphics.newFont('simhei.ttf',font_size)
local origin=Point(1,0,0)
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
local myShader,myImage,myMesh
function love.draw()
    love.graphics.setShader(myShader)
    love.graphics.draw(myMesh)
    love.graphics.setShader()

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
    -- love.graphics.draw(myImage,Width/2-img_w/2,100)
    -- css:render(spire)
end
--- see https://www.love2d.org/wiki/love.run
--- after update, call origin,clear,draw
function love.update(dt)
    timer.update(dt)
    local time = love.timer.getTime()
    myShader:send("Time",time)
    local r,g,b=1,1,1
    for i=1,myMesh:getVertexCount() do
        r=20*math.cos(2.4*time)
        local z=10+5*math.cos(time)
        b=50*math.sin(time*1.1)
        myMesh:setVertexAttribute(i,3,r,b,40)
        -- myMesh:setVertexAttribute(i, 2, g,1,1)
    end
    -- myMesh:setVertex(1,x,y,z,u,v)
end

function love.load()
    love.graphics.setMeshCullMode('front')
    local f_name = 'model/test_color.glb'
    -- local f_name = 'model/test.glb'
    local model = glb.read(f_name)

    local font =love.graphics.newFont(18)
    love.graphics.setFont(font)
    print('load')
    myShader=love.graphics.newShader("shader/hi.glsl")
    myImage=love.graphics.newImage("th.jpg")
    local vertex_format={
        {"VertexPosition","float",3},
        {"VertexColor","float",3},
        {"origin","float",3}
    }
    local vert={
        { 10,   -60,  40.0, 1, 0, 0 },
        { 20,   -60,  40.0, 1, 1, 0 },
        { 20,   -60,  50,   1, 1 },
        { 10,   -60,  50,   0, 1 },
        { 10,   -70,  40.0, 0, 0, 1 },
        { 20,   -70,  40.0, 1, 0 },
        { 10,   -70,  50.0, 1, 0 },
        { 0,    -100, 50 ,1,1,1},
        { 1,    -100, 50 ,0,1,1},
        { -100, 100,  100 ,.5,1,.5},
        { -101, 100,  100 ,1,.5,.5},
    }
    myMesh=love.graphics.newMesh(vertex_format,model.vertex,"triangles")
    -- myMesh=love.graphics.newMesh(vertex_format,vert,"triangles")
    -- myMesh:setTexture(myImage)
    -- myMesh:setVertexMap(3,2,4,1,4,2,1,5,6,2,5,6,4,7,5)
    myMesh:setVertexMap(model.index)
    -- myMesh:setVertexMap(8,9,10,8,11,10)
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

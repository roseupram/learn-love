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
    love.graphics.setShader(myShader)
    -- love.graphics.draw(myMesh)
    myShader:send("scale",3)
    love.graphics.drawInstanced(myMesh,nil or #origins)
    myShader:send("scale",1)
    love.graphics.draw(myline)
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
    -- love.graphics.draw(model.images[1],Width/2-img_w/2,100)
    -- css:render(spire)
end
--- see https://www.love2d.org/wiki/love.run
--- after update, call origin,clear,draw
function love.update(dt)
    local max_v=20
    local v = Vec()
    local front_vec=Vec(1,0):rotate(-y_rot)
    local side_vec=Vec(0,1):rotate(-y_rot)
    if love.keyboard.isDown('w') then
        v.x=1
    elseif love.keyboard.isDown('s') then
        v.x=-1
    end
    if love.keyboard.isDown('d') then
        v.y=1
    elseif love.keyboard.isDown('a') then
        v.y=-1
    end
    local orien = (front_vec*v.x + side_vec*v.y)*dt*max_v
    z_t = z_t + orien.x
    x_t = x_t + orien.y

    v=0
    if love.keyboard.isDown('q') then
        v=1
    elseif love.keyboard.isDown('e') then
        v=-1
    end
    y_rot=y_rot+v*dt
    local up_v_len,gravity=40,9.8*10
    local y_max=100
    if love.keyboard.isDown('space') and y_t <=y_max then
        up_v=up_v_len
    end
    up_v = up_v - gravity * dt
    y_t = y_t + dt * up_v
    if y_t<0 then
        y_t=0
        up_v=0
    end
    timer.update(dt)
    local time = love.timer.getTime()
    myShader:send("Time",time)
    myShader:send("u_translate",{x_t,y_t,z_t})
    myShader:send("y_r",y_rot)
    myShader:send("focal_len",focal_len)

    local Width,Height= love.graphics.getDimensions()
    myShader:send('wh_ratio',Width/Height)
    myMesh:attachAttribute("origin",instancemesh,"perinstance")
    -- myMesh:setVertex(1,x,y,z,u,v)
end

function love.load()
    love.graphics.setMeshCullMode('back')
    love.graphics.setDepthMode("less",true)
    local f_name = 'model/dice_uv.glb'
    -- f_name = 'model/dice.glb'
    -- local f_name = 'model/torch.glb'
    -- local f_name = 'model/test_color.glb'
    -- local f_name = 'model/test.glb'
    model = glb.read(f_name)

    local font =love.graphics.newFont(18)
    love.graphics.setFont(font)
    print('load')
    myShader=love.graphics.newShader("shader/hi.glsl")
    myImage=love.graphics.newImage("th.jpg")
    local vertex_format={
        {"VertexPosition","float",3},
        {"VertexColor","float",3},
        {"VertexTexCoord","float",2},
        {"origin","float",3},
    }
    local z=40
    local vertex={
        { 0, 0,  z*.2,   0.5, 1, 1 },
        { 20,  0,  z,   1, 0, 0 },
        { 20,  -1, z, 1, 0, 0},
        { 0,  -1, z*.2, 0.5, 1, 1},
    }
    myMesh=love.graphics.newMesh(vertex_format,model.vertex,"triangles")
    myline=love.graphics.newMesh(vertex_format,vertex,'triangles')
    myline:setVertexMap(1,3,2,1,4,3)
    -- myMesh=love.graphics.newMesh(vertex_format,vert,"triangles")
    myMesh:setTexture(model.images[1])
    myMesh:setVertexMap(model.index)
    -- myMesh:setVertexMap(8,9,10,8,11,10)
    -- timer.oneshot(function (t)
    --     print(t,'oneshot')
    -- end,1000)
    -- local w,h,_=love.window.getMode()
    -- love.mouse.setPosition(w/2,h/2)
    -- pen.size=Vec(200,200)
    -- pen:push(Shape.Line(pen.center,Vec(100,100)))
    instancemesh=love.graphics.newMesh({{"origin","float",3}},origins,nil,'static')
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
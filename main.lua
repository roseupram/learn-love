-- require('lldebugger').start()
-- print(_VERSION)
local Vec= require("vec")
local Point = require("point")
local Shape = require("shape")
local Color=Shape.Color
local Array=require('array')
local FP=require('FP')
local timer=require('timer')()
local scene=require('scene')


local root_scene
local my_mesh,my_shader
local lg = love.graphics
local Time=0
function love.draw()
    local bg_color = {0.,0.,0.}
    love.graphics.clear(table.unpack(bg_color))
    lg.setShader(my_shader)
    love.graphics.draw(my_mesh)
    lg.setShader()
    -- root_scene:render()
end
--- see https://www.love2d.org/wiki/love.run
--- after update, call origin,clear,draw
function love.update(dt)
    Time=Time+dt
    my_shader:send('time',Time)
    timer:update(dt)
    -- root_scene:update(dt)
end

function love.load()
    lg.setDepthMode('less',true)
    local vformat={
        {"VertexPosition","float",3},
        {"VertexColor","float",3},
    }
    local vertex={
        { -1, 1,  1,  1, 0, 0 },
        { 1,  1,  1,  1, 0, 0 },
        { 1,  -1, 1,  1, 0, 0 },
        { -1, -1, 1,  1, 0, 0 },
        {-1,1,1,0,1,0},
        {1,1,1,0,1,0},
        {1,1,-1,0,1,0},
        {-1,1,-1,0,1,0},
        { 1,  1,  1,  0, 0, 1 },
        { 1,  -1, 1,  0, 0, 1 },
        { 1,  -1, -1, 0, 0, 1 },
        { 1,  1,  -1, 0, 0, 1 },
        { -1, 1,  -1,  1, 1, 0 },
        { 1,  1,  -1,  1, 1, 0 },
        { 1,  -1,-1,  1, 1, 0 },
        { -1, -1, -1,  1, 1, 0 },
    }
    -- for i,v in ipairs(vertex) do
    --     vertex[i][1]=vertex[i][1]/400
    --     vertex[i][2]=vertex[i][2]/400
    --     vertex[i][3]=vertex[i][3]/400
    -- end
    my_mesh=lg.newMesh(vformat,vertex,"triangles")
    my_mesh:setVertexMap(1,3,2,1,4,3,8,5,6,8,6,7,9,10,11,9,11,12,13,14,15,13,15,16)
    my_shader=lg.newShader('shader/isometric.glsl')
    local w,h=lg.getDimensions()
    my_shader:send('wh_ratio',w/h)

    local font =love.graphics.newFont(18)
    love.graphics.setFont(font)
    print('load')
    root_scene = scene {
        y = 10,
        width = 100,
        height = 90
    }
end
function love.resize(w,h)
    my_shader:send('wh_ratio',w/h)
    -- spire.content=rectsize(0,0,w,h)
end
function love.mousereleased(x,y)
end
function love.mousemoved(x,y)
    -- hexgon.center:set(x,y)
end
function love.mousepressed(x,y,button,istouch,times)
    root_scene:mousepressed(x,y,button,istouch,times)
end
function love.textinput(t)
    -- print(t)
end
function love.keypressed(key,scancode,isrepeat)
    -- print(key)
    if key =='escape'then
        love.event.quit(0)
    end
    root_scene:keypressed(key,scancode,isrepeat)
end

function love.wheelmoved(x,y) 
end
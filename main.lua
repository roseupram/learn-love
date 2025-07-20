-- require('lldebugger').start()
-- print(_VERSION)
local Vec= require("vec")
local Point = require("point")
local Shape = require("shape")
local Color=Shape.Color
local Array=require('array')
local FP=require('FP')
local timer=require('timer')
local scene=require('scene')


local myImage
local container=scene{
    y=10,
    width = 100,
    height = 80
}
local pos=Vec(400,400)
function love.draw()
    local bg_color = {0.,0.,0.}
    love.graphics.clear(table.unpack(bg_color))
    container:draw()
end
--- see https://www.love2d.org/wiki/love.run
--- after update, call origin,clear,draw
function love.update(dt)
    timer.update(dt)
    container:update(dt)
    local x,y = love.mouse.getPosition()
    if love.mouse.isDown(1) then
        pos = Vec(x, y)
    end
    local time = love.timer.getTime()
end

function love.load()

    local font =love.graphics.newFont(18)
    love.graphics.setFont(font)
    print('load')
    myImage=love.graphics.newImage("images/player.png")
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
end
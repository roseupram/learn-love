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


local myImage
local root_scene
function love.draw()
    local bg_color = {0.,0.,0.}
    love.graphics.clear(table.unpack(bg_color))
    root_scene:draw()
end
--- see https://www.love2d.org/wiki/love.run
--- after update, call origin,clear,draw
function love.update(dt)
    timer:update(dt)
    root_scene:update(dt)
end

function love.load()
    timer:oneshot(function (self,elapsed)
        print(string.format("%.3f s elasped",elapsed))
    end,2000)

    local font =love.graphics.newFont(18)
    love.graphics.setFont(font)
    print('load')
    myImage=love.graphics.newImage("images/player.png")
    root_scene = scene {
        y = 10,
        width = 100,
        height = 90
    }
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
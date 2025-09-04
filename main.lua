-- require('lldebugger').start()
-- print(_VERSION)
local function addpath(folder)
    -- DO NOT use package.path, not works in windows
    local lfs = love.filesystem
    local fmt='%s;%s/?.lua;%s/?/init.lua'
    local p=string.format(fmt,lfs.getRequirePath(),folder,folder)
    lfs.setRequirePath(p)
end

local root_scene
function love.draw()
    root_scene:render()
end
--- see https://www.love2d.org/wiki/love.run
--- after update, call origin,clear,draw
function love.update(dt)
    root_scene:update(dt)
end

function love.load()
    addpath('lib')
    addpath('lib/std')
    local font =love.graphics.newFont(18)
    love.graphics.setFont(font)
    print('load')
    local scene=require('scene.isometric')
    root_scene = scene {
        y = 10,
        width = 100,
        height = 90
    }
end
function love.resize(w,h)
    root_scene:resize(w,h)
    -- spire.content=rectsize(0,0,w,h)
end
function love.mousereleased(x,y)
end
function love.mousemoved(x,y)
    root_scene:mousemoved(x,y)
end
function love.mousepressed(x,y,button,istouch,times)
    root_scene:mousepressed(x,y,button,istouch,times)
end
function love.textinput(t)
    -- print(t)
end
function love.keyreleased(key,scancode)
    root_scene:keyreleased(key,scancode)
end
function love.keypressed(key,scancode,isrepeat)
    -- print(key)
    if key =='escape'then
        love.event.quit(0)
    end
    root_scene:keypressed(key,scancode,isrepeat)
end

function love.wheelmoved(x,y)
    root_scene:wheelmoved(x,y)
end
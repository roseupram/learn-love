--require('lldebugger').start()
-- print(_VERSION)
local function addpath(folder)
    -- DO NOT use package.path, not works in windows
    local lfs = love.filesystem
    local fmt='%s;%s/?.lua;%s/?/init.lua'
    local p=string.format(fmt,lfs.getRequirePath(),folder,folder)
    lfs.setRequirePath(p)
end

local root_scene
local Event
function love.draw()
    root_scene:render()
end
--- see https://www.love2d.org/wiki/love.run
--- after update, call origin,clear,draw
function love.update(dt)
    Event.update(dt)
    root_scene:update(dt)
end

function love.load()
    addpath('lib')
    addpath('lib/std')
    Event=require('event')
    local font =love.graphics.newFont(18)
    love.graphics.setFont(font)
    print('load')
    local scene=require('scene.rune_raider')
    root_scene = scene {
        y = 10,
        width = 100,
        height = 90
    }
end
function love.resize(w,h)
    Event.push('resize',{w=w,h=h})
end
function love.mousereleased(x, y, button, istouch, times)
    Event.push('mouse', { x = x, y = y, button = button, is_touch = istouch, times = times, release = true })
end

function love.mousemoved(x, y)
    Event.push('mouse', { x = x, y = y, move = true })
end

function love.mousepressed(x, y, button, istouch, times)
    Event.push('mouse', { x = x, y = y, button = button, is_touch = istouch, times = times, down = true })
end
function love.textinput(t)
    -- print(t)
end
function love.keyreleased(key,scancode,isrepeat)
    Event.push('keyboard',{key=key,scancode=scancode,is_repreat=isrepeat,release=true})
end
function love.keypressed(key,scancode,isrepeat)
    Event.push('keyboard',{key=key,scancode=scancode,is_repreat=isrepeat,down=true})
end

function love.wheelmoved(x,y)
    Event.push('mouse', { x = x, y = y, wheel = true })
end
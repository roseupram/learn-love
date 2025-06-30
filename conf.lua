-- this file will load first
-- then load main.lua
local function addpath(folder)
    local p=string.format('%s;./%s/?.lua;./%s/?/init.lua',package.path,folder,folder)
    package.path = p
    -- package.path = package.path .. ';./'..folder..'/?.lua'
    -- print(package.path)
end
addpath('lib')
addpath('lib/std')
-- local __verson=require('version')
function love.conf(t)
    t.console=false
    t.window.width=1024
    t.window.height=768
    t.window.title='raid the gloom'
    t.window.borderless=false
    -- t.modules.joystick=false
    t.modules.physics=false
    -- t.window.fullscreen=true
    t.window.resizable=false
    t.window.depth=16
    -- t.window.msaa=10
end
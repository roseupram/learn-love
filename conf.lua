-- this file will load first
-- then load main.lua
-- local __verson=require('version')
function love.conf(t)
    love.config={Release=false}
    t.console=false
    t.window.width=1024
    t.window.height=768
    t.window.title='raid the gloom'
    -- t.modules.joystick=false
    t.modules.physics=false
    -- t.window.fullscreen=true
    t.window.fullscreen=false
    t.window.borderless=t.window.fullscreen
    -- t.window.fullscreentype="exclusive"
    -- t.window.fullscreentype="desktop"
    t.window.resizable=false
    t.window.depth=16
    t.window.msaa=4
end

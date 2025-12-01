-- require('lldebugger').start()
-- print(_VERSION)
local Event=require('event')
local Vec= require("vec")
local Point = require("3d.point")
local Shape = require("shape")
local Color=Shape.Color
local Array=require('array')
local FP=require('FP')
local Node=require('3d.node')
local UI=require('UI.hand_card')
local Combat=require('scene.combat')


local my_shader
local lg = love.graphics
local sc = Node{name="Rune_Raider"}
function sc:draw()
    lg.push('all')
    self.combat:draw()
    self.UI:draw()
    lg.setShader()
    lg.setDepthMode()
    local x, y =love.mouse.getPosition()
    lg.setColor(1,1,0)
    local w,h = lg.getDimensions()
    local scale=FP.clamp(math.max(w,h)/100,10,20)
    local polygon={0,0,1.2,1,1.5,2,.5,1}
    for i=1,#polygon/2 do
        polygon[i*2-1]=polygon[i*2-1]*scale+x
        polygon[i*2]=polygon[i*2]*scale+y
    end
    lg.polygon('fill',polygon)
    lg.setColor(.3,.3,.7)
    lg.setLineWidth(2)
    lg.polygon('line',polygon)
    lg.pop()
end
---@param dt number
function sc:update(dt)
    self.combat:update(dt)
    self.UI:update(dt)
    local time=love.timer.getTime()
    if self.state and self.waketime<=time then
        local state, delay = coroutine.resume(self.co)
        self.state=state
        if state and delay then
            self.waketime = love.timer.getTime() + delay
        end
    end
end

function sc:new()
    self.co =coroutine.create( function ()
        print('start')
        coroutine.yield(1)
        print('after 1s')
        coroutine.yield(2)
        print('after 2s')
        coroutine.yield(3)
        print('after 3s')
    end)
    local delay=0
    self.state,delay=coroutine.resume(self.co)
    self.waketime=love.timer.getTime()+delay
    local plt={
        red = Color(.9, .2, .2),
        cyan = Color(.1, .7, .9),
        green=Color(.2,.8,.2)
    }
    self.combat=Combat()
    self.UI=UI()
    self.draw_pile={}
    self.hand_pile={}
    self.RNG=love.math.newRandomGenerator(1)
    local cards={
        {name='attack',color=plt.red,range=2},
        {name='move',color=plt.cyan,range=4},
        {name='attack',color=plt.red,range=3},
        {name='move',color=plt.cyan,range=5},
        {name='attack',color=plt.red,range=5},
        {name='move',color=plt.cyan,range=3},
        {name='power',color=plt.green},
    }
    self.discard_pile=cards
    self.turn_number=0
    self.shortcut_table={
        e=function (e)
            if e.release then
                print("turn " .. self.turn_number .. " end")
                self.UI.cards={}
            end
        end
    }
    self:new_turn()
    Event.bind('keyboard',function (e)
        local key=e.key
        local action=self.shortcut_table[key]
        if action then
            action(e)
        end
    end)
end
function sc:new_turn()
    self.turn_number = self.turn_number + 1
    self:draw_cards(5)
end
function sc:draw_cards(number)
    for i=1,number do
        if #self.draw_pile==0 then
            self:shuffle()
        end
        local card=table.remove(self.draw_pile,1)
        table.insert(self.hand_pile,card)
    end
    self.UI:add_cards(self.hand_pile)
end
function sc:shuffle()
    local t=self.discard_pile
    local discard_size=#self.discard_pile
    for i=discard_size,2,-1 do
        local j=self.RNG:random(1,i)
        t[j], t[i] = t[i], t[j]
    end
    self.draw_pile=t
    self.discard_pile={}
end
return sc
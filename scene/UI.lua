-- require('lldebugger').start()
-- print(_VERSION)
local Vec= require("vec")
local Shape = require("shape")
local Color=Shape.Color
local Array=require('array')
local FP=require('FP')
local timer=require('timer')()
local Mesh=require('3d.mesh')
local Shader=require('shader')
local Node=require('3d.node')
local Quat=require('3d.quat')
local Face=require('3d.face')
local Mat=require("3d.mat")
local Movable=require('scene.movable')
local Card=require('scene.card')


local lg = love.graphics
local UI = Node{name="UI"}
function UI:draw()
    lg.push('all')
    lg.setShader()
    lg.setDepthMode()
    for i, card in ipairs(self.cards ) do
        if i~=self.selected_i then
        card:draw()
        end
    end
    if self.selected_i then
        self.cards[self.selected_i]:draw()
    end
    if self.actived_i then
        self.cards[self.actived_i]:draw()
    end
    lg.pop()
end
---@param dt number
function UI:update(dt)
    local lm=love.mouse
    self:check_mouse_in_card()
    -- print(self.selected_i,self.clicked)
    if self.selected_i and self.clicked == 1 then
        local card = self.cards[self.selected_i]
        if self.actived_i and self.actived_i ~= self.selected_i then
            self.cards[self.actived_i]:deactive()
        end
        self.actived_i = self.selected_i
        card:active()
        self:on_card_used(card)
    end
    if self.actived_i and self.clicked == 2 then
        local card = self.cards[self.actived_i]
        card:deactive()
        self:on_card_canceld(card)
        self.actived_i = nil
    end
    if self.clicked then
        self.clicked=nil
    end
end

function UI:new()
    local plt={
        red = Color(.9, .2, .2),
        cyan = Color(.1, .7, .9),
        green=Color(.2,.8,.2)
    }
    self.cards={}
    self:resize(lg.getDimensions())
    self.uniform_list=Shader.uniform_list()
    local cards={
        {name='attack',color=plt.red},
        {name='move',color=plt.cyan},
        {name='attack',color=plt.red},
        {name='move',color=plt.cyan},
        {name='attack',color=plt.red},
        {name='move',color=plt.cyan},
        {name='power',color=plt.green},
    }
    self:add_cards(cards)
end

function UI:check_mouse_in_card()
    local x,y=love.mouse.getPosition()
    if self.selected_i and self.cards[self.selected_i]:include(x,y) then
        return
    end
    local selected_i
    for i=#self.cards,1,-1 do
        local card=self.cards[i]
        if card:include(x,y) then
            selected_i=i
            print(selected_i)
            card:mouse_in(x, y)
            break
        end
    end
    if selected_i ~= self.selected_i and self.selected_i then
        self.cards[self.selected_i]:mouse_out()
    end
    self.selected_i=selected_i
end

function UI:add_cards(cards)
    for i,card_info in ipairs(cards) do
        local card=Card(card_info)
        table.insert(self.cards,card)
    end
    self:arrange_card_pos()
end
function UI:arrange_card_pos()
    if #self.cards<1 then
        return
    end
    local w,h = self.win_size:unpack()
    local size=#self.cards
    local offset_y=h*0.06
    local cx,cy=w/2,h+offset_y
    local card_size=Vec(w*0.1,h*0.16)
    local space=card_size.x*.8
    local n=(size-1)/2
    local start_x=cx-space*n
    for i,card in ipairs(self.cards) do
        card.pos=Vec(start_x+(i-1)*space,cy)
        card.size=card_size
        card.selected_move=Vec(0,-offset_y)
    end
end
function UI:on_card_used(card)
    
end
function UI:mousepressed(x,y,button,is_touch,times)
    local stop=false
    self.clicked = button
    if button==1 and self.selected_i then
        stop=true
    end
    return stop
end
function UI:resize(w,h)
    self.win_size=Vec(w,h)
    self:arrange_card_pos()
end
function UI:wheelmoved(x,y)
    self.camera:zoom(-y)
end
function UI:keypressed(key,scancode,isrepeat)
    if key=='lalt' then
        local x,y=love.mouse.getPosition()
        self.rotate_pivot=x
        self.y_base=self.camera.y_rot
    end
end
function UI:keyreleased(key,scancode,isrepeat)
    if key=='lalt' then
        self.rotate_pivot=-1
    end
end
function UI:mousemoved(x,y,dx,dy)
end

return UI
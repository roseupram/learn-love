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
local Card=require('scene.card')

local lg = love.graphics
local lm = love.mouse

local UI_Card = Node{name="UI_Card"}
function UI_Card:draw()
    lg.push('all')
    lg.setShader()
    lg.setDepthMode()
    self:draw_shortcut()
    self:draw_enegy()
    for i, card in ipairs(self.cards ) do
        if i~=self.hovered_i then
        card:draw()
        end
    end
    if self.hovered_i then
        self.cards[self.hovered_i]:draw()
    end
    if self.selected_i then
        self.cards[self.selected_i]:draw()
    end
    lg.pop()
end
---@param dt number
function UI_Card:update(dt)
    self:check_mouse_in_card()
    -- print(self.selected_i,self.clicked)
    if self.hovered_i and self.clicked == 1 then
        local card = self.cards[self.hovered_i]
        if self.selected_i and self.selected_i ~= self.hovered_i then
            self.cards[self.selected_i]:deselected()
        end
        self.selected_i = self.hovered_i
        card:selected()
        self:on_card_used(card,self.selected_i)
    end
    if self.selected_i and self.clicked == 2 then
        local card = self.cards[self.selected_i]
        card:deselected()
        self:on_card_canceld(card,self.selected_i)
        self.selected_i = nil
    end
    if self.clicked then
        self.clicked=nil
    end
end

function UI_Card:new()
    local plt={
        red = Color(.9, .2, .2),
        cyan = Color(.1, .7, .9),
        green=Color(.2,.8,.2)
    }
    self.cards={}
    self:resize(lg.getDimensions())
end
function UI_Card:draw_shortcut()
    local font=lg.getFont()
    for i,card in ipairs(self.cards) do
        local x,y=card.pos:unpack()
        local w,h=card.size:unpack()
        local top=y-h-font:getHeight()*1.2
        local left=x-w/2+10
        lg.printf(i,left,top,w)
    end
end
function UI_Card:draw_enegy()
    lg.push('all')
    local font=lg.getFont()
    local ex,ey=self.enegy_layout.pos:unpack()
    local radius=self.enegy_layout.radius
    lg.setColor(self.enegy_layout.color:unpack())
    lg.circle('fill',ex,ey,radius)
    lg.setColor(1,1,1)
    lg.printf('3/3',ex-radius,ey-font:getHeight()/2,radius*2,'center')
    lg.pop()
end
function UI_Card:discard(card_i)
    table.remove(self.cards,card_i)
    self.hovered_i=nil
    self.selected_i=nil
    self:arrange_card_pos()
end
function UI_Card:check_mouse_in_card()
    local x,y=love.mouse.getPosition()
    if self.hovered_i and self.cards[self.hovered_i]:include(x,y) then
        return
    end
    local hover_i
    for i=#self.cards,1,-1 do
        local card=self.cards[i]
        if card:include(x,y) then
            hover_i=i
            print(hover_i)
            card:mouse_in(x, y)
            break
        end
    end
    if hover_i ~= self.hovered_i and self.hovered_i then
        self.cards[self.hovered_i]:mouse_out()
    end
    self.hovered_i=hover_i
end

function UI_Card:add_cards(cards)
    for i,card_info in ipairs(cards) do
        local card=Card(card_info)
        table.insert(self.cards,card)
    end
    self:arrange_card_pos()
end
function UI_Card:arrange_card_pos()
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
function UI_Card:on_card_used(card,card_i)
    
end
function UI_Card:on_card_canceld(card,card_i)
    
end
function UI_Card:mousepressed(x,y,button,is_touch,times)
    local stop=false
    self.clicked = button
    if button==1 and self.hovered_i then
        stop=true
    end
    return stop
end
function UI_Card:resize(w,h)
    self.win_size=Vec(w,h)
    self.enegy_layout={
        pos=self.win_size*Vec(.1,.85),
        radius=h*.06,
        color=Color(.9,.2,.3)
    }
    self:arrange_card_pos()
end
function UI_Card:wheelmoved(x,y)
    self.camera:zoom(-y)
end
function UI_Card:keypressed(key,scancode,isrepeat)
    if key=='lalt' then
        local x,y=love.mouse.getPosition()
        self.rotate_pivot=x
        self.y_base=self.camera.y_rot
    end
end
function UI_Card:keyreleased(key,scancode,isrepeat)
    if key=='lalt' then
        self.rotate_pivot=-1
    end
end
function UI_Card:mousemoved(x,y,dx,dy)
end

return {
    Card=UI_Card}
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

local UI_Enegy= Node{name="UI_Enegy"}

local lg = love.graphics
local lm = love.mouse
-- hover |-> select   |-> play     |-> discard 
--       |-> unhover  |-> deselect |-> cancel
---@class UI_Card:Node
---@overload fun(...):UI_Card
local UI_Card = Node{name="UI_Card"}
function UI_Card:new()
    self.children=Array()
    self.cards={}
    local enegy=UI_Enegy()
    self:push(enegy,'ui_enegy')
    self.mouse={}
    self.key={}

    self:resize(lg.getDimensions())
end

function UI_Card:draw()
    lg.push('all')
    lg.setShader()
    lg.setDepthMode()
    self:draw_children()
    self:draw_shortcut()
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
    self:check_shortcut()
    if not self.mouse_block then
        self:check_mouse_in_card()
    end
    -- print(self.selected_i,self.clicked)
    if self.hovered_i and self.clicked == 1 then
        local card = self.cards[self.hovered_i]
        if self.selected_i and self.selected_i ~= self.hovered_i then
            self.cards[self.selected_i]:deselected()
        end
        self:select_card(self.hovered_i)
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
    if self.mouse.released then
        if self.selected_i then
            local card=self.cards[self.selected_i]
            if card:include(self.mouse.pos:unpack()) and card.name=='power' then
                self:play_card(self.selected_i)
            end
        end
        self.mouse.released=false
    end
end
function UI_Card:check_shortcut()
    if self.key.name then
        local key=self.key.name
        if key:find("^%d$") then
            local i=key+0
            local state=self.key.state
            if state=='press' then
                self.mouse_block = true
                self:hover_card(i, 0, 0)
            elseif state=='release' then
                if i==self.hovered_i then
                    self:deselect_card(self.selected_i)
                    self:select_card(i)
                    self.mouse_block = false
                    if self.cards[i].name=='power' then
                        self:play_card(i)
                    end
                end
            end
        end
        self.key.name=nil
    end
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
end
function UI_Card:discard(card_i)
    table.remove(self.cards,card_i)
    self.hovered_i=nil
    self.selected_i=nil
    self:arrange_card_pos()
end
function UI_Card:select_card(i)
    if i and i <= #self.cards then
        local card = self.cards[i]
        local enegy= self:get('ui_enegy')
        local remain=enegy:get()
        if remain>=card.cost then
            self.selected_i = i
            card:selected()
            self:on_card_used(card,self.selected_i)
        end
    end
end
function UI_Card:play_card(i)
    local card=self.cards[i]
    self:discard(i)
    local enegy = self:get('ui_enegy')
    enegy:move(-card.cost)
end
function UI_Card:deselect_card(i)
    if i then
        local card = self.cards[i]
        card:deselected()
        self.selected_i=nil
    end
end
function UI_Card:unhover_card(i)
    if i then
        local card = self.cards[i]
        card:mouse_out()
        self.hovered_i=nil
    end
end
function UI_Card:hover_card(i,x,y)
    if i and i <= #self.cards then
        self:unhover_card(self.hovered_i)
        self:deselect_card(self.selected_i)
        local card = self.cards[i]
        card:mouse_in(x, y)
        self.hovered_i=i
    end
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
            self:hover_card(i,x,y)
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
    local w,h = self.size:unpack()
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
function UI_Card:keypressed(key,scancode,isrepeat)
    self.key.name=key
    self.key.state='press'
end
function UI_Card:keyreleased(key,scancode,isrepeat)
    self.key.name=key
    self.key.state='release'
end
function UI_Card:mousemoved(x,y)
    self.mouse_moved=true
end
function UI_Card:mousereleased(x, y, button, is_touch, times)
    local stop=false
    self.mouse.released=true
    self.mouse.pos=Vec(x,y)
    return stop
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
    self.size=Vec(w,h)
    self:get("ui_enegy").layout={
        pos=self.size*Vec(.1,.85),
        radius=h*.06,
        color=Color(.9,.2,.3)
    }
    self:arrange_card_pos()
end

function UI_Enegy:new()
    self.enegy = { max = 3, remain = 3 }
end
function UI_Enegy:move(n)
    self.enegy.remain=self.enegy.remain+n
end
function UI_Enegy:get()
    return self.enegy.remain
end
function UI_Enegy:draw()
    lg.push('all')
    local font = lg.getFont()
    local ex, ey = self.layout.pos:unpack()
    local radius = self.layout.radius
    lg.setColor(self.layout.color:unpack())
    lg.circle('fill', ex, ey, radius)
    lg.setColor(1, 1, 1)
    local enegy = self.enegy
    lg.printf(enegy.remain .. '/' .. enegy.max, ex - radius, ey - font:getHeight() / 2, radius * 2, 'center')
    lg.pop()
end

return {
    Card=UI_Card}
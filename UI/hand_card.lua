local Vec= require("vec")
local Event = require("event")
local Shape = require("shape")
local Color=Shape.Color
local Array=require('array')
local FP=require('FP')
local timer=require('timer')()
local Node=require('3d.node')
local Card=require('UI.single_card')
local UI_Enegy=require('UI.enegy_bar')


local lg = love.graphics
local lm = love.mouse
-- hover |-> select   |-> play     |-> discard 
--       |-> unhover  |-> deselect |-> cancel
---@class Hand_Card:Node
---@overload fun(...):Hand_Card
local Hand_card = Node{name="UI_Card"}
function Hand_card:new()
    self.children=Array()
    self.cards={}
    local enegy=UI_Enegy()
    self:push(enegy)
    self.enegy=enegy
    self.mouse={}
    self.key={}
    Event.bind('resize',function (e)
        self:resize(e.w,e.h)
    end)
    Event.bind('mouse',function (e)
        self:on_mouse(e)
    end)
    Event.bind('keyboard',function (e)
        self:on_keyboard(e)
    end)
    Event.bind('play_card',function (e)
        self:play_card(e.index)
    end)
    self:resize(lg.getDimensions())
end

function Hand_card:draw()
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
function Hand_card:update(dt)
    if not self.mouse_block then
        self:check_mouse_in_card()
    end
end
function Hand_card:draw_shortcut()
    local font=lg.getFont()
    for i,card in ipairs(self.cards) do
        local x,y=card.pos:unpack()
        local w,h=card.size:unpack()
        local top=y-h-font:getHeight()*1.2
        local left=x-w/2+10
        lg.printf(i,left,top,w)
    end
end
function Hand_card:discard(card_i)
    table.remove(self.cards,card_i)
    self.hovered_i=nil
    self.selected_i=nil
    self:arrange_card_pos()
end
function Hand_card:select_card(i)
    if i and i <= #self.cards then
        if self.selected_i and self.selected_i ~= i then
            self.cards[self.selected_i]:deselected()
        end
        local card = self.cards[i]
        local remain=self.enegy:remain()
        if remain>=card.cost then
            self.selected_i = i
            card:selected()
            Event.push('select_card',{card=card,index=i})
        end
    end
end
function Hand_card:play_card(i)
    local card=self.cards[i]
    self:discard(i)
    self.enegy:move(-card.cost)
end
function Hand_card:deselect_card(i)
    if i then
        local card = self.cards[i]
        card:deselected()
        self.selected_i=nil
        Event.push('deselect_card',{card=card,index=i})
    end
end
function Hand_card:unhover_card(i)
    if i then
        local card = self.cards[i]
        card:mouse_out()
        self.hovered_i=nil
    end
end
function Hand_card:hover_card(i,x,y)
    if i and i <= #self.cards then
        self:unhover_card(self.hovered_i)
        self:deselect_card(self.selected_i)
        local card = self.cards[i]
        card:mouse_in(x, y)
        self.hovered_i=i
    end
end
function Hand_card:check_mouse_in_card()
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

---@param cards table
function Hand_card:add_cards(cards)
    for i,card_info in ipairs(cards) do
        local card=Card(card_info)
        table.insert(self.cards,card)
    end
    self:arrange_card_pos()
end
function Hand_card:arrange_card_pos()
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
function Hand_card:on_keyboard(e)
    local key = e.key
    if key:find("^%d$") then
        local i = key + 0
        if e.down then
            self.mouse_block = true
            self:hover_card(i, 0, 0)
        elseif e.release then
            if i == self.hovered_i then
                self:deselect_card(self.selected_i)
                self:select_card(i)
                self.mouse_block = false
                if self.selected_i==i and self.cards[i].name == 'power' then
                    self:play_card(i)
                end
            end
        end
        e.stop = true
    end

end
function Hand_card:on_mouse(e)
    local button = e.button
    if e.down then
        if self.hovered_i and button == 1 then
            local card = self.cards[self.hovered_i]
            self:select_card(self.hovered_i)
            e.stop = true
        end
        if self.selected_i and button == 2 then
            local card = self.cards[self.selected_i]
            self:deselect_card(self.selected_i)
            e.stop = true
        end
    end
    if e.release then
        if self.selected_i then
            local card = self.cards[self.selected_i]
            if card:include(e.x, e.y) and card.name == 'power' then
                self:play_card(self.selected_i)
                e.stop = true
            end
        end
    end
end
function Hand_card:resize(w,h)
    self.size=Vec(w,h)
    self.enegy.layout={
        pos=self.size*Vec(.1,.85),
        radius=h*.06,
        color=Color(.9,.2,.3)
    }
    self:arrange_card_pos()
end


return Hand_card
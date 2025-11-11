local Node=require('3d.node')
local Vec=require('vec')
local Color=require('color')
local Card=Node{name="Card"}
local lg =love.graphics
function Card:new(ops)
    self.name=ops.name
    self.pos=Vec()
    self.range=ops.range or 0
    self.selected_move=Vec(0,-20)
    self.size=ops.size or Vec(70,100)
    self.color=ops.color or Color(.5,.5,.5)
    self.damage=ops.damage or 6
    if self.range>0 then
        if self.name=='move' then
            self.description = string.format("%s\nR:%d", self.name,self.range)
        else
            self.description = string.format("%s\nR:%d D:%d", self.name,self.range,self.damage)
        end
    else
        self.description = self.name
    end
end
function Card:draw()
    lg.push('all')
    local x,y=self.pos:unpack()
    local w,h=self.size:unpack()
    local x_left=x-w/2
    local y_top=y-h
    if self.is_active then
        lg.setLineWidth(10)
        lg.setColor(1, 1, 1)
    else
        lg.setLineWidth(2)
        lg.setColor(.4, .2, .1)
    end
    lg.rectangle('line', x_left, y_top, w, h)
    lg.setColor(self.color:unpack())
    lg.rectangle('fill',x_left,y_top,w,h)
    lg.setColor(1,1,1)
    lg.printf(self.description,x_left,y_top+h*.1,w,'center')
    lg.pop()
end
function Card:include(tx,ty)
    local x,y=self.pos:unpack()
    local w,h=self.size:unpack()
    local x_left=x-w/2
    local y_top=y-h
    return  x_left<tx and y_top<ty and x_left+w>tx and y_top+h>ty
end
function Card:mouse_in(x, y)
    if not self.is_active then
        self.last_pos = self.pos
        self.pos = self.pos + self.selected_move
    end
end

function Card:selected()
    self.is_active = true
end
function Card:deselected()
    print('deactive')
    self.is_active = false
    self:mouse_out()
end
function Card:mouse_out()
    if not self.is_active then
        self.pos = self.last_pos
    end
end
return Card
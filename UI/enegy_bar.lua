local lg = love.graphics
local Node=require('3d.node')

local UI_Enegy= Node{name="UI_Enegy"}
function UI_Enegy:new()
    self.enegy = { max = 3, remain = 3 }
end
function UI_Enegy:move(n)
    self.enegy.remain=self.enegy.remain+n
end
function UI_Enegy:remain()
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
return UI_Enegy
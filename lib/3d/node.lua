local pttype=require('prototype')
---@class Node:prototype
local Node=pttype{name='Node'}
local Array=require('array')
function Node:new(ops)
    self:merge(ops)
    self.children=Array()
    self.to_draw=Array()
end
function Node:push(child,name)
    if name then
        assert(self.children[name] == nil, string.format("%s has been used",name))
        self.children[name]=child
    else
        self.children:push(child)
    end
    if child.draw then
        self.to_draw:push(child)
    end
end
function Node:get(name)
    return self.children[name]
end
function Node:render()
    self:before_draw()
    self:draw()
    self:after_draw()
end
function Node:before_draw()
    love.graphics.push('all')
end
function Node:after_draw()
    love.graphics.pop()
end
function Node:draw()
    self.to_draw:each(function (child)
        if child.render then
            child:render()
        else
            child:draw()
        end
    end)
end
function Node:mousepressed(x,y,button,is_touch,times) end
return Node
local pttype=require('prototype')
local Array=require('array')
---@class Node:prototype
local Node=pttype{name='Node'}
function Node:new(ops)
    self:merge(ops)
    self.children=Array()
end
function Node:push(child,name)
    if name then
        assert(self.children[name] == nil, string.format("%s has been used",name))
        self.children[name]=child
    end
    self.children:push(child)
end
function Node:update(...)
    local args={...}
    self.children:each(function (child,i,arr)
        child:update(table.unpack(args))
    end)
end
function Node:get(name)
    return self.children[name]
end
function Node:render()
    self:before_draw()
    if self.draw then
        self:draw()
    else
        self:draw_children()
    end
    self:after_draw()
end
function Node:before_draw()
    love.graphics.push('all')
end
function Node:after_draw()
    love.graphics.pop()
end
function Node:draw_children()
    self.children:each(function (child)
        if child.render then
            child:render()
        else
            child:draw()
        end
    end)
end
function Node:mousepressed(x,y,button,is_touch,times) end
return Node
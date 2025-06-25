local Array=require('array')
local rectsize=require('data.rectsize')
---@class css
local export={}
---from a class_table to a style_table
---@param class_table table
---@return table
function export:get_class_style(class_table)
    local st=self.style_table
    local style = Array(class_table):reduce(function (accu_style,class_name)
        local s=st[class_name]

        if s.compose then
            local composed=self:get_class_style(s.compose)
            s.compose=nil
            s=table.merge(composed,s)
            st[class_name]=s
        end

        return table.merge(accu_style,s)
    end,{})
    return style
end
function export:get_style(element)
    local class_style = self:get_class_style(element.class)
    local style = table.merge(self.style_table.default,
        class_style, element.style or {})
    return style
end
local function get_vwh()
    local vw,vh,_=love.window.getMode()
    return vw,vh
end
--- 23 vw vh % deg turn
---@param keys any
---@param element any
---@param parent any
---@return unknown
function export:unit_convert(keys,element,parent)
    if type(keys)~='table' then
        keys={keys}
    end
    parent=parent or {content=rectsize}
    local st=self:get_style(element)
    local t={}
    local vw, vh = get_vwh()
    for i,key in ipairs(keys) do
        local x = st[key]
        if type(x) == 'string' then
            -- x=x
            local map = { vw = vw, vh = vh }
            map['%']=parent.content[key]
            local num, unit = string.match(x, '([%d%.]+)([%a%%]+)')
            x = map[unit] * num/100
        end
        table.insert(t, x)
    end
    return unpack(t)
end
return export
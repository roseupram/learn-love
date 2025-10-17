local proto=require("prototype")
local Parser=proto{name="json_parser"}
function Parser:new(str)
    self.str=str
    self.len=str:len()
    self.pos=1
end
function Parser:char(pos)
    pos=pos or self.pos
    return self.str:sub(pos,pos)
end
function Parser:move_by(offset)
    self.pos=self.pos+offset
end
function Parser:is_end()
    return self.pos>self.len
end
function Parser:run()
    while not self:is_end() do
        local char = self:char()
        if char == '{' then
            return self:get_object()
        elseif char == '[' then
            return self:get_array()
        elseif char~=" " then
            return self:get_value()
        end

        self:move_by(1)
    end
end
function Parser:match(pattern)
    return self.str:match(pattern,self.pos)
end

function Parser:get_value()
    local value
    local offset=0
    while not self:is_end() do
        local char = self:char()
        if char == '{' then
            return self:get_object()
        elseif char == '[' then
            return self:get_array()
        elseif char:find("[-%d]") == 1 then --number -5.1e-8
            value =  self:match('[-]?%d+[.]?[%de-]*')
            offset = string.len(value)
            self:move_by(offset)
            return value+0
        elseif char == '"' then -- string
            value = self:match('("[^"]-")%s*[,}%]]')

            offset = string.len(value)
            value = value:sub(2, -2)
            self:move_by(offset)
            return value
        elseif char:find("[tf]")==1 then -- true/false
            value = self:match('%a+')
            offset = string.len(value)
            self:move_by(offset)
            return value
        end
        self:move_by(1)
    end
end
function Parser:skip_space()
    local has_space=self:char():find("%s") == 1
    if has_space then
        local space_str = self.str:match("%s+")
        self:move_by(space_str:len())
    end
end
function Parser:get_object()
    local object={}
    self:move_by(1)
    while not self:is_end() do
        --get key
        local key,value
        if self:char()=='"' then
            key = self:match('%a[%w_]*')
            self:move_by(key:len()+2)
        end
        if self:char()==":" then
            self:move_by(1)
            value= self:get_value() -- eat all value
            object[key] = value
        end

        if self:char() == '}' then
            self:move_by(1)
            break
        end

        if not value then
            self:move_by(1)
        end
    end
    return object
end
function Parser:get_array()
    local array={}
    self:move_by(1)
    while not self:is_end() do
        local value = self:get_value()
        table.insert(array, value)
        self:skip_space()
        if self:char()==']' then
            self:move_by(1)
            break
        end
        self:move_by(1)
    end
    return array
end

local json={}
function json.read(json_str)
    local parser = Parser(json_str)
    local json_table=parser:run()
    return json_table
end

local function test()
    local s=[[
    { "number":[1,2,"bad"] , "b":-2 }
    ]]
    local j =json.read(s)
    for k,v in ipairs(j.number) do
        print(k, v,type(v))
    end
end
-- test()
return json
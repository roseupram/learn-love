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
    while true do
        local char = self:char()
        if char == '{' then
            return self:get_object()
        elseif char == '[' then
            return self:get_array()
        elseif char~=" " then
            return self:get_value()
        end

        self:move_by(1)
        if self:is_end() then
            break
        end
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
        elseif char:find("%s") ~= 1 then
            -- ([-%w."]+)           [,}%]]
            -- word and number      end char
            value = self:match('([-%w."]+)%s*[,}%]]')
            offset = string.len(value)
            if value:sub(1, 1) == '"' then
                -- this a string, remove ""
                value = value:sub(2, -2)
            elseif value:find("[-%d]") == 1 then
                value = value + 0
            end
            self:move_by(offset)
            return value
        end
        self:move_by(1)
    end
end
function Parser:get_object()
    local object={}
    self:move_by(1)
    while true do
        --get key
        local key,value
        if self:char()=='"' then
            key = self:match('%a+')
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

        self:move_by(1)
        if self:is_end() then
            break
        end
    end
    return object
end
function Parser:get_array(str)
    local array={}
    self:move_by(1)
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
    { "peole":"bob" , "b":-2 }
    ]]
    local j =json.read(s)
    for k,v in pairs(j) do
        print(k, v,type(v))
    end
end
test()
return json
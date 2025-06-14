local proto=require('prototype')
local unp=require("version").unp
local FP=require('FP')
---@class Array:prototype
---@operator call:Array
local Array=proto{name='Array'}

function Array:new(...)
    -- input can be number,string,table... 
    local args={...}
    if #args == 1 then
        args=args[1]
        if args.name=='Array' then
            return args:clone()
        end
        if args.name or type(args)~='table' then
            args={args}
        end
    end
    for i,v in ipairs(args) do
        local typ=type(v)
        if typ=="table" and v.name==nil then
            self:push(Array(unp(v)))
        else
            self:push(v)
        end
    end
end
function Array:filter(func)
    local filtered=Array{}
    self:each(function (v,i,arr)
        if func(v,i,arr) then
            filtered:push(v)
        end
    end)
    return filtered
end
function Array:unpack()
   return unpack(self)
end
function Array:slice(start,end_,step)
    local wrap = function(x)
        local len = #self
        if x < 0 then
            -- -1 => len , -2 => len-1
            x = len + 1 + x
        end
        return FP.clamp(x,1,len)
    end

    start = start or 1
    end_ = end_ or #self
    start,end_=Array{start,end_}:map(wrap):unpack()

    if start==end_ then
        return Array{self[start]}
    end
    local diff=end_-start
    step = step or diff/math.abs(diff)

    local i=start
    local not_get_end = function(i,end_,step)
        -- include end_
        -- 1,10,1
        -- 10,1,-1
        return (end_ - i) * step >= 0
    end

    local arr=Array{}
    while not_get_end(i,end_,step) and self[i] do
        arr:push(self[i])
        i=i+step
    end
    return arr
end
---reduce(func,init_value)
---func(accumulator,value,index)
---@param func function
---@param init_value any
---@return any
function Array:reduce(func,init_value)
    local accumulator=init_value or 0
    self:each(function (v,i)
        accumulator = func(accumulator, v,i)
    end)
    return accumulator
end
function Array:map(func)
    local re=Array{}
    for i,v in ipairs(self) do
        re[i]=func(v,i,self)
    end
    return re
end
function Array:clone()
    local unchange=function (x)
        if type(x) =="table" and x.clone then
            return x:clone()
        else
            return x
        end
    end
    return self:map(unchange)
end
---func(v, i, self)
---@param func function
function Array:each(func)
    for i,v in ipairs(self) do
        func(v, i, self)
    end
end
function Array:__tostring()
    local res=""
    local items={}
    for i=1,#self  do
        local v=self[i]
        local str=string.format("%s",v)
        table.insert(items,str)
    end
    return string.format("Array(%s)",table.concat(items,", "))
end
function Array:__add(add)
    -- onyly for Array + add, not for add + Array
    if type(add)=='table' then
        for index, value in ipairs(add) do
            self:push(value)
        end
    else
            self:push(add)
    end
    return self
end
function Array:__mul(n_repeat)
    
end

function Array:push(x)
    -- push to end
    table.insert(self,x)
end
function Array:pop()
    -- pop at end
    return table.remove(self)
end
function Array:shift(x)
    -- push at head
    table.insert(self,1,x)
end
function Array:unshift()
    -- pop at head
    return table.remove(self,1)
end
function Array:remove(i)
    return table.remove(self,i)
end
function Array:exist(func)
    -- check if at least one item satisfies condition
    for i,v in ipairs(self) do
        local bool=func(v,i,self)
        if bool==true then
            return true
        end
    end
    return false
end
function Array:every(func)
    for i,v in ipairs(self) do
        local bool=func(v,i,self)
        if bool==false then
            return false
        end
    end
    return true
end
---return ascend order,
--- 
---if compare return true, so first arg remain first
---@param compare function|nil
---@return Array
function Array:sorted(compare)
    -- return sorted array
    local arr=self:clone()
    table.sort(arr,compare)
    return arr
end
function Array:reversed()
    local len = #self
    return self:map(function(value, index, arr)
        return arr[len - index + 1]
    end)
end
function Array:max_min()
    local sorted = self:sorted()
    local min, max = sorted[1], sorted[#sorted]
    return max, min
end
---@param seperator string|nil
---@return string
function Array:join(seperator)
    seperator=seperator or ', '
    return table.concat(self,seperator)
end

local function test()
    local arr=Array{1,2,4}
    arr:push(23)
    print(arr)
    print(arr:max_min())
end
-- test()
return Array
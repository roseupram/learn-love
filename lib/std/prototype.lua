local version_=require('version')
--- prototype for all classes
---@class prototype
---@field super function the class extended
local prototype={}
prototype.__index=prototype
prototype.name='prototype'
function prototype:new(t)
    -- print('prototype new')
    self:merge(t or {})
end
--- only add nonexist key
function prototype:merge(t)
    for k,v in pairs(t) do
        if not rawget(self,k) then
            self[k]=v
        end
    end
end
function prototype:update(t,excluded_keys)
    local temp=table.merge({},t)
    excluded_keys=excluded_keys or {}
    if type(excluded_keys)~='table' then
        excluded_keys={excluded_keys}
    end
    for i,v in ipairs(excluded_keys) do
        temp[v]=nil
    end
    for k,v in pairs(temp) do
        self[k] = v
    end
end
function prototype:__tostring()
    local ret=string.format('{%s}\n',self.name)
    for k,v in pairs(self) do
        ret=ret..string.format('%s: %s\n',k,v)
    end
    return string.sub(ret,1,-2)
end
---check whether same prototype
---@param T any
---@return boolean
function prototype:is(T)
    local mt =getmetatable(self)
    while mt do
        if mt == T then
            return true
        end
        mt=getmetatable(mt)
    end
    return false
end
prototype=setmetatable(prototype, {
    __call=function (t, ...)
        -- t is called class
        local mt=getmetatable(t)
        local o =setmetatable({},t)
        -- extend from super class
        if not rawget(t,'_extend') then
            -- print(t.name,'extend',mt.name)
            for func_name, func in pairs(mt) do
                if func_name:find("__") == 1 then
                    t[func_name] = t[func_name] or mt[func_name]
                end
            end
            t._extend = true
        end
        t.__index=t
        o.super=t.new
        t.new(o,...)
        return o
    end,
}
)
local function test()
    local people = prototype { name = 'people' }
    function people:new(t)
        people.super(self, t)
    end

    local student = people { name = 'student' }
    function student:new(t)
        student.super(self, t)
    end

    local a = student({ name = 'student' })
    print(a:is(prototype))
end
return prototype
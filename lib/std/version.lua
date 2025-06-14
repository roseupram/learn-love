local version=string.sub(_VERSION,string.len(_VERSION))+0
local unp
---return merged table
---@return table
table.merge=function (...)
    local args={...}
    -- only add nonexist key
    local new_table={}
    for i, t in ipairs(args) do
        for k, v in pairs(t) do
            new_table[k] = v
        end
    end
    return new_table
end
---update first table
---@param t table
---@param p table
table.update=function (t,p)
    -- update all key, existing or nonexisting
    for k,v in pairs(p) do
        t[k] = v
    end
end
table.keys=function (t)
    local keys={}
    for key, value in pairs(t) do
        table.insert(keys,key)
    end
    return keys
end

if version>1 then
   unp= function (x)
---@diagnostic disable-next-line: deprecated
    return table.unpack(x)
   end
else
    table.unpack=function (t)
        return unpack(t)
    end
    unp = function (x)
        return unpack(x)
    end
end
local export={
    version=version,
    unp=unp
}
return export
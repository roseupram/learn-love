---@class Event
---singleton 
local Event = {}
local Queue={}
local kf={}
---bind 
function Event.bind(event_name,fn)
    kf[event_name]=kf[event_name] or {}
    table.insert(kf[event_name],fn)
end
---trigger
function Event.push(name,et)
    if kf[name] then
        for i,fn in ipairs(kf[name]) do
            fn(et)
            if et.stop then
                break
            end
        end
    end
end
function Event.update(dt)
    
end
return Event
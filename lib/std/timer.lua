local prototype=require('prototype')
---@class Timer
local timer=prototype{name='timer'}
local Array=require("array")


function timer:new()
    self.time=0 --- second
    self.queue = Array()
end
---@param func any return true to remove self
---@param period_ms number|nil in milisecond
function timer:interval(func,period_ms)
    self.queue:push{
        f=func,
        period_ms=period_ms or 1000,
        start=self.time,
        cycle=0,
    }
end

---@param func fun(self:table,elapsed:number)
---@param delay_ms number|nil in milisecond, default 1000
function timer:oneshot(func,delay_ms)
    self:interval(function (...)
        func(...)
        return true
    end,delay_ms or 1000)
end

function timer:update(t)
    self.time=self.time+t

    local pop_index=Array()
    self.queue:each(function (v,i)
        local period=v.period_ms/1000
        local dt=self.time-v.start
        if dt>period*(v.cycle+1) then
            v.cycle=v.cycle+1
            local stop = v.f(v,dt)
            if stop == true then
                pop_index:push(i)
            end
        end
    end)
    pop_index:reversed():each(function (index)
        self.queue:remove(index)
    end)
end
return timer
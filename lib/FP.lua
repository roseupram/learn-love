local FP={}
function FP.add(x,y)
    return x+y
end
function FP.mul(x,y)
    return x*y
end
function FP.chain(...)
    local fns={...}
    return function (x)
        for i, fn in ipairs(fns) do
            x=fn(x)
        end
        return x
    end
end
function FP.clamp(x,min,max)
        if x<min then
            x=min
        elseif x > max then
            x = max
        end
        return x
end
function FP.is_zero(v)
    return v==0
end
function FP.remove_minus_0(v)
    if v == 0 then
        return 0
    end
    return v
end
function FP.sign(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
end
function FP.relu(x)
    if x>0 then
        return x
    else
        return 0
    end
end
function FP.sin(x,max,min)
    max=max or 1
    min=min or -1
    local base=(max+min)/2
    local A=(max-min)/2
    return A*math.sin(x)+base
end
return FP
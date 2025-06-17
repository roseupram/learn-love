local proto = require("prototype")
local vp = require("vector")

local Vec4 = vp { name = "Vec4", default = { x = 0, y = 0, z = 0, w = 0 } }
function Vec4:new(x,y,z,w)
    self.x=x
    self.y=y
    self.z=z
    self.w=w
end

local Mat4=proto{name="Mat4"}
function Mat4:new()
    for i = 1, 4 do
        self[i] = {0,0,0,0}
        self[i][i] = 1
    end
end
function Mat4:row(i)
    return Vec4(table.unpack(self[i]))
end
function Mat4:column(c)
   local col={}
   for i=1,4 do
    table.insert(col,self[i][c])
   end
   return Vec4(table.unpack(col))
end
function Mat4:__tostring()
    local s = "Mat4 {\n"
    for i,row in ipairs(self) do
        s=s.. string.format("  [ %s ]\n", table.concat(row,", ") )
    end
    return s.."}\n"
end
local function test()
    local m =Mat4()
    print(m)
    local r1 = m:row(1)
    local c = m:column(1)
    print(r1:dot(c))
end
-- test()
return Mat4

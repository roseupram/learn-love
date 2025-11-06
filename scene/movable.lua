local Node=require('3d.node')
local Mesh=require('3d.mesh')
local Point=require('3d.point')
local Shader=require('shader')
local lg=love.graphics
---@class Movable
local Movable=Node{name="Movable"}
function Movable:new(ops)
    self.image=ops.image
    self.mesh = Mesh { vertex = {
        { -1, 1,  0, 1, 1, 1, 0, 0 },
        { -1, -1, 0, 1, 1, 1, 0, 1 },
        { 1,  -1, 0, 1, 1, 1, 1, 1 },
        { 1,  1,  0, 1, 1, 1, 1, 0 },
    }, texture = self.image,
        anchor = Point(0, -1, 0),
    }
    self.shader=Shader.new("outline")
    self.shader:send('edge_color',{.9,.5,.3,1})
    self.position=Point()
end

function Movable:draw()
    lg.setMeshCullMode('none')
    self.mesh:draw()
end
function Movable:get_position()
    return self.position
end
function Movable:set_position(p3d)
    self.position=p3d
    self.mesh:set_position(p3d)
end
function Movable:move(dx)
    self.position:add(dx)
    self.mesh:set_position(self.position)
end
function Movable:set_quat(q)
    self.mesh:set_quat(q)
end
function Movable:before_draw()
    love.graphics.push('all')
    love.graphics.setShader(self.shader)
end
return Movable

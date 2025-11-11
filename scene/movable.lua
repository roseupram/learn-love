local Node=require('3d.node')
local Face=require('3d.face')
local Mesh=require('3d.mesh')
local Point=require('3d.point')
local Shader=require('shader')
local lg=love.graphics
---@class Movable
local Movable=Node{name="Movable"}
function Movable:new(ops)
    local vertex={
        { -1, 1,  0, 1, 1, 1, 0, 0 },
        { -1, -1, 0, 1, 1, 1, 0, 1 },
        { 1,  -1, 0, 1, 1, 1, 1, 1 },
        { 1,  1,  0, 1, 1, 1, 1, 0 },
    }
    self.image=ops.image
    self.mesh = Mesh { vertex = vertex, texture = self.image,
        anchor = ops.anchor or Point(0, -1, 0),
    }
    self.shader=Shader.new("outline")
    self.position=Point()
    local points={}
    for i,v in ipairs(vertex) do
        table.insert(points, Point(v[1], v[2], v[3])+Point(0,1,0))
    end
    self.face=Face{points=points,normal=Point(0,0,1)}
    self:set_position(self.position)
end
function Movable:hurt(damage)
    print('hurt '..damage)
end
function Movable:highlight()
    self.shader:send('edge_color',{.9,.5,.3,1})
end
function Movable:normal()
    self.shader:send('edge_color',{1,1,1,1})
end
function Movable:test_ray(p,d)
    return self.shape:test_ray(p,d)
end
function Movable:draw()
    lg.setMeshCullMode('none')
    self.mesh:draw()
end
function Movable:get_position()
    return self.position
end
function Movable:set_position(p3d)
    self.position=Point(p3d)
    self.mesh:set_position(self.position)
    self.shape=self.face+self.position
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

-- require('lldebugger').start()
-- print(_VERSION)
local Vec= require("vec")
local Point = require("3d.point")
local Shape = require("shape")
local Color=Shape.Color
local Array=require('array')
local FP=require('FP')
local timer=require('timer')()
local Pen=require('pen')
local Camera=require('3d.camera')


local my_mesh,my_shader
local lg = love.graphics
local tls={
    {0,0,0},
    {2,0,4},
    {2,0,-2}
}
local Time=0
local sc = Pen.Scene{name="Isometric"}
function sc:draw()
    local bg_color = {.1,.1,.1}
    lg.clear(table.unpack(bg_color))
    lg.print(self.name,1,1)
    lg.setShader(my_shader)
    for i,tl in ipairs(tls) do
        my_shader:send('tl', tl)
        lg.draw(my_mesh)
    end
    lg.setShader()
end
---@param dt number
function sc:update(dt)
    timer:update(dt)
    local lk=love.keyboard
    local dz, dx = 0, 0
    if lk.isDown('w') then
        dz = dz + 1
    end
    if lk.isDown('s') then
        dz = dz - 1
    end
    if lk.isDown('a') then
        dx=dx-1
    end
    if lk.isDown('d') then
        dx=dx+1
    end
    local cam = self.camera
    local front = cam:front()*cam.wh_ratio -- in glsl, y*=wh_ratio
    local left=cam:left()
    local dv=front*dz+left*dx
    cam:move(dv*dt)
    Time=Time+dt
    my_shader:send('time',Time)
    my_shader:send('camera_param','column',cam:param_mat())
end

function sc:new()
    self.rotate_pivot=-1
    self.camera=Camera()
    lg.setDepthMode('less',true)
    local vformat={
        {"VertexPosition","float",3},
        {"VertexColor","float",3},
    }
    local vertex={
        { -1, 1,  1,  1, 0, 0 },
        { 1,  1,  1,  1, 0, 0 },
        { 1,  -1, 1,  1, 0, 0 },
        { -1, -1, 1,  1, 0, 0 },
        {-1,1,1,0,1,0},
        {1,1,1,0,1,0},
        {1,1,-1,0,1,0},
        {-1,1,-1,0,1,0},
        { 1,  1,  1,  0, 0, 1 },
        { 1,  -1, 1,  0, 0, 1 },
        { 1,  -1, -1, 0, 0, 1 },
        { 1,  1,  -1, 0, 0, 1 },

        { -1, 1,  -1, 1, 1, 0 },
        { 1,  1,  -1, 1, 1, 0 },
        { 1,  -1, -1, 1, 1, 0 },
        { -1, -1, -1, 1, 1, 0 },
    }
    my_mesh=lg.newMesh(vformat,vertex,"triangles")
    my_mesh:setVertexMap(1,3,2,1,4,3,8,5,6,8,6,7,9,10,11,9,11,12,13,14,15,13,15,16)
    my_shader=lg.newShader('shader/isometric.glsl')
    local w,h=lg.getDimensions()
    self:resize(w,h)
end
function sc:resize(w,h)
    self.camera.wh_ratio=w/h
    -- spire.content=rectsize(0,0,w,h)
end
function sc:wheelmoved(x,y)
    self.camera:zoom(-y/10)
end
function sc:keypressed(key,scancode,isrepeat)
    if key=='lalt' then
        local x,y=love.mouse.getPosition()
        self.rotate_pivot=x
        self.y_base=self.camera.y_rot
    end
end
function sc:keyreleased(key,scancode,isrepeat)
    if key=='lalt' then
        self.rotate_pivot=-1
    end
end
function sc:mousemoved(x,y)
    if self.rotate_pivot>0 then
        local dx= x-self.rotate_pivot
        self.camera.y_rot=self.y_base+dx
    end
end

return sc
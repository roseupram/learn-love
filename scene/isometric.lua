-- require('lldebugger').start()
-- print(_VERSION)
local Vec= require("vec")
local Point = require("point")
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
    lg.setShader(my_shader)
    for i,tl in ipairs(tls) do
        my_shader:send('tl', tl)
        lg.draw(my_mesh)
    end
    lg.setShader()
end
--- see https://www.love2d.org/wiki/love.run
--- after update, call origin,clear,draw
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
    dz=dz*dt; dx=dx*dt
    local y_rot=-self.camera.y_rot
    local front = Vec(-1,0):rotate(y_rot,true)
    local left=Vec(0,1):rotate(y_rot,true)
    local dv=front*dz+left*dx
    -- dv[1]=dz*front.y+dx*left.y
    -- dv[3]=dz*front.x+dx*left.x
    self.camera:move{dv.y,0,dv.x}
    Time=Time+dt
    my_shader:send('time',Time)
    my_shader:send('camera_param','column',self.camera:param_mat())
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
    my_shader:send('wh_ratio',w/h)
end
function sc:resize(w,h)
    my_shader:send('wh_ratio',w/h)
    -- spire.content=rectsize(0,0,w,h)
end
function sc:wheelmoved(x,y)
    self.radius=FP.clamp(self.radius-y/10,.5,4)
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
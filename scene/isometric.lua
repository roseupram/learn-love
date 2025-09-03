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


local my_mesh,my_shader,data_tl,data_rot,data_sc
local lg = love.graphics
local tfs={
    {{0,0,0}, {2,0,4}, {2,0,-2}},
    {{0,0,0}, {0,0,0},{0,0,0}},
    {{1,1,1},{1,1,1},{1,1,1},}
}
local player_tl={3,0,-1}
local Time=0
local sc = Pen.Scene{name="Isometric"}
function sc:draw()
    local bg_color = {.2,.3,.3}
    lg.clear(table.unpack(bg_color))
    lg.print(self.name,1,1)
    lg.setShader(my_shader)
    lg.drawInstanced(my_mesh,#tfs[1])
    -- my_shader:send('tl', player_tl)
    lg.draw(self.player)
    lg.setShader()
end
---@param dt number
function sc:update(dt)
    Time=Time+dt
    timer:update(dt)
    data_tl:setVertex(1,0,0,math.sin(Time))
    data_rot:setVertex(2,0,Time,0)
    data_sc:setVertex(3,1,1+math.sin(Time),1)
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
    local front = cam:front_z()*cam.wh_ratio -- in glsl, y*=wh_ratio
    local left=cam:left_x()
    local dv=front*dz+left*dx
    cam:move(dv*dt)
    my_shader:send('time',Time)
    my_shader:send('camera_param','column',cam:param_mat())
    local p,d=cam:ray(love.mouse.getPosition())
    local t= (p.y-0)/d.y
    local gp=p-d*t
    player_tl=gp:table()
end

function sc:new()
    self.rotate_pivot=-1
    self.camera=Camera()
    lg.setDepthMode('less',true)
    local vformat={
        {"VertexPosition","float",3},
        {"VertexColor","float",3},
        {"VertexTexCoord","float",2}
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
    data_tl=lg.newMesh({{'a_tl','float',3}},tfs[1],nil)
    data_rot=lg.newMesh({{'a_rot','float',3}},tfs[2],nil)
    data_sc=lg.newMesh({{'a_sc','float',3}},tfs[3],nil)
    my_mesh:attachAttribute("a_tl",data_tl,"perinstance")
    my_mesh:attachAttribute("a_rot",data_rot,"perinstance")
    my_mesh:attachAttribute("a_sc",data_sc,"perinstance")
    self.player=lg.newMesh(vformat,{
        {-1,1,0,1,1,1,  0,0},
        {1,1,0,1,1,1,   1,0},
        {1,-1,0,1,1,1,  1,1},
        {-1,-1,0,1,1,1, 0,1},
    })
    self.image= lg.newImage("images/player.png")
    self.player:setTexture(self.image)
    local w,h=lg.getDimensions()
    -- love.mouse.setVisible(false)
    self:resize(w,h)
end
function sc:resize(w,h)
    self.camera.wh_ratio=w/h
    -- spire.content=rectsize(0,0,w,h)
end
function sc:wheelmoved(x,y)
    self.camera:zoom(-y)
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
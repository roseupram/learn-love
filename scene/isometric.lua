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
local Mesh=require('3d.mesh')
local Shader=require('shader')


local my_shader
local lg = love.graphics
local sc = Pen.Scene{name="Isometric"}
function sc:draw()
    local bg_color = {.2,.3,.3}
    lg.clear(table.unpack(bg_color))
    lg.print(self.name,1,1)
    lg.setShader(my_shader)
    local cam = self.camera
    for i,child in ipairs(self.children) do
        if child.draw then
            
        if child.shader then
            child.shader:send('camera_param', 'column', cam:param_mat())
        end
        child:draw()
        end
    end
    lg.setShader()
end
---@param dt number
function sc:update(dt)
    local Time = self.Time+dt
    self.Time=Time
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
    local front = cam:front_z()*cam.wh_ratio -- in glsl, y*=wh_ratio
    local left=cam:left_x()
    local dv=front*dz+left*dx
    cam:move(dv*dt)
    my_shader:send('time',Time)
    my_shader:send('camera_param','column',cam:param_mat())
    local p,d=cam:ray(love.mouse.getPosition())
    local t= (p.y-0)/d.y
    local gp=p-d*t
    self.circle:set_position(gp-Point(0,.99,0))
    local player_pos=self.player:get_position()
    local velocity = gp+Point(0,.0,0)-player_pos
    local P=3
    self.player:move(velocity*dt*P)
    local scale = FP.sin(Time,.2,1)
    self.circle:set_scale(Point(scale,1,scale))
    local cube=self:get('cube')
    cube:set_position(2,Point(-4,0,FP.sin(2*Time,0,5)))
    cube:set_rotate(2,Point(0,0,Time*3))
end

function sc:new()
    self.Time=0
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
    local vmap={1,3,2,1,4,3,8,5,6,8,6,7,9,10,11,9,11,12,13,14,15,13,15,16}
    local tfs = {
        { { 0, 0, 0 }, { 2, 0, 4 }, { 2, 0, -2 } },
        { { 0, 0, 0 }, { 0, 0, 0 }, { 0, 0, 0 } },
        { { 1, 1, 1 }, { 1, 1, 1 }, { 1, 1, 1 }, }
    }
    local cube=Mesh{vmap=vmap,vertex=vertex,mode="triangles",
    instance=3,tl=tfs[1],rot=tfs[2],sc=tfs[3],
    color = {{1,1,1,1},{1,1,1,1},{1,1,1,1}}
    }
    self:push(cube,"cube")

    my_shader=Shader.new('isometric','frag')
    self.image= lg.newImage("images/player.png")
    self.player = Mesh { vertex = {
        { -1, 1,  0, 1, 1, 1, 0, 0 },
        { 1,  1,  0, 1, 1, 1, 1, 0 },
        { 1,  -1, 0, 1, 1, 1, 1, 1 },
        { -1, -1, 0, 1, 1, 1, 0, 1 },
    }, texture=self.image
    }
    self.player.shader=Shader.new("outline")
    self.player.shader:send('edge_color',{.9,.5,.3,1})
    local w,h=lg.getDimensions()
    -- love.mouse.setVisible(false)
    self:resize(w,h)
    self.circle=Mesh.ring()
    local plt={
        red = Color(.9, .2, .2),
        cyan = Color(.1, .7, .9),
    }
    self.circle:color_tone(plt.cyan:clone())
    self:push(self.player,"player")
    self:push(self.circle,"circle")
    local line= Mesh.line{
        points = {
            0, 0, 1,
            2, 0, 0,
            0, 0, -1,
            1, 0, .7,
            1, 0, -.7,
        },
    }
    line:set_position(1,Point(-2,-1,4))
    line:color_tone(Color(.9,.5,.9))
    self:push(line,"line")
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
-- require('lldebugger').start()
-- print(_VERSION)
local Vec= require("vec")
local Point = require("3d.point")
local Shape = require("shape")
local Color=Shape.Color
local Array=require('array')
local FP=require('FP')
local timer=require('timer')()
local Camera=require('3d.camera')
local Mesh=require('3d.mesh')
local Shader=require('shader')
local Node=require('3d.node')


local my_shader
local lg = love.graphics
local sc = Node{name="Isometric"}
function sc:draw()
    local bg_color = {.2,.3,.3}
    lg.clear(table.unpack(bg_color))
    lg.print(self.name..'\nFPS:'..love.timer.getFPS(),1,1)
    lg.setShader(my_shader)
    local cam = self.camera
    for i,child in ipairs(self.to_draw) do
        -- lg.setWireframe(true)
        if child.shader then
            child.shader:send('camera_param', 'column', cam:param_mat())
        end
        child:draw()
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
    local A=Point(0,-.1,0) -- (A,n) is a plane
    local n=Point(0,1,0)
    local t=(p-A):dot(n)/(d:dot(n))
    local gp=p-d*t
    self.circle:set_position(gp)

    local ground=self:get('ground')
    local aabb=ground:get_aabb()+ground:get_position()
    local point,face_n = aabb:test_ray(p,d)
    local velocity = Point()
    local player_pos=self.player:get_position()
    if point then
        -- print(point,face_n)
        velocity = point - player_pos+Point(0,1,0)
        self.circle:set_position(point+face_n*.1)
    end
    --- mesh {A,B,C}
    -- t = Ap:dot(AB:cross(BC))/(d:dot(n))
    -- p_in_plane=t*p+d
    -- local t= (p.y-0)/d.y
    local P=3

    local scale = FP.sin(Time,.2,1)
    self.circle:set_scale(Point(scale,1,scale))
    local in_aabb=false
    local dvdt = velocity * dt * P
    if not in_aabb then
        self.player:move(dvdt)
        local yr = math.atan2(velocity.x,velocity.z)
        self.player:set_rotate(Point(0,yr,0))
    end
end

function sc:new()
    local beat = love.audio.newSource('audio/beat.ogg','static')
    beat:setLooping(true)
    beat:setVolume(.2)
    beat:play()
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
        { { 0, 0, 0 }, { -5, 0, 4 }, { 2, 0, -2 } },
    }
    local cube = Mesh { vmap = vmap, vertex = vertex, mode = "triangles",
        instance = 3, tl = tfs[1] ,
    }
    -- self:push(cube,"cubes")
    cube:set_position(3,Point(3,0,-1))

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
    self.player:set_position(Point(-1,0,-3))
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
            -1, 0, 0,
            0, 2, 0,
            1, 0, 0,
            -.7, 1, 0,
            .7, 1, 0,
        },
        normal=Point(0,0,1)
    }
    line:set_position(Point(-2,-1,4))
    line:set_scale(Point(.5,.5,.5))
    line:color_tone(Color(.9,.5,.9))
    self:push(line,"line")
    local arrow= Mesh.line{
        points = {
            0,0,0,
            3,0,0,
            2,0,-1,
            2,0,1,
            3,0,0,
            2,0,-1,
        },
    }
    arrow:set_position(Point(4,-1,4))
    self:push(arrow,"arrow")
    local wall = Mesh{
        vertex={
            {-2,-1,0,1,1,1,0,0},
            {2,-1,0,1,1,1,0,0},
            {2,1,0,1,1,1,0,0},
            {-2,1,0,1,1,1,0,0},
        }
    }
    wall:set_position(Point(1,0,3))
    wall:color_tone(Color.hex('#7a573d'))
    self:push(wall,"wall")

    local ground = Mesh{
        vertex={
            {-1,0,0,1,1,1,0,0},
            {1,0,0,1,1,1,0,0},
            {-1,0,-2,1,1,.8,0,0},
            {1,0,-2,1,1,.9,0,0},
            {-1,2,-4,1,.5,1,0,0},
            {1,2,-4,.3,1,1,0,0},
            {-1,2,-6,1,1,1,0,0},
            {1,2,-6,1,1,1,0,0},
        },
        mode='strip'
    }
    ground:set_position(Point(8,0,3))
    self:push(ground,"ground")
    local unit_cube = Mesh.cube{wireframe=true}
    self:push(unit_cube,'debug_cube')
    local aabb=ground:get_aabb()
    local size = aabb.max-aabb.min
    local center = (aabb.max+aabb.min)/2
    unit_cube:set_scale(size/2)
    unit_cube:set_position(ground:get_position()+center)
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
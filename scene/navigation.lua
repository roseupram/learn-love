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
local Quat=require('3d.quat')
local Face=require('3d.face')
local Navigate=require('3d.navigate')
local Mat=require("3d.mat")
local Movable=require('scene.movable')
local PQ=require('data.pqueue')


local my_shader
local lg = love.graphics
local sc = Node{name="Isometric"}
function sc:draw()
    lg.push('all')
    local bg_color = {.2,.3,.3}
    lg.clear(table.unpack(bg_color))
    lg.print(self.name..'\nFPS:'..love.timer.getFPS(),1,1)
    lg.setDepthMode('less',true)
    lg.setShader(my_shader)
    local cam = self.camera
    local transp={}
    local to_draw={}
    for i,child in ipairs(self.to_draw) do
        if child.transparent then
            table.insert(transp,child)
        else
            table.insert(to_draw,child)
        end
    end
    table.sort(transp,function (a, b)
        local pa=a:get_position()
        local pb=b:get_position()
        if pa.y~=pb.y then
            return pa.y < pb.y
        else
            return pa.z<pb.z
        end
    end)
    for i,child in ipairs(transp) do
        table.insert(to_draw, child)
    end
    for i,child in ipairs(to_draw) do
        -- lg.setWireframe(true)
        if child.shader then
            child.shader:send('VIEW', 'column', cam:view_mat():flat())
            child.shader:send('PROJECT', 'column', cam:project_mat():flat())
        end
        if child.render then
            child:render()
        else
            child:draw()
        end
    end
    lg.setShader()
    lg.setDepthMode()
    local x, y =love.mouse.getPosition()
    lg.setColor(1,1,0)
    local w,h = lg.getDimensions()
    local scale=FP.clamp(math.max(w,h)/100,10,20)
    local polygon={0,0,1.2,1,1.5,2,.5,1}
    for i=1,#polygon/2 do
        polygon[i*2-1]=polygon[i*2-1]*scale+x
        polygon[i*2]=polygon[i*2]*scale+y
    end
    lg.polygon('fill',polygon)
    lg.setColor(.3,.3,.7)
    lg.setLineWidth(2)
    lg.polygon('line',polygon)
    lg.pop()
end
---@param dt number
function sc:update(dt)
    local Time = self.Time+dt
    self.Time=Time
    timer:update(dt)
    local dz, dx = 0, 0
    local mouse_pos=Vec(love.mouse.getPosition())
    if self.rotate_pivot>0 then
        local dx_= mouse_pos.x-self.rotate_pivot
        self.camera.y_rot=self.y_base+dx_
    end
    local win_size = Vec(love.graphics.getDimensions())
    mouse_pos=mouse_pos/win_size
    local move_range=.03
    dz=-FP.double_step(mouse_pos.y,move_range,1-move_range)
    dx=FP.double_step(mouse_pos.x,move_range,1-move_range)
    local cam = self.camera
    local front = cam:front_z()*cam.wh_ratio -- in glsl, y*=wh_ratio
    local left=cam:left_x()
    local dv=front*dz+left*dx
    cam:move(dv*dt*cam.radius)
    my_shader:send('time',Time)
    my_shader:send('VIEW','column',cam:view_mat():flat())
    my_shader:send('PROJECT','column',cam:project_mat():flat())
    if self.clicked then
        local times = FP.clamp(self.clicked,1,2)
        self.velocity_P=times==1 and 3 or 8
        self.clicked=false
        local p, d = cam:ray(love.mouse.getPosition())
        local A = Point(0, .1, 0) -- (A,n) is a plane
        local n = Point(0, 1, 0)
        local t = (p - A):dot(n) / (d:dot(n))
        local gp = p + d * -t
        self.circle:set_position(gp)
        self.target_pos=gp
    end

    local player_pos=self.player:get_position()
    local PT = self.target_pos- player_pos
    local distance = PT:len()
    if distance<.1 and #self.waypoints>0 then
        self.target_pos=self.waypoints[1]
        table.remove(self.waypoints,1)
        PT = self.target_pos- player_pos
        distance = PT:len()
    end
    local velocity = PT:normal()

    local scale = FP.sin(Time,.2,.5)
    self.circle:set_scale(Point(scale,1,scale))
    local dvdt = velocity * dt * self.velocity_P
    if #self.waypoints==0 then
        dvdt=dvdt*FP.clamp(distance,0,1)
    end
    self.player:move(dvdt)
    self:get("base_ring"):set_position(self.player:get_position())
    -- local q = Quat.from_normal(Point(0, 1, 0), math.rad(-cam.y_rot))
    -- self.player:set_quat(q)
end

function sc:new()
    local plt={
        red = Color(.9, .2, .2),
        cyan = Color(.1, .7, .9),
    }

    local beat = love.audio.newSource('audio/beat.ogg','static')
    beat:setLooping(true)
    beat:setVolume(.1)
    beat:play()
    self.Time=0
    self.rotate_pivot=-1
    self.camera=Camera()
    lg.setDepthMode('less',true)
    -- love.mouse.setRelativeMode(true)
    local w,h=lg.getDimensions()
    self.shadowmap_canvas=lg.newCanvas(w,h,{format="depth16",readable=true})
    love.mouse.setPosition(w/2,h/2)
    if love.config.Release then
        love.mouse.setVisible(false)
        love.mouse.setGrabbed(true)
    end
    self:resize(w,h)
    self.clicked=false
    self.target_pos=Point(1,0,1)
    self.waypoints={}
    self.velocity_P=1

    my_shader=Shader.new('isometric','frag')
    self.player=Movable{image=lg.newImage("images/player.png")}
    local enemy=Movable{image=lg.newImage("images/enemy.png")}
    enemy:set_position(Point(-2,0,-4))
    self:push(enemy,'enemy')

    local base_ring=Mesh.ring()
    base_ring:set_scale{.2,.2,.2}
    self:push(base_ring,"base_ring")
    self:push(self.player,"player")

    self.circle=Mesh.ring()
    self.circle:color_tone(plt.cyan:clone()-Color(0,0,0,.3))
    self:push(self.circle,"circle")

    local platform = Mesh.glb("model/platform.glb")
    platform:set_position(Point(6,0,0))
    local aabb_platform=Mesh.cube{wireframe=true,AABB=platform:get_AABB()}
    self:push(platform,"platform")
    self:push(aabb_platform,"aabb_platform")
    local tris=platform:get_triangles()
    local walkable={}
    local cos_thre =math.cos(math.rad(45))
    for t,tri in ipairs(tris) do
        local A=Point(tri[1])
        local B=Point(tri[2])
        local C=Point(tri[3])
        local n=(B-A):cross(C-B):normal()
        if n:dot(Point(0,1,0))> cos_thre then
            table.insert(walkable,{A,B,C})
        end
    end

    local house=Mesh.glb("model/test.glb")
    house:set_position(Point(-4,0,-4))
    self:push(house,"house")
    local house_aabb=house:get_AABB()
    local aabb_mesh=Mesh.cube{wireframe=true,AABB=house_aabb}
    self:push(aabb_mesh,"debug_aabb")
    local hole=house_aabb:project(Point(0,-1,0))
    local ground_size=10
    local points={{1,0,1},{1,0,-1},{-1,0,-1},{-1,0,1}}
    for i,p in ipairs(points) do
        points[i]=Point(p)*ground_size
    end
    local platform_hole=platform:get_AABB():project(Point(0,-1,0))
    points=Navigate.poly_diff(points,hole)
    points=Navigate.poly_diff(points,platform_hole)
    local face=Face{points=points,sorted=true}
    --- union(points,walkable)
    local colors={{1,0,0},{0,1,0},{0,0,1},{.5,.5,.5},{.2,.7,.9}}
    local face_tris=face:triangulate()
    local group=Mesh.group()
    for i,tri in ipairs(face_tris) do
        local vertex={}
        for t,p in ipairs(tri) do
            local x,y,z=Point(p):unpack()
            local r,g,b=table.unpack(colors[FP.cycle(i,1,#colors)])
            local v={x,y,z,r,g,b,0,0}
            table.insert(vertex,v)
        end
        local mesh = Mesh { vertex = vertex, mode="triangles" }
        -- group:push(mesh)
    end
    local convex=Navigate.convex_decompose(face)
    for i,conv in ipairs(convex) do
        local mesh=Mesh.polygon{points=conv}
        local color = Color(colors[FP.cycle(i,1,#colors)])
        color.r=color.r*math.sin(i)
        mesh:color_tone(color)
        group:push(mesh)
    end
    self:push(group,"mesh_group")

    local ground=Mesh.polygon{points=points}
    ground:color_tone{.6,.6,.9}
    -- self:push(ground,"ground")
end
function sc:mousepressed(x,y,button,is_touch,times)
    if button==1 then
        self.clicked=times
    end
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
function sc:mousemoved(x,y,dx,dy)
end

return sc
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
local Movable=require('scene.movable')


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
            child.shader:send('camera_param', 'column', cam:param_mat())
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
    local move_range=-.05
    dz=-FP.double_step(mouse_pos.y,move_range,1-move_range)
    dx=FP.double_step(mouse_pos.x,move_range,1-move_range)
    local cam = self.camera
    local front = cam:front_z()*cam.wh_ratio -- in glsl, y*=wh_ratio
    local left=cam:left_x()
    local dv=front*dz+left*dx
    cam:move(dv*dt)
    my_shader:send('time',Time)
    my_shader:send('camera_param','column',cam:param_mat())
    if self.clicked then
        local times = FP.clamp(self.clicked,1,2)
        self.velocity_P=(times-1)*5+3
        self.clicked=false
        local p, d = cam:ray(love.mouse.getPosition())
        local A = Point(0, .1, 0) -- (A,n) is a plane
        local n = Point(0, 1, 0)
        local t = (p - A):dot(n) / (d:dot(n))
        local gp = p - d * t
        self.circle:set_position(gp)
        self.target_pos=gp

        local goal
        for i,face in ipairs(self.convex_face) do
            local t=face:test_ray(p,d)
            if t then
                goal=p+d*t
            end
        end
        if goal then
            local waypoints=Navigate.path(self.convex_face, self.player:get_position(), goal)
            if waypoints then
                self.waypoints=waypoints
                self.target_pos=waypoints[1]
            end
        end
        local ground = self:get('ground')
        local aabb = ground:get_aabb() + ground:get_position()
        local point, face_n = aabb:test_ray(p, d)
        if point then
            point=nil
            local gpos=ground:get_position()
            local faces = ground:get_faces()
            for i,face in ipairs(faces) do
                face=face+gpos
                local t_face = face:test_ray(p,d)
                if t_face then
                    point=p+d*t_face
                    face_n=face.normal
                    break
                end
            end
            if point then
                self.target_pos = point
                self.circle:set_position(point + face_n * .1)
            end
        end
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
    local q = Quat.from_normal(Point(0, 1, 0), math.rad(-cam.y_rot))
    self.player:set_quat(q)
end

function sc:new()
    local plt={
        red = Color(.9, .2, .2),
        cyan = Color(.1, .7, .9),
    }
    local area = { { -2,0, -2 }, { -2,0, 2 }, { 6,0, 2 }, { 6,0, -2 },}
    local obstacle={ { -1,0, -1 },{1,0,-1},{1,0,1},{-1,0,1} }
    local points = Navigate.poly_diff(area,obstacle)
    local obstacle2={ { 2,0, -1 },{4,0,-1},{4,0,1},{2,0,1} }
    points=Navigate.poly_diff(points,obstacle2)

    local polygon=Navigate.polygon{points=points}
    points = { { 0, 0, 0 }, { 0, 0, -3 }, { 3, 0, -4 }, { 3, 0, -10 }, { -1, 0, -10 }, { -1, 0, -8 }, { 1, 0, -8 },
        {2,0,-6.5},{2,0,-5},{-1,0,-3.5},{-2,0,0}
    }
    -- polygon=Navigate.polygon{points=points}
    local tris=polygon:triangulate()
    local polygon_vertex={}
    local colors={{1,0,0},{0,1,0},{0,0,1},{1,0,1},{0,1,1},{.5,.2,.8}}
    for i,tri in ipairs(tris) do
        local r, g, b = unpack(colors[FP.cycle(i,1,#colors)])
        for k=1,3 do
            local x,y,z=tri[k]:unpack()
            table.insert(polygon_vertex,{x,y,z,r,g,b,0,0})
        end
    end
    local polygon_mesh=Mesh{vertex=polygon_vertex,mode="triangles"}
    polygon_mesh:set_position(Point(0,0,-10))
    self:push(polygon_mesh,"polygon")
    -- polygon_mesh:color_tone{1,1,1,.5}
    ---BUG can not merge all triangle

    local convex=Navigate.convex_decompose(polygon)
    local cni=Navigate.get_neighbor_info(convex)
    local convex_vertex={}
    local convex_map={}
    self.convex_face={}
    local offset=1
    for i,cvex in ipairs(convex) do
        cvex=Face{points=cvex,sorted=true}:convex_hull()
        local r, g, b = unpack(colors[FP.cycle(i,1,#colors)])
        for _,p in ipairs(cvex) do
            local x, y, z = p:unpack()
            table.insert(convex_vertex, { x, y, z, r, g, b, 0, 0 })
        end
        for k=offset,offset+#cvex-3 do
            table.insert(convex_map,offset)
            table.insert(convex_map,k+1)
            table.insert(convex_map,k+2)
        end
        table.insert(self.convex_face,Face{points=cvex,sorted=true})
        offset=offset+#cvex
    end
    local convex_mesh=Mesh{vertex=convex_vertex,vmap=convex_map,mode="triangles"}
    self:push(convex_mesh,"convex")

    local beat = love.audio.newSource('audio/beat.ogg','static')
    beat:setLooping(true)
    beat:setVolume(.2)
    beat:play()
    self.Time=0
    self.rotate_pivot=-1
    self.camera=Camera()
    lg.setDepthMode('less',true)
    -- love.mouse.setRelativeMode(true)
    local w,h=lg.getDimensions()
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
    local enemy=Movable{image=lg.newImage("images/enemy.png")}
    enemy:set_position(Point(-2,0,-4))
    self:push(enemy,'enemy')
    my_shader=Shader.new('isometric','frag')
    self.image= lg.newImage("images/player.png")
    self.player=Movable{image=self.image}
    local base_ring=Mesh.ring()
    base_ring:set_scale{.2,.2,.2}
    self:push(base_ring,"base_ring")
    self:push(self.player,"player")

    self.circle=Mesh.ring()
    self.circle:color_tone(plt.cyan:clone()-Color(0,0,0,.3))
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
        },
        anchor=Point(0,-1,0)
    }
    wall:set_position(Point(1,0,3))
    wall:color_tone(Color.hex('#7a573d'))
    self:push(wall,"wall")

    local ground = Mesh{
        vertex={
            {-1,0,0,1,1,1,0,0},
            {2,0,0,1,1,1,0,0},
            {-1,0,-2,.7,1,.8,0,0},
            {1,0,-2,.7,.9,.9,0,0},
            {-1,0,-2,.7,1,.8,0,0},
            {1,0,-2,.7,1,.9,0,0},
            {-1,2,-4,.7,.5,1,0,0},
            {1,2,-4,.3,1,.9,0,0},
            {-1,2,-4,.7,.5,1,0,0},
            {1,2,-4,.3,1,.9,0,0},
            {-1,2,-6,1,1,1,0,0},
            {2,2,-6,1,1,1,0,0},
        },
        mode='triangles',
        vmap={
            1,2,3,3,2,4,
            5,6,7,7,6,8,
            9,10,11,11,10,12,
        }
    }
    ground:set_position(Point(8,0,3))
    self:push(ground,"ground")
    local unit_cube = Mesh.cube{wireframe=true}
    -- self:push(unit_cube,'debug_cube')
    local aabb=ground:get_aabb()
    self.player:set_position(aabb.max+ground:get_position())
    local size = aabb.max-aabb.min
    local center = (aabb.max+aabb.min)/2
    unit_cube:set_scale(size/2)
    unit_cube:set_position(ground:get_position()+center)
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
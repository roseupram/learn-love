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
local UI=require('scene.UI')


local my_shader
local lg = love.graphics
local sc = Node{name="Rune_Raider"}
function sc:draw()
    lg.push('all')
    local bg_color = {.2,.3,.3}
    lg.clear(table.unpack(bg_color))
    lg.print(self.name..'\nFPS:'..love.timer.getFPS(),1,1)
    lg.setDepthMode('less',true)
    lg.setShader(my_shader)
    self.uniform_list:apply(my_shader)
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
            self.uniform_list:apply(child.shader)
        end
        if child.render then
            child:render()
        else
            child:draw()
        end
    end
    self.UI:draw()
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
    self.UI:update(dt)
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
    self.uniform_list:set('time',Time)
    self.uniform_list:set('VIEW','column',cam:view_mat():flat())
    self.uniform_list:set('PROJECT','column',cam:project_mat():flat())
    self.uniform_list:set('view_pos',cam:view_pos():table())
    if self.clicked and self.used_card.name == "move" then
        local times = FP.clamp(self.clicked,1,2)
        self.velocity_P=(times-1)*5+3
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
    local velocity = PT:normal()

    local scale = FP.sin(Time,.2,.5)
    self.circle:set_scale(Point(scale,1,scale))
    local dvdt = velocity * dt * self.velocity_P
    dvdt = dvdt * FP.clamp(distance, 0, 1)
    self.player:move(dvdt)
end

function sc:new()
    self.used_card={}
    self.UI=UI()
    self.UI.on_card_used=function (ui_ref,card)
        print(card and card.name or "nothing","used")
        self.used_card=card
    end
    self.UI.on_card_canceld=function (ui_ref,card)
        print(card and card.name or "nothing","cancel")
        self.used_card={}
    end
    local plt={
        red = Color(.9, .2, .2),
        cyan = Color(.1, .7, .9),
    }
    self.uniform_list=Shader.uniform_list()
    self.Time=0
    self.rotate_pivot=-1
    self.camera=Camera()
    lg.setDepthMode('less',true)
    lg.setMeshCullMode('back')
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
    self.velocity_P=1
    local enemy=Movable{image=lg.newImage("images/enemy.png")}
    enemy:set_position(Point(-2,0,-4))
    self:push(enemy,'enemy')
    my_shader=Shader.new('isometric','frag')
    local image= lg.newImage("images/player.png")
    self.player=Movable{image=image}
    self:push(self.player,"player")

    self.circle=Mesh.ring()
    self.circle:color_tone(plt.cyan:clone()-Color(0,0,0,.3))
    self:push(self.circle,"circle")
    local terrain=Mesh.glb{filename='model/base.glb'}
    self:push(terrain[1])
    local polygon=Mesh.polygon{points={
        {0,0,10},
        {10,0,0},
        {0,0,-10},
        {-10,0,0}
    }}
    polygon:color_tone{.2,.4,.4}
    self:push(polygon,'polygon')
end
function sc:mousepressed(x,y,button,is_touch,times)
    local stop=self.UI:mousepressed(x,y,button,is_touch,times)
    if stop then
        return
    end
    if button==1 then
        self.clicked=times
    end
end
function sc:resize(w,h)
    self.camera.wh_ratio=w/h
    self.UI:resize(w,h)
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
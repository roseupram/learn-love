-- require('lldebugger').start()
-- print(_VERSION)
local Event=require('event')
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
local UI=require('UI.hand_card')


local my_shader
local lg = love.graphics
local sc = Node{name="Combat"}
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
    for i,child in ipairs(self.children) do
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
        if child.shader then
            self.uniform_list:apply(child.shader)
        end
        if child.render then
            child:render()
        else
            child:draw()
        end
    end
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
    local move_range=-.03
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
    if self.used_card then
        local card=self.used_card
        local p, d = cam:ray(love.mouse.getPosition())
        local player_pos=self.player:get_position()
        local A = Point(0, .1, 0)     -- (A,n) is a plane
        local n = Point(0, 1, 0)
        local t = (p - A):dot(n) / (d:dot(n))
        local gp = p + d * -t
        self.circle:set_position(gp)

        if gp:distance(player_pos) <= self.used_card.range then
            self.target_pos = gp
            self.circle:color_tone{1,0,0}
        else
            self.target_pos = nil
            self.circle:color_tone { .5, .5, .5 }
        end
        if card.name=='attack' then
            local enemy=self:get('enemy')
            local tt= enemy:test_ray(p,d)
            local enemy_pos=enemy:get_position()
            if tt then
                if enemy_pos:distance(player_pos)<card.range then
                    self.circle:set_position(enemy_pos)
                    self.target_enemy = enemy
                    enemy:highlight()
                end
            else
                self.target_enemy=nil
                enemy:normal()
            end
        end
    end
    if self.mouse.release and self.mouse.button == 1 and self.used_card then
        local x,y=love.mouse.getPosition()
        local card=self.used_card
        if card.name=='move' then
            if self.target_pos then
                self.velocity_P = 10
                self.used_card = nil
                self:get('range_cirlce'):hide()
            end
        elseif card.name=='attack' then
            if self.target_enemy then
                self.target_enemy:hurt(card.damage)
                self.used_card = nil
                self.target_enemy=nil
                self:get('range_cirlce'):hide()
            end
        end
        if self.used_card==nil then
            Event.push('play_card',{index=self.used_card_i})
        end
        self.mouse.release=nil
    end

    if self.target_pos and self.velocity_P>0 then
        self.player:set_position(self.target_pos)
        self.target_pos=nil
        self.velocity_P=0
    end
end

function sc:new()
    self.children=Array()
    local plt={
        red = Color(.9, .2, .2),
        cyan = Color(.1, .7, .9),
        green=Color(.2,.8,.2)
    }
    self.uniform_list=Shader.uniform_list()
    self.Time=0
    self.rotate_pivot=-1
    self.camera=Camera()
    lg.setDepthMode('less',true)
    -- lg.setMeshCullMode('back')
    -- love.mouse.setRelativeMode(true)
    local w,h=lg.getDimensions()
    self.shadowmap_canvas=lg.newCanvas(w,h,{format="depth16",readable=true})
    love.mouse.setPosition(w/2,h/2)
    if love.config.Release then
        love.mouse.setVisible(false)
        love.mouse.setGrabbed(true)
    end
    self:resize(w,h)
    self.mouse={}
    self.target_pos=nil
    self.velocity_P=0
    local enemy=Movable{image=lg.newImage("images/enemy.png")}
    enemy:set_position(Point(-2,0,-4))
    self:push(enemy,'enemy')
    my_shader=Shader.new('isometric','frag')
    local image= lg.newImage("images/player.png")
    self.player=Movable{image=image}
    self.player:set_position{1,0,1}
    self:push(self.player,"player")

    local range_cirlce=Mesh.ring(.9)
    self:push(range_cirlce,"range_cirlce")
    self.circle=Mesh.circle()
    self.circle:color_tone(plt.red:clone())
    self.circle:set_scale{.2,.2,.2}
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
    polygon:set_position{0,-.1,0}
    self:push(polygon,'polygon')
    Event.bind('resize',function (e)
        self:resize(e.w,e.h)
    end)
    Event.bind('mouse',function (e)
        local button=e.button
        if e.wheel then
            self.camera:zoom(-e.y)
        elseif e.release then
            self.mouse.release=true
            self.mouse.button=button
        end
    end)
    Event.bind('select_card',function (e)
        local card = e.card
        print(card.name .. ' selected')
        self.used_card = card
        self.used_card_i = e.index
        local range_cirlce = self:get('range_cirlce')
        range_cirlce:set_scale { card.range, 1, card.range }
        range_cirlce:set_position(self.player:get_position() + Point(0, .05, 0))
        range_cirlce:show()
        self.velocity_P = 0
        self.target_pos = nil
    end)
    Event.bind("deselect_card",function (e)
        print(e.card and e.card.name or "nothing","cancel")
        self.used_card=nil
        self:get("range_cirlce"):hide()
    end)
    Event.bind('keyboard',function (e)
        local key=e.key
        if key=='escape' then
            love.event.quit(0)
        elseif key=='f5' then
            love.event.quit('restart')
        elseif key=='lalt' then
            if e.down then
                local x, y = love.mouse.getPosition()
                self.rotate_pivot = x
                self.y_base = self.camera.y_rot
            elseif e.release then
                self.rotate_pivot = -1
            end
        end
    end)
end
function sc:mousereleased(x,y,button,is_touch,times)
    local stop=self.UI:mousereleased(x,y,button,is_touch,times)
    if button==1 then
        self.release_clicked=times
    end
end
function sc:resize(w,h)
    self.camera.wh_ratio=w/h
end

return sc
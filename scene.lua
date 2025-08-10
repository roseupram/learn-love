local Vec=require('vec')
local Color=require('color')
local pen=require("pen")
local palette={
    cyan=Color(.2,.7,.9)
}
---@class sc1:Scene
local sc1=pen.Scene{name="sc1"}
function sc1:new(t)
    sc1.super(self,t)
    local bg_color=Color(.77,.7,.65)
    local bg = pen.Rect{x=0,y=0,width=100,height=100,color=bg_color}
    self:push(bg)
    local player = pen.Image{path="images/player.png",height=20,x=50,y=48,wh_ratio=1,anchor=Vec(50,90)}
    local enemy = pen.Image{path="images/enemy.png",height=20,x=80,y=20,wh_ratio=1}

    local arrow_altas=pen.Altas{path="images/arrows.png",grid_size=64}

    local hbox=pen.Hbox{x=50,y=60,width=20,height=10,anchor=Vec(0,50)}
    hbox.color = palette.cyan:clone()
    -- TODO repeat texture uv, pingpong mode
    local head= arrow_altas:get_mesh{bound={0,0,2,2}}
    local tail = arrow_altas:get_mesh{bound={0,0,.01,2}}
    head:wh(nil,100)
    tail:wh(0,100)
    tail.expand=1
    
    hbox:push(tail)
    hbox:push(head)
    hbox.rotate=.2


    self:push(enemy,"enemy")
    self:push(hbox,'hbox')
    self:push(player,"player")
    local botttom_bar = pen.Scene{x=30,y=80,bottom=100,width=40,name="bottom bar"}
    self:push(botttom_bar,"bottom_bar")
    local button  =pen.Button{x=4,y=0,height=100,wh_ratio=2/3} 
    self.button = button

    botttom_bar:push(pen.Rect{color=Color(.8,.4,.6)})
    botttom_bar:push(self.button)

    local img = pen.Image{path="images/attack.png",width=100,wh_ratio=1}
    local rect1 = pen.Rect{color=Color(.2,.2,.4),width=100,wh_ratio=1}
    local text = pen.Text{text="Punch\n(A)",y=2*100/3,color=rect1.color:clone()}
    local rect = pen.Rect{color=Color(.4,.4,.8),y=text.y,bottom=100}
    self.button:push(rect1,"bg")
    self.button:push(rect)
    self.button:push(img,"img")
    self.button:push(text,"text")
    button.on_hover={
        { '$bg.color.g',   .6 },
        { '$text.color.g', .99 },
    }

    local mesh_vertices ={
        {100,100,0,0,1,0,0},
        {200,100,1,0,1,0,0},
        {200,200,1,1,1,0,0},
        {100,200,0,1,1,0,0},
    }
    self.time=0
    self.mesh=love.graphics.newMesh(mesh_vertices)
    self.mesh:setVertexMap({1,3,2,1,4,3})
    self.shader=love.graphics.newShader([[
        uniform float time;
        vec4 position(mat4 transform,vec4 vertex_position){
            return transform*(vertex_position+10*vec4(sin(2*time),cos(time),0,0));
        }
        vec4 effect(vec4 base_color,Image tex,vec2 texture_coords,vec2 screen_coords){
            return vec4(texture_coords,0,1);
        }
    ]])
    local rate=44100
    local hz=440
    local sound_data=love.sound.newSoundData(1*rate,rate)
    local p =math.floor(rate/hz)
    for i=0,sound_data:getSampleCount()-1 do
        -- sound_data:setSample(i,math.sin(i*2*math.pi*hz/rate))
        sound_data:setSample(i,i%p<p/2 and 1 or -1)
    end
    self.music = love.audio.newSource(sound_data)
    sound_data:release()
    self.music:setLooping(true)
    print("volume",self.music:getVolume())
    self.music:setVolume(.1)
    self.bezier = love.math.newBezierCurve({100,100,184,100,230,200,100,240,
    100,130,100,100
})
    local canvas = love.graphics.newCanvas(20,20)
    love.graphics.setCanvas(canvas)
    love.graphics.rectangle('fill',5,0,10,20)
    love.graphics.circle('fill',10,10,8)
    love.graphics.setCanvas()
    self.canvas=canvas
    -- use draw instance to make particle
    local psystem = love.graphics.newParticleSystem(canvas,32)
    psystem:setParticleLifetime(2,6)
    psystem:setEmissionRate(30)
    psystem:setSizeVariation(.3)
    psystem:setSpin(-1,1)
    psystem:setSpeed(0,20)
    psystem:setDirection(-1.5)
    psystem:setSizes(.5,1,1.2,.6,.0)
    psystem:setLinearAcceleration(0,-5,0,0)
    psystem:setInsertMode('random')
    psystem:setEmissionArea('normal',10,2)
    psystem:setRadialAcceleration(-1,1)
    psystem:setColors(1, .6, .2, .7,
        1, 0, 0, .2)
    self.psystem=psystem
    -- self.music:play()
end
function sc1:draw()
    local x, y, w, h =self:xywh()
    love.graphics.push('all')
    -- love.graphics.translate(0,5*math.sin(10*self.time))
    love.graphics.print(string.format("FPS: %i",love.timer.getFPS()), 10, 10)
    for i,child in ipairs(self.children) do
        if(child.draw) then
            child:draw()
        end
    end
    love.graphics.setShader(self.shader)
    love.graphics.draw(self.mesh)
    love.graphics.setShader()

    love.graphics.draw(self.psystem,w/5,h/2)

    local bx,by= self.bezier:evaluate(self.time%1)
    love.graphics.line(self.bezier:render())
    love.graphics.circle('fill',bx,by,4)
    love.graphics.pop()
end
function sc1:update(dt)
    self.time = self.time + dt
    local hbox=self:get('hbox')
    self.psystem:moveTo(5*math.sin(10*self.time),0)
    self.psystem:update(dt)
    local inside_pos = self:mouse_in()
    local w,h=self:wh()

    local player =self:get('player')
    local px,py=player:xy()
    local target
    local base = Vec(px, py)
    if inside_pos then
        target=inside_pos+Vec(self:xy())
        local max_len = .2*w
        local direction =target - base
        if direction:len() > max_len then
            target =base + direction:normal() * max_len
        end
        hbox.rotate=math.atan2(direction.y,direction.x)
        hbox:set_size((target-base):len(),nil)
    end
    if self.cmd and target then
        self.cmd = false
        player:global(target.x,target.y)
    end

    hbox:global(px,py)
    
    local button_bg = self.button:get('bg')
    if not self.punch then
        self.button:style()
        hbox.hidden=true
    end
    if target and self.punch then
        player.scale.x=(target-base).x>=0 and 1 or -1
        self.button:style('hover')
        hbox.hidden=false
    end

   self.shader:send("time",self.time)
end
function sc1:keypressed(key)

    if key=='a' and self:mouse_in() then
        self.punch=true
    end
end
function sc1:mousepressed(x,y,button,istouch,times)
    if not self:mouse_in() then
        return
    end
    if button==2 then
        self.punch=false
    end
    if button==1 and self.punch then
        self.cmd=true
        self.punch=false
    end
end
return sc1
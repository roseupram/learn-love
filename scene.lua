local prototype=require('prototype')
local Vec=require('vec')
local Color=require('color')
local sprite = require('sprite')
local pen=require("pen")
local sc1=pen.Scene()
function sc1:new(t)
    sc1.super(self,t)
    local x,y,w,h=self:get_xywh()
    self.player = sprite{img_path = "images/player.png",width=w*.2,center=Vec(30,20)}
    self.enemy = sprite{img_path="images/enemy.png",width=w*.2,center=Vec(60,40)}
    self:push(self.enemy)
    self:push(self.player)
    local botttom_bar = pen.Scene{x=0,y=80,height=20,width=100}
    botttom_bar.debug=true
    botttom_bar.name="bottom bar"
    self:push(botttom_bar)
    self.button = pen.Button{x=10,y=0,height=100,wh_ratio=2/3}
    botttom_bar:push(self.button)

    local img = pen.Image{path="images/attack.png",width=100,wh_ratio=1}
    local text = pen.Text{text="Punch\n(A)",y=2*100/3}
    local rect1 = pen.Rect{color=Color(.2,.2,.4),width=100,wh_ratio=1}
    local rect = pen.Rect{color=Color(.4,.4,.8),y=text.y}
    self.button.image = img
    self.button.text=text
    self.button:push(rect1)
    self.button:push(rect)
    self.button:push(img)
    self.button:push(text)
    self.button.color={1,1,1}
    self.button.draw=function (self)
        local x,y,w,h=self:get_xywh()
        love.graphics.push('all')
        love.graphics.translate(x,y)
        -- love.graphics.setShader(self.shader)
        love.graphics.setColor(table.unpack(self.color))
        love.graphics.rectangle("line",0,0,w,h)
        love.graphics.setColor(1,1,1)
        for i,child in ipairs(self.children) do
            child:draw()
        end
        love.graphics.pop()
    end
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
    love.graphics.rectangle('fill',0,0,20,20)
    love.graphics.setCanvas()
    self.canvas=canvas
    local psystem = love.graphics.newParticleSystem(canvas,128)
    psystem:setParticleLifetime(2,5)
    psystem:setEmissionRate(20)
    psystem:setSizeVariation(1)
    psystem:setSpin(-1,1)
    psystem:setSpeed(10,30)
    psystem:setDirection(-1.5)
    psystem:setSizes(1,0)
    psystem:setLinearAcceleration(-10,-2,10,0)
    psystem:setColors(1,1,.2,1,1,1,1,0)
    self.psystem=psystem
    -- self.music:play()
end
function sc1:draw()
    love.graphics.push('all')
    local Width,Height= love.graphics.getDimensions()
    local x, y, w, h =self:get_xywh()
    local to_screen = Vec(w,h)/100
    love.graphics.setColor(1,.2,.4)
    love.graphics.rectangle('fill', x,y,w,h)
    love.graphics.pop()

    love.graphics.push('all')
    love.graphics.translate(x,y)
    love.graphics.print(string.format("FPS: %i",love.timer.getFPS()), 10, 10)
    love.graphics.stencil(function ()
        love.graphics.rectangle('fill', 0, 0, w, h)
    end,"replace",1)
    love.graphics.setStencilTest("greater",0)
    for i,child in ipairs(self.children) do
        if(child.draw) then
            local normal_center=child.center
            child.center=child.center*to_screen
            child:draw()
            child.center=normal_center
        end
    end
    love.graphics.setShader(self.shader)
    love.graphics.draw(self.mesh)
    love.graphics.setShader()

    love.graphics.draw(self.psystem,w/2,h/2)   

    local bx,by= self.bezier:evaluate(self.time%1)
    love.graphics.line(self.bezier:render())
    love.graphics.circle('fill',bx,by,4)
    love.graphics.setStencilTest()
    love.graphics.pop()
end
function sc1:update(dt)
    self.psystem:update(dt)
    local inside_pos = self:mouse_in()
   if inside_pos and love.mouse.isDown(1) then
   end
   if(self.button:mouse_in()) then
    self.button.color[3]=.4
   else
    self.button.color[3]=1
   end
   self.time=self.time+dt
   self.shader:send("time",self.time)
end
return sc1
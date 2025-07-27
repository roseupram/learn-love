---@diagnostic disable: param-type-mismatch, undefined-global, lowercase-global
-- draw everything
-- normal coordinate [-1,1]
-- manage drawing, coloring, font
local prototype=require('prototype')
local Color=require('color')
local Vec=require('vec')
local Pen={}
local Fonts={}
local Imgs={}
local Sounds={}

---@class Scene
---@field super function
local scene = prototype { name = "scene", x = 0, y = 0, width = 100, height = 100,wh_ratio=1 }
function scene:new(x,y,w,h,wh_ratio)
    if type(x)=="table" then
        self.x=x.x
        self.y=x.y
        self.width=x.width
        self.height=x.height
        self.wh_ratio=x.wh_ratio
        self.name=x.name
        self:merge(x)
    else
        self.x = x
        self.y = y
        self.width = w
        self.height = h
        self.wh_ratio=wh_ratio
    end
    self.center=Vec(self.x,self.y)
    x,y,w,h=self:get_xywh()
    self.children={}
    self.debug=false
end
---return x,y,w,h in parent space
---@return number
---@return number
---@return number
---@return number
function scene:get_xywh(is_global)
    ---TODO make it in global space
    local Width,Height
    if self.parent then
        _,_,Width, Height = self.parent:get_xywh()
    else
        Width, Height = love.graphics.getDimensions()
    end
    local x, y, w, h = self.x / 100 * Width, self.y / 100 * Height, self.width / 100 * Width, self.height / 100 * Height
    if rawget(self,'wh_ratio') then
        if not rawget(self, 'height') then
            h = w / self.wh_ratio
        elseif not rawget(self, 'width') then
            w = h * self.wh_ratio
        end
    end
    return x,y,w,h
end
function scene:push(child)
    table.insert(self.children,child)
    child.parent=self
end
---return normal pos if mouse_in
---@return Vec2|nil relative to self leftup in percentage
function scene:mouse_in()
    local x, y = love.mouse.getPosition()
    local px, py = 0, 0
    if self.parent then
        local inside = self.parent:mouse_in()
        if not inside then
            return nil
        end
        -- print("inside parent",self.parent.name,love.timer.getTime())
        px,py,pw,ph=self.parent:get_xywh()
        x, y = (inside * Vec(pw, ph)/100):unpack() -- relative to parent leftup
    end
    local ox, oy, w, h = self:get_xywh()           --relative to parent leftup
    x, y = x - ox , y - oy
    local inside = x > 0 and x < w and y > 0 and y < h
    if (inside) then
        return Vec(x, y)/Vec(w,h)*100
    end
end
function scene:draw()
    love.graphics.push('all')
    local x, y, w, h =self:get_xywh()
    if self.debug then
        love.graphics.rectangle('line', x, y, w, h)
    end
    local to_screen = Vec(w,h)/100
    love.graphics.translate(x,y)
    for i,child in ipairs(self.children) do
        if(child.draw) then
            local normal_center=child.center
            child.center=child.center*to_screen
            child:draw()
            child.center=normal_center
        end
    end
    love.graphics.pop()
end
Pen.Scene=scene

---@class Button:Scene  
local Button=scene{name="Button"}
function Button:new(ops)
    Button.super(self,ops)
end
Pen.Button=Button

---@class Image:Scene
local Image=scene{name="Image"}
function Image:new(ops)
    Image.super(self,ops)
    self.image=Pen.get_img(ops.path)
end
function Image:draw()
    local x,y,w,h=self:get_xywh()
    local scale_w=w/self.image:getWidth()
    local scale_h=h/self.image:getHeight()
    love.graphics.draw(self.image,x,y,0,scale_w,scale_h)
end
Pen.Image=Image

---@class Text:Scene
---@field text string
local Text=scene{name="Text",size=18}
function Text:new(ops)
    Text.super(self,ops)
    self.size=ops.size
    local font = Pen.get_font(self.size)
    self.content=ops.text
    self.text=love.graphics.newText(font,ops.text)
end
function Text:draw()
    local x,y,w,h=self:get_xywh()
    self.text:setf(self.content,w,'center')
    love.graphics.draw(self.text,x,y)
end
Pen.Text=Text

---@class Rect:Scene
local Rect=scene{name="Rect",color=Color(1,1,1)}
function Rect:new(ops)
    Rect.super(self,ops)
    self.color=ops.color and ops.color:clone()
end
function Rect:draw()
    local x,y,w,h=self:get_xywh()
    love.graphics.push('all')
    love.graphics.setColor(self.color:unpack())
    love.graphics.rectangle('fill',x,y,w,h)
    love.graphics.pop()
end
Pen.Rect=Rect

function Pen.bezier(bezier)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(4)
    love.graphics.line(bezier:render())
end
function Pen.draw_element(config)
    if not config then
        return
    end

    if config.element.draw then
        config.element:draw(config)
        return
    end

    if config.border_radius then
        Pen.round_rect(config)
    else
        Pen.rect(config)
    end
    if config.img then
       Pen.img(config) 
    end
    if config.text then
        Pen.text(config)
    end
end
---comment
---@param config table {border,border_radius,x,y,width,height}
function Pen.round_rect(config)
    local deg90=math.pi/2
    local env={love=love,_G=_G,math=math}
    table.update(env,config)
    setfenv(1,env)
    local border_radius=math.min(border_radius,height/2,width/2)
    love.graphics.setColor(color:table())
    --[[
            270
            |
            |
    180 ----------> 0
            |     x
            | y
            v 
            90
    --]]
    if bg then
        local mode='fill'
        local arc_type='pie'
        love.graphics.setColor(bg:table())
        local tx,ty=x+border_radius,y+border_radius
        love.graphics.arc(mode,arc_type,tx,ty,border_radius,2*deg90,3*deg90)
        tx=x+width-border_radius
        love.graphics.arc(mode,arc_type,tx,ty,border_radius,3*deg90,4*deg90)
        tx,ty=x+width-border_radius,y+height-border_radius
        love.graphics.arc(mode,arc_type,tx,ty,border_radius,0*deg90,1*deg90)
        tx=x+border_radius
        love.graphics.arc(mode,arc_type,tx,ty,border_radius,1*deg90,2*deg90)
        love.graphics.rectangle(mode,x+border_radius,y,width-2*border_radius,height)
        love.graphics.rectangle(mode,x,y+border_radius,width,height-2*border_radius)
    end
    if border_width then
        local mode='line'
        local arc_type='open'
        local segment=border
        love.graphics.setColor(border_color:table())
        local lw=love.graphics.getLineWidth()
        love.graphics.setLineWidth(border_width)
        local tx,ty=x+border_radius,y+border_radius
        love.graphics.arc(mode,arc_type,tx,ty,border_radius,2*deg90,3*deg90,segment)
        love.graphics.line(x+border_radius,y,x+width-border_radius,y)
        tx=x+width-border_radius
        love.graphics.arc(mode,arc_type,tx,ty,border_radius,3*deg90,4*deg90,segment)
        love.graphics.line(x+width,y+border_radius,x+width,y+height-border_radius)
        tx,ty=x+width-border_radius,y+height-border_radius
        love.graphics.arc(mode,arc_type,tx,ty,border_radius,0*deg90,1*deg90,segment)
        love.graphics.line(x+width-border_radius,y+height,x+border_radius,y+height)
        tx=x+border_radius
        love.graphics.arc(mode,arc_type,tx,ty,border_radius,1*deg90,2*deg90,segment)
        love.graphics.line(x,y+height-border_radius,x,y+border_radius)
        love.graphics.setLineWidth(lw)
    end
    _G.setfenv(1,_G)
end
---comment
---@param config table {mode,x,y,w,h,color}
function Pen.rect(config)
    local env={love=love,_G=_G}
    table.update(env,config)
    setfenv(1,env)
    local x,y=offset:unpack()
    if border_width then
        local lw=love.graphics.getLineWidth()
        love.graphics.setLineWidth(border_width)
        love.graphics.setColor(border_color:table())
        love.graphics.rectangle('line',x,y,width,height)
        love.graphics.setLineWidth(lw)
    end
    if bg then
        love.graphics.setColor(bg:table())
        love.graphics.rectangle('fill',x,y,width,height)
    end
    _G.setfenv(1,_G)
end
---comment
---@param config table {text,offset,width,align,color,size}
function Pen.text(config)
    local env = { love = love, _G = _G}
    table.update(env,config)
    setfenv(1,env)
    local font=Pen.get_font(size or 30)
    local limit=width or font:getWidth(text)
    local x,y=offset:unpack()
    if padding then
        x=x+padding[2]
        y=y+padding[1]
        limit=limit-padding[2]*2
    end
    love.graphics.setFont(font)
    color=color or Color()
    love.graphics.setColor(color:table())
    scale=scale or 1
    ---text,x,y,limit,align, rotate,scale_x,scale_y,offset_x,offset_y, shearing
    love.graphics.printf(text,x,y,limit,align or 'center',0,scale,scale,0,0)
    _G.setfenv(1,_G)
end
function Pen.img(config)
    local env = { love = love, _G = _G}
    table.update(env,config)
    setfenv(1,env)
    local img=Pen.get_img(img)
    local x,y=offset:unpack()
    love.graphics.setColor(color:table())
    local w,h=img:getWidth(),img:getHeight()
    local scale=width/w
    -- scale=1
    love.graphics.draw(img,x,y,0,scale,scale)
    ---text,x,y,limit,align, rotate,scale_x,scale_y,offset_x,offset_y, shearing
    -- love.graphics.printf(text,x,y,limit,align,0,1,1,0,0)
    _G.setfenv(1,_G)
end
function Pen.get_font(size)
    if not Fonts[size] then
        Fonts[size]=love.graphics.newFont(size)
    end
    return Fonts[size]
end
function Pen.get_img(img_path)
    if not Imgs[img_path] then
        local img=love.graphics.newImage(img_path,{
            -- mipmaps=true
        })
        Imgs[img_path]=img
        -- Imgs[img_path]:setFilter('nearest','nearest',8)
    end
    return Imgs[img_path]
    
end
function Pen.get_sound(sound_path,type_)
    if not Sounds[sound_path] then
        if not io.open(sound_path) then
            error(sound_path..' not exist. ')
        end
        local sound=love.audio.newSource(sound_path,type_ or 'static')
        Sounds[sound_path]=sound
    end
    return Sounds[sound_path]
end
return Pen
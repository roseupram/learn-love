---@diagnostic disable: param-type-mismatch, undefined-global, lowercase-global
-- draw everything
-- normal coordinate [-1,1]
-- manage drawing, coloring, font
local prototype=require('prototype')
local Color=require('color')
local Array=require('array')
local Vec2=require('vec')
local Pen={}
local Fonts={}
local Imgs={}
local Sounds={}

---@class Scene
---@field super function
---@field merge function    
---@field parent Scene|nil
---@field anchor Vec2
---@field scale Vec2
---@field rotate number
---@field bottom number
---@field color Color|"inherit"
---@field hidden boolean
---@overload fun(...):Scene|any
local scene = prototype { name = "scene", x = 0, y = 0, width = 100, height = 100, wh_ratio = 1,
    anchor = Vec2(0, 0),rotate=0, hidden=false}
function scene:new(x,y,w,h,wh_ratio)
    if type(x)=="table" then
        self.x=x.x
        self.y=x.y
        self.width=x.width
        self.height=x.height
        self.wh_ratio=x.wh_ratio
        self.name=x.name
        self.color=x.color or Color(1,1,1)
        self.scale = x.scale or Vec2(1,1)
        self:merge(x)
    else
        self.x = x
        self.y = y
        self.width = w
        self.height = h
        self.wh_ratio=wh_ratio
    end
    x,y,w,h=self:xywh()
    self.children={}
    self.debug=false
    self._edited=Array()
end
--- set xywh in percentage    
--- or return x,y,w,h in screen space
--- @return any
--- @return any
--- @return any
--- @return any
function scene:xywh(x,y,w,h)
    if x or y or w or h then
        self:xy(x,y)
        self:wh(w,h)
        return
    end
    x, y = self:xy()
    w,h=self:wh()
    return x,y,w,h
end
--- set in percentage  
--- or return in screen space
---@param x any
---@param y any
function scene:xy(x,y)
    if x or y then
        self.x=x or rawget(self,'x')
        self.y=y or rawget(self,'y')
        return
    end
    local px,py=0,0
    local Width,Height
    if self.parent then
        px,py,Width, Height = self.parent:xywh()
    else
        Width, Height = love.graphics.getDimensions()
    end
    x, y = self.x / 100 * Width, self.y / 100 * Height
    return x+px,y+py
end
--- set in percentage  
--- or return in screen space
---@param w any
---@param h any
function scene:wh(w,h)
    if w or h then
        self.width=w or rawget(self,'width')
        self.height=h or rawget(self,'height')
        return
    end
    local Width,Height
    if self.parent then
        _,_,Width, Height = self.parent:xywh()
    else
        Width, Height = love.graphics.getDimensions()
    end
    if self.bottom then
        self.height=self.bottom-self.y
    end
    w, h = self.width / 100 * Width, self.height / 100 * Height
    if rawget(self,'wh_ratio') then
        if not rawget(self, 'height') then
            h = w / self.wh_ratio
        elseif not rawget(self, 'width') then
            w = h * self.wh_ratio
        end
    end
    return w,h
end

---set in screen space
---@param w any
---@param h any
function scene:set_size(w,h)
    if self.parent then
        local pw, ph = self.parent:wh()
        self:wh(w and w/pw*100,h and h/ph*100)
    end
end
--- set in screen space 
--- or return in screen space
function scene:global(x,y)
    if x==nil then
        return self:xy()
    end
    local w, h
    if self.parent then
        local local_xy=Vec2(x,y)-Vec2(self.parent:xy())
        x,y=local_xy:unpack()
        w, h = self.parent:wh()
    else
        w, h = love.graphics.getDimensions()
    end
    self.x = x / w * 100
    self.y = y / h * 100
end
--- add to .children
---@param child Scene
---@param name string|nil
function scene:push(child,name)
    assert(child,"child can not be nil")
    table.insert(self.children,child)
    if(name)then
        if self.children[name] then
            error("repeat name of child")
        end
        self.children[name] = child
    end
    child.parent=self
end
---get child by name
---@param child_name string 
---@return Scene|any
function scene:get(child_name)
    assert(self.children[child_name],string.format("no child is %s",child_name))
    return self.children[child_name]
end
---scene.on_name ={ '$child.prop.prop', value}
---@param name string |nil nil to reset
function scene:style(name)
    if name==nil then
        self._style=""
        self._edited:each(function (v,i,arr)
            local t,prop,value=table.unpack(v)
            t[prop]=value
        end)
        self._edited:clear()
        return
    end
    if self._style==name then
        return
    end
    local full_name = 'on_'.. name
    assert(self[full_name],string.format("No style is %s",name))
    self._style=name
    for i,t in ipairs(self[full_name]) do
        local key, value = table.unpack(t)
        local target=self
        for n in key:gmatch("([$%a]+)%.") do
            -- child or property
            target=n:find("%$")==1 and target:get(n:sub(2)) or target[n]
            assert(target,string.format("In %s,  %s not exists!",key,n))
        end
        local prop =key:match("(%a+)$")
        local old_value=target[prop]
        target[prop]=value
        self._edited:push({target,prop,old_value})
    end
end
function scene:before_draw()
    love.graphics.push('all')
    if(self.color ~= 'inherit') then
        love.graphics.setColor(self.color:table())
    end
end
function scene:after_draw()
    love.graphics.pop()
end
---return pos in screen space if mouse_in
---@return Vec2|nil relative to self leftup in screen space
function scene:mouse_in()
    local x, y ,w,h= self:xywh()
    local mouse_pos= Vec2(love.mouse.getPosition())
    x, y = mouse_pos.x - x , mouse_pos.y - y
    local inside = x > 0 and x < w and y > 0 and y < h
    if (inside) then
        return Vec2(x, y)
    end
end
function scene:render()
    if self.hidden then
        return
    end
    self:before_draw()
    self:draw()
    self:after_draw()
end
function scene:draw()
    local x, y, w, h =self:xywh()
    if self.debug then
        love.graphics.rectangle('line', x, y, w, h)
    end
    for i,child in ipairs(self.children) do
        if(child.draw) then
            child:render()
        end
    end
end
function scene:keypressed() end
function scene:mousepressed() end
Pen.Scene=scene

---@class Button:Scene  
---@field shortcut string
---@overload fun(...):Button
local Button=scene{name="Button",shortcut="undefined"}
function Button:new(ops)
    Button.super(self,ops)
end
Pen.Button=Button

---@class Image:Scene
local Image=scene{name="Image",anchor=Vec2(0,0)}
function Image:new(ops)
    Image.super(self,ops)
    self.image=Pen.get_img(ops.path)
    self.shader = love.graphics.newShader("shader/outline.glsl")
    self.outline=0
end
function Image:draw()
    self:before_draw()
    local x,y,w,h=self:xywh()
    local img_size = Vec2(self.image:getWidth(),self.image:getHeight())
    local scale=self.scale*Vec2(w,h)/img_size
    local origin = self.anchor*img_size/100
    self.shader:send('lw',self.outline/w)
    love.graphics.setShader(self.shader)
    love.graphics.draw(self.image,x,y,0,scale.x,scale.y,origin.x,origin.y)
    love.graphics.setShader()
    self:after_draw()
end
Pen.Image=Image

---@class Text:Scene
local Text=scene{name="Text",size=18}
function Text:new(ops)
    Text.super(self,ops)
    self.size=ops.size
    local font = Pen.get_font(self.size)
    self.content=ops.text
    self.text=love.graphics.newText(font,ops.text)
end
function Text:draw()
    self:before_draw()
    local x,y,w,h=self:xywh()
    self.text:setf(self.content,w,'center')
    love.graphics.draw(self.text,x,y)
    self:after_draw()
end
Pen.Text=Text

---@class Rect:Scene
local Rect=scene{name="Rect",color=Color(1,1,1),
    x = 0, y = 0, width = 100, height = 100 }
function Rect:new(ops)
    Rect.super(self,ops)
    self.color=ops.color and ops.color:clone()
end
function Rect:draw()
    local x,y,w,h=self:xywh()
    love.graphics.push('all')
    love.graphics.setColor(self.color:unpack())
    love.graphics.rectangle('fill',x,y,w,h)
    love.graphics.pop()
end
Pen.Rect=Rect
---@class Line:Scene
local Line=scene{name="Line",points={},width=4,color=Color(1,1,1)}
function Line:new(ops)
    Line.super(self,ops)
    self.points=ops.points --{x,y,x,y}
    self.color=ops.color
end
function Line:draw()
    love.graphics.push('all')
    love.graphics.setLineWidth(self.width)
    love.graphics.setColor(self.color:unpack())
    local points=self.points
    if(#points==0) then
        error("no points")
    elseif (#points%2==1) then
        error("wrong points size")
    end
    love.graphics.line(points)
    love.graphics.pop()
end
Pen.Line=Line
---@class Mesh:Scene
---@field vertex table
---@field mode 'fan'|'triangles'
---@field usage 'dynamic'|'static'|'stream'
---@field vertex_map table
---@field rotate number
local Mesh = scene { name = "Mesh",
    mode = 'fan', usage = 'dynamic', vertex = {}, vertex_map = {},
    anchor = Vec2(0, 0), rotate = 0 }
function Mesh:new(ops)
    Mesh.super(self,ops)
    self.mesh=love.graphics.newMesh(self.vertex,self.mode,self.usage)
    if self.mode=='triangles' and self.vertex_map then
        self.mesh:setVertexMap(self.vertex_map)
    end
    if ops.texture then
        self.mesh:setTexture(ops.texture)
    end
    self.color= ops.color or 'inherit'
end
function Mesh:draw()
    local x,y,w,h=self:xywh()
    local o =self.anchor/100
    love.graphics.draw(self.mesh,x,y,self.rotate,w,h,o.x,o.y)
end
Pen.Mesh=Mesh

---@class Atlas:Scene
---@overload fun(...):Atlas
local Atlas=scene{name="Atlas",grid_size=1}
function Atlas:new(ops)
    Atlas.super(self,ops)
    self.grid_size = ops.grid_size
    self.image=Pen.get_img(ops.path)
end
--- bound: [leftupx, leftupy, rightdownx, rightdowny]
---@param ops {bound:[number,number,number,number]}
function Atlas:get_mesh(ops)
    local lux,luy,rdx,rdy=table.unpack(ops.bound)
    local unit = Vec2(self.image:getDimensions()):invert() * self.grid_size
    local leftup = Vec2(lux,luy) * unit
    local rightdown = Vec2(rdx,rdy)*unit
    local size= rightdown-leftup
    local x,y=leftup:unpack()
    local w,h=size:unpack()
    local vertice = {
        { 0, 0, x,     y },
        { 1, 0, x + w, y },
        { 1, 1, x + w, y+h },
        { 0, 1, x,     y + h },
    }      --{ {x,y,u,v,r,g,b}... }
    local mesh=Pen.Mesh{vertex=vertice,mode='fan',texture=self.image}
    mesh.wh_ratio=math.abs(w/h)
    return mesh
end
Pen.Altas=Atlas


---@class Hbox:Scene
---@overload fun(...):Hbox
local Hbox=scene{name="Hbox"}
function Hbox:new(ops)
    Hbox.super(self,ops)
end
function Hbox:draw()
    if self.hidden then
        return
    end
    local w,h=self:wh()
    local widths=Array()
    local expand_child=Array()
    local expand_t=0
    local total_width=0
    for i,child in ipairs(self.children) do
        local cw,ch=child:wh()
        widths:push(cw)
        if child.expand then
            expand_child:push(child)
            expand_t=expand_t+child.expand
        else
            total_width = total_width + cw
        end
    end
    local space_to_expand=w-total_width
    if space_to_expand>0  then
        for i,child in ipairs(expand_child) do
            local dw=child.expand/expand_t*space_to_expand
            child.width=dw/w*100
        end
    end
    local x,y=0,0
    local offset=self.anchor*Vec2(w,h)/100
    local tl=Vec2(self:xy())
    -- love.graphics.push('all')
    love.graphics.translate(tl:unpack()) -- set rotate pivot
    love.graphics.rotate(self.rotate)
    love.graphics.translate((-tl-offset):unpack()) --back, (x,y) is pivot, not leftup 
    -- love.graphics.setColor(self.color:table())
    for i,child in ipairs(self.children) do
        child.x=x
        child.y=y
        child:render()
        local cw,ch = child:wh()
        x=x+cw/w*100
    end
    -- love.graphics.pop()
end
Pen.Hbox=Hbox

---@class Ring:Scene
---@field range number
local Ring=Pen.Scene{name="Circle",range=math.pi*2}
function Ring:new(ops)
    Ring.super(self,ops)
    self.inner_radius=ops.inner_radius
end
function Ring:draw()
    self:before_draw()
    local x,y,w,h=self:xywh()
    love.graphics.translate(x,y) -- move origin 
    love.graphics.scale(self.scale:unpack())
    love.graphics.translate(-x,-y) -- restore
    local radius= w/2
    love.graphics.stencil(function ()
        love.graphics.circle('fill',x,y,self.inner_radius*radius/100)
    end,'replace',1)
    love.graphics.setStencilTest('equal',0)
    love.graphics.arc('fill', x, y, radius,
        self.rotate, self.rotate + self.range)
    love.graphics.setStencilTest()
    self:after_draw()
end
Pen.Ring=Ring

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
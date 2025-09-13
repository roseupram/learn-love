local ptt=require('prototype')
local path=(...):gsub("[^.]+$","") -- remove last name
local Point=require(path..'point')
---@class Mat4:prototype
local mat=ptt{name="Mat4"}
function mat.identity()
    return mat{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1}
end
function mat.rotate_mat(x,y,z)
    local sin,cos=math.sin,math.cos
    local sx,cx = sin(x),cos(x)
    local sy,cy = sin(y),cos(y)
    local sz,cz = sin(z),cos(z)
    return mat{
        cy*cz+sz*sx*sy, -sz*cy+cz*sx*sy,sy*cx,0,
        sz*cx,          cz*cx,          -sx,0,
        -sy*cz+sz*sx*sy,sz*sy+cz*sx*cy, cx*cy,0,
        0,0,0,1,
    }
end
---comment
---@param m Mat4 | Point
function mat:__mul(m)
    assert(m.is,"wrong type of param")
    local res
    if m:is(mat) then
        res=self:map(function (v,r,c,mat_ref)
            local n=0
            for i=1,4 do
                n=n+mat_ref[r][i]*m[i][c]-- left_row * right_column
            end
            return n
        end)
    elseif m:is(Point) then
        res=Point()
        for i=1,3 do
            local row=Point(self[i][1],self[i][2],self[i][3])
            res[res.keys[i]]=m:dot(row)+self[i][4]
        end
    else
         error("wrong type of param")
    end
    return res
end

---f(value, row, column, self)
---@param f function
function mat:each(f)
    for i=1,4 do
        for j=1,4 do
            f(self[i][j],i,j,self)
        end
    end
end
---m[r][c] = f(value, row, column, self)
---@param f function
function mat:map(f)
    local m=mat.identity()
    self:each(function (v,i,j)
        m[i][j]=f(v,i,j,self)
    end)
    return m
end

function mat:__tostring()
    local data_s=""
    for i = 1,4 do
        local row=""
        for j = 1,4 do
            row=row..string.format("%.2f, ",self[i][j])
        end
        data_s=string.format("%s  %s\n",data_s,row)
    end
    return string.format("%s(\n%s)",self.name,data_s)
end
function mat:new(t)
    t = t or {
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        0,0,0,1,
    }
    for i,v in ipairs(t) do
        i=i-1
        local row,column=math.floor(i/4)+1,i%4+1
        if(column==1) then
            self[row]={}
        end
        self[row][column]=v
    end
end
return mat
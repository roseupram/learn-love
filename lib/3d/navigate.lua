local Point=require('3d.point')
local FP=require('FP')
local Face=require('3d.face')
---@alias Polygon Point[][]
local Navigate={}
function Navigate.poly_diff(poly,d)
    --- if d is a hole inside poly
    local p1=Point(d[1])
    local short_i=1
    local short_k=1
    local min_dist=p1:distance(Point(poly[1]))
    for k,dp in ipairs(d) do
    for i,p in ipairs(poly) do
        local pd=Point(p):distance(Point(dp))
        if pd<min_dist then
            min_dist=pd
            short_i=i
            short_k=k
        end
    end
    end
    for i=1,#d do
        table.insert(poly, short_i+i, d[FP.cycle(short_k+i-1,1,#d)])
    end
    table.insert(poly,short_i+#d+1,d[short_k])
    table.insert(poly,short_i+#d+2,poly[short_i])
    return poly
end
function Navigate.path(faces,from,to)
    local polygon_points={}
    local start_i=-1
    local end_i=-1
    for i,f in ipairs(faces) do
        polygon_points[i]=f.points
        if f:has_point_in(from) then
            start_i=i
        end
        if f:has_point_in(to) then
            end_i = i
        end
    end
    -- print(start_i,end_i)
    if start_i<0 or end_i<0 then
        return false
    end
    local neighbors=Navigate.get_neighbor_info(polygon_points)
    ---[[point,point]...]
    local q={start_i}
    local visited={}
    visited[start_i]=true
    local record={}
    record[start_i]={cost=0,g=0,parent=nil,point=from}
    while #q>0 do
        table.sort(q,function (a, b)
            return record[a].cost<record[b].cost
        end)
        local current=q[1]
        table.remove(q,1)
        for i, neighb in ipairs(neighbors[current]) do
            local index=neighb.index
            if not visited[index] then
                local polygon = polygon_points[index]
                local g = from:distance(polygon[1])
                local pi = 1
                for k, p in ipairs(polygon) do
                    local d = p:distance(from)
                    if d < g then
                        pi = k
                        g = d
                    end
                end
                local h = to:distance(polygon[pi])
                local cost = g + h
                --FIXME cost=cost+parent.cost
                if record[index] then
                    if record[index].cost > cost then
                        record[index] = { cost = cost, parent = current }
                    end
                else
                    record[index] = { cost = cost, parent = current }
                end
                if index==end_i then
                    q={}
                    break
                end
                table.insert(q,index)
                visited[index]=true
            end
        end
    end
    local parent=record[end_i].parent
    local path={end_i}
    while parent do
        table.insert(path,parent)
        parent=record[parent].parent
    end
    local edge_pass={}
    for i=#path,2,-1 do
        local current=path[i]
        local next=path[i-1]
        for _,neighb in ipairs(neighbors[current]) do
            local index=neighb.index
            local A,B=table.unpack(neighb.edge)
            if index==next then
                table.insert(edge_pass,{A,B})
                break
            end
        end
    end
    ---Funnel Algorithm to optimize
    table.insert(edge_pass,{to,to})
    local waypoint=Navigate.funnel_waypoint(edge_pass,from)
    table.insert(waypoint, to)
    return waypoint
end
local function get_lr(base,A,B)
    local normal=Point(0,1,0)
    if (A-base):cross(B-base):dot(normal)<=0 then
        return A,B
    else
        return B,A
    end
end
function Navigate.funnel_waypoint(edge,start)
    local waypoint={}
    local apex=start
    local left,right=get_lr(apex,edge[1][1],edge[1][2])
    local Normal=Point(0,1,0)
    local mid=(left+right)/2
    local i=2
    local right_i,left_i=1,1
    while left~=right do
        local newL,newR=get_lr(mid,table.unpack(edge[i]))
        mid=(newL+newR)/2
        if (right-apex):cross(newR-apex):dot(Normal)>=0 then
            right=newR
            right_i=i
        end
        if (newL-apex):cross(left-apex):dot(Normal)>=0 then
            left=newL
            left_i=i
        end
        local cant_shrink=(left-apex):cross(right-apex):dot(Normal)>0
        if  cant_shrink then
            if right:distance(apex)<left:distance(apex) then
                apex=right
                i=right_i
            else
                apex=left
                i=left_i
            end
            local last_mid=(edge[i][1]+edge[i][2])/2
            left,right=get_lr(last_mid,table.unpack(edge[FP.clamp(i+1,1,#edge)]))
            -- print(apex,left,right)
            i=i+1
            right_i=i
            left_i=i
            mid=(left+right)/2
            table.insert(waypoint,apex)
        end
        i=FP.clamp(i+1,1,#edge)
    end
    return waypoint
end

---@param ops {points:table,map:table?}
---@return Face
function Navigate.polygon(ops)
    local points={}
    if ops.map then
        for i,p in ipairs(ops.map) do
            points[i]=Point(ops.points[p])
        end
    else
        for i, point in ipairs(ops.points) do
            points[i]= Point(point)
        end
    end
    local normal=Point(0,1,0)
    return Face{points=points,normal=normal,sorted=true}
end
local function min_max(a,b)
   if a>b then
    return b,a
   else 
    return a,b
   end 
end
---comment
---@param line1 [Point,Point]
---@param line2 [Point,Point]
local function line_intersect(line1,line2)
    local A,B=table.unpack(line1)
    local C,D=table.unpack(line2)
    local dir=(B-A):normal()
    local ta=0
    local tb=dir:dot(B-A)
    local tc,td=dir:dot(C-A),dir:dot(D-A)
    tc, td=min_max(tc,td)
    ta,tb=min_max(ta,tb)
    if tb<=tc or td<=ta then
        return false
    end
    local ts={ta,tb,tc,td}
    table.sort(ts)
    local p1=A+dir*ts[2]
    local p2=A+dir*ts[3]
    return {p1,p2}
end

local function is_neighbor(poly1,poly2)
    local normal=Point(0,1,0)
    for i,p1 in ipairs(poly1) do
        local p2 = poly1[FP.cycle(i + 1, 1, #poly1)]
        local AB=p2-p1
        for j,p3 in ipairs(poly2) do
            local p4 = poly2[FP.cycle(j + 1, 1, #poly2)]
            local CD=p4-p3
            local AC,AD=p3-p1,p4-p1
            local is_coline=AB:cross(AC):dot(normal)==0 and AB:cross(AD):dot(normal)==0
            if is_coline then
                local is_intersect = line_intersect({ p1, p2 }, { p3, p4 })
                if is_intersect then
                    return is_intersect
                end
            end
        end
    end
    return false
end

---@alias neighbor_info [number,Point,Point]
---info[polygon_index][i]=  [neighbor_index,edge_A,edge_B]
---@param polygons Point[][]
---@return {index:number,edge:[Point,Point]}[]
function Navigate.get_neighbor_info(polygons)
    ---BUG shared_edge may not full edge
    local neighbors={}
    for i,polygon in ipairs(polygons) do
        local neighbor={}
        for k,polygonB in ipairs(polygons) do
            if i~=k then
                local e = is_neighbor(polygon, polygonB)
                if e then
                    table.insert(neighbor,{index=k,edge=e})
                end
            end
        end
        neighbors[i]=neighbor
    end
    return neighbors
end
function Navigate.merge_triangle(convex,tri,A,B)
    local posA, posB = -1, -1
    local pos_i = -1
    for k, cp in ipairs(convex) do
        if A:hash() == cp:hash() then
            posA = k
        elseif B:hash() == cp:hash() then
            posB = k
        end
        if posA > 0 and posB > 0 then
            local min = math.min(posA, posB)
            local max = math.max(posA, posB)
            if (max == #convex and min == 1) then
                pos_i = #convex + 1
            else
                pos_i = min + 1
            end
        end
    end
    local tip
    for _, p in ipairs(tri) do
        if p:hash() ~= A:hash() and p:hash() ~= B:hash() then
            tip = p
            break
        end
    end
    local is_success=true
    table.insert(convex, pos_i, tip)
    local f=Face{points=convex,sorted=true}
    if not f:is_convex() then
        table.remove(convex, pos_i)
        is_success=false
    end
    return is_success
end
---@param polygon Face
---@return table
function Navigate.convex_decompose(polygon)
    local tris=polygon:triangulate()
    local neighbors=Navigate.get_neighbor_info(tris)
    local merged={}
    local result={}
    local convex={table.unpack(tris[1])}
    local q={1}
    while #q>0 do
        local ti=q[1]
        merged[ti]=true
        table.remove(q,1)
        local before_merge=#convex
        for _, neighb in ipairs(neighbors[ti]) do
            local index=neighb.index
            local A, B = table.unpack(neighb.edge)
            if not merged[index] then
                local tb = tris[index]
                local success = Navigate.merge_triangle(convex, tb, A, B)
                if success then
                    merged[index] = true
                    table.insert(q,1,index)
                end
            end
        end

        if #convex==before_merge then
            table.insert(result,convex)
            for i=1,#tris do
                if not merged[i] then
                    table.insert(q,i)
                    convex = { table.unpack(tris[q[1]]) }
                    break
                end
            end
        end

    end
    return result
end
return Navigate
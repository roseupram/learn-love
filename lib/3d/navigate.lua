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
        elseif f:has_point_in(to) then
            end_i = i
        end
    end
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
            local index,edge_a,edge_b=unpack(neighb)
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
            local index,A,B=table.unpack(neighb)
            if index==next then
                table.insert(edge_pass,{A,B})
                break
            end
        end
    end
    ---Funnel Algorithm to optimize
    local waypoint={}
    local base=from
    for i,e in ipairs(edge_pass) do
        local A,B = table.unpack(e)
        local SP=to-base
        local AP=A-base
        local BP=B-base
        local c=SP:cross(AP):dot(SP:cross(BP))
        if A:distance(to)+A:distance(from) < B:distance(to)+B:distance(from) then
            base = A
        else
            base = B
        end
        table.insert(waypoint, base)
    end
    table.insert(edge_pass,{to,to})
    waypoint=Navigate.funnel_waypoint(edge_pass,from)
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
            left,right=get_lr(apex,table.unpack(edge[i+1]))
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

---@alias neighbor_info [number,Point,Point]
---info[polygon_index][i]=  [neighbor_index,edge_A,edge_B]
---@param polygons Point[][]
---@return neighbor_info[][]
function Navigate.get_neighbor_info(polygons)
    ---BUG shared_edge may not full edge
    local shared_edge={}
    local edge={}
    for i, polygon in ipairs(polygons) do
        for t=1,#polygon do
            local next_t=FP.cycle(t+1,1,#polygon)
            local A=polygon[t]
            local B=polygon[next_t]
            local a,b=A:hash(),B:hash()
            local u,v
            local edge_index={i,t,next_t}
            if a>b then
                u=b;v=a
            else
                u=a;v=b
            end
            edge[u]=edge[u] or {}
            edge[u][v]=edge[u][v] or {}
            table.insert(edge[u][v],i)
            if #edge[u][v]>=2 then
                table.insert(shared_edge,{u,v,edge_index})
            end
        end
    end
    local neighbors={}
    for i,e in ipairs(shared_edge) do
        local ta,tb=table.unpack(edge[e[1]][e[2]])
        local edge_index=e[3]
        neighbors[ta] = neighbors[ta] or {}
        neighbors[tb] = neighbors[tb] or {}
        local edge_a=polygons[edge_index[1]][edge_index[2]]
        local edge_b=polygons[edge_index[1]][edge_index[3]]
        table.insert(neighbors[ta],{tb,edge_a,edge_b})
        table.insert(neighbors[tb],{ta,edge_a,edge_b})
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
            local index, A, B = table.unpack(neighb)
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
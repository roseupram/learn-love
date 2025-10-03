local Point=require('3d.point')
local FP=require('FP')
local Navigate=require("prototype"){name="Navigate"}
function Navigate:new(ops)
    self.points={}
    if ops.map then
        for i,p in ipairs(ops.map) do
            self.points[i]=Point(ops.points[p])
        end
    else
        for i, point in ipairs(ops.points) do
            self.points[i]= Point(point)
        end
    end
    self.mapi={}
    for i,point in ipairs(self.points) do
        self.mapi[point]=i
    end
    self.normal=Point(0,0,1)
end
function Navigate:convex_hull()
    ---https://swaminathanj.github.io/cg/ConvexHull.html
    local UP_P=self.normal

    local ccw_order={}
    local set={}
    local base_p=self.points[1]
    for i,point in ipairs(self.points) do
        if set[point:hash()]==nil then
            table.insert(ccw_order,point)
            set[point:hash()] = point
        end
        if point.y<base_p.y  then
            base_p=point
        end
    end
    table.sort(ccw_order,function (a, b)
        local pa=a-base_p
        local pb=b-base_p
        return pa:cross(pb):dot(UP_P)>0
    end)
    local hull={}
    for i,p in ipairs(ccw_order) do
        table.insert(hull,p)
        local is_last3_not_convex = true
        while #hull>=3 and is_last3_not_convex do
            ---check last 3
            local A = hull[#hull - 2]
            local B = hull[#hull - 1]
            local C = hull[#hull - 0]
            local AB, BC = B - A, C - B
            if AB:cross(BC):dot(UP_P) > 0 then
                is_last3_not_convex = false
            else
                table.remove(hull, #hull - 1)
            end
        end
    end
    return hull
end
function Navigate.no_point_in(polygon, points)
    for i,point in ipairs(points) do
        local is_in=true
        for k,A in ipairs(polygon) do
            local B=polygon[FP.cycle(k+1,1,#polygon)]
            if not Navigate.is_convex({A,B,point}) then
                is_in=false
                break
            end
        end
        if is_in then
            return false
        end
    end
    return true
end
function Navigate.is_convex(points,normal)
    normal=normal or Point(0,0,1)
    for i=1,#points do
        local A=points[i]
        local B=points[FP.cycle(i+1,1,#points)]
        local C=points[FP.cycle(i+2,1,#points)]
        local AB, BC = B - A, C - B
        local is_convex = AB:cross(BC):dot(normal) > 0
        if not is_convex then
            return false
        end
    end
    return true
end
function Navigate:triangulate()
    if self.tris_cache then
        return self.tris_cache
    end
    local tris={}
    local points={table.unpack(self.points)}
    while #points>3 do
        for i,point in ipairs(points) do
            local A=points[FP.cycle(i-1,1,#points)]
            local B=point
            local C=points[FP.cycle(i+1,1,#points)]
            if Navigate.is_convex({A,B,C}) and Navigate.no_point_in({A,B,C},points)then
                table.remove(points,i)
                table.insert(tris,{A,B,C})
                break
            end
        end
    end
    table.insert(tris,{unpack(points)})
    self.tris_cache=tris
    return tris
end
---[  
--- [ [index,edge_A,edge_B],...],   
--- ...  
--- ]
function Navigate.get_neighbor_info(tris)
    local shared_edge={}
    local edge={}
    for i, tri in ipairs(tris) do
        for t=1,3 do
            local next_t=FP.cycle(t+1,1,3)
            local A=tri[t]
            local B=tri[next_t]
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
        local ta,tb=unpack(edge[e[1]][e[2]])
        local edge_index=e[3]
        neighbors[ta] = neighbors[ta] or {}
        neighbors[tb] = neighbors[tb] or {}
        local edge_a=tris[edge_index[1]][edge_index[2]]
        local edge_b=tris[edge_index[1]][edge_index[3]]
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
    if not Navigate.is_convex(convex) then
        table.remove(convex, pos_i)
        is_success=false
    end
    return is_success
end
function Navigate:convex_decompose()
    local tris=self:triangulate()
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
        for i, neighb in ipairs(neighbors[ti]) do
            local index, A, B = table.unpack(neighb)
            if not merged[index] then
                local tb = tris[index]
                local success = Navigate.merge_triangle(convex, tb, A, B)
                if success then
                    merged[index] = true
                    table.insert(q,index)
                end
            end
        end
        if #convex==before_merge then
            table.insert(result,convex)
            local next_i=-1
            for i, neighb in ipairs(neighbors[ti]) do
                local index, A, B = table.unpack(neighb)
                if not merged[index] then
                    next_i=index
                    break
                end
            end
            if next_i<0 then
                break
            end
            convex={table.unpack(tris[next_i])}
            table.insert(q,next_i)
        end
    end
    return result
end
return Navigate
--- every node is smaller than children
local PQueue=require("prototype"){name="PQueue"}
local function default_cmp(a,b)
    return a<b
end
function PQueue:new(ops)
    self.compare=ops.compare or default_cmp
    self.heap={}
end
function PQueue:top()
    return self.heap[1]
end
function PQueue:push(v)
    local heap=self.heap
    local cmp=self.compare
    table.insert(heap,v)
    local i=#heap
    while i>1 do
        local parent=math.floor(i/2)
        if cmp(heap[i],heap[parent]) then
            heap[parent],heap[i]=heap[i],heap[parent]
        else
            break
        end
        i=parent
    end
end
function PQueue:pop()
    local top_value=self:top()
    local heap=self.heap
    local cmp=self.compare
    heap[1]=heap[#heap]
    heap[#heap]=nil
    local i=1
    while i<#heap do
        local left=2*i
        local right=left+1
        local small=i
        if left <= #heap and cmp(heap[left], heap[small]) then
            small = left
        end
        if right <= #heap and cmp(heap[right], heap[small]) then
            small = right
        end
        if small==i then
            break
        end
        heap[i],heap[small]=heap[small],heap[i]
        i=small
    end

    return top_value
end
function PQueue:len()
    return #self.heap
end
return PQueue
---@class JPS
local JPS = class("JPS")

function JPS:ctor()
    self.nodes = {}

    self.canShiftFunc = nil
    self.distFunc = nil
end

function JPS:Fetch(x, z)
    local key = x * 1024 + z
    if self.nodes[key] == nil then
        self.nodes[key] = {
            x = x,
            z = z,
            g = 0,
            h = 0,
            f = 0,
            closed = false,
            parent = nil
        }
    end
    return self.nodes[key]
end

function JPS:Clear()
    self.nodes = {}
end

function JPS:GetNeighbours(node)
    local neighbours = {}
    if node.parent == nil then
        local matrix = {{1, 1}, {1, 0}, {1, -1}, {0, 1}, {0, -1}, {-1, 1}, {-1, 0}, {-1, -1}}
        for i = 1, #matrix do
            local nx = node.x + matrix[i][1]
            local nz = node.z + matrix[i][2]
            if self.canShiftFunc(node, matrix[i][1], matrix[i][2]) then
                table.insert(neighbours, self:Fetch(nx, nz))
            end
        end
    else
        local px = node.parent.x
        local pz = node.parent.z
        local dx = (node.x - px) / math.max(node.x - px, 1)
        local dz = (node.z - pz) / math.max(node.z - pz, 1)
        if dx ~= 0 and dz ~= 0 then
            if self.canShiftFunc(node, dx, 0) then
                table.insert(neighbours, self:Fetch(node.x + dx, 0))
            end
            if self.canShiftFunc(node, 0, dz) then
                table.insert(neighbours, self:Fetch(node.x, node.z + dz))
            end
            if self.canShiftFunc(node, dz, dz) then
                table.insert(neighbours, self:Fetch(node.x + dx, node.z + dz))
            end
            if not self.canShiftFunc(node, -dx, 0) and self.canShiftFunc(node, -dx, dz) then
                table.insert(neighbours, self:Fetch(node.x - dx, node.z + dz))
            end
            if not self.canShiftFunc(node, 0, -dz) and self.canShiftFunc(node, dx, -dz) then
                table.insert(neighbours, self:Fetch(node.x + dx, node.z - dz))
            end
        elseif dx ~= 0 then
            if self.canShiftFunc(node, dx, 0) then
                table.insert(neighbours, self:Fetch(node.x + dx, node.z))
            end
            if not self.canShiftFunc(node, 0, dz) and self.canShiftFunc(node, dx, dz) then
                table.insert(neighbours, self:Fetch(node.x + dx, node.z + dz))
            end
            if not self.canShiftFunc(node, 0, -dz) and self.canShiftFunc(node, dx, -dz) then
                table.insert(neighbours, self:Fetch(node.x + dx, node.z - dz))
            end
        elseif dz ~= 0 then
            if self.canShiftFunc(node, 0, dz) then
                table.insert(neighbours, self:Fetch(node.x, node.z + dz))
            end
            if not self.canShiftFunc(node, dx, 0) and self.canShiftFunc(node, dx, dz) then
                table.insert(neighbours, self:Fetch(node.x + dx, node.z + dz))
            end
            if not self.canShiftFunc(node, -dx, -0) and self.canShiftFunc(node, -dx, dz) then
                table.insert(neighbours, self:Fetch(node.x - dx, node.z + dz))
            end
        end
    end
    return neighbours
end

function JPS:Jump(parent, node)
    local dx = (node.x - parent.x) / math.max(node.x - parent.x, 1)
    local dz = (node.z - parent.z) / math.max(node.z - parent.z, 1)
end

---@param start node 开始点
---@param goal node 目标点
function JPS:Finder(start, goal)
    local startNode = self:Fetch(start.x, start.z)
    startNode.h = self.distFunc(startNode, goal)
    startNode.f = startNode.h + startNode.g
    local openQue = {startNode}

    while #openQue > 0 do
        local curNode = openQue[1]
        local neighbours = self:GetNeighbours(curNode)
        curNode.closed = true

        for i = 1, #neighbours do
            local jumpNode = self:Jump(curNode, neighbours[i])
            if jumpNode ~= nil and jumpNode.closed == false then
                local ng = curNode.g + self.distFunc(jumpNode, curNode)
                local nh = self.distFunc(jumpNode, goal)
                local nf = ng + nh

                local sameIndex = nil
                for i = 1, #openQue do
                    if openQue[i].x == jumpNode.x and openQue[i].z == jumpNode.z then
                        sameIndex = i
                        break
                    end
                end

                if sameIndex ~= nil then
                    if openQue[sameIndex].f > nf then
                        openQue[sameIndex].g = ng
                        openQue[sameIndex].h = nh
                        openQue[sameIndex].f = nf
                    end
                else
                    jumpNode.g = ng
                    jumpNode.h = nh
                    jumpNode.f = nf
                    table.insert(openQue, jumpNode)
                end
            end
        end
        table.remove(openQue, 1)
        table.sort(
            openQue,
            function(a, b)
                return a.f < b.f
            end
        )
    end
end

return JPS

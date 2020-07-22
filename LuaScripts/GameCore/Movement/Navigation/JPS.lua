---@class JPS
local JPS = class("JPS")

function JPS:ctor()
    self.nodes = {}
    self.start = nil
    self.goal = nil

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

    if node.x == self.goal.x and node.z == self.goal.z then
        return self:Fetch(node.x, node.z)
    end

    if dx ~= 0 and dz ~= 0 then
        if
            (not self.canShiftFunc(node, -dx, 0) and self.canShiftFunc(node, -dx, dz)) or
                (not self.canShiftFunc(node, 0, -dz) and self.canShiftFunc(node, dx, -dz))
         then
            return self:Fetch(node.x, node.z)
        end
        if self:Jump(node, self:Fetch(node.x + dx, node.z)) or self:Jump(node, self:Fetch(node.x, node.z + dz)) then
            return self:Fetch(node.x, node.z)
        end
    elseif dx ~= 0 then
        if
            (not self.canShiftFunc(node, 0, 1) and self.canShiftFunc(node, dx, 1)) or
                (not self.canShiftFunc(node, 0, -1) and self.canShiftFunc(node, dx, -1))
         then
            return self:Fetch(node.x, node.z)
        end
    elseif dz ~= 0 then
        if
            (not self.canShiftFunc(node, 1, 0) and self.canShiftFunc(node, 1, dz)) or
                (not self.canShiftFunc(node, -1, dz) and self.canShiftFunc(node, -1, dz))
         then
            return self:Fetch(node.x, node.z)
        end
    end

    if self.canShiftFunc(node, dx, dz) then
        return self:Jump(node, self:Fetch(node.x + dx, node.z + dz))
    else
        return nil
    end
end

---@param start node 开始点
---@param goal node 目标点
function JPS:Finder(start, goal)
    local startNode = self:Fetch(start.x, start.z)
    local goalNode = self:Fetch(goal.x, goal.z)
    startNode.h = self.distFunc(startNode, goal)
    startNode.f = startNode.h + startNode.g

    self.start = startNode
    self.goal = goalNode

    local openQue = {startNode}
    local optimalNode = nil

    while #openQue > 0 do
        local curNode = openQue[1]

        --check goal
        if curNode.x == self.goal.x and curNode.z == self.goal.z then
            return self:BuildPath(curNode)
        end

        -- start search
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
                        openQue[sameIndex].parent = curNode
                    end
                else
                    jumpNode.g = ng
                    jumpNode.h = nh
                    jumpNode.f = nf
                    jumpNode.parent = curNode
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

    return nil
end

function JPS:BuildPath(endNode)
    local path = {}
    local curNode = endNode
    while curNode ~= nil do
        table.insert(path, 1, {x = curNode.x, z = curNode.z})
        curNode = curNode.parent
    end
    return path
end

return JPS

---@class MoveController
local Ctrller = class("MoveController")
local Avatar = require("GameLogics.Battle.Field.Unit.Components.Avatar")

Ctrller.State = {
    Walking = "walking",
    Stop = "stop"
}

function Ctrller:ctor(master)
    self.master = master
    self:Init()
    self.state = Ctrller.State.Stop
end

function Ctrller:Init()
    local px, pz = self.master.sess.map:TryCreateUnit(self.master)
    self.position = {
        x = px,
        z = pz
    }
    self.viewPosition = self.master.sess.map:GetMapGridCenter(self.position.x, self.position.z)
    self.curState = Ctrller.State.Stop

    self.path = {}
    self.pathIterator = 0
end

function Ctrller:Update(delta)
    self:Walk(delta)
end

function Ctrller:SwitchState(state)
    if state == self.state then
        return
    end
    if state == Ctrller.State.Walking then
        Debug.Log(self.master.name .. " start walking")
        self.master.avatar:SwitchAction(Avatar.ActionType.Walk)
    elseif state == Ctrller.State.Stop then
        Debug.Log(self.master.name .. " stop walking")
        self.master.avatar:SwitchAction(Avatar.ActionType.Idle)
    end
    self.state = state
end

function Ctrller:MoveToPos(pos)
    local result, next = self.master.sess.map:UnitReqMove(self.master, pos)
    if result then
        local map = self.master.sess.map
        self.master.avatar:TurnToPos(map:GetMapGridCenter(next.x, next.z))
    end
    return result
end

function Ctrller:Walk(delta)
    if self.path ~= nil then
        local map = self.master.sess.map
        local advanceDist = self.master.properties:GetProperty("speed") * delta
        local advancePos = self.position
        local result = nil
        local isStop = false
        for i = self.pathIterator, #self.path do
            local between = map:GetDist(advancePos, self.path[i])
            if advanceDist >= between then
                self.pathIterator = self.pathIterator + 1
                advanceDist = advanceDist - between
                advancePos = self.path[i]
                if self.pathIterator > #self.path then
                    result = {
                        x = advancePos.x,
                        z = advancePos.z
                    }
                    isStop = true
                end
            else
                local k = advanceDist / between
                result = {
                    x = k * (self.path[i].x - advancePos.x) + advancePos.x,
                    z = k * (self.path[i].z - advancePos.z) + advancePos.z
                }
            end
        end
        if result then
            self.position = result
        end
        if isStop then
            self:Stop()
        end
    end
end

function Ctrller:Stop()
end

return Ctrller

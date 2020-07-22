require("GameCore.Main.MainProcedure")

SystemConst.logicMode = true

local beginTime = os.time()
local costTick = function()
    print("cost time: " .. tostring(os.time() - beginTime) .. "s")
    beginTime = os.time()
end

Main()
BattleManager:StartBattle({id = 1, myHeros = {{1, 2}, {1, 2}}})

local function loadUnits(data)
    for i = 1, #data do
        local vo = ConfigManager:GetUnitConfig(data[i].unitId)
        vo.initPos = {
            x = data[i].x,
            z = data[i].z
        }
        BattleManager.session.field:CreateUnit(vo, data[i].camp)
    end
end

local testData = {}

loadUnits(testData)
BattleManager.session.fsm:Switch2State(require("GameLogics.Battle.Session.SessionFSM").SessionType.Action)
local path = BattleManager.session.map:JPSFind({x = 5, z = 5}, {x = 50, z = 57}, 3)
for i = 1, #path do
    print("x=" .. tostring(path[i].x) .. " z=" .. tostring(path[i].z))
end
-- --costTick()
-- while BattleManager.session ~= nil do
--     MainUpdate(0.003)
--     --costTick()
-- end

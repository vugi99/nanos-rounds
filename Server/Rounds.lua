
PLAYERS_JOINED = {}
WAITING_PLAYERS = {}
PLAYERS_REMAINING = {}
TEAMS_PLAYERS = {}

ROUND_RUNNING = false

local ROUND_RESTART_TIMEOUT

local Remaining_Spawns = {}

local function table_count(T)
    local count = 0
    for k, v in pairs(T) do count = count + 1 end
    return count
end

function RoundEnd()
    if ROUND_RUNNING then
        Events.Call("RoundEnding")
        ROUND_RUNNING = false

        WAITING_PLAYERS = {}
        PLAYERS_REMAINING = {}
        if ROUNDS_CONFIG.ROUND_TYPE == "TEAMS" then
            TEAMS_PLAYERS = {}
        end

        for k, v in pairs(PLAYERS_JOINED) do
            local char = v:GetControlledCharacter()
            if char then
                char:Destroy()
            end
            if ROUNDS_CONFIG.WAITING_ACTION[1] == "SPECTATE_REMAINING_PLAYERS" then
                v:SetValue("RoundPlaying", false, true)
            end
        end

        if RoundStartCondition() then
            if ROUNDS_CONFIG.ROUNDS_INTERVAL_ms then
                ROUND_RESTART_TIMEOUT = Timer.SetTimeout(function()
                    if RoundStartCondition() then
                        RoundStart()
                    end
                end, ROUNDS_CONFIG.ROUNDS_INTERVAL_ms)
            end
        end

        return true
    end
end

function RESET_SPAWNS_TABLE()
    Remaining_Spawns = {}
end

function RoundStart()
    if not ROUND_RUNNING then
        if ROUND_RESTART_TIMEOUT then
            Timer.ClearTimeout(ROUND_RESTART_TIMEOUT)
            ROUND_RESTART_TIMEOUT = nil
        end
        WAITING_PLAYERS = {}
        if ROUNDS_CONFIG.ROUND_TYPE == "TEAMS" then
            TEAMS_PLAYERS = {}
            for i = 1, table_count(ROUNDS_CONFIG.ROUND_TEAMS) do
                table.insert(TEAMS_PLAYERS, {})
            end
        end

        ROUND_RUNNING = true

        RESET_SPAWNS_TABLE()
        for k, v in pairs(PLAYERS_JOINED) do
            SpawnPlayer(v)
        end
        RESET_SPAWNS_TABLE()

        Events.Call("RoundStart")

        return true
    end
end


function WaitingAction(ply)
    local char = ply:GetControlledCharacter()
    if char then
        char:Destroy()
    end

    if ROUNDS_CONFIG.ROUND_TYPE == "TEAMS" then
        ply:SetValue("PlayerTeam", nil, true)
    end

    if ROUNDS_CONFIG.WAITING_ACTION[1] == "SPECTATE_REMAINING_PLAYERS" then
        ply:SetValue("RoundPlaying", false, true)
    end

    Events.Call("RoundPlayerWaiting", ply)
end

function GetSpawn(team)
    if ROUNDS_CONFIG.SPAWNING[1] == "SPAWNS" then
        local remaining_count = table_count(Remaining_Spawns)
        if remaining_count == 0 then
            for i, v in ipairs(ROUNDS_CONFIG.SPAWNING[2]) do
                table.insert(Remaining_Spawns, v)
            end
        end
        local spawn = Remaining_Spawns[1]
        table.remove(Remaining_Spawns, 1)
        return spawn
    elseif ROUNDS_CONFIG.SPAWNING[1] == "RANDOM_SPAWNS" then
        return ROUNDS_CONFIG.SPAWNING[2][math.random(table_count(ROUNDS_CONFIG.SPAWNING[2]))]
    elseif ROUNDS_CONFIG.SPAWNING[1] == "TEAM_SPAWNS" then
        local regen_remaining = false
        if not Remaining_Spawns[team] then
            regen_remaining = true
        else
            local remaining_in_team_count = table_count(Remaining_Spawns[team])
            if remaining_in_team_count == 0 then
                regen_remaining = true
            end
        end
        if regen_remaining then
            Remaining_Spawns[team] = {}
            for i, v in ipairs(ROUNDS_CONFIG.SPAWNING[2][team]) do
                table.insert(Remaining_Spawns[team], v)
            end
        end
        local spawn = Remaining_Spawns[team][1]
        table.remove(Remaining_Spawns[team], 1)
        return spawn
    end
end

function SpawnPlayer(ply, respawn)
    if ROUND_RUNNING then
        local ochar = ply:GetControlledCharacter()
        if ochar then
            ochar:Destroy()
        end

        for k, v in pairs(WAITING_PLAYERS) do
            if v == ply then
                table.remove(WAITING_PLAYERS, k)
                break
            end
        end

        local team
        if ROUNDS_CONFIG.ROUND_TYPE == "TEAMS" then
            if respawn then
                team = ply:GetValue("PlayerTeam")
            else
                local smaller_count
                for i, v in ipairs(TEAMS_PLAYERS) do
                    local count = table_count(v)
                    if (not smaller_count or smaller_count > count) then
                        team = i
                        smaller_count = count
                    end
                end
            end
        end

        --print(team)

        local spawn = GetSpawn(team)
        if ROUNDS_CONFIG.SPAWN_POSSESS[1] == "CHARACTER" then
            local char = Character(spawn[1], spawn[2], table.unpack(ROUNDS_CONFIG.SPAWN_POSSESS[2]))
            ply:Possess(char)
        elseif ROUNDS_CONFIG.SPAWN_POSSESS[1] == "CAMERA" then
            ply:SetCameraLocation(spawn[1])
            ply:SetCameraRotation(spawn[2])
        elseif ROUNDS_CONFIG.SPAWN_POSSESS[1] == "TRANSLATE_CAMERA" then
            ply:TranslateCameraTo(spawn[1], table.unpack(ROUNDS_CONFIG.SPAWN_POSSESS[2]))
            ply:RotateCameraTo(spawn[2], table.unpack(ROUNDS_CONFIG.SPAWN_POSSESS[2]))
        end

        table.insert(PLAYERS_REMAINING, ply)
        if ROUNDS_CONFIG.ROUND_TYPE == "TEAMS" then
            table.insert(TEAMS_PLAYERS[team], ply)
            if not respawn then
                ply:SetValue("PlayerTeam", team, true)
            end
        end

        if ROUNDS_CONFIG.WAITING_ACTION[1] == "SPECTATE_REMAINING_PLAYERS" then
            ply:SetValue("RoundPlaying", true, true)
        end

        Events.Call("RoundPlayerSpawned", ply)
        return true
    end
    return false
end

function RoundStartCondition()
    if ROUNDS_CONFIG.ROUND_START_CONDITION[1] == "PLAYERS_NB" then
        local players_count = table_count(PLAYERS_JOINED)
        --print(players_count)
        if players_count >= ROUNDS_CONFIG.ROUND_START_CONDITION[2] then
            return true
        end
    end
end

function RoundEndCondition()
    if ROUNDS_CONFIG.ROUND_END_CONDITION[1] == "REMAINING_PLAYERS" then
        if table_count(PLAYERS_REMAINING) <= ROUNDS_CONFIG.ROUND_END_CONDITION[2] then
            return true
        end
    elseif ROUNDS_CONFIG.ROUND_END_CONDITION[1] == "REMAINING_PLAYERS_IN_TEAM" then
        for i, v in ipairs(TEAMS_PLAYERS) do
            if table_count(v) <= ROUNDS_CONFIG.ROUND_END_CONDITION[2][i] then
                return true
            end
        end
    end
end

function RoundsPlayerOut(ply)
    local is_playing_player
    for k, v in pairs(PLAYERS_REMAINING) do
        if v == ply then
            is_playing_player = true
            break
        end
    end
    if is_playing_player then
        for k, v in pairs(PLAYERS_REMAINING) do
            if v == ply then
                table.remove(PLAYERS_REMAINING, k)
                break
            end
        end

        for k, v in pairs(TEAMS_PLAYERS) do
            for k2, v2 in pairs(v) do
                if v2 == ply then
                    table.remove(TEAMS_PLAYERS[k], k2)
                    break
                end
            end
        end

        table.insert(WAITING_PLAYERS, ply)

        Events.Call("RoundPlayerOut", ply)

        if ROUNDS_CONFIG.PLAYER_OUT_ACTION[1] == "WAITING" then
            WaitingAction(ply)
        elseif ROUNDS_CONFIG.PLAYER_OUT_ACTION[1] == "RESPAWN" then
            SpawnPlayer(ply, true)
        end

        if RoundEndCondition() then
            RoundEnd()
        end
    end
end

function HandlePlayerJoin(ply, more_joining)
    --print("HandlePlayerJoin", ply)
    local players_count = table_count(PLAYERS_JOINED)
    if (not ROUNDS_CONFIG.MAX_PLAYERS or players_count + 1 <= ROUNDS_CONFIG.MAX_PLAYERS) then
        table.insert(PLAYERS_JOINED, ply)
        Events.Call("RoundPlayerJoined", ply)
        if not ROUND_RUNNING then
            if RoundStartCondition() then
                if not ROUND_RESTART_TIMEOUT then
                    if not more_joining then
                        RoundStart()
                    end
                end
            end
        elseif ROUNDS_CONFIG.CAN_JOIN_DURING_ROUND then
            SpawnPlayer(ply)
        else
            table.insert(WAITING_PLAYERS, ply)

            WaitingAction(ply)
        end
    else
        ply:Kick("Gamemode Full")
    end
end
Player.Subscribe("Spawn", HandlePlayerJoin)
Package.Subscribe("Load", function()
    local count = table_count(Player.GetPairs())
    local i = 0
    for k, v in pairs(Player.GetPairs()) do
        i = i + 1
        if i == count then
            HandlePlayerJoin(v)
        else
            HandlePlayerJoin(v, true)
        end
    end
end)

Player.Subscribe("Destroy", function(ply)
    local char = ply:GetControlledCharacter()
    if char then
        char:Destroy()
    end

    for k, v in pairs(PLAYERS_JOINED) do
        if v == ply then
            table.remove(PLAYERS_JOINED, k)
            break
        end
    end

    for k, v in pairs(WAITING_PLAYERS) do
        if v == ply then
            table.remove(WAITING_PLAYERS, k)
            break
        end
    end

    for k, v in pairs(PLAYERS_REMAINING) do
        if v == ply then
            table.remove(PLAYERS_REMAINING, k)
            break
        end
    end

    for k, v in pairs(TEAMS_PLAYERS) do
        for k2, v2 in pairs(v) do
            if v2 == ply then
                table.remove(TEAMS_PLAYERS[k], k2)
                break
            end
        end
    end

    if RoundEndCondition() then
        RoundEnd()
    end
end)

Character.Subscribe("Death", function(char, ...)
    local ply = char:GetPlayer()
    if ply then
        if ROUNDS_CONFIG.PLAYER_OUT_CONDITION[1] == "DEATH" then
            Events.Call("RoundPlayerOutDeath", char, ...)
            RoundsPlayerOut(ply)
        end
    end
end)
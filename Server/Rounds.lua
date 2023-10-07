
Package.Export("PLAYERS_JOINED", {})
Package.Export("WAITING_PLAYERS", {})
Package.Export("PLAYERS_REMAINING", {})
Package.Export("TEAMS_PLAYERS", {})

Package.Export("TEAMS_FOR_THIS_ROUND", nil)

Package.Export("ROUND_RUNNING", false)

Package.Export("ROUND_RESTART_TIMEOUT", nil)
Package.Export("LOBBY_TIMEOUT", nil)

Package.Export("ROUNDS_SLEEPING", true)

local Remaining_Spawns = {}
local Teams_Counts

local function table_count(T)
    local count = 0
    for k, v in pairs(T) do count = count + 1 end
    return count
end

local function ROUNDS_CALL_EVENT(event, ...)
    if ROUNDS_CONFIG.ROUNDS_DEBUG then
        print("Rounds Debug : ", event, ...)
    end
    Events.Call(event, ...)
end

local function Random_Reorder_Table(tbl)
    local maxn = 0
    for k, _ in pairs(tbl) do
        if k > maxn then
            maxn = k
        end
    end

    -- Shrink table filling holes
    local attach_i = 1
    for i = 1, maxn do
        if tbl[i] then
            if attach_i ~= i then
                tbl[attach_i] = tbl[i]
                tbl[i] = nil
            end
            attach_i = attach_i+1
        end
    end

    local c = attach_i - 1 -- last index is attach_i-1
    for i, v in ipairs(tbl) do
        local tmp = v
        local r = math.random(c)
        tbl[i] = tbl[r]
        tbl[r] = tmp
    end
end

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
      local j = math.random(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

local function SetRoundsSleeping(bool)
    if bool ~= ROUNDS_SLEEPING then
        ROUNDS_SLEEPING = bool
        ROUNDS_CALL_EVENT("Rounds_Sleeping", bool)
    end
end



function RoundEnd()
    if ROUND_RUNNING then
        ROUNDS_CALL_EVENT("RoundEnding")
        ROUND_RUNNING = false
        TEAMS_FOR_THIS_ROUND = nil

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
            --if ROUNDS_CONFIG.WAITING_ACTION[1] == "SPECTATE_REMAINING_PLAYERS" then
            v:SetValue("RoundPlaying", false, true)
            --end

            if ROUNDS_CONFIG.ROUND_TYPE ~= "PERSISTENT_TEAMS" then
                if v.BOT then
                    v:Kick()
                end
            end
        end

        ROUNDS_CALL_EVENT("RoundEnded")

        if RoundStartCondition() then
            if ROUNDS_CONFIG.ROUNDS_INTERVAL_ms then
                ROUND_RESTART_TIMEOUT = Timer.SetTimeout(function()
                    ROUND_RESTART_TIMEOUT = nil
                    if RoundStartCondition() then
                        if not ROUNDS_CONFIG.LOBBY_CONFIG then
                            RoundStart()
                        else
                            LobbyStart()
                        end
                    else
                        SetRoundsSleeping(true)
                    end
                end, ROUNDS_CONFIG.ROUNDS_INTERVAL_ms)
            else
                if not ROUNDS_CONFIG.LOBBY_CONFIG then
                    RoundStart()
                else
                    LobbyStart()
                end
            end
        else
            SetRoundsSleeping(true)
        end

        return true
    end
end
Package.Export("RoundEnd", RoundEnd)

function RESET_SPAWNS_TABLE()
    Remaining_Spawns = {}
end
Package.Export("RESET_SPAWNS_TABLE", RESET_SPAWNS_TABLE)

function PlayerEnterTeam(ply)
    local team
    if (ROUNDS_CONFIG.ROUND_TEAMS[1] == "AUTO_BALANCED" or (ROUNDS_CONFIG.ROUND_TEAMS[1] == "PASSED_TEAMS" and ROUNDS_CONFIG.ROUND_TEAMS[4] and not TEAMS_FOR_THIS_ROUND)) then
        local smaller_count
        for i, v in ipairs(TEAMS_PLAYERS) do
            local count = table_count(v)
            if (not smaller_count or smaller_count > count) then
                team = i
                smaller_count = count
            end
        end
    elseif ROUNDS_CONFIG.ROUND_TEAMS[1] == "PASSED_TEAMS" then
        for i, v in ipairs(TEAMS_FOR_THIS_ROUND) do
            for i2, v2 in ipairs(v) do
                if v2 == ply then
                    team = i
                    break
                end
            end
        end
    elseif ROUNDS_CONFIG.ROUND_TEAMS[1] == "CODE_BALANCED_TEAMS" then
        if Teams_Counts then

            local randoms_to_teams_players_indexes = {}
            for i, _ in ipairs(TEAMS_PLAYERS) do
                table.insert(randoms_to_teams_players_indexes, i)
            end
            shuffle(randoms_to_teams_players_indexes)

            for _, i in ipairs(randoms_to_teams_players_indexes) do
                local v = TEAMS_PLAYERS[i]
                local count = table_count(v)
                if count < Teams_Counts[i] then
                    team = i
                    break
                end
            end
        else
            error("Teams_Counts not returned properly from teams_count_func")
        end
    end

    if team then
        table.insert(TEAMS_PLAYERS[team], ply)
        ply:SetValue("PlayerTeam", team, true)

        return true
    end
    return false
end
Package.Export("PlayerEnterTeam", PlayerEnterTeam)

function RoundsBotsJoin()
    if ROUNDS_CONFIG.VBOTS_CONFIG then
        if ROUNDS_CONFIG.VBOTS_CONFIG[1] == "FILL" then
            if VBotJoin then
                local loop_end = ROUNDS_CONFIG.VBOTS_CONFIG[2] or 0
                --[[if (ROUNDS_CONFIG.MAX_PLAYERS and (not ROUNDS_CONFIG.VBOTS_CONFIG[3])) then
                    loop_end = min(loop_end, ROUNDS_CONFIG.MAX_PLAYERS - table_count(PLAYERS_JOINED))
                end]]--
                for i = 1, loop_end do
                    local bot = VBotJoin()
                    table.insert(PLAYERS_JOINED, bot)
                end
            end
        end
    end
end
Package.Export("RoundsBotsJoin", RoundsBotsJoin)


local Generating_teams = false
function GenerateTeamsTables()
    Generating_teams = true

    TEAMS_PLAYERS = {}

    ROUNDS_CALL_EVENT("ROUND_PASS_TEAMS")

    if (ROUNDS_CONFIG.ROUND_TEAMS[1] == "AUTO_BALANCED" or (ROUNDS_CONFIG.ROUND_TEAMS[1] == "PASSED_TEAMS" and ROUNDS_CONFIG.ROUND_TEAMS[4] and not TEAMS_FOR_THIS_ROUND)) then
        for i = 1, table_count(ROUNDS_CONFIG.ROUND_TEAMS[3]) do
            table.insert(TEAMS_PLAYERS, {})
        end

        RoundsBotsJoin()
    elseif ROUNDS_CONFIG.ROUND_TEAMS[1] == "PASSED_TEAMS" then
        if TEAMS_FOR_THIS_ROUND and type(TEAMS_FOR_THIS_ROUND) == "table" then
            for i = 1, table_count(TEAMS_FOR_THIS_ROUND) do
                table.insert(TEAMS_PLAYERS, {})
            end
        else
            error("Rounds : wrong or nothing passed into TEAMS_FOR_THIS_ROUND")
        end
    elseif ROUNDS_CONFIG.ROUND_TEAMS[1] == "CODE_BALANCED_TEAMS" then
        Teams_Counts = ROUNDS_Special_Serverside_Config.teams_count_func()
        if Teams_Counts then
            for i, v in ipairs(Teams_Counts) do
                table.insert(TEAMS_PLAYERS, {})
            end
        end

        RoundsBotsJoin()
    end

    Random_Reorder_Table(PLAYERS_JOINED)

    for k, v in pairs(PLAYERS_JOINED) do -- Players join first
        if not v.BOT then
            PlayerEnterTeam(v)
        end
    end
    for k, v in pairs(PLAYERS_JOINED) do -- Then fill with bots
        if v.BOT then
            local entered = PlayerEnterTeam(v)
            if not entered then
                v:Kick()
            end
        end
    end

    Generating_teams = false
end
Package.Export("GenerateTeamsTables", GenerateTeamsTables)

function SpawnEveryone()
    Random_Reorder_Table(PLAYERS_JOINED)

    RESET_SPAWNS_TABLE()
    for k, v in pairs(PLAYERS_JOINED) do
        SpawnPlayer(v)
    end
    --RESET_SPAWNS_TABLE()
end
Package.Export("SpawnEveryone", SpawnEveryone)

function RoundStart(sleeping)
    if not ROUND_RUNNING then
        if type(sleeping) == "nil" then
            sleeping = ROUNDS_SLEEPING
            SetRoundsSleeping(false)
        end


        ROUNDS_CALL_EVENT("RoundStarting", sleeping)

        if ROUND_RESTART_TIMEOUT then
            Timer.ClearTimeout(ROUND_RESTART_TIMEOUT)
            ROUND_RESTART_TIMEOUT = nil
        end
        WAITING_PLAYERS = {}
        if ROUNDS_CONFIG.ROUND_TYPE == "TEAMS" then
            if ROUNDS_CONFIG.ROUND_TEAMS[2] == "ROUNDSTART_GENERATION" then
                GenerateTeamsTables()
            end
        elseif ROUNDS_CONFIG.ROUND_TYPE == "PERSISTENT_TEAMS" then
            if sleeping then
                if ROUNDS_CONFIG.ROUND_TEAMS[2] == "ROUNDSTART_GENERATION" then
                    GenerateTeamsTables()
                end
            end
        elseif ROUNDS_CONFIG.ROUND_TYPE == "BASIC" then
            RoundsBotsJoin()
        end

        ROUND_RUNNING = true

        if ROUNDS_CONFIG.SPAWNING[3] == "ROUNDSTART_SPAWN" then
            SpawnEveryone()
        end

        ROUNDS_CALL_EVENT("RoundStart", sleeping)

        if RoundEndCondition() then
            RoundEnd()
        end

        return true
    end
end
Package.Export("RoundStart", RoundStart)

function LobbyEnd(sleeping)
    if not ROUND_RUNNING then
        if LOBBY_TIMEOUT then
            Timer.ClearTimeout(LOBBY_TIMEOUT)
            LOBBY_TIMEOUT = nil
        end

        ROUNDS_CALL_EVENT("LobbyEnding", sleeping)

        if RoundStartCondition() then
            RoundStart(sleeping)
        else
            SetRoundsSleeping(true)
        end
    end
end
Package.Export("LobbyEnd", LobbyEnd)

function LobbyStart()
    if not ROUND_RUNNING then
        local sleeping = ROUNDS_SLEEPING
        SetRoundsSleeping(false)

        if LOBBY_TIMEOUT then
            Timer.ClearTimeout(LOBBY_TIMEOUT)
        end

        ROUNDS_CALL_EVENT("LobbyStarting", sleeping)

        if ROUNDS_CONFIG.ROUND_TYPE == "TEAMS" then
            if ROUNDS_CONFIG.ROUND_TEAMS[2] == "LOBBYSTART_GENERATION" then
                GenerateTeamsTables()
            end
        elseif ROUNDS_CONFIG.ROUND_TYPE == "PERSISTENT_TEAMS" then
            if sleeping then
                if ROUNDS_CONFIG.ROUND_TEAMS[2] == "LOBBYSTART_GENERATION" then
                    GenerateTeamsTables()
                end
            end
        end

        LOBBY_TIMEOUT = Timer.SetTimeout(function()
            LOBBY_TIMEOUT = nil
            LobbyEnd(sleeping)
        end, ROUNDS_CONFIG.LOBBY_CONFIG[1])

        if ROUNDS_CONFIG.SPAWNING[3] == "LOBBYSTART_SPAWN" then
            SpawnEveryone()
        end

        ROUNDS_CALL_EVENT("LobbyStarted", sleeping)

        return true
    end
end
Package.Export("LobbyStart", LobbyStart)


function WaitingAction(ply)
    local char = ply:GetControlledCharacter()
    if char then
        char:Destroy()
    end

    if ROUNDS_CONFIG.ROUND_TYPE == "TEAMS" then
        ply:SetValue("PlayerTeam", nil, true)
    end

    --if ROUNDS_CONFIG.WAITING_ACTION[1] == "SPECTATE_REMAINING_PLAYERS" then
    ply:SetValue("RoundPlaying", false, true)
    --end

    ROUNDS_CALL_EVENT("RoundPlayerWaiting", ply)
end
Package.Export("WaitingAction", WaitingAction)

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
Package.Export("GetSpawn", GetSpawn)

function SpawnPlayer(ply)
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
    if (ROUNDS_CONFIG.ROUND_TYPE == "TEAMS" or ROUNDS_CONFIG.ROUND_TYPE == "PERSISTENT_TEAMS") then
        team = ply:GetValue("PlayerTeam")
        if not team then
            PlayerEnterTeam(ply)
            team = ply:GetValue("PlayerTeam")
            if not team then
                return false
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

    --if ROUNDS_CONFIG.WAITING_ACTION[1] == "SPECTATE_REMAINING_PLAYERS" then
    ply:SetValue("RoundPlaying", true, true)
    --end

    ROUNDS_CALL_EVENT("RoundPlayerSpawned", ply)
    return true
end
Package.Export("SpawnPlayer", SpawnPlayer)

function RoundStartCondition()
    if ROUNDS_CONFIG.ROUND_START_CONDITION[1] == "PLAYERS_NB" then
        local players_count = table_count(PLAYERS_JOINED)
        --print(players_count)
        if players_count >= ROUNDS_CONFIG.ROUND_START_CONDITION[2] then
            return true
        end
    end
end
Package.Export("RoundStartCondition", RoundStartCondition)

function RoundEndCondition()
    if ROUNDS_CONFIG.ROUND_END_CONDITION[1] == "REMAINING_PLAYERS" then
        local count = 0
        for k, v in pairs(PLAYERS_REMAINING) do
            if (not ROUNDS_CONFIG.ROUND_END_CONDITION[3] or (ROUNDS_CONFIG.ROUND_END_CONDITION[3] and not v.BOT)) then
                count = count + 1
            end
        end
        if count <= ROUNDS_CONFIG.ROUND_END_CONDITION[2] then
            return true
        end
    elseif ROUNDS_CONFIG.ROUND_END_CONDITION[1] == "REMAINING_PLAYERS_IN_TEAM" then
        for i, v in ipairs(TEAMS_PLAYERS) do
            local count = 0
            for k2, v2 in pairs(v) do
                if v2:GetValue("RoundPlaying") then
                    if (not ROUNDS_CONFIG.ROUND_END_CONDITION[3] or (ROUNDS_CONFIG.ROUND_END_CONDITION[3] and not v2.BOT)) then
                        count = count + 1
                    end
                end
            end
            if count <= ROUNDS_CONFIG.ROUND_END_CONDITION[2][i] then
                return true
            end
        end
    elseif ROUNDS_CONFIG.ROUND_END_CONDITION[1] == "REMAINING_TEAMS" then
        local teams_remaining = 0
        for i, v in ipairs(TEAMS_PLAYERS) do
            local count = 0
            for k2, v2 in pairs(v) do
                if v2:GetValue("RoundPlaying") then
                    if (not ROUNDS_CONFIG.ROUND_END_CONDITION[3] or (ROUNDS_CONFIG.ROUND_END_CONDITION[3] and not v2.BOT)) then
                        count = count + 1
                    end
                end
            end
            if count ~= 0 then
                teams_remaining = teams_remaining + 1
            end
        end
        if teams_remaining <= ROUNDS_CONFIG.ROUND_END_CONDITION[2] then
            return true
        end
    end
end
Package.Export("RoundEndCondition", RoundEndCondition)

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

        ROUNDS_CALL_EVENT("RoundPlayerOut", ply)

        if ROUNDS_CONFIG.PLAYER_OUT_ACTION[1] == "WAITING" then
            WaitingAction(ply)
        elseif ROUNDS_CONFIG.PLAYER_OUT_ACTION[1] == "RESPAWN" then
            SpawnPlayer(ply)
        end

        if RoundEndCondition() then
            RoundEnd()
        end
    end
end
Package.Export("RoundsPlayerOut", RoundsPlayerOut)

function HandlePlayerJoin(ply, more_joining)
    --print("HandlePlayerJoin", ply)
    local players_count = table_count(PLAYERS_JOINED)
    if (not ROUNDS_CONFIG.MAX_PLAYERS or players_count + 1 <= ROUNDS_CONFIG.MAX_PLAYERS) then
        --print(ply, ROUNDS_CONFIG)
        Events.CallRemote("SyncRoundsConfig", ply, ROUNDS_CONFIG)

        table.insert(PLAYERS_JOINED, ply)
        ROUNDS_CALL_EVENT("RoundPlayerJoined", ply)
        if not ROUND_RUNNING then
            if RoundStartCondition() then
                if not ROUND_RESTART_TIMEOUT then
                    if not more_joining then
                        if not ROUNDS_CONFIG.LOBBY_CONFIG then
                            RoundStart()
                        else
                            LobbyStart()
                        end
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
Package.Export("HandlePlayerJoin", HandlePlayerJoin)

function PackageLoadFunc()
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
end
Package.Export("PackageLoadFunc", PackageLoadFunc)

if not ROUNDS_CONFIG.OVERRIDE_LOAD_EVENT then
    Package.Subscribe("Load", PackageLoadFunc)
else
    Events.Subscribe(ROUNDS_CONFIG.OVERRIDE_LOAD_EVENT[1], PackageLoadFunc)
end

function HandlePlayerDestroy(ply)
    if ply:IsValid() then
        local char = ply:GetControlledCharacter()
        if char then
            char:Destroy()
        end
    end

    for k, v in pairs(PLAYERS_JOINED) do
        if v == ply then
            PLAYERS_JOINED[k] = nil
            --table.remove(PLAYERS_JOINED, k)
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

    if ((not Generating_teams) or (not ply.BOT)) then
        if RoundEndCondition() then
            RoundEnd()
        end

        if LOBBY_TIMEOUT then
            if not RoundStartCondition() then
                LobbyEnd()
            end
        end
    end
end
Player.Subscribe("Destroy", HandlePlayerDestroy)
if VBot then
    VBot.Subscribe("Destroy", HandlePlayerDestroy)
end

Character.Subscribe("Death", function(char, ...)
    local ply = char:GetPlayer()
    if ply then
        if ROUNDS_CONFIG.PLAYER_OUT_CONDITION[1] == "DEATH" then
            ROUNDS_CALL_EVENT("RoundPlayerOutDeath", char, ...)
            if ROUNDS_CONFIG.PLAYER_OUT_CONDITION[2] <= 0 then
                RoundsPlayerOut(ply)
            else
                Timer.SetTimeout(function()
                    if ply:IsValid() then
                        RoundsPlayerOut(ply)
                    end
                end, ROUNDS_CONFIG.PLAYER_OUT_CONDITION[2])
            end
        end
    end
end)



Package.Export("ROUNDS_CONFIG", nil)

Package.Require("Sh_Funcs.lua")

ROUNDS_Special_Serverside_Config = {}

function INIT_ROUNDS(Config_Tbl)
    Package.Export("ROUNDS_CONFIG", Config_Tbl)

    if ROUNDS_CONFIG.SPAWNING then
        if not ROUNDS_CONFIG.SPAWNING[3] then
            ROUNDS_CONFIG.SPAWNING[3] = "ROUNDSTART_SPAWN"
        end
    end

    if ROUNDS_CONFIG.PLAYER_OUT_CONDITION then
        if ROUNDS_CONFIG.PLAYER_OUT_CONDITION[1] == "DEATH" then
            if not ROUNDS_CONFIG.PLAYER_OUT_CONDITION[2] then
                ROUNDS_CONFIG.PLAYER_OUT_CONDITION[2] = 0
            end
        end
    end

    if ROUNDS_CONFIG.ROUND_TEAMS then
        if type(ROUNDS_CONFIG.ROUND_TEAMS[3]) == "function" then
            ROUNDS_Special_Serverside_Config.teams_count_func = ROUNDS_CONFIG.ROUND_TEAMS[3]
            ROUNDS_CONFIG.ROUND_TEAMS[3] = nil
        end
    end

    if ROUNDS_CONFIG.SPAWNING then
        if ROUNDS_CONFIG.SPAWNING[1] == "TEAM_SPAWNS" then
            Console.Warn("SPAWNING TEAM_SPAWNS Deprecated, use PER_TEAM_CONFIG SPAWNING instead")

            if not ROUNDS_CONFIG.PER_TEAM_CONFIG then
                ROUNDS_CONFIG.PER_TEAM_CONFIG = {}
            end

            for i, v in ipairs(ROUNDS_CONFIG.SPAWNING[2]) do
                if not ROUNDS_CONFIG.PER_TEAM_CONFIG[i] then
                    ROUNDS_CONFIG.PER_TEAM_CONFIG[i] = {}
                end

                if not ROUNDS_CONFIG.PER_TEAM_CONFIG[i].SPAWNING then
                    ROUNDS_CONFIG.PER_TEAM_CONFIG[i].SPAWNING = {"SPAWNS", v, ROUNDS_CONFIG.SPAWNING[3]}
                end
            end

            ROUNDS_CONFIG.SPAWNING = nil
        end
    end

    if not ROUNDS_CONFIG.WAITING_ACTION then
        Console.Warn("Missing Root ROUNDS_CONFIG WAITING_ACTION, you should always need one")
    end

    Package.Require("Rounds.lua")

    return true
end
Package.Export("INIT_ROUNDS", INIT_ROUNDS)
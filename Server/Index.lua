
Package.Export("ROUNDS_CONFIG", nil)

ROUNDS_Special_Serverside_Config = {}

function INIT_ROUNDS(Config_Tbl)
    ROUNDS_CONFIG = Config_Tbl

    if ROUNDS_CONFIG.SPAWN_POSSESS then
        if not ROUNDS_CONFIG.SPAWN_POSSESS[2] then
            ROUNDS_CONFIG.SPAWN_POSSESS[2] = {}
        end
    end

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

    Package.Require("Rounds.lua")

    return true
end
Package.Export("INIT_ROUNDS", INIT_ROUNDS)

ROUNDS_CONFIG = nil

function INIT_ROUNDS(Config_Tbl)
    ROUNDS_CONFIG = Config_Tbl
    if (ROUNDS_CONFIG.ROUND_TEAMS and type(ROUNDS_CONFIG.ROUND_TEAMS[1]) == "table") then
        local new_tbl = {"AUTO_BALANCED", "ROUNDSTART_GENERATION", ROUNDS_CONFIG.ROUND_TEAMS}
        ROUNDS_CONFIG.ROUND_TEAMS = new_tbl
        Package.Warn("Using deprecated ROUND_TEAMS structure, please update it")
    end

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

    Package.Require("Rounds.lua")

    return true
end
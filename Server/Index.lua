
ROUNDS_CONFIG = nil

function INIT_ROUNDS(Config_Tbl)
    ROUNDS_CONFIG = Config_Tbl

    Package.Require("Rounds.lua")

    return true
end
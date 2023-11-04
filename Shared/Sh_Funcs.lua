

function GetTeamConfigValue(team, key)
    if type(team) == "number" then
        if ROUNDS_CONFIG.PER_TEAM_CONFIG then
            if ROUNDS_CONFIG.PER_TEAM_CONFIG[team] then
                if ROUNDS_CONFIG.PER_TEAM_CONFIG[team][key] ~= nil then
                    return ROUNDS_CONFIG.PER_TEAM_CONFIG[team][key]
                end
            end
        end
    end
    return ROUNDS_CONFIG[key]
end
Package.Export("GetTeamConfigValue", GetTeamConfigValue)

function GetTeamConfigValueWBool(team, key)
    if type(team) == "number" then
        if ROUNDS_CONFIG.PER_TEAM_CONFIG then
            if ROUNDS_CONFIG.PER_TEAM_CONFIG[team] then
                if ROUNDS_CONFIG.PER_TEAM_CONFIG[team][key] ~= nil then
                    return ROUNDS_CONFIG.PER_TEAM_CONFIG[team][key], true
                end
            end
        end
    end
    return ROUNDS_CONFIG[key], false
end
Package.Export("GetTeamConfigValueWBool", GetTeamConfigValueWBool)


function shuffle_table_w_number_indexes(tbl)
    for i = #tbl, 2, -1 do
      local j = math.random(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end
Package.Export("shuffle_table_w_number_indexes", shuffle_table_w_number_indexes)

function TableRandomIndexes(t) -- Only with numbers indexes
    local r_indexes = {}
    for k, _ in pairs(t) do
        table.insert(r_indexes, k)
    end
    shuffle_table_w_number_indexes(r_indexes)

    return r_indexes
end
Package.Export("TableRandomIndexes", TableRandomIndexes)

function Random_Reorder_Table(tbl)
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
Package.Export("Random_Reorder_Table", Random_Reorder_Table)

function TableUnpackWithNilDetection(t)
    if type(t) == "nil" then
        return nil
    elseif type(t) == "table" then
        return table.unpack(t)
    else
        error("Wrong passed param type in TableUnpackWithNilDetection, expected table or nil")
    end
end
Package.Export("TableUnpackWithNilDetection", TableUnpackWithNilDetection)
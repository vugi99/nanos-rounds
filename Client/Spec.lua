
--print("Spec.lua")
Package.Export("Spectating_Player", nil)


local function LocalPlayerTeam()
    --[[local p_team = Client.GetLocalPlayer():GetValue("PlayerTeam")
    if not p_team then
        return last_player_team
    end
    return p_team]]--

    if Client.GetLocalPlayer() then
        return Client.GetLocalPlayer():GetValue("RoundSpectating")
    end
end

function GetResetPlyID(old_ply_id, prev_ply)
    local Team = LocalPlayerTeam()
    local selected_ply_id
    local selected_ply
    local team_wa = GetTeamConfigValue(Team, "WAITING_ACTION")
    for k, v in pairs(Player.GetPairs()) do
        if (v ~= Client.GetLocalPlayer() and not v.BOT) then
            if v:GetID() ~= old_ply_id then
                local playing = v:GetValue("RoundPlaying")
                if playing then
                    if (Team == v:GetValue("PlayerTeam") or Team == true or (team_wa and team_wa[2])) then
                        if (not selected_ply_id or ((v:GetID() < selected_ply_id and not prev_ply) or (v:GetID() > selected_ply_id and prev_ply))) then
                            if v ~= Spectating_Player then
                                selected_ply_id = v:GetID()
                                selected_ply = v
                            end
                        end
                    end
                end
            end
        end
    end
    return selected_ply
end

function GetNewPlayerToSpec(old_ply_id, prev_ply)
    old_ply_id = old_ply_id or 0
    local Team = LocalPlayerTeam()
    local new_ply
    local new_ply_id
    local team_wa = GetTeamConfigValue(Team, "WAITING_ACTION")
    for k, v in pairs(Player.GetPairs()) do
        if (v ~= Client.GetLocalPlayer() and not v.BOT) then
            local playing = v:GetValue("RoundPlaying")
            if playing then
                if (Team == v:GetValue("PlayerTeam") or Team == true or (team_wa and team_wa[2])) then
                    if (((v:GetID() > old_ply_id and not new_ply_id and not prev_ply) or (v:GetID() < old_ply_id and not new_ply_id and prev_ply)) or (((v:GetID() > old_ply_id and not prev_ply) or (v:GetID() < old_ply_id and prev_ply)) and ((new_ply_id > v:GetID() and not prev_ply) or (new_ply_id < v:GetID() and prev_ply)))) then
                        if v ~= Spectating_Player then
                            new_ply = v
                            new_ply_id = v:GetID()
                        end
                    end
                end
            end
        end
    end
    if not new_ply then
        new_ply = GetResetPlyID(old_ply_id, prev_ply)
    end
    return new_ply
end

function StartSpectating(new_spec)
    if (new_spec and new_spec:IsValid()) then
        Client.GetLocalPlayer():Spectate(new_spec)
        Package.Export("Spectating_Player", new_spec)
    end
end

function StopSpectating()
    if (Spectating_Player ~= nil) then
        Client.GetLocalPlayer():ResetCamera()
        Package.Export("Spectating_Player", nil)
    end
end

Player.Subscribe("ValueChange", function(ply, key, value)
    if ply:IsValid() then
        if key == "RoundSpectating" then
            local team_wa = GetTeamConfigValue(LocalPlayerTeam(), "WAITING_ACTION")
            if (team_wa and team_wa[1] == "SPECTATE_REMAINING_PLAYERS") then
                -- Spectate end for ply
                if not value then
                    if ply == Client.GetLocalPlayer() then
                        StopSpectating()
                    end
                -- Spec start for ply
                else
                    if ply == Client.GetLocalPlayer() then
                        local new_spec = GetNewPlayerToSpec()
                        StartSpectating(new_spec)
                    elseif ply == Spectating_Player then
                        local new_spec = GetNewPlayerToSpec()
                        if new_spec then
                            StartSpectating(new_spec)
                        else
                            StopSpectating()
                        end
                    end
                end
            end
        elseif key == "RoundPlaying" then
            if value then
                -- Spec player that started playing if we aren't spectating cuz there was no player to spec before (after additional checks)
                if (ply ~= Client.GetLocalPlayer() and (not Spectating_Player) and (Client.GetLocalPlayer():GetValue("RoundSpectating"))) then
                    local new_spec = GetNewPlayerToSpec()
                    StartSpectating(new_spec)
                end
            end
        end
    end
end)

Player.Subscribe("Destroy", function(ply)
    --print("Player Destroy")
    if ply == Spectating_Player then
        local new_spec = GetNewPlayerToSpec()
        if new_spec then
            StartSpectating(new_spec)
        else
            StopSpectating()
        end
    end
end)

Input.Register("SpectatePrev", "Left")
Input.Register("SpectateNext", "Right")

Input.Bind("SpectatePrev", InputEvent.Pressed, function()
    if Spectating_Player then
        local new_spec = GetNewPlayerToSpec(Spectating_Player:GetID(), true)
        StartSpectating(new_spec)
    end
end)

Input.Bind("SpectateNext", InputEvent.Pressed, function()
    if Spectating_Player then
        local new_spec = GetNewPlayerToSpec(Spectating_Player:GetID())
        StartSpectating(new_spec)
    end
end)

Package.Export("ROUNDS_CONFIG", nil)

Package.Require("Sh_Funcs.lua")

Package.Subscribe("Load", function()
    Package.Require("Spec.lua")

    Console.Log("Rounds " .. tostring(Package.GetVersion()) .. " loaded")
end)

Events.SubscribeRemote("SyncRoundsConfig", function(config)
    Package.Export("ROUNDS_CONFIG", config)
end)
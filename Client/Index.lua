
Package.Export("ROUNDS_CONFIG", nil)

Package.Subscribe("Load", function()
    Package.Require("Spec.lua")
end)

Events.SubscribeRemote("SyncRoundsConfig", function(config)
    ROUNDS_CONFIG = config
end)
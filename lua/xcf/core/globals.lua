local XCF = XCF

do -- Player loaded hook
	-- PlayerInitialSpawn isn't reliable when it comes to network messages
	-- So we'll ask the clientside to tell us when it's actually ready to send and receive net messages
	-- For more info, see: https://wiki.facepunch.com/gmod/GM:PlayerInitialSpawn
	if SERVER then
		util.AddNetworkString("XCF_PlayerLoaded")

		net.Receive("XCF_PlayerLoaded", function(_, Player)
			hook.Run("XCF_OnLoadPlayer", Player)
		end)
	else
		hook.Add("InitPostEntity", "XCF Player Loaded", function()
			net.Start("XCF_PlayerLoaded")
			net.SendToServer()

			hook.Remove("InitPostEntity", "XCF Player Loaded")
		end)
	end
end
GTetris = GTetris || {}
GTetris.LoadPath = "gtetris/"

if(CLIENT) then
	local loadOrder = {
		"library",
		"shared",
		"client",
	}
	for _, dir in ipairs(loadOrder) do
		for _, fn in ipairs(file.Find("lua/"..GTetris.LoadPath..dir.."/*.lua", "GAME")) do
			print("[GTetris] [Client] Loading "..GTetris.LoadPath..dir.."/"..fn)
			include(GTetris.LoadPath..dir.."/"..fn)
		end
	end
else
	local loadOrder = {
		"shared",
		"server",
	}
	for _, dir in ipairs(loadOrder) do
		for _, fn in ipairs(file.Find("lua/"..GTetris.LoadPath..dir.."/*.lua", "GAME")) do
			print("[GTetris] [Server] Loading "..GTetris.LoadPath..dir.."/"..fn)
			include(GTetris.LoadPath..dir.."/"..fn)
		end
	end
	local loadOrder = {
		"library",
		"shared",
		"client",
	}
	for _, dir in ipairs(loadOrder) do
		for _, fn in ipairs(file.Find("lua/"..GTetris.LoadPath..dir.."/*.lua", "GAME")) do
			AddCSLuaFile(GTetris.LoadPath..dir.."/"..fn)
		end
	end
end
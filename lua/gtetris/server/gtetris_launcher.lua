util.AddNetworkString("GTetris.OpenGame")

hook.Add("PlayerSay", "GTetris_PlayerSay", function(ply, text)
	if(string.lower(text) == "/tetris" || string.lower(text) == "!tetris") then
		net.Start("GTetris.OpenGame")
		net.Send(ply)
		return ""
	end
end)
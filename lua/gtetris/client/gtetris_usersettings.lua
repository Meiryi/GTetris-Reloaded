GTetris.UserData = GTetris.UserData || {}
GTetris.UserData_Default = {}
GTetris.UserData_Default.Version = "1.1"

-- Volume
GTetris.UserData.MusicVol = 1
GTetris.UserData.SFXVol = 1
GTetris.UserData.UIVol = 1

GTetris.UserData_Default.MusicVol = 1
GTetris.UserData_Default.SFXVol = 1
GTetris.UserData_Default.UIVol = 1

-- Gameplay
GTetris.UserData.BoardShaking = 1
GTetris.UserData_Default.BoardShaking = 1

-- Input
GTetris.UserData.Input_DAS = 0.167
GTetris.UserData.Input_ARR = 0.033
GTetris.UserData.Input_SDF = 10

GTetris.UserData_Default.Input_DAS = 0.167
GTetris.UserData_Default.Input_ARR = 0.033
GTetris.UserData_Default.Input_SDF = 10

GTetris.UserData.Keys = {
	Left = KEY_LEFT,
	Right = KEY_RIGHT,
	Softdrop = KEY_DOWN,
	RotateLeft = KEY_UP,
	RotateRight = KEY_Z,
	Rotate180 = KEY_A,
	Hold = KEY_C,
	Drop = KEY_SPACE,
}

GTetris.UserData_Default.Keys = {
	Left = KEY_LEFT,
	Right = KEY_RIGHT,
	Softdrop = KEY_DOWN,
	RotateLeft = KEY_UP,
	RotateRight = KEY_Z,
	Rotate180 = KEY_A,
	Hold = KEY_C,
	Drop = KEY_SPACE,
}

function GTetris.WriteUserData()
	file.Write("gtetris_reloaded/userdata.json", util.TableToJSON(GTetris.UserData, true))
end

function GTetris.LoadUserData()
	local data = file.Read("gtetris_reloaded/userdata.json", "DATA")
	if(!data) then
		GTetris.UserData = table.Copy(GTetris.UserData_Default)
		file.Write("gtetris_reloaded/userdata.json", util.TableToJSON(GTetris.UserData_Default, true))
		return
	else
		print("[GTetris] UserData Loaded")
		GTetris.UserData = util.JSONToTable(data)
		if(GTetris.UserData.Version != GTetris.UserData_Default.Version) then
			GTetris.UserData = table.Copy(GTetris.UserData_Default)
			file.Write("gtetris_reloaded/userdata.json", util.TableToJSON(GTetris.UserData_Default, true))
			print("[GTetris] UserData has been wiped due to version mismatch.")
		end
		for key, value in pairs(GTetris.UserData_Default) do
			if(GTetris.UserData[key] == nil) then
				GTetris.UserData[key] = value
			end
		end
	end
end
GTetris.LoadUserData()
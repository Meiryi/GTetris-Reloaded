function GTetris.PlayWinnerAnimSequence(winnerName, func)
	if(!IsValid(GTetris.MainUI)) then return end
	if(IsValid(GTetris.AnimLayer)) then
		GTetris.AnimLayer:Remove()
	end
	local scrw, scrh = ScrW(), ScrH()
	local timelines = {}
	local addtext = function(text, font, color, x, y, entertime, staytime, exittime, stayspeed, exitspeed, fadespeed)
		local time = SysTime()
		table.insert(timelines,{
			text = text,
			font = font,
			color = color,
			x = x,
			y = y,

			entertime = entertime,
			staytime_t = staytime,
			staytime = time + staytime,
			exittime = time + exittime,

			stayspeed = stayspeed,
			exitspeed = exitspeed,

			currentx = scrw * 1.2,
			fadespeed = fadespeed,
			alpha = 255,
		})
	end
	local tw, th = GTetris.GetTextSize("GTetris_AnimSequence2x", winnerName)
	addtext("Winner!", "GTetris_AnimSequence1x", color_white, scrw * 0.25, scrh * 0.3, nil, 0.6, 2.5, 0.5, 30, 30)
	addtext(winnerName, "GTetris_AnimSequence2x", color_white, scrw * 0.5, scrh * 0.5 - ScreenScaleH(32), SysTime() + 0.6, 0.9, 2.55, 0.33, 30, 15)
	addtext("Last player standing", "GTetris_AnimSequence3x", color_white, scrw * 0.8, scrh * 0.6, SysTime() + 1, 1.2, 2.6, 0.5, 30, 20)

	local layer = GTetris.CreatePanel(GTetris.MainUI, 0, 0, scrw, scrh, color_transparent)
		layer:MakePopup()

		layer.Time = 3
		layer.KillTime = SysTime() + layer.Time
		layer.Paint = function()
			local systime = SysTime()
			for _, text in ipairs(timelines) do
				if(text.staytime > systime) then -- entering
					if(text.entertime) then
						if(text.entertime < systime) then
							local t = text.staytime - text.entertime
							local fraction = (math.Clamp((text.staytime - systime) / t, 0, 1))
							text.currentx = Lerp(fraction, text.x, scrw * 1.2)
						end
					else
						local fraction = (math.Clamp((text.staytime - systime) / text.staytime_t, 0, 1))
						text.currentx = Lerp(fraction, text.x, scrw * 1.2)
					end
				else
					if(text.exittime > systime) then -- staying
						text.currentx = text.currentx - GTetris.GetFixedValue(text.stayspeed)
					else -- exiting
						text.currentx = text.currentx - GTetris.GetFixedValue(text.exitspeed)
						text.alpha = math.Clamp(text.alpha - GTetris.GetFixedValue(text.fadespeed), 0, 255)
					end
				end
				draw.DrawText(text.text, text.font, text.currentx, text.y, Color(text.color.r, text.color.g, text.color.b, text.alpha), TEXT_ALIGN_CENTER)
			end

			if(layer.KillTime < systime) then
				layer:Remove()
				if(func) then
					func()
				end
			end
		end
	GTetris.AnimLayer = layer
end

function GTetris.PlayStartingAnimSequence(parent, roomName)
	local scrw, scrh = ScrW(), ScrH()
	local layer = GTetris.CreatePanel(parent, 0, 0, scrw, scrh, color_transparent)

		layer.Time = 6
		layer.KillTime = SysTime() + layer.Time
		layer.LastTime = -1
		layer.CurrentScale1 = 1
		layer.CurrentScale2 = 1
		layer.RoomNameAlpha = 0
		layer.RoomNameScale = 0
		layer.Alpha = 0
		layer:NoClipping(true)
		layer.Paint = function()
			local x, y = ScrW() * 0.5, ScrH() * 0.5
			local systime = SysTime()
			if(systime > layer.KillTime) then
				layer:Remove()
				return
			end

			local timeleft = layer.KillTime - systime
			local matrix1 = Matrix()
			local matrix2 = Matrix()
			if(timeleft <= 4) then
				local t = math.floor(timeleft)
				if(t <= 0) then
					t = "GO!"
				end
				if(layer.LastTime != t) then
					layer.CurrentScale1 = 1
					layer.CurrentScale2 = 1
					layer.Alpha = 255
				end
				local tw, th = GTetris.GetTextSize("GTetris_AnimSequence4x", t)
				layer.CurrentScale1 = GTetris.IncFV(layer.CurrentScale1, -0.02, 0, 1)
				layer.CurrentScale2 = GTetris.IncFV(layer.CurrentScale2, 0.02, 0, 2)
				layer.Alpha = GTetris.IncFV(layer.Alpha, -7, 0, 255)
				matrix1:SetTranslation(Vector(scrw * 0.5, scrh * 0.5, 0))
				matrix1:SetScale(Vector(layer.CurrentScale1, layer.CurrentScale1, 1))
				cam.PushModelMatrix(matrix1)
					draw.DrawText(t, "GTetris_AnimSequence4x", 0, -th * 0.5, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
				cam.PopModelMatrix()

				matrix2:SetTranslation(Vector(scrw * 0.5, scrh * 0.5, 0))
				matrix2:SetScale(Vector(layer.CurrentScale2, layer.CurrentScale2, 1))
				cam.PushModelMatrix(matrix2)
					draw.DrawText(t, "GTetris_AnimSequence4x", 0, -th * 0.5, Color(100, 100, 100, layer.Alpha * 0.5), TEXT_ALIGN_CENTER)
				cam.PopModelMatrix()
				layer.LastTime = t
			else
				local t = timeleft - 4
				if(t > 1.3) then
					layer.RoomNameAlpha = GTetris.IncFV(layer.RoomNameAlpha, 10, 0, 255)
					layer.RoomNameScale = GTetris.IncFV(layer.RoomNameScale, 0.04, 0, 1)
				else
					if(t < 0.65) then
						layer.RoomNameAlpha = GTetris.IncFV(layer.RoomNameAlpha, -10, 0, 255)
						layer.RoomNameScale = GTetris.IncFV(layer.RoomNameScale, -0.01, 0, 1)
					end
				end
				local tw, th = GTetris.GetTextSize("GTetris_AnimSequence4x", roomName)
				local matrix = Matrix()
				matrix:SetTranslation(Vector(scrw * 0.5, scrh * 0.5, 0))
				matrix:SetScale(Vector(layer.RoomNameScale, layer.RoomNameScale, 1))
				cam.PushModelMatrix(matrix)
					draw.DrawText(roomName, "GTetris_AnimSequence4x", 0, -th * 0.5, Color(255, 255, 255, layer.RoomNameAlpha), TEXT_ALIGN_CENTER)
				cam.PopModelMatrix()
			end
		end
end

function GTetris.PlayAbortAnimSequence(winnerName)

end

net.Receive("GTetris.InitBoardLayer", function(length, sender)
	local len = net.ReadUInt(32)
	local data = net.ReadData(len)
	local roomdata = GTetris.DecompressTable(data)
	local players = {}

	if(IsValid(GTetris.MuliplayerPanel)) then
		GTetris.MuliplayerPanel.Hide = true
	end

	for _, ply in ipairs(player.GetAll()) do
		players[ply:GetCreationID()] = ply
	end
	local BaseUI = GTetris.MainUI
	local layer = GTetris.SetupBoardLayer(BaseUI)
	layer.Multiplayer = true
	layer.InputBlockTime = SysTime() + 5
	GTetris.PlayStartingAnimSequence(layer.AnimLayer, roomdata.roomName)
	GTetris.AddBackButton(layer.AnimLayer, function()
		layer.Exiting = true
		if(IsValid(GTetris.MuliplayerPanel)) then
			GTetris.MuliplayerPanel.Hide = false
		end
		net.Start("GTetris.AbortGame")
		net.SendToServer()
	end, true)
	GTetris.ApplyRulesets(roomdata.ruleset)

	for _, ply in pairs(roomdata.players) do
		local player = players[ply.playerID]
		if(ply.Bot) then
		else
			if(player == LocalPlayer()) then
				local id = tostring(ply.playerID)
				local board = GTetris.CreateBoard(id, true)
				layer.LocalPlayerID = id
				board.PlayerNick = ply.nick
			else
				local id = tostring(ply.playerID)
				local board = GTetris.CreateBoard(id)
				board.PlayerNick = ply.nick
			end
		end
	end

	GTetris.SortBoards(true)
end)

net.Receive("GTetris.SendAttack", function(length, sender)
	
end)
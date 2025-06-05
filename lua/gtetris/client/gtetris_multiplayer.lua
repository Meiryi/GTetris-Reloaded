GTetris.RoomData = GTetris.RoomData || {
	host = nil,
	roomname = "null",
	maxplayers = 4,
	players = {},
	spectators = {},
}

local buttons = {
	{
		title = "Create Rooms",
		func = function(ui)
			net.Start("GTetris.CreateRoom")
			net.SendToServer()
			GTetris.WaitingIndicator()
		end,
	},
	{
		title = "Refresh",
		func = function(ui)
			net.Start("GTetris.GetRooms")
			net.SendToServer()
			GTetris.WaitingIndicator()
		end,
	},
}

function GTetris.ResetRoomData()
	GTetris.RoomData = {
		host = nil,
		roomname = "null",
		maxplayers = 4,
		players = {},
		spectators = {},
	}
end

function GTetris.IsRoomHost()
	return GTetris.RoomData.host == LocalPlayer():GetCreationID()
end

function GTetris.SendVarModify(pointer, val, type)
	net.Start("GTetris.ModifyVars")
	net.WriteString(pointer)
	net.WriteInt(type, 6)
	GTetris.WriteFuncs[type](val)
	net.SendToServer()
end

function GTetris.SyncRoomData()
	net.Start("GTetris.SyncRoomData")
	net.WriteString(GTetris.RoomData.roomname)
	net.WriteInt(GTetris.RoomData.maxplayers, 32)
	net.SendToServer()
end

function GTetris.MultiplayerUI(ui)
	if(IsValid(GTetris.MuliplayerPanel)) then
		GTetris.MuliplayerPanel:Remove()
	end
	local scrw, scrh = ScrW(), ScrH()
	local scale = 0.115
	local gap = ScreenScaleH(6)
	local base = GTetris.CreatePanel(ui, scrw * scale, scrh * scale, scrw * (1 - scale * 2), scrh * (1 - scale * 2), Color(25, 25, 25, 255))
	local startX = gap
	local btnWide = base:GetWide() * 0.175
	local btnTall = base:GetTall() * 0.07
	for _, button in ipairs(buttons) do
		local btn = GTetris.CreatePanel(base, startX, gap, btnWide, btnTall, Color(15, 15, 15, 255))
		local _, _, title = GTetris.CreateLabel(btn, btn:GetWide() * 0.5, btn:GetTall() * 0.5, button.title, "GTetris_UIFontMedium", Color(255, 255, 255, 255))
			title.CentPos()
			btn.Paint2x = function()
				surface.SetDrawColor(200, 200, 200, 255)
				surface.DrawOutlinedRect(0, 0, btn:GetWide(), btn:GetTall(), ScreenScaleH(1))
			end
			GTetris.ApplyIButton(btn, function()
				button.func(ui)
			end)

		startX = startX + btn:GetWide() + gap
	end

	base.RoomList = GTetris.CreateScroll(base, gap, gap * 2 + btnTall, base:GetWide() - (gap * 2), base:GetTall() - ((gap * 3) + btnTall), Color(20, 20, 20, 255))
	base.RoomList.ReloadList = function(list)
		local gap = ScreenScaleH(2)
		base.RoomList:Clear()
		for _, room in ipairs(list) do
			local base = GTetris.CreatePanel(base.RoomList, 0, 0, base.RoomList:GetWide(), base.RoomList:GetTall() * 0.125, Color(30, 30, 30, 255))
				base:Dock(TOP)
				base:DockMargin(0, 0, 0, ScreenScaleH(2))
				local _, _, name = GTetris.CreateLabel(base, gap, base:GetTall() * 0.5, room.name, "GTetris_LobbyMedium2x", Color(255, 255, 255, 255))
					name.CentVer()
					local _, _, count = GTetris.CreateLabel(base, gap, base:GetTall() * 0.5, room.players.." / "..room.maxplayers, "GTetris_LobbyMedium2x", Color(255, 255, 255, 255))
						count.CentVer()
						count:SetX(base:GetWide() - (count:GetWide() + gap * 3))

					GTetris.ApplyIButton(base, function()
						net.Start("GTetris.JoinRoom")
						net.WriteString(room.roomid)
						net.SendToServer()
						GTetris.WaitingIndicator()
					end)
		end
	end

	base.Hide = false
	base.Alpha = 0
	base.Think = function()
		if(!base.Hide) then
			base.Alpha = GTetris.IncFV(base.Alpha, 15, 0, 255)
		else
			base.Alpha = GTetris.IncFV(base.Alpha, -15, 0, 255)
		end
		base:SetAlpha(base.Alpha)
	end

	GTetris.MuliplayerPanel = base
	GTetris.MuliplayerBaseUI = ui

	net.Start("GTetris.GetRooms")
	net.SendToServer()
	GTetris.WaitingIndicator()
end

net.Receive("GTetris.GetRooms", function(length, sender)
	local len = net.ReadUInt(32)
	local data = net.ReadData(len)
	local roomlist = GTetris.DecompressTable(data, len)
	if(!IsValid(GTetris.MuliplayerPanel)) then
		return
	end
	GTetris.MuliplayerPanel.RoomList.ReloadList(roomlist)
	GTetris.RespondWaiting()
end)

function GTetris.AddNotify(title, desc)
	if(IsValid(GTetris.NotifyPanel)) then
		GTetris.NotifyPanel:Remove()
	end
	local scrw, scrh = ScrW(), ScrH()
	local scale = 0.33
	local gap = ScreenScaleH(4)
	local base = GTetris.CreatePanel(GTetris.MainUI, 0, 0, scrw, scrh, Color(0, 0, 0, 225))
	local inner = GTetris.CreatePanel(base, scrw * scale, scrh * scale, scrw * (1 - scale * 2), scrh * (1 - scale * 2), Color(25, 25, 25, 255))
	local header = GTetris.CreatePanel(inner, 0, 0, inner:GetWide(), inner:GetTall() * 0.15, Color(22, 22, 22, 255))
	GTetris.CreateLabel(header, gap, gap, title, "GTetris_NotifyTitle", Color(255, 255, 255, 255))
	GTetris.CreateLabel(inner, gap, gap + header:GetTall(), desc, "GTetris_NotifyDesc", Color(255, 255, 255, 255))

	local btnTall = inner:GetTall() * 0.15
	local btn = GTetris.CreatePanel(inner, 0, inner:GetTall() - btnTall, inner:GetWide(), btnTall, Color(17, 17, 17, 255))
	local _, _, confirm = GTetris.CreateLabel(btn, btn:GetWide() * 0.5, btn:GetTall() * 0.5, "OK", "GTetris_NotifyTitle", Color(255, 255, 255, 255))
		confirm.CentPos()
	GTetris.ApplyIButton(btn, function()
		base.Exiting = true
	end)

	base.Alpha = 0
	base.Think = function()
		if(!base.Exiting) then
			base.Alpha = GTetris.IncFV(base.Alpha, 15, 0, 255)
		else
			base.Alpha = GTetris.IncFV(base.Alpha, -15, 0, 255)
			if(base.Alpha <= 0) then
				base:Remove()
				return
			end
		end
		base:SetAlpha(base.Alpha)
	end
	GTetris.NotifyPanel = base
end

net.Receive("GTetris.Notify", function(length, sender)
	local title = net.ReadString()
	local desc = net.ReadString()
	if(!IsValid(GTetris.MainUI)) then return end
	GTetris.AddNotify(title, desc)
end)

net.Receive("GTetris.JoinRoom", function(length, sender)
	local roomID = net.ReadString()
	if(!IsValid(GTetris.MuliplayerBaseUI) || !IsValid(GTetris.MuliplayerPanel)) then
		net.Start("GTetris.LeaveRoom")
		net.SendToServer()
		return
	end
	GTetris.DestroyLastBackButton()
	GTetris.DesiredMusic = "gtetris/ost/room.mp3"
	local _
	local ui = GTetris.MuliplayerPanel
	local scrw, scrh = ScrW(), ScrH()
	local gap = ScreenScaleH(6)
	local base = GTetris.CreatePanel(ui, 0, 0, ui:GetWide(), ui:GetTall(), Color(25, 25, 25, 255))
		base.BaseWide = ScreenScaleH(1)
		base.Exiting = false
		base.Alpha = 0
		base.CurrentWide = base.BaseWide
		base.TargetWide = ui:GetWide()
		base.Think = function()
			if(!base.Exiting) then
				base.Alpha = GTetris.IncFV(base.Alpha, 15, 0, 255)
				base.CurrentWide = GTetris.IncFV(base.CurrentWide, (base.TargetWide - base.CurrentWide) * 0.15, base.BaseWide, base.TargetWide)
			else
				base.Alpha = GTetris.IncFV(base.Alpha, -15, 0, 255)
				base.CurrentWide = GTetris.IncFV(base.CurrentWide, -base.CurrentWide * 0.15, base.BaseWide, base.TargetWide)
				if(base.Alpha <= 0) then
					base:Remove()
					return
				end
			end
			base:SetAlpha(base.Alpha)
			base:SetWide(base.CurrentWide)
		end

		local CreateHeader = function(parent, title)
			local header = GTetris.CreatePanel(parent, 0, 0, parent:GetWide(), ScreenScaleH(18), Color(10, 10, 10, 255))
			local _, _, title = GTetris.CreateLabel(header, header:GetWide() * 0.5, header:GetTall() * 0.5, title, "GTetris_LobbyHeaderSmall", Color(200, 200, 200, 255))
			header.title = title
			title.CentPos()
			return header
		end

		base.HeaderTall = ScreenScaleH(24)
		base.Header = GTetris.CreatePanel(base, 0, 0, ui:GetWide(), base.HeaderTall, Color(15, 15, 15, 255))
		_, _, base.RoomTitle = GTetris.CreateLabel(base.Header, base.Header:GetWide() * 0.5, base.Header:GetTall() * 0.5, "NULL", "GTetris_UIFontMedium", Color(200, 200, 200, 255))
		base.RoomTitle.Think = function()
			base.RoomTitle.UpdateText(GTetris.RoomData.roomname)
			base.RoomTitle.CentPos()
		end
		base.Inner = GTetris.CreatePanel(base, 0, base.HeaderTall, base:GetWide(), base:GetTall() - base.HeaderTall, Color(0, 0, 0, 0))
		local w, h = base.Inner:GetWide(), base.Inner:GetTall()
		local panelHeight = h * 0.85
		local addbot_tall = h * 0.07
		base.PlayerList = GTetris.CreatePanel(base.Inner, gap, gap, w * 0.2 - gap, panelHeight, Color(20, 20, 20, 255))
		base.PlayerList.Header = CreateHeader(base.PlayerList, "Players")
		base.PlayerList.List = GTetris.CreateScroll(
			base.PlayerList,
			0,
			base.PlayerList.Header:GetTall(),
			base.PlayerList:GetWide(),
			base.PlayerList:GetTall() - (base.PlayerList.Header:GetTall() + addbot_tall + gap * 2),
			color_transparent
		)
--[[
		base.PlayerList.Addbot = GTetris.CreatePanel(
			base.PlayerList,
			gap,
			base.PlayerList:GetTall() - addbot_tall - gap,
			base.PlayerList:GetWide() - gap * 2,
			addbot_tall,
			Color(30, 30, 30, 255)
		)
		local _base = base.PlayerList.Addbot
		local _, _, addbot = GTetris.CreateLabel(_base, _base:GetWide() * 0.5, _base:GetTall() * 0.5, "Add bot", "GTetris_NotifyDesc", Color(200, 200, 200, 255))
			addbot.CentPos()
			_base.Paint2x = function()
				surface.SetDrawColor(200, 200, 200, 255)
				surface.DrawOutlinedRect(0, 0, _base:GetWide(), _base:GetTall(), ScreenScaleH(1))
			end
			GTetris.ApplyIButton(_base, function()
				net.Start("GTetris.AddBot")
				net.SendToServer()
			end)
]]
		base.PlayerList.List.ReloadPlayers = function()
			base.PlayerList.List:Clear()
			local playerlist = {}
			for _, ply in ipairs(player.GetAll()) do
				playerlist[ply:GetCreationID()] = ply
			end
			local roomdata = GTetris.RoomData
			local players = roomdata.players
			for CID, nick in pairs(players) do
				local base = GTetris.CreatePanel(base.PlayerList.List, 0, 0, base.PlayerList.List:GetWide(), ScreenScaleH(18), Color(30, 30, 30, 255))
					base:Dock(TOP)
					base:DockMargin(0, 0, 0, ScreenScaleH(1))

					if(istable(nick)) then -- bot
						local nick = nick.name
						local avatar = GTetris.CreatePanelMatAuto(base, 0, 0, base:GetTall(), base:GetTall(), "gtetris/")
					else
						local ply = playerlist[CID]
						if(!IsValid(ply)) then
							base:Remove()
							continue
						end
						local avatar = vgui.Create("AvatarImage", base)
							avatar:SetSize(base:GetTall(), base:GetTall())
							avatar:SetPlayer(ply, 64)
							local _, _, nick = GTetris.CreateLabel(base, base:GetTall() + gap, base:GetTall() * 0.5, nick, "GTetris_LobbyHeaderSmall", Color(255, 255, 255, 255))
							nick.CentVer()
							if(CID == roomdata.host) then
								nick.UpdateText(nick:GetText().." [Host]")
							end
					end
			end
		end
		GTetris.CurrentPlayerList = base.PlayerList.List

		base.SettingsPanel = GTetris.CreatePanel(base.Inner, base.PlayerList:GetWide() + gap * 2, gap, w * 0.6 - gap * 2, panelHeight, Color(20, 20, 20, 255))
		base.SettingsPanel.Header = CreateHeader(base.SettingsPanel, "Game Settings")
		base.SettingsPanel.Scroll = GTetris.CreateScroll(base.SettingsPanel, 0, base.SettingsPanel.Header:GetTall(), base.SettingsPanel:GetWide(), base.SettingsPanel:GetTall() - base.SettingsPanel.Header:GetTall(), Color(20, 20, 20, 255))
		local sbase = base.SettingsPanel.Scroll

		GTetris.InsertOptionTitle(sbase, "Room Settings")
		GTetris.InsertOptionLine(sbase)
		local __base = GTetris.CreatePanel(sbase, 0, 0, sbase:GetWide(), sbase:GetTall() * 0.08, Color(100, 255, 255, 0))
			__base:Dock(TOP)
			__base:DockMargin(0, ScreenScaleH(2), 0, ScreenScaleH(2))
			local _, _, title = GTetris.CreateLabel(__base, ScreenScaleH(4), __base:GetTall() * 0.5, "Room Name", "GTetris_OptionsDesc", Color(200, 200, 200, 255))
				title.CentVer()
				local wide = __base:GetWide() - (title:GetX() + title:GetWide() + ScreenScaleH(8))
				local entry = GTetris.CreateTextEntry(
					__base,
					title:GetX() + title:GetWide() + ScreenScaleH(4),
					ScreenScaleH(2),
					wide,
					__base:GetTall() - ScreenScaleH(4),
					"Room's name",
					"GTetris_OptionsDesc",
					Color(200, 200, 200, 255),
					Color(50, 50, 50, 255),
					Color(10, 10, 10, 255)
				)
				entry.Alpha = 50
				entry.Paint2x = function()
					if(entry:HasFocus()) then
						entry.Alpha = GTetris.IncFV(entry.Alpha, 25, 50, 255)
					else
						entry.Alpha = GTetris.IncFV(entry.Alpha, -25, 50, 255)
					end
					surface.SetDrawColor(200, 200, 200, entry.Alpha)
					surface.DrawOutlinedRect(0, 0, entry:GetWide(), entry:GetTall(), ScreenScaleH(1))
				end
				entry.Think = function()
					entry:SetEnabled(GTetris.IsRoomHost())
					if(!entry:HasFocus()) then
						entry:SetValue(GTetris.RoomData.roomname)
					end
				end
				function entry:OnEnter(val)
					if(utf8.len(val) > 32) then
						GTetris.AddNotify("Room name too long", "Room name must be less than 32 characters")
						entry:SetValue("")
						return
					end
					if(!GTetris.IsRoomHost()) then return end
					GTetris.RoomData.roomname = val
					GTetris.SyncRoomData()
					GTetris.WaitingIndicator()
					entry:SetValue("")
				end
		GTetris.InsertValueChanger(sbase, "Max players", "RoomData->maxplayers", 2, 19, 1, function(pointer)
			GTetris.SyncRoomData()
		end)
		GTetris.InsertOptionGap(sbase, 4)
		GTetris.InsertOptionTitle(sbase, "Gameplay")
		GTetris.InsertOptionLine(sbase)
		GTetris.InsertOptionGap(sbase, 4)
		GTetris.InsertValueChanger(sbase, "Playfield Width", "Rulesets->Width", 4, 10, 1, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueChanger(sbase, "Playfield Height", "Rulesets->Height", 4, 24, 1, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueChanger(sbase, "Gravity", "Rulesets->Gravity", 0, 40, 1, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueChanger(sbase, "Autolock Time", "Rulesets->AutolockTime", 0, 10, 0.2, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_FLOAT)
		end)
		GTetris.InsertOptionGap(sbase, 4)
		GTetris.InsertOptionTitle(sbase, "Piece Generation")
		GTetris.InsertOptionLine(sbase)
		GTetris.InsertOptionGap(sbase, 4)
		GTetris.InsertValueCheckBox(sbase, "7 Bag", "Rulesets->BagSystem", GTetris.Enums.BAGSYS_7BAG, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueCheckBox(sbase, "14 Bag", "Rulesets->BagSystem", GTetris.Enums.BAGSYS_14BAG, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueCheckBox(sbase, "35 Bag", "Rulesets->BagSystem", GTetris.Enums.BAGSYS_35BAG, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueCheckBox(sbase, "Completely Random", "Rulesets->BagSystem", GTetris.Enums.BAGSYS_RANDOM, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertOptionGap(sbase, 4)
		GTetris.InsertOptionTitle(sbase, "Spins Bonus & Wallkicks")
		GTetris.InsertOptionLine(sbase)
		GTetris.InsertOptionGap(sbase, 4)
		GTetris.InsertOptionDesc(sbase, "Spins")
		GTetris.InsertValueCheckBox(sbase, "T Spins", "Rulesets->AllowedSpins", GTetris.Enums.ALLOWEDSPINS_TSPIN, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueCheckBox(sbase, "All Spins", "Rulesets->AllowedSpins", GTetris.Enums.ALLOWEDSPINS_ALL, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueCheckBox(sbase, "Everything is a spin", "Rulesets->AllowedSpins", GTetris.Enums.ALLOWEDSPINS_STUPID, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueCheckBox(sbase, "None", "Rulesets->AllowedSpins", GTetris.Enums.ALLOWEDSPINS_NONE, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertOptionDesc(sbase, "Wallkicks")
		GTetris.InsertValueCheckBox(sbase, "SRS+", "Rulesets->SpinSystem", GTetris.Enums.ROTATIONSYS_SRS, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueCheckBox(sbase, "ARS", "Rulesets->SpinSystem", GTetris.Enums.ROTATIONSYS_ARS, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueCheckBox(sbase, "Classic", "Rulesets->SpinSystem", GTetris.Enums.ROTATIONSYS_CLS, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertOptionGap(sbase, 4)
		GTetris.InsertOptionTitle(sbase, "Attacks & Combo")
		GTetris.InsertOptionLine(sbase)
		GTetris.InsertOptionGap(sbase, 4)
		GTetris.InsertOptionDesc(sbase, "Combo Table")
		GTetris.InsertValueCheckBox(sbase, "Multiplier", "Rulesets->ComboTable", GTetris.Enums.COMBOTABLE_MULTIPLIER, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueCheckBox(sbase, "Increment", "Rulesets->ComboTable", GTetris.Enums.COMBOTABLE_INCREMENT, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueCheckBox(sbase, "Squaring", "Rulesets->ComboTable", GTetris.Enums.COMBOTABLE_SQUARING, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertValueCheckBox(sbase, "None", "Rulesets->ComboTable", GTetris.Enums.COMBOTABLE_NONE, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertOptionDesc(sbase, "Back to back")
		GTetris.InsertValueToggleBox(sbase, "Enable back to back charging", "Rulesets->B4BCharge", function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_BOOL)
		end)
		GTetris.InsertValueChanger(sbase, "Minimum back to back for charging", "Rulesets->B4BChargeAmount", 1, 10, 1, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertOptionDesc(sbase, "Attacks")
		GTetris.InsertValueChanger(sbase, "Attack multiplier", "Rulesets->AttackMultiplier", 0.5, 100, 0.5, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_FLOAT)
		end)
		GTetris.InsertValueChanger(sbase, "Attack arrive time", "Rulesets->AttackArriveTime", 0.1, 5, 0.1, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_FLOAT)
		end)
		GTetris.InsertValueChanger(sbase, "Attack apply delay", "Rulesets->AttackApplyDelay", 0.1, 5, 0.1, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_FLOAT)
		end)
		GTetris.InsertValueChanger(sbase, "Attack cap", "Rulesets->AttackCap", 1, 20, 1, function(pointer, newValue)
			GTetris.SendVarModify(pointer, newValue, GTetris.DataType_INT)
		end)
		GTetris.InsertOptionGap(sbase, 8)

		local entryTall = base.SettingsPanel:GetTall() * 0.07
		base.Chat = GTetris.CreatePanel(base.Inner, base.PlayerList:GetWide() + base.SettingsPanel:GetWide() + gap * 3, gap, w * 0.2 - gap, panelHeight, Color(20, 20, 20, 255))
		base.Chat.Header = CreateHeader(base.Chat, "Chat")
		base.Chat.ChatScroll = GTetris.CreateScroll(
			base.Chat,
			0,
			base.Chat.Header:GetTall(),
			base.Chat:GetWide(),
			base.Chat:GetTall() - (entryTall + gap * 2 + base.Chat.Header:GetTall()),
			color_transparent
		)
		local entry = GTetris.CreateTextEntry(base.Chat, gap, base.Chat:GetTall() - (entryTall + gap), base.Chat:GetWide() - gap * 2, entryTall, "Type something..", "GTetris_ChatFont", Color(200, 200, 200, 255), Color(100, 100, 100, 255), Color(10, 10, 10, 255))
		entry.Alpha = 50
		entry.Paint2x = function()
			if(entry:HasFocus()) then
				entry.Alpha = GTetris.IncFV(entry.Alpha, 25, 50, 255)
			else
				entry.Alpha = GTetris.IncFV(entry.Alpha, -25, 50, 255)
			end
			surface.SetDrawColor(200, 200, 200, entry.Alpha)
			surface.DrawOutlinedRect(0, 0, entry:GetWide(), entry:GetTall(), ScreenScaleH(1))
		end
		local _, _, textlimit = GTetris.CreateLabel(base.Chat, gap * 1.5, base.Chat:GetTall() - (entryTall + gap), "0/64", "GTetris_ChatFont", Color(200, 200, 200, 255))
			textlimit:SetY(textlimit:GetY() - textlimit:GetTall())
		function entry:OnChange()
			local len = utf8.len(entry:GetValue())
			textlimit.UpdateText(len.."/64")
			if(len > 64) then
				textlimit:SetTextColor(Color(255, 55, 55, 255))
			else
				textlimit:SetTextColor(Color(200, 200, 200, 255))
			end
		end
		function entry:OnEnter(val)
			local len = utf8.len(val)
			if(len < 1) then return end
			textlimit.UpdateText("0/64")
			textlimit:SetTextColor(Color(200, 200, 200, 255))
			if(len > 64) then
				GTetris.AddNotify("Failed to send message", "Your message is too long!")
				entry:SetText("")
				return
			end
			net.Start("GTetris.Chat")
			net.WriteString(val)
			net.SendToServer()
			entry:SetText("")
		end
		local startTall = h - (panelHeight + gap * 3)
		local startWide = startTall * 7
		base.Start = GTetris.CreatePanel(base.Inner, (w - startWide) * 0.5, panelHeight + gap * 2, startWide, startTall, Color(20, 20, 20, 255))
		base.Start.Paint2x = function()
			surface.SetDrawColor(255, 255, 255, 100)
			surface.DrawOutlinedRect(0, 0, startWide, startTall, ScreenScaleH(1))
		end
		_, _, base.StartText = GTetris.CreateLabel(base.Start, startWide * 0.5, startTall * 0.5, "Start", "GTetris_UIFontMedium", Color(255, 255, 255, 255))
		base.StartText.CentPos()
		GTetris.ApplyIButton(base.Start, function()
			if(GTetris.RoomData.started) then
				net.Start("GTetris.SpectateGame")
				net.SendToServer()
				return
			end
			if(!GTetris.IsRoomHost()) then
				return
			end
			net.Start("GTetris.StartGame")
			net.SendToServer()
		end)
		base.StartText.Think = function()
			if(GTetris.RoomData.started) then
				base.StartText.UpdateText("Spectate Game")
			else
				base.StartText.UpdateText("Start")
			end
			base.StartText.CentPos()
		end

		GTetris.CurrentChatPanel = base.Chat.ChatScroll
		GTetris.CurrentRoomPanel = base

	GTetris.AddBackButton(GTetris.MuliplayerBaseUI, function()
		base.Exiting = true
		net.Start("GTetris.LeaveRoom")
		net.SendToServer()
		GTetris.ResetRoomData()
		net.Start("GTetris.GetRooms")
		net.SendToServer()
		GTetris.WaitingIndicator()
		GTetris.AddBackButton(GTetris.MuliplayerBaseUI, function()
			GTetris.ResetRulesets()
			GTetris.MainUI.SwitchScene(GTetris.UI_MAIN)
			GTetris.DesiredMusic = "gtetris/ost/menu.mp3"
		end)
		GTetris.DesiredMusic = "gtetris/ost/menu.mp3"
	end)
end)

net.Receive("GTetris.Chat", function(length, sender)
	local ply = net.ReadEntity()
	local msg = net.ReadString()
	if(!IsValid(GTetris.CurrentChatPanel)) then return end
	local ui = GTetris.CurrentChatPanel
	local gap = ScreenScaleH(2)
	local base = GTetris.CreatePanel(ui, 0, 0, ui:GetWide(), ui:GetTall() * 0.09, Color(27, 27, 27, 255))
		base:Dock(TOP)
		base:DockMargin(0, 0, 0, gap)
		local avatar = vgui.Create("AvatarImage", base)
			avatar:SetSize(base:GetTall(), base:GetTall())
			avatar:SetPlayer(ply, 64)
			local entryArea = GTetris.CreatePanel(base, base:GetTall(), 0, base:GetWide() - base:GetTall(), base:GetTall(), Color(0, 0, 0, 0))
			local entryWide = entryArea:GetWide() - gap
			local Tall = base:GetTall()
			local newStr = ""
			local checkStr = ""
			for i = 1, utf8.len(msg) do
				local char = utf8.sub(msg, i, i)
				checkStr = checkStr..char
				local tw, th = GTetris.GetTextSize("GTetris_ChatFont", checkStr)
				if(tw >= entryWide) then
					checkStr = ""
					newStr = newStr.."\n"..char
					local _, _th = GTetris.GetTextSize("GTetris_ChatFont", newStr)
					if(_th > Tall) then
						Tall = Tall + th
					end
				else
					newStr = newStr..char
				end
			end
			local offset = ScreenScaleH(4)
			local _, _, text = GTetris.CreateLabel(entryArea, gap, offset, newStr, "GTetris_ChatFont", Color(255, 255, 255, 255))
			base:SetTall(Tall + offset)
			entryArea:SetTall(Tall + offset)
end)

net.Receive("GTetris.ModifyVars", function(length, sender)
	if(!IsValid(GTetris.CurrentRoomPanel)) then return end
	local pointer = net.ReadString()
	local type = net.ReadUInt(6)
	local val = GTetris.ReadFuncs[type]()
	GTetris.SetPointerValue(GTetris, pointer, val)
end)
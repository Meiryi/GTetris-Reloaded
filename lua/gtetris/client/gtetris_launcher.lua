GTetris.MainUI = GTetris.MainUI || nil
GTetris.UI_MAIN = 1
GTetris.UI_SINGLEPLAYER = 2
GTetris.UI_MULTIPLAYER = 3
GTetris.UI_MULTIPLAYER_LOBBY = 4
GTetris.UI_SETTINGS = 5

GTetris_ButtonFuncs = {
	{
		title = "#maxplayers_1",
		icon = "gtetris/singleplayer.png",
		desc = "#gtetris.chalyours",
		func = function(ui)
			local BaseUI = ui.SetupScene(GTetris.UI_SINGLEPLAYER)
		end,
		clickfunc = function(ui)
			local BaseUI = ui.GetScene(GTetris.UI_SINGLEPLAYER)
			GTetris.ChooseCalmMusic()
			ui.SwitchScene(GTetris.UI_SINGLEPLAYER)
			GTetris.SetupBoardLayer(BaseUI)
			local board = GTetris.CreateBoard(LocalPlayer():SteamID64(), true)
			board.PlayerNick = LocalPlayer():Nick()
			GTetris.SortBoards(true)
			GTetris.AddBackButton(BaseUI, function()
				ui.SwitchScene(GTetris.UI_MAIN)
				GTetris.DestroyBoardLayer()
				GTetris.DesiredMusic = "gtetris/ost/menu.mp3"
			end)
			local localplayer = GTetris.GetLocalPlayer()
			localplayer.StartPlayingTime = SysTime()
		end,
	},
	{
		title = "#gtetris.multiplayer",
		icon = "gtetris/multiplayer.png",
		desc = "#gtetris.multiplayerdesc",
		func = function(ui)
			local BaseUI = ui.SetupScene(GTetris.UI_MULTIPLAYER)
		end,
		clickfunc = function(ui)
			local BaseUI = ui.GetScene(GTetris.UI_MULTIPLAYER)
			GTetris.MultiplayerUI(BaseUI)
			ui.SwitchScene(GTetris.UI_MULTIPLAYER)
			GTetris.AddBackButton(BaseUI, function()
				ui.SwitchScene(GTetris.UI_MAIN)
			end)
		end,
	},
	{
		title = "#spawnmenu.utilities.settings",
		icon = "gtetris/settings.png",
		desc = "#gtetris.change.gsettings",
		func = function(ui)
			local BaseUI = ui.SetupScene(GTetris.UI_SETTINGS)
		end,
		clickfunc = function(ui)
			local BaseUI = ui.GetScene(GTetris.UI_SETTINGS)
			ui.SwitchScene(GTetris.UI_SETTINGS)
			GTetris.SettingsUI(BaseUI)
			GTetris.AddBackButton(BaseUI, function()
				ui.SwitchScene(GTetris.UI_MAIN)
			end)
		end,
	},
	{
		title = "#quit",
		icon = "gtetris/quit.png",
		desc = "#gtetris.quitdesc",
		func = function(ui)

		end,
		clickfunc = function(ui)
			GTetris.MainUI:Remove()
		end,
	}
}

local logo = Material("gtetris/logo.png")
function GTetris.LaunchGame()
	if(IsValid(GTetris.MainUI)) then
		return
	end
	local scrw, scrh = ScrW(), ScrH()
	local headerTall = scrh * 0.07
	local gap = ScreenScaleH(8)
	local buttonTall = scrh * 0.12
	local ui = GTetris.CreateFrame(nil, 0, 0, scrw, scrh, Color(0, 0, 0, 225))
		ui:MakePopup()
		ui.Scenes = {}
		ui.Container = GTetris.CreatePanelContainer(ui, 0, 0, scrw, scrh, Color(0, 0, 0, 0))
		ui.Header = GTetris.CreateFrame(ui, 0, 0, scrw, headerTall, Color(25, 25, 25, 255))
		ui.Footer = GTetris.CreateFrame(ui, 0, scrh - headerTall, scrw, headerTall, Color(25, 25, 25, 255))
		ui.LogoSize = scrh * 0.215
		
		ui.SetupScene = function(sceneid)
			local panel = GTetris.CreatePanel(ui.Container, 0, 0, scrw, scrh, Color(0, 0, 0, 0))
			ui.Scenes[sceneid] = panel
			ui.Container.AddPanel(panel)
			return panel
		end

		ui.SwitchScene = function(sceneid)
			local scene = ui.Scenes[sceneid]
			if(IsValid(scene)) then
				ui.Container.CurrentPanel = scene
			end
		end

		ui.GetScene = function(sceneid)
			return ui.Scenes[sceneid]
		end

		ui.GetCurrentScene = function()
			return ui.Container.CurrentPanel
		end

		ui.HeaderSizes = headerTall
		ui.HeaderInc = ScreenScaleH(4)
		ui.HeaderDisplaying = true
		ui.Think = function()
			if(ui.HeaderDisplaying) then
				ui.HeaderSizes = GTetris.IncFV(ui.HeaderSizes, ui.HeaderInc, 0, headerTall)
			else
				ui.HeaderSizes = GTetris.IncFV(ui.HeaderSizes, -ui.HeaderInc, 0, headerTall)
			end
			ui.Header:SetTall(ui.HeaderSizes)
			ui.Footer:SetTall(ui.HeaderSizes)
			ui.Footer:SetY(scrh - ui.HeaderSizes)
		end

		ui.ToggleHeaders = function(toggle)
			ui.HeaderDisplaying = toggle
		end

		local MainUI = ui.SetupScene(GTetris.UI_MAIN)
		ui.SwitchScene(GTetris.UI_MAIN)
		ui.Logo = GTetris.CreatePanelMatAuto(MainUI, (scrw - ui.LogoSize) * 0.5, scrh * 0.125, ui.LogoSize, ui.LogoSize, "gtetris/logo.png", color_white)

		local StartY = ui.Logo:GetY() + ui.Logo:GetTall() + ScreenScaleH(16)
		local StartX = scrh * 0.33
		local maxoffset = ScreenScaleH(70)
		local offset_step = ScreenScaleH(4)
		local margin = ScreenScaleH(12)
		for index, btn in ipairs(GTetris_ButtonFuncs) do
			local base = GTetris.CreatePanel(MainUI, StartX, StartY, scrw, buttonTall, Color(30, 30, 30, 255))
			local icon = GTetris.CreatePanelMatAuto(base, margin, margin, buttonTall - margin * 2, buttonTall - margin * 2, btn.icon, color_white)
			local _, _, title = GTetris.CreateLabel(base, icon:GetX() + icon:GetWide() + gap, gap, btn.title, "GTetris_UIFontBig", color_white)
			local _, _, desc = GTetris.CreateLabel(base, icon:GetX() + icon:GetWide() + gap, GTetris.NY(title), btn.desc, "GTetris_UIFontMedium", Color(255, 255, 255, 120))
				base.Offset = 0
				btn.func(ui)
				base.ibutton = GTetris.ApplyIButton(base, function()
					GTetris_ButtonFuncs[index].clickfunc(ui)
					GTetris.Playsound("sound/gtetris/ui/click.mp3", GTetris.UserData.UIVol * 2)
				end)
				base.ibutton.Think = function()
					if(base.ibutton:IsHovered()) then
						base.Offset = GTetris.IncFV(base.Offset, (maxoffset - base.Offset) * 0.225, 0, maxoffset)
					else
						base.Offset = GTetris.IncFV(base.Offset, -base.Offset * 0.225, 0, maxoffset)
					end
					base:SetX(StartX - base.Offset)
				end
				function base.ibutton:OnCursorEntered()
					GTetris.Playsound("sound/gtetris/ui/button_tick.mp3", GTetris.UserData.UIVol * 2)
				end

			StartY = StartY + buttonTall + ScreenScaleH(4)
		end

	GTetris.DesiredMusic = "gtetris/ost/menu.mp3"
	GTetris.MainUI = ui
end

concommand.Add("gtetris", function()  
	GTetris.LaunchGame()
end)

net.Receive("GTetris.OpenGame", function()
	GTetris.LaunchGame()
end)

local printed = false
hook.Add("HUDPaint", "GTetris_Notify", function()
	local localply = LocalPlayer()
	if(printed || !IsValid(localply)) then
		return
	end
	localply:ChatPrint("[GTetris] Type '/tetris' to open the game")
	printed = true
end)

--[[
hook.Add("RenderScene", "GTetris_StopRendering", function()
	if(IsValid(GTetris.MainUI)) then
		return true
	end
end)
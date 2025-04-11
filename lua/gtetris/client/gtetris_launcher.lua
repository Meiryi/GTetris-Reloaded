GTetris.MainUI = GTetris.MainUI || nil

local buttons = {
	{
		title = "Singleplayer",
		func = function(ui)

		end,
	},
	{
		title = "Multiplayer",
		func = function(ui)

		end,
	},
	{
		title = "Settings",
		func = function(ui)

		end,
	},
}

local logo = Material("gtetris/logo.png")
function GTetris.LaunchGame()
	if(IsValid(GTetris.MainUI)) then
		GTetris.MainUI:Remove()
	end
	local scrw, scrh = ScrW(), ScrH()
	local headerTall = scrh * 0.07
	local gap = ScreenScaleH(8)
	local buttonTall = scrh * 0.1
	local ui = GTetris.CreateFrame(nil, 0, 0, scrw, scrh, Color(0, 0, 0, 225))
		ui:MakePopup()
		ui.Header = GTetris.CreateFrame(ui, 0, 0, scrw, headerTall, Color(25, 25, 25, 255))
		ui.Footer = GTetris.CreateFrame(ui, 0, scrh - headerTall, scrw, headerTall, Color(25, 25, 25, 255))
		ui.LogoSize = scrh * 0.25
		ui.Logo = GTetris.CreatePanelMatAuto(ui, (scrw - ui.LogoSize) * 0.5, scrh * 0.125, ui.LogoSize, ui.LogoSize, "gtetris/logo.png", color_white)

		ui.HeaderSizes = headerTall
		ui.HeaderDisplaying = true
		ui.Think = function()
			if(ui.HeaderDisplaying) then

			else

			end
		end

		ui.ToggleHeaders = function(toggle)
			ui.HeaderDisplaying = toggle
		end

		for _, btn in ipairs(buttons) do

		end

	GTetris.MainUI = ui
end

concommand.Add("gtetris", function()  
	GTetris.LaunchGame()
end)

net.Receive("GTetris.OpenGame", function()
	GTetris.LaunchGame()
end)
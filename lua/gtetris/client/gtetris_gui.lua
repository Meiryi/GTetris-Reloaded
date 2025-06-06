local mat = Material("gtetris/quit.png")
function GTetris.AddBackButton(parent, func, nooverride)
	local scrw, scrh = ScrW(), ScrH()
	local w, h = scrh * 0.2, scrh * 0.075
	local gap = ScreenScaleH(6)
	local base = GTetris.CreatePanel(parent, 0, scrh * 0.8, ScreenScaleH(1), h, Color(25, 25, 25, 255))
	local icon = GTetris.CreatePanelMatAuto(base, gap, gap, h - gap * 2, h - gap * 2, "gtetris/quit.png", color_white)
	local _, _, title = GTetris.CreateLabel(base, w * 0.5, h * 0.5, "Back", "GTetris_UIFontMedium2x", color_white)
	local btn = GTetris.ApplyIButton(base, function()
		base.Exiting = true
		func()
		GTetris.Playsound("sound/gtetris/ui/back.mp3", GTetris.UserData.UIVol * 4)
	end)
		title.CentPos()
		base:SetZPos(32766)
		base.TargetWide = w
		base.Wide = ScreenScaleH(1)
		base.Alpha = 255
		base.Exiting = false
		base.Paint = function()
			draw.RoundedBox(0, 0, 0, base:GetWide(), base:GetTall(), Color(25, 25, 25, 255))
			surface.SetDrawColor(255, 255, 255, 150)
			surface.DrawOutlinedRect(0, 0, base:GetWide(), base:GetTall(), ScreenScaleH(1))
			if(!base.Exiting) then
				base.Wide = GTetris.IncFV(base.Wide, (base.TargetWide - base:GetWide()) * 0.15, ScreenScaleH(1), base.TargetWide)
			else
				base.Alpha = GTetris.IncFV(base.Alpha, -20, 0, 255)
				base.Wide = GTetris.IncFV(base.Wide, -base:GetWide() * 0.15, ScreenScaleH(1), scrw * 0.2)
				if(base.Alpha <= 0) then
					base:Remove()
					return
				end
			end
			base:SetAlpha(base.Alpha)
			base:SetWide(base.Wide)
			btn:SetWide(base:GetWide())
		end
	if(!nooverride) then
		GTetris.LastBackButton = base
	end
	function btn:OnCursorEntered()
		GTetris.Playsound("sound/gtetris/ui/button_tick.mp3", GTetris.UserData.UIVol * 3)
	end
end

function GTetris.DestroyLastBackButton()
	if(!IsValid(GTetris.LastBackButton)) then return end
	GTetris.LastBackButton.Exiting = true
end

local white = Color(200, 200, 200, 255)
function GTetris.InsertOptionTitle(parent, title)
	local gap = ScreenScaleH(4)
	local _, _, title = GTetris.CreateLabel(parent, gap, gap, title, "GTetris_OptionsTitle", white)
	title:Dock(TOP)
	title:DockMargin(gap, gap, 0, ScreenScaleH(2))
end

function GTetris.InsertOptionDesc(parent, title)
	local gap = ScreenScaleH(4)
	local _, _, title = GTetris.CreateLabel(parent, gap, gap, title, "GTetris_OptionsDesc.5x", white)
	title:Dock(TOP)
	title:DockMargin(gap * 2, gap, 0, ScreenScaleH(2))
end

function GTetris.InsertOptionLine(parent)
	local gap = ScreenScaleH(4)
	local line = GTetris.CreatePanel(parent, gap, 0, parent:GetWide() - (gap * 2), ScreenScaleH(1), Color(200, 200, 200, 50))
	line:Dock(TOP)
	line:DockMargin(gap, ScreenScaleH(2), 0, ScreenScaleH(2))
end

function GTetris.InsertOptionGap(parent, height)
	local gap = ScreenScaleH(4)
	local line = GTetris.CreatePanel(parent, 0, 0, gap, ScreenScaleH(height), color_transparent)
	line:Dock(TOP)
end

local addSymbol = function(self, symbol)
	local _, _, symbol = GTetris.CreateLabel(self, self:GetWide() * 0.5, self:GetTall() * 0.5, symbol, "GTetris_OptionsDesc", Color(200, 200, 200, 255))
	symbol.CentPos()
end
local outlineFunc = function(self)
	surface.SetDrawColor(200, 200, 200, 255)
	surface.DrawOutlinedRect(0, 0, self:GetWide(), self:GetTall(), ScreenScaleH(1))
end

function GTetris.InsertValueChanger(parent, text, pointer, mins, maxs, add, func)
	local gap = ScreenScaleH(4)
	local base = GTetris.CreatePanel(parent, 0, 0, parent:GetWide() - gap * 2, ScreenScaleH(18), Color(100, 100, 255, 0))
		base:Dock(TOP)
		base:DockMargin(gap, 0, 0, ScreenScaleH(2))
		local size = base:GetTall()
		local dec = GTetris.CreatePanel(base, 0, 0, size, size, Color(15, 15, 15, 255))
		addSymbol(dec, "-")
		dec.Paint2x = outlineFunc
		dec.DASTime = 0
		dec.ARRTime = 0
		dec.OldKeyState = false
		dec.Think = function()
			if(!GTetris.IsRoomHost()) then return end
			if(dec:IsHovered()) then
				local keystate = input.IsMouseDown(MOUSE_LEFT)
				local systime = SysTime()
				local value = GTetris.GetPointerValue(GTetris, pointer)
				if(keystate && !dec.OldKeyState) then
					GTetris.SetPointerValue(GTetris, pointer, math.Round(math.Clamp(value - add, mins, maxs), 2))
					func(pointer, GTetris.GetPointerValue(GTetris, pointer))
					GTetris.Playsound("sound/gtetris/ui/click_tick.mp3", GTetris.UserData.UIVol * 3)
					dec.DASTime = systime + 0.15
				end
				if(keystate && dec.ARRTime < systime && dec.DASTime < systime) then
					GTetris.SetPointerValue(GTetris, pointer, math.Round(math.Clamp(value - add, mins, maxs), 2))
					func(pointer, GTetris.GetPointerValue(GTetris, pointer))
					dec.ARRTime = systime + 0.077
				end
				dec.OldKeyState = keystate
			else
				dec.OldKeyState = false
			end
		end

		local inc = GTetris.CreatePanel(base, dec:GetX() + dec:GetWide() + gap, 0, size, size, Color(15, 15, 15, 255))
		addSymbol(inc, "+")
		inc.Paint2x = outlineFunc
		inc.DASTime = 0
		inc.ARRTime = 0
		inc.OldKeyState = false
		inc.Think = function()
			if(!GTetris.IsRoomHost()) then return end
			if(inc:IsHovered()) then
				local keystate = input.IsMouseDown(MOUSE_LEFT)
				local systime = SysTime()
				local value = GTetris.GetPointerValue(GTetris, pointer)
				if(keystate && !inc.OldKeyState) then
					GTetris.SetPointerValue(GTetris, pointer, math.Round(math.Clamp(value + add, mins, maxs), 2))
					func(pointer, GTetris.GetPointerValue(GTetris, pointer))
					GTetris.Playsound("sound/gtetris/ui/click_tick.mp3", GTetris.UserData.UIVol * 3)
					inc.DASTime = systime + 0.15
				end
				if(keystate && inc.ARRTime < systime && inc.DASTime < systime) then
					GTetris.SetPointerValue(GTetris, pointer, math.Round(math.Clamp(value + add, mins, maxs), 2))
					func(pointer, GTetris.GetPointerValue(GTetris, pointer))
					inc.ARRTime = systime + 0.077
				end
				inc.OldKeyState = keystate
			else
				inc.OldKeyState = false
			end
		end

		function inc:OnCursorEntered()
			GTetris.Playsound("sound/gtetris/ui/tick.mp3", GTetris.UserData.UIVol * 3)
		end

		function dec:OnCursorEntered()
			GTetris.Playsound("sound/gtetris/ui/tick.mp3", GTetris.UserData.UIVol * 3)
		end
		local _, _, title = GTetris.CreateLabel(base, inc:GetX() + inc:GetWide() + gap, base:GetTall() * 0.5, "", "GTetris_OptionsDesc", white)
			title.CentVer()
			title.Think = function()
				local str = text.." : "..math.Round(GTetris.GetPointerValue(GTetris, pointer), 2)
				title.UpdateText(str)
			end
end

function GTetris.InsertValueCheckBox(parent, text, pointer, value, func)
	local gap = ScreenScaleH(4)
	local innergap = ScreenScaleH(3)
	local base = GTetris.CreatePanel(parent, 0, 0, parent:GetWide() - gap * 2, ScreenScaleH(18), Color(100, 100, 255, 0))
		base:Dock(TOP)
		base:DockMargin(gap, 0, 0, ScreenScaleH(2))

		local size = base:GetTall() - innergap * 2
		local button = GTetris.CreatePanel(base, innergap, innergap, size, size, color_transparent)
		button.Paint2x = function()
			if(GTetris.GetPointerValue(GTetris, pointer) == value) then
				draw.RoundedBox(0, 0, 0, size, size, white)
			end
			outlineFunc(button)
		end
		function button:OnMousePressed()
			if(!GTetris.IsRoomHost()) then return end
			GTetris.SetPointerValue(GTetris, pointer, value)
			func(pointer, GTetris.GetPointerValue(GTetris, pointer))
			GTetris.Playsound("sound/gtetris/ui/click_tick.mp3", GTetris.UserData.UIVol * 3)
		end
		function button:OnCursorEntered()
			GTetris.Playsound("sound/gtetris/ui/tick.mp3", GTetris.UserData.UIVol * 3)
		end
		local _, _, text = GTetris.CreateLabel(base, button:GetX() + button:GetWide() + gap, base:GetTall() * 0.5, text, "GTetris_OptionsDesc", white)
			text.CentVer()
end
function GTetris.InsertValueToggleBox(parent, text, pointer, func)
	local gap = ScreenScaleH(4)
	local innergap = ScreenScaleH(3)
	local base = GTetris.CreatePanel(parent, 0, 0, parent:GetWide() - gap * 2, ScreenScaleH(18), Color(100, 100, 255, 0))
		base:Dock(TOP)
		base:DockMargin(gap, 0, 0, ScreenScaleH(2))

		local size = base:GetTall() - innergap * 2
		local button = GTetris.CreatePanel(base, innergap, innergap, size, size, color_transparent)
		button.Paint2x = function()
			if(GTetris.GetPointerValue(GTetris, pointer) == true) then
				draw.RoundedBox(0, 0, 0, size, size, white)
			end
			outlineFunc(button)
		end
		function button:OnMousePressed()
			if(!GTetris.IsRoomHost()) then return end
			GTetris.SetPointerValue(GTetris, pointer, !GTetris.GetPointerValue(GTetris, pointer))
			func(pointer, GTetris.GetPointerValue(GTetris, pointer))
			GTetris.Playsound("sound/gtetris/ui/click_tick.mp3", GTetris.UserData.UIVol * 3)
		end
		function button:OnCursorEntered()
			GTetris.Playsound("sound/gtetris/ui/tick.mp3", GTetris.UserData.UIVol * 3)
		end
		local _, _, text = GTetris.CreateLabel(base, button:GetX() + button:GetWide() + gap, base:GetTall() * 0.5, text, "GTetris_OptionsDesc", white)
			text.CentVer()
end

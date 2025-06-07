GTetris.OldRenderingMethod = true

function GTetris.InsertSpace(parent, space)
	local base = GTetris.CreatePanel(parent, 0, 0, parent:GetWide(), ScreenScaleH(space), color_transparent)
		base:Dock(TOP)
end

function GTetris.InsertLine(parent, gap)
	gap = ScreenScaleH(gap)
	local base = GTetris.CreatePanel(parent, 0, 0, parent:GetWide() - gap * 2, ScreenScaleH(1), Color(150, 150, 150, 255))
		base:Dock(TOP)
		base:DockMargin(gap, 0, 0, 0)
end

function GTetris.InsertKeybinder(parent, title, key)
	if(!parent.KeyBinders) then
		parent.KeyBinders = {}
	end
	local tall = ScreenScaleH(24)
	local base = GTetris.CreatePanel(parent, 0, 0, parent:GetWide(), tall, Color(24, 24, 24, 255))
		base:Dock(TOP)
		base:DockMargin(0, 0, 0, ScreenScaleH(2))
		base.Alpha = 0
		base.WarningTime = 0
		base.WarningAlpha = 0
		base.Binding = false
		base.Key = key

		local _, _, title = GTetris.CreateLabel(base, ScreenScaleH(4), base:GetTall() * 0.5, title, "GTetris-UIMedium.5x", color_white)
		local margin = ScreenScaleH(2)
		local w, h = base:GetWide() * 0.2, base:GetTall() - (margin * 2)
		local binder = GTetris.CreatePanel(base, base:GetWide() - (w + margin), margin, w, h, Color(18, 18, 18, 255))
		local _, _, bindtext = GTetris.CreateLabel(binder, binder:GetWide() * 0.5, binder:GetTall() * 0.5, string.upper(input.GetKeyName(GTetris.UserData.Keys[key])), "GTetris-UIMedium.5x", color_white)
		local btn = GTetris.ApplyIButton(base, function()
			if(parent.BindingTarget == base) then
				parent.BindingTarget = nil
			else
				parent.BindingTarget = base
			end
			GTetris.Playsound("sound/gtetris/ui/click_tick.mp3", GTetris.UserData.UIVol * 2)
		end)
		title.CentVer()
		bindtext.CentPos()
		btn.HoverFx = false
		function btn:OnCursorEntered()
			GTetris.Playsound("sound/gtetris/ui/tick.mp3", GTetris.UserData.UIVol * 2)
		end
		base.Paint2x = function()
			base.Binding = parent.BindingTarget == base
			if(base.Binding) then
				base.Alpha = GTetris.IncFV(base.Alpha, 3, 0, 15)
				local state = input.IsMouseDown(MOUSE_LEFT)
				if(!btn:IsHovered() && state) then
					base.Binding = false
					parent.BindingTarget = nil
				end

				bindtext.UpdateText("...")
				bindtext.CentPos()

				for i = 1, 159 do
					if(i >= 107 && i <= 113) then -- Mouse buttons
						continue
					end

					if(input.IsKeyDown(i)) then
						local canbind = true
						for pkey, pnl in pairs(parent.KeyBinders) do
							if(pnl == base) then
								continue
							end
							if(GTetris.UserData.Keys[pkey] == i) then
								pnl.WarningTime = SysTime() + 0.1
								canbind = false
								break
							end
						end
						if(canbind) then
							GTetris.UserData.Keys[key] = i
							GTetris.WriteUserData()
							parent.BindingTarget = nil
							base.Binding = false
						end
					end
				end
			else
				base.Alpha = GTetris.IncFV(base.Alpha, -3, 0, 15)
				bindtext.UpdateText(string.upper(input.GetKeyName(GTetris.UserData.Keys[key])))
				bindtext.CentPos()
			end

			if(base.WarningTime > SysTime()) then
				base.WarningAlpha = GTetris.IncFV(base.WarningAlpha, 10, 0, 50)
			else
				base.WarningAlpha = GTetris.IncFV(base.WarningAlpha, -10, 0, 50)
			end

			draw.RoundedBox(0, 0, 0, base:GetWide(), base:GetTall(), Color(255, 255, 255, base.Alpha))
			draw.RoundedBox(0, 0, 0, base:GetWide(), base:GetTall(), Color(255, 0, 0, base.WarningAlpha))
		end
	parent.KeyBinders[key] = base
end

function GTetris.InsertSlider(parent, title, key, min, max, drawfunc, updatefunc, step)
	local tall = ScreenScaleH(24)
	local base = GTetris.CreatePanel(parent, 0, 0, parent:GetWide(), tall, Color(24, 24, 24, 255))
		base:Dock(TOP)
		base:DockMargin(0, 0, 0, ScreenScaleH(2))
	local _, _, title = GTetris.CreateLabel(base, ScreenScaleH(4), base:GetTall() * 0.5, title, "GTetris-UIMedium.5x", color_white)
	title.CentVer()

	local margin = ScreenScaleH(2)
	local w, h = base:GetWide() * 0.15, base:GetTall() - (margin * 2)
	local varbase = GTetris.CreatePanel(base, base:GetWide() - (w + margin), margin, w, h, Color(10, 10, 10, 255))
	local _, _, var = GTetris.CreateLabel(varbase, varbase:GetWide() * 0.5, varbase:GetTall() * 0.5, 0, "GTetris-UIMedium.5x", color_white)
	var.Think = function()
		local val = GTetris.UserData[key]
		if(drawfunc) then
			val = drawfunc(val)
		end
		var.UpdateText(val)
		var.CentPos()
	end

	local margin2x = ScreenScaleH(4)
	local wide = base:GetWide() - GTetris.NX(title, margin2x) - (w + margin2x + margin)
	local slider = GTetris.CreatePanel(base, GTetris.NX(title, margin2x), margin2x, wide, tall - (margin2x * 2), color_transparent)
	local lineTall = ScreenScaleH(2)
	local barWide, barTall = ScreenScaleH(4), slider:GetTall()
	local y = (slider:GetTall() - lineTall) * 0.5
	local clr = Color(200, 200, 200, 255)
	local tval = max - min
	slider.LastVar = GTetris.UserData[key]
	slider.Paint2x = function()
		local fraction = math.Clamp((GTetris.UserData[key] - min) / tval, 0, 1)
		draw.RoundedBox(0, 0, y, wide, lineTall, Color(70, 70, 70, 255))
		draw.RoundedBox(0, 0, y, wide * fraction, lineTall, clr)
		draw.RoundedBox(0, wide * fraction - (barWide * 0.5), 0, barWide, barTall, clr)

		if(slider:IsHovered() && input.IsMouseDown(MOUSE_FIRST)) then
			local pos = slider:ScreenToLocal(gui.MouseX(), gui.MouseY())
			local val = math.Round(math.Clamp(pos / slider:GetWide(), 0, 1) * tval, 2) + min
			if(step) then
				if(math.abs(val - slider.LastVar) < step) then
					return
				else
					val = math.Round(val / step) * step
				end
			end
			if(slider.LastVar != val) then
				slider.LastVar = val
				GTetris.UserData[key] = val
				GTetris.WriteUserData()
				if(updatefunc) then
					updatefunc(val)
				end
			end
		end
	end
end

local buttons = {
	{
		title = "Controls",
		func = function(ui)
			GTetris.InsertKeybinder(ui, "Move left", "Left")
			GTetris.InsertLine(ui, 6)
			GTetris.InsertKeybinder(ui, "Move right", "Right")
			GTetris.InsertLine(ui, 6)
			GTetris.InsertKeybinder(ui, "Softdrop", "Softdrop")
			GTetris.InsertLine(ui, 6)
			GTetris.InsertKeybinder(ui, "Harddrop", "Drop")
			GTetris.InsertLine(ui, 6)
			GTetris.InsertKeybinder(ui, "Hold piece", "Hold")
			GTetris.InsertLine(ui, 6)
			GTetris.InsertKeybinder(ui, "Rotate clockwise", "RotateLeft")
			GTetris.InsertLine(ui, 6)
			GTetris.InsertKeybinder(ui, "Rotate counterclockwise", "RotateRight")
			GTetris.InsertLine(ui, 6)
			GTetris.InsertKeybinder(ui, "Rotate 180 degree", "Rotate180")
		end,
	},
	{
		title = "Handling",
		func = function(ui)
			--parent, title, key, min, max, drawfunc, updatefunc, step
			GTetris.InsertSlider(ui, "ARR (Auto-Repeat Rate)", "Input_ARR", 0, 0.1, function(val)
				local ms = math.Round(val * 1000, 2)
				return ms.."ms ("..(ms / 16).."f)"
			end)
			GTetris.InsertLine(ui, 6)
			GTetris.InsertSlider(ui, "DAS (Delayed Auto Shift)", "Input_DAS", 0.01, 0.35, function(val)
				local ms = math.Round(val * 1000, 2)
				return ms.."ms ("..(ms / 16).."f)"
			end)
			GTetris.InsertLine(ui, 6)
			GTetris.InsertSlider(ui, "SDF (Soft Drop Factor)", "Input_SDF", 1, 50, function(val)
				local str = val
				if(val >= 50) then
					str = "Instant"
				end
				return str
			end, nil, 1)
		end,
	},
	{
		title = "Volume & Audio",
		func = function(ui)
			GTetris.InsertSlider(ui, "Music volume", "MusicVol", 0, 2, function(val)
				return (val * 100).."%"
			end)
			GTetris.InsertLine(ui, 6)
			GTetris.InsertSlider(ui, "SFX volume", "SFXVol", 0, 2, function(val)
				return (val * 100).."%"
			end)
			GTetris.InsertLine(ui, 6)
			GTetris.InsertSlider(ui, "UI volume", "UIVol", 0, 2, function(val)
				return (val * 100).."%"
			end)
		end,
	},
	{
		title = "Gameplay",
		func = function(ui)
			GTetris.InsertSlider(ui, "Damage shakiness", "BoardShaking", 0, 3, function(val)
				return (val * 100).."%"
			end)
		end,
	},
}

function GTetris.SettingsUI(ui)
	if(IsValid(GTetris.SettingsPanel)) then
		GTetris.SettingsPanel:Remove()
	end
	local scrw, scrh = ScrW(), ScrH()
	local scale = 0.15
	local gap = ScreenScaleH(6)
	local base = GTetris.CreateScroll(ui, scrw * scale, scrh * scale, scrw * (1 - scale * 2), scrh * (1 - scale * 2), Color(0, 0, 0, 0))

	local column_tall = ScreenScaleH(32)
	local margin = ScreenScaleH(6)
	for _, data in ipairs(buttons) do
		local base = GTetris.CreatePanel(base, 0, 0, base:GetWide(), column_tall, Color(30, 30, 30, 255))
			base:Dock(TOP)
			base:DockMargin(0, 0, 0, margin)
			local inner = GTetris.CreateScroll(base, 0, column_tall, base:GetWide(), base:GetTall(), Color(0, 0, 0, 0))
			data.func(inner)

			local arrow = GTetris.CreatePanel(base, gap, gap, column_tall - gap * 2, column_tall - gap * 2, Color(23, 23, 23, 255))
			local arrowsize = arrow:GetTall() * 0.7
				base.Paint = function()
					draw.RoundedBox(0, 0, 0, base:GetWide(), base:GetTall(), Color(30, 30, 30, 255))
				end
				arrow.Paint2x = function()
					local mat = GTetris.GetCachedMaterial("gtetris/arrow_down.png")
					surface.SetDrawColor(255, 255, 255, 200)
					surface.SetMaterial(mat)
					if(base.Opened) then
						surface.DrawTexturedRectUV((arrow:GetWide() - arrowsize) * 0.5, (arrow:GetTall() - arrowsize) * 0.5, arrowsize, arrowsize, 0, 1, 1, 0)
					else
						surface.DrawTexturedRectUV((arrow:GetWide() - arrowsize) * 0.5, (arrow:GetTall() - arrowsize) * 0.5, arrowsize, arrowsize, 0, 0, 1, 1)
					end
				end

			local _, _, title = GTetris.CreateLabel(base, GTetris.NX(arrow, gap), base:GetTall() * 0.5, data.title, "GTetris_ConfirmText", color_white)
				title.CentVer()


			local btn = GTetris.ApplyIButton(base, function()
				if(base.Opened) then
					base:SetTall(column_tall)
				else
					base:SetTall(column_tall + inner:GetCanvas():GetTall())
					inner:SetTall(inner:GetCanvas():GetTall())
				end
				GTetris.Playsound("sound/gtetris/ui/click_tick.mp3", GTetris.UserData.UIVol * 2)
				base.Opened = !base.Opened
			end)

			function btn:OnCursorEntered()
				GTetris.Playsound("sound/gtetris/ui/button_tick.mp3", GTetris.UserData.UIVol * 2)
			end

			base.Opened = false
	end

	GTetris.SettingsPanel = base
end
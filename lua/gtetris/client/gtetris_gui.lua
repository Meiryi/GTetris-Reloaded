local mat = Material("gtetris/quit.png")
function GTetris.AddBackButton(parent, func)
	local scrw, scrh = ScrW(), ScrH()
	local w, h = scrh * 0.2, scrh * 0.075
	local gap = ScreenScaleH(6)
	local base = GTetris.CreatePanel(parent, 0, scrh * 0.8, ScreenScaleH(1), h, Color(25, 25, 25, 255))
	local icon = GTetris.CreatePanelMatAuto(base, gap, gap, h - gap * 2, h - gap * 2, "gtetris/quit.png", color_white)
	local _, _, title = GTetris.CreateLabel(base, w * 0.5, h * 0.5, "Back", "GTetris_UIFontMedium2x", color_white)
	local btn = GTetris.ApplyIButton(base, function()
		base.Exiting = true
		func()
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

	GTetris.LastBackButton = base
end

function GTetris.DestroyLastBackButton()
	GTetris.LastBackButton.Exiting = true
end
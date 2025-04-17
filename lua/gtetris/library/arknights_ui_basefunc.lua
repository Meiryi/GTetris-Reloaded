local m_num = 3
function GTetris_NumberSeparator(num)
    local formatted = tostring(num):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return formatted:match("^,") && formatted:sub(2) || formatted
end

function GTetris.CreateAvatar(parent, x, y, w, h, player, resolution)
    local av = vgui.Create("AvatarImage", parent)
    av:SetPos(x, y)
    av:SetSize(w, h)
    av:SetPlayer(player, resolution)
    return av
end

function GTetris.CustomPopupMenu(parent, x, y, w, h, font, color)
    local menu = GTetris.CreatePanel(nil, x, y, w, 1, color)
    menu:SetZPos(32766)
    menu:MakePopup()
    local removing = false
    local alpha = 0

    menu.TargetHeight = 0
    menu.CurrentTall = 1
    menu.AddOptions = function(opt, func)
        local btn = GTetris.CreateButton(menu, 0, 0, menu:GetWide(), h * 0.5, opt, font, Color(220, 220, 220, 255), Color(30, 30, 30, 255), function()
            removing = true
            func()
        end)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, ScreenScaleH(1))
        menu.TargetHeight = menu.TargetHeight + h * 0.5 + ScreenScaleH(1)
        btn.Alpha = 0
        btn.Paint2x = function() end
        btn.Paint = function()
            draw.RoundedBox(0, 0, 0, btn:GetWide(), btn:GetTall(), Color(30, 30, 30, 255))
            btn.Paint2x()
            if(btn:IsHovered()) then
                btn.Alpha = math.Clamp(btn.Alpha + GTetris.GetFixedValue(15), 0, 105)
            else
                btn.Alpha = math.Clamp(btn.Alpha - GTetris.GetFixedValue(15), 0, 105)
            end
            draw.RoundedBox(0, 0, 0, btn:GetWide(), btn:GetTall(), Color(255, 255, 255, btn.Alpha))
        end
        return btn
    end

    menu.Wait = true
    menu:SetAlpha(0)
    menu.Think = function()
        if(menu.Wait) then menu.Wait = false return end -- 1 Frame delay
        if(removing) then
            alpha = math.Clamp(alpha - GTetris.GetFixedValue(15), 0, 255)
            menu.CurrentTall = math.Clamp(menu.CurrentTall - GTetris.GetFixedValue(menu.CurrentTall * 0.25), 0, menu.TargetHeight)
        else
            alpha = math.Clamp(alpha + GTetris.GetFixedValue(15), 0, 255)
            menu.CurrentTall = math.Clamp(menu.CurrentTall + GTetris.GetFixedValue((menu.TargetHeight - menu.CurrentTall) * 0.25), 0, menu.TargetHeight)
        end
        if(!IsValid(parent) || !menu:HasFocus()) then
            removing = true
        end
        menu:SetTall(menu.CurrentTall)
        menu:SetAlpha(alpha)
        if(alpha <= 0 && removing) then
            menu:Remove()
        end
    end
    menu.Paint = function()
        draw.RoundedBox(0, 0, 0, menu:GetWide(), menu:GetTall(), color)
    end
    return menu
end

function GTetris.GetTextSize(font, text)
    surface.SetFont(font)
    return surface.GetTextSize(text)
end

function GTetris.CreateImage(parent, x, y, w, h, image, color) -- Don't use this, use CreatePanelMat instead, it will create a Material everytime
    if(!color) then color = color_white end
    local img = vgui.Create("DImage", parent)
        img:SetPos(x, y)
        img:SetSize(w, h)
        img:SetImage(image)
        img:SetImageColor(color)

    return img
end

function GTetris.CreatePanelContainer(parent, x, y, w, h, color)
    local pa = GTetris.CreatePanel(parent, x, y, w, h, color)
    pa.CurrentPanel = nil
    pa.Panels = {}

    pa.AddPanel = function(_pa)
        _pa.Alpha = 0
        table.insert(pa.Panels, _pa)
    end

    pa.Think = function()
        for k,v in pairs(pa.Panels) do
            if(!IsValid(v)) then continue end
            if(v == pa.CurrentPanel) then
                if(!v:IsVisible()) then
                    v:SetVisible(true)
                end
                v.Alpha = GTetris.IncFV(v.Alpha, 18, 0, 255)
                v:SetAlpha(v.Alpha)
            else
                if(v:IsVisible()) then
                    v.Alpha = GTetris.IncFV(v.Alpha, -18, 0, 255)
                    v:SetAlpha(v.Alpha)
                    if(v.Alpha <= 0) then
                        v:SetVisible(false)
                    end
                end
            end
        end
    end

    return pa
end

function GTetris.CreateFrame(parent, x, y, w, h, color)
    local panel = vgui.Create("DFrame", parent)
        panel:SetPos(x, y)
        panel:SetSize(w, h)
        panel:SetDraggable(false)
        panel:SetTitle("")
        panel:ShowCloseButton(false)
        panel:SetZPos(0)
        panel.Alpha = color.a
        panel.Paint2x = function() end
        panel.Paint = function()
            draw.RoundedBox(0, 0, 0, w, h, Color(color.r, color.g, color.b, panel.Alpha))
            panel.Paint2x()
        end
    return panel
end

function GTetris.AutoImage(parent, x, y, w, h, mat, color, time, fadespeed)
    local img = GTetris.CreatePanelMat(parent, x, y, w, h, mat, color)
    local killtime = CurTime() + time
    local alpha = color.a
    img.Paint2x = function()
        local time = CurTime()
        if(killtime < time) then
            alpha = GTetris.IncFV(alpha, -fadespeed, 0, 255)
            if(alpha <= 0) then
                img:Remove()
                return
            end
        else
            alpha = GTetris.IncFV(alpha, fadespeed, 0, 255)
        end
    end
    img.Paint = function()
        surface.SetDrawColor(color.r, color.g, color.b, alpha)
        surface.SetMaterial(img.mat)
        surface.DrawTexturedRect(0, 0, w, h)
        img.Paint2x()
    end
end

local bordershadow = Material("")
function GTetris.CreatePanelMat(parent, x, y, w, h, mat, color)
    if(!color) then color = color_white end
    local panel = vgui.Create("DPanel", parent)
        panel:SetPos(x, y)
        panel:SetSize(w, h)
        panel.mat = mat
        panel.color = color
        panel.Paint2x = function() end
        panel.Paint = function()
            surface.SetDrawColor(panel.color.r, panel.color.g, panel.color.b, panel.color.a)
            surface.SetMaterial(panel.mat)
            surface.DrawTexturedRect(0, 0, w, h)
            panel.Paint2x()
        end
    return panel
end

function GTetris.CreatePanelMatAuto(parent, x, y, w, h, mat, color)
    if(!color) then color = color_white end
    local panel = vgui.Create("DPanel", parent)
        panel:SetPos(x, y)
        panel:SetSize(w, h)
        panel.mat = GTetris.GetCachedMaterial(mat)
        panel.color = color
        panel.Paint2x = function() end
        panel.Paint = function()
            surface.SetDrawColor(panel.color.r, panel.color.g, panel.color.b, panel.color.a)
            surface.SetMaterial(panel.mat)
            surface.DrawTexturedRect(0, 0, w, h)
            panel.Paint2x()
        end
    return panel
end

function GTetris.GetGUINextPos(panel)
    return Vector(panel:GetX() + panel:GetWide(), panel:GetY() + panel:GetTall(), 0)
end

function GTetris.CreateTextEntry(parent, x, y, w, h, placeholder, font, color, pcolor, bgcolor)
    local panel = GTetris.CreatePanel(parent, x, y, w, h, bgcolor)
    local text = vgui.Create("DTextEntry", panel)
        text:SetPos(0, 0)
        text:SetSize(w, h)
        text:SetPlaceholderText(placeholder)
        text:SetPlaceholderColor(pcolor)
        text:SetPaintBackground(false)
        text:SetTextColor(color)
        text:SetFont(font)
        text.oPaint = text.Paint
        text.Paint2x = function() end
        text.Paint = function()
            text.oPaint(text)
            text.Paint2x()
        end
    return text
end

function GTetris.CreatePanel(parent, x, y, w, h, color, r)
    r = r || 0
    local panel = vgui.Create("DPanel", parent)
        panel:SetPos(x, y)
        panel:SetSize(w, h)
        panel.color = color
        panel.Paint2x = function() end
        panel.Paint = function()
            draw.RoundedBox(r, 0, 0, w, h, panel.color)
            panel.Paint2x(panel)
        end
        panel:SetZPos(0)
    return panel
end

function GTetris.CreateLabelBG(parent, x, y, text, font, color, bgcolor, mat)
    local edge_extend = ScreenScaleH(1)
    local side_margin = ScreenScaleH(2)
    local text_wide, text_tall = GTetris.GetTextSize(font, text)
    local hasmaterial = mat != nil
    local base = vgui.Create("DPanel", parent)
        base.oPos = Vector(x, y)
        base:SetPos(x, y)
        base.bgcolor = bgcolor
        local extend_wide = side_margin * 2
        if(hasmaterial) then
            extend_wide = (side_margin * 3) + text_tall
        end
        base:SetSize(text_wide + extend_wide + (edge_extend * 2), text_tall + (edge_extend * 2))
        local round = base:GetTall() * 0.2
        base.Paint = function()
            draw.RoundedBox(round, 0, 0, base:GetWide(), base:GetTall(), base.bgcolor)
        end
        local _, _, text = GTetris.CreateLabel(base, side_margin + edge_extend, edge_extend, text, font, color)
        base.text = text
        if(hasmaterial) then
            base.img = GTetris.CreatePanelMat(base, side_margin + edge_extend, edge_extend, text_tall, text_tall, mat, color)
            text:SetX(side_margin * 2 + text_tall)
        end

        base.CentHor = function()
            base:SetX(base.oPos.x - base:GetWide() * 0.5)
        end

        base.CentVer = function()
            base:SetY(base.oPos.y - base:GetTall() * 0.5)
        end

        base.CentPos = function()
            base:SetPos(base.oPos.x - base:GetWide() * 0.5, base.oPos.y - base:GetTall() * 0.5)
        end

    return base
end

function GTetris.CreateLabel(parent, x, y, text, font, color, bg, bgcolor)
    local label = vgui.Create("DLabel", parent)
        label.oPos = Vector(x, y)
        label:SetPos(x, y)
        label:SetFont(font)
        label:SetText(text)
        label:SetColor(color)
        local w, h = GTetris.GetTextSize(font, label:GetText())
        label:SetSize(w, h)

        label.CentHor = function()
            local w, h = GTetris.GetTextSize(font, label:GetText())
            label:SetPos(label.oPos.x - w / 2, label.oPos.y)
            label:SetSize(w, h)
        end

        label.CentVer = function()
            local w, h = GTetris.GetTextSize(font, label:GetText())
            label:SetPos(label.oPos.x, label.oPos.y - h / 2)
            label:SetSize(w, h)
        end

        label.CentPos = function()
            local w, h = GTetris.GetTextSize(font, label:GetText())
            label:SetPos(label.oPos.x - w / 2, label.oPos.y - h / 2)
            label:SetSize(w, h)
        end

        label.UpdateText = function(text)
            label:SetText(text)
            local w, h = GTetris.GetTextSize(font, label:GetText())
            label:SetSize(w, h)
        end

        if(bg) then
            label.oPaint = label.Paint
            label.Paint = function()
                draw.RoundedBox(0, 0, 0, label:GetWide(), label:GetTall(), bgcolor)
            end
        end

    local tw, th = GTetris.GetTextSize(font, label:GetText())
    return tw, th, label
end

function GTetris.NX(ui, gap)
    return ui:GetX() + ui:GetWide() + (gap || 0)
end

function GTetris.NY(ui, gap)
    return ui:GetY() + ui:GetTall() + (gap || 0)
end

local bgcolor = Color(10, 10, 10 ,255)
function GTetris.CreateProgressBar(parent, x, y, w, h, color, sval, cval, eval, updatefunc)
    r = r || 0
    local panel = vgui.Create("DPanel", parent)
        panel:SetPos(x, y)
        panel:SetSize(w, h)
        panel.sval = sval
        panel.cval = cval
        panel.eval = eval
        panel.hscale = 0.33
        panel.round = 0
        panel.cfrac = 0
        panel.bgclr = bgcolor
        panel.Paint2x = function() end
        panel.Paint = function()
            local frac = math.Clamp((panel.cval / panel.eval), 0, 1)
            panel.cfrac = GTetris.IncFV(panel.cfrac, (frac - panel.cfrac) * 0.2, 0, 1)
            local _w = w * panel.cfrac
            local _h = h * panel.hscale
            draw.RoundedBox(panel.round, 0, h * 0.5 - _h * 0.5, w, _h, panel.bgclr)
            draw.RoundedBox(panel.round, 0, h * 0.5 - _h * 0.5, _w, _h, color)
            panel.Paint2x()
        end
        if(updatefunc) then
            panel.Think2x = updatefunc
        end
        panel.Think = function()
            panel.Think2x(panel)
        end
        panel:SetZPos(0)
    return panel
end

function GTetris.CreateScroll(parent, x, y, w, h, color)
    local frame = vgui.Create("DScrollPanel", parent)
    frame:SetPos(x, y)
    frame:SetSize(w, h)
    frame.Paint = function() draw.RoundedBox(0, 0, 0, w, h, color) end

    frame.ScrollAmount = ScreenScaleH(64) -- You can change it with returned panel object
    frame.Smoothing = 0.2

    frame.CurrrentScroll = 0
    frame.MaximumScroll = 0 -- Don't touch this value
    frame.Panels = {}

    frame.FiltePanels = function(searchString)
        for k,v in ipairs(frame.Panels) do
            if(!IsValid(v)) then
                table.remove(frame.Panels, k)
                continue
            end
            if(!v.SortString) then continue end
            if(string.find(v.SortString, searchString)) then
                if(!frame.HideAnimation) then
                    v:SetVisible(true)
                else
                    v.Display = true
                end
            else
                if(!frame.HideAnimation) then
                    v:SetVisible(false)
                    v.Display = false
                end
            end
            local t = v:GetTall() -- So it recalculate the dock position
            v:SetTall(t - 1)
            v:SetTall(t)
        end
    end

    frame.AddPanel = function(ui)
        table.insert(frame.Panels, ui)
    end

    local DVBar = frame:GetVBar()
    local down = false
    local clr = 0

    DVBar:SetWide(ScreenScaleH(4))
    DVBar:SetX(DVBar:GetX() - DVBar:GetWide())

    DVBar.Think = function()
        frame.MaximumScroll = DVBar.CanvasSize
        if(down) then return end
        local dvscroll = DVBar:GetScroll()
        local step = frame.CurrrentScroll - dvscroll
        if(math.abs(step) > 1) then
            clr = 125
        end
        DVBar:SetScroll(dvscroll + GTetris.GetFixedValue(step * frame.Smoothing))
    end

    function frame:OnMouseWheeled(delta)
        frame.CurrrentScroll = math.Clamp(frame.CurrrentScroll + frame.ScrollAmount * -delta, 0, frame.MaximumScroll)
    end

    function DVBar:Paint(drawW, drawH)
        draw.RoundedBox(0, 0, 0, drawW, drawH, Color(0, 0, 0, 150))
    end

    function DVBar.btnUp:Paint() return end
    function DVBar.btnDown:Paint() return end

    DVBar.btnGrip.oOnMousePressed = DVBar.btnGrip.OnMousePressed
    function DVBar.btnGrip.OnMousePressed(self, code)
        down = true
        DVBar.btnGrip.oOnMousePressed(self, code)
        frame.CurrrentScroll = DVBar:GetScroll()
    end
    DVBar.oOnMousePressed = DVBar.OnMousePressed
    function DVBar.OnMousePressed(self, code)
        down = true
        DVBar.oOnMousePressed(self, code)
    end

    function DVBar.btnGrip:Paint(drawW, drawH)
        local roundWide = drawW * 0.5
        if(DVBar.btnGrip:IsHovered()) then
            clr = math.Clamp(clr + GTetris.GetFixedValue(8), 0, 80)
            if(input.IsMouseDown(107) && !down) then
                down = true
            end
        else
            clr = math.Clamp(clr - GTetris.GetFixedValue(8), 0, 80)
        end

        if(down && !input.IsMouseDown(107)) then
            down = false
        end

        if(down) then
            frame.CurrrentScroll = DVBar:GetScroll()
            clr = 125
        end

        local _color = 130 + clr
        draw.RoundedBox(roundWide, 0, 0, drawW, drawH, Color(_color, _color, _color, 255))
    end
    return frame
end

function GTetris.InvisButton(parent, x, y, w, h, func)
    local btn = vgui.Create("DButton", parent)
        btn:SetPos(x, y)
        btn:SetSize(w, h)
        btn:SetText("")
        btn.HoverFx = true
        btn.Alpha = 0
        btn.MaxAlpha = 20
        btn.Paint2x = function() end
        btn.Paint = function()
            if(btn.HoverFx) then
                if(btn:IsHovered()) then
                    btn.Alpha = GTetris.IncFV(btn.Alpha, 5, 0, btn.MaxAlpha)
                else
                    btn.Alpha = GTetris.IncFV(btn.Alpha, -5, 0, btn.MaxAlpha)
                end
            end
            draw.RoundedBox(0, 0, 0, btn:GetWide(), btn:GetTall(), Color(255, 255, 255, btn.Alpha))
            btn.Paint2x()
        end
        btn.DoClick = func
        
        return btn
end

function GTetris.ApplyIButton(parent, func)
    return GTetris.InvisButton(parent, 0, 0, parent:GetWide(), parent:GetTall(), func)
end

function GTetris.CreateButton(parent, x, y, w, h, text, font, tcolor, bcolor, func, r)
    if(!r) then r = 0 end
    local b = vgui.Create("DButton", parent)
    b:SetPos(x, y)
    b:SetSize(w, h)
    b:SetText(text)
    b:SetFont(font)
    b:SetTextColor(tcolor)
    b.Paint2x = function() end
    b.Paint = function() draw.RoundedBox(r, 0, 0, b:GetWide(), b:GetTall(), bcolor) b.Paint2x() end
    b.DoClick = func
    return b
end

function GTetris.CreateButtonOutline(parent, x, y, w, h, text, font, tcolor, color, ocolor, os, func)
    local button = vgui.Create("DPanel", parent)
        button:SetPos(x, y)
        button:SetSize(w, h)
        local tw, th = GTetris.GetTextSize(font, text)
        local _x, _y = w * 0.5, (h * 0.5) - (th * 0.5)
        button.Paint = function()
            draw.RoundedBox(0, 0, 0, w, h, ocolor)
            draw.RoundedBox(0, os, os, w - os * 2, h - os * 2, color)
            draw.DrawText(text, font, _x, _y, tcolor, TEXT_ALIGN_CENTER)
        end
        function button:OnMousePressed()
            func()
        end
    return button
end

function GTetris.CreateMatButton(parent, x, y, w, h, mat, func)
    local bg = GTetris.CreateFrame(parent, x, y, w, h, Color(0, 0, 0, 0))
    local clr = 255
    local keydown = false
    local hovered = false
    bg.mat = mat
    bg:NoClipping(false)
    bg.Paint2x = function() end
    bg.Paint = function()
        bg.Paint2x()
        surface.SetDrawColor(clr, clr, clr, 255)
        surface.SetMaterial(bg.mat)
        surface.DrawTexturedRect(0, 0, w, h)
    end
    function bg:OnMousePressed()
        func(bg)
    end
    return bg
end

function GTetris.CreateMatButtonScale(parent, x, y, w, h, mat, scale, bgColor, func)
    local bg = GTetris.CreateFrame(parent, x, y, w, h, Color(0, 0, 0, 0))
    local clr = 255
    local keydown = false
    local hovered = false
    local offsetW = (w - (w * scale)) * 0.5
    local offsetH = (h - (h * scale)) * 0.5
    local sizeW = w * scale
    local sizeH = h * scale
    bg.mat = mat
    bg:NoClipping(false)
    bg.Paint2x = function() end
    bg.Paint = function()
        draw.RoundedBox(0, 0, 0, w, h, bgColor)
        surface.SetDrawColor(clr, clr, clr, 255)
        surface.SetMaterial(bg.mat)
        surface.DrawTexturedRect(offsetW, offsetH, sizeW, sizeH)
        
        bg.Paint2x()
    end
    function bg:OnMousePressed()
        func()
    end
    return bg
end

function GTetris.CreateButtonTextIcon(parent, x, y, w, h, bgclr, text, font, color, mat2, offs, func)
    local bg = GTetris.CreateFrame(parent, x, y, w, h, bgclr)
    local clr = 255
    local keydown = false
    local hovered = false
    bg:NoClipping(false)
    local size = h * 0.5
    local icon = GTetris.CreatePanelMat(bg, 0, 0, size, size, mat2, Color(255, 255, 255, 255))
    icon:SetY((bg:GetTall() * 0.5 - size * 0.5) + offs.y)
    local textwide, texttall, text = GTetris.CreateLabel(bg, offs.x, (bg:GetTall() * 0.5) + offs.y, text, font, color)
    text.CentVer()
    local margin = ScreenScaleH(2)
    local offset = textwide + margin
    icon:SetX((bg:GetWide() * 0.5 - offset * 0.5) + offs.x)
    text:SetX(bg:GetWide() * 0.5 - ((offset * 0.5) - (icon:GetWide() + margin)))
    local btn = GTetris.InvisButton(bg, 0, 0, w, h, func)
    btn.DoClick = func
end

function GTetris.CreateMatButtonTextIcon(parent, x, y, w, h, mat1, text, font, color, mat2, offs, func)
    local bg = GTetris.CreateFrame(parent, x, y, w, h, Color(0, 0, 0, 0))
    local clr = 255
    local keydown = false
    local hovered = false
    bg:NoClipping(false)
    bg.Paint2x = function() end
    bg.Paint = function()
        surface.SetDrawColor(clr, clr, clr, 255)
        surface.SetMaterial(mat1)
        surface.DrawTexturedRect(0, 0, w, h)
        bg.Paint2x()
    end
    local size = h * 0.5
    local icon = GTetris.CreatePanelMat(bg, 0, 0, size, size, mat2, Color(255, 255, 255, 255))
    icon:SetY((bg:GetTall() * 0.5 - size * 0.5) + offs.y)
    local textwide, texttall, text = GTetris.CreateLabel(bg, offs.x, (bg:GetTall() * 0.5) + offs.y, text, font, color)
    text.CentVer()
    local margin = ScreenScaleH(2)
    local offset = textwide + margin
    icon:SetX((bg:GetWide() * 0.5 - offset * 0.5) + offs.x)
    text:SetX(bg:GetWide() * 0.5 - ((offset * 0.5) - (icon:GetWide() + margin)))
    local btn = GTetris.InvisButton(bg, 0, 0, w, h, func)
    btn.DoClick = func
end

function GTetris.CreateMatButtonText(parent, x, y, w, h, mat, text, font, color, func, bw, bh)
    local bg = GTetris.CreateFrame(parent, x, y, w, h, Color(0, 0, 0, 0))
    local clr = 255
    local keydown = false
    local hovered = false
    bg:NoClipping(false)
    bg.Paint2x = function() end
    bg.Paint = function()
        surface.SetDrawColor(clr, clr, clr, 255)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(0, 0, w, h)
        bg.Paint2x()
    end
    local btn = vgui.Create("DButton", bg)
        btn:SetSize(bw || bg:GetWide(), bh || bg:GetTall())
        btn:SetText(text)
        btn:SetFont(font)
        btn:SetTextColor(color)
        btn.Paint = function()
            return
        end
        btn.DoClick = func
end

function GTetris.CreateMatButton3D2D(parent, x, y, w, h, mat, buttonpts, func)
    local bg = GTetris.CreateFrame(parent, x, y, w, h, Color(0, 0, 0, 0))
    local clr = 255
    local keydown = false
    local hovered = false
    bg:NoClipping(false)
    bg.Paint2x = function() end
    bg.Paint = function()
        surface.SetDrawColor(clr, clr, clr, 255)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(0, 0, w, h)
        local state = input.IsMouseDown(107)
        local cx, cy = input.GetCursorPos()

        if(cx > buttonpts.x1 && cx < buttonpts.x2 && cy > buttonpts.y1 && cy < buttonpts.y2) then
            if(state && !keydown) then
                func()
            end
            hovered = true
        else
            hovered = false
        end
        keydown = state
        bg.Paint2x()
    end
    bg.pts = buttonpts
    return bg
end

function GTetris.CreateMat3D2D(parent, x, y, w, h, mat)
    local bg = GTetris.CreateFrame(parent, x, y, w, h, Color(0, 0, 0, 0))
    local clr = 255
    local keydown = false
    local hovered = false
    bg:NoClipping(false)
    bg.Paint2x = function() end
    bg.Paint = function()
        surface.SetDrawColor(clr, clr, clr, 255)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(0, 0, w, h)
    end
    return bg
end

function GTetris.CircleAvatar(parent, x, y, w, h, player, resolution)
    if(!IsValid(player)) then return end
    local base = GTetris.CreatePanel(parent, x, y, w, h, Color(30, 30, 30, 255))
    local av = base:Add("AvatarImage")
    local c = GTetris.BuildCircle(base:GetWide() / 2, base:GetTall() / 2, base:GetWide() * 0.5)
    av:SetSize(w, h)
    av:SetPlayer(player, resolution)
    av:SetPaintedManually(true)
    base.Paint = function()
        render.ClearStencil()
        render.SetStencilEnable(true)
        render.SetStencilTestMask(0xFF)
        render.SetStencilWriteMask(0xFF)
        render.SetStencilReferenceValue(0x01)
        render.SetStencilCompareFunction(STENCIL_NEVER)
        render.SetStencilFailOperation(STENCIL_REPLACE)
        render.SetStencilZFailOperation(STENCIL_REPLACE)
        draw.NoTexture()
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawPoly(c)
        render.SetStencilCompareFunction(STENCIL_EQUAL)
        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)
        av:PaintManual()
        render.SetStencilEnable(false)
    end
    return base
end

local circle_seg = 64
function GTetris.BuildCircle(x, y, radius)
    local c = {}
    table.insert(c, {x = x, y = y})

    for i = 0, circle_seg do
        local a = math.rad(i / circle_seg * -360)
        table.insert(c, {
            x = x + math.sin(a) * radius,
            y = y + math.cos(a) * radius
        })
    end

    local a = math.rad(0)
    table.insert(c, {
        x = x + math.sin(a) * radius,
        y = y + math.cos(a) * radius
    })
    return c
end

local blur = Material("pp/blurscreen")
function GTetris.DrawBlur(panel, passes, amount)
    local x, y = panel:LocalToScreen(0, 0)
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)
    for i = 1, 2 do
        blur:SetFloat("$blur", (i / 6) * amount)
        blur:Recompute()
        render.UpdateScreenEffectTexture()

        surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
    end
end

function GTetris.DrawFilledCircle(x, y, radius, scl)
    local cir = {}
    local seg = 30
    table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
    for i = 0, seg do
        local a = math.rad( ( i / seg ) * (-360 * scl))
        table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
    end
    surface.DrawPoly( cir )
end

function GTetris.CircleTimerAnimation(x, y, radius, thickness, t, color)
    draw.NoTexture()
    surface.SetDrawColor(color.r, color.g, color.b, color.a) -- Don't use Color(), it's slow af, check wiki

    render.ClearStencil()

    render.SetStencilEnable(true)
    render.SetStencilTestMask(0xFF)
    render.SetStencilWriteMask(0xFF)
    render.SetStencilReferenceValue(0x01)

    render.SetStencilCompareFunction(STENCIL_NEVER)
    render.SetStencilFailOperation(STENCIL_REPLACE)
    render.SetStencilZFailOperation(STENCIL_REPLACE)
    GTetris.DrawFilledCircle(x, y, radius - thickness, 1)
    render.SetStencilCompareFunction(STENCIL_GREATER)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    GTetris.DrawFilledCircle(x, y, radius, t)
    render.SetStencilEnable(false)
end

function GTetris.RespondWaiting()
    if(!IsValid(GTetris.FetchingPanel)) then return end
    GTetris.FetchingPanel.Respond()
end

GTetris.FetchingPanel = GTetris.FetchingPanel || nil
function GTetris.WaitingIndicator()
    local ui = GTetris.CreatePanel(nil, 0, 0, ScrW(), ScrH(), Color(0, 0, 0, 0))
    ui:MakePopup()
    local tall = 0
    local target_tall = ScrH() * 0.125
    local alphamul = 0
    local timeout = SysTime() + 10
    local responded = false
    local timedout = false
    local static_flash_size = ScreenScaleH(28)
    local static_X, static_Y = (ScrW() * 0.5) - static_flash_size * 0.5,  (ScrH() - target_tall) + (target_tall - static_flash_size) * 0.2
    local flash_size = static_flash_size
    local flash_alpha = 0
    local flash_interval = 0.75
    local flash_next_t = SysTime() + flash_interval
    local flash_target_s = static_flash_size * 4
    local flashmat = GTetris.GetCachedMaterial("gtetris/white_t.png")
    ui:SetZPos(32767)
    ui.Paint = function()
        if(!responded && !timedout) then
            tall = math.Clamp(tall + GTetris.GetFixedValue(12), 0, target_tall)
            if(timeout < SysTime()) then
                timedout = true
            end
        else
            tall = math.Clamp(tall - GTetris.GetFixedValue(12), 0, target_tall)
            if(tall <= 0) then
                ui:Remove()
            end
        end
        draw.RoundedBox(0, 0, ScrH() - tall, ScrW(), tall, Color(0, 0, 0, 150))
        alphamul = math.Clamp(tall / target_tall, 0, 1)
        surface.SetMaterial(flashmat)
        surface.SetDrawColor(255, 255, 255, 255 * alphamul)
        surface.DrawTexturedRect(static_X, static_Y, static_flash_size, static_flash_size)
        if(flash_next_t < SysTime()) then
            flash_size = static_flash_size
            flash_alpha = 255
            flash_next_t = SysTime() + flash_interval
        else
            flash_size = math.Clamp(flash_size + GTetris.GetFixedValue((flash_target_s - flash_size) * 0.085), static_flash_size, flash_target_s)
            flash_alpha = math.Clamp((0.9 - math.Clamp((flash_size / flash_target_s), 0, 1)) * 255, 0, 255)
        end
        surface.SetDrawColor(255, 255, 255, flash_alpha * alphamul)
        surface.DrawTexturedRect((ScrW() * 0.5) - (flash_size * 0.5), static_Y - (flash_size * 0.5) + (static_flash_size * 0.5), flash_size, flash_size)
        local t = math.max(timeout - SysTime(), 0)
        if(t < 5) then
            draw.DrawText("Waiting respond from the server.., Timeout in "..math.floor(t).." seconds", "GTetris-UISmall2x", (ScrW() * 0.5), static_Y + ScreenScaleH(32), Color(255, 255, 255, 255 * alphamul), TEXT_ALIGN_CENTER)
        else
            draw.DrawText("Waiting respond from the server..", "GTetris-UISmall2x", (ScrW() * 0.5), static_Y + ScreenScaleH(32), Color(255, 255, 255, 255 * alphamul), TEXT_ALIGN_CENTER)
        end
    end
    ui.Respond = function()
        responded = true
    end

    GTetris.FetchingPanel = ui
end

function GTetris.PopupConfirm(data)
    local ui = GTetris.CreateFrame(nil, 0, 0, ScrW(), ScrH(), Color(0, 0, 0, 0))
        ui.BlurPasses = 0
        ui.Alpha = 0
        ui.Exiting = false
        ui:SetAlpha(0)
        ui:MakePopup() -- So DTextEntry can receive inputs
        ui.Paint = function()
            if(ui.Exiting) then
                ui.Alpha = math.Clamp(ui.Alpha - GTetris.GetFixedValue(15), 0, 255)
                if(ui.Alpha <= 0) then
                    ui:Remove()
                end
            else
                ui.Alpha = math.Clamp(ui.Alpha + GTetris.GetFixedValue(15), 0, 255)
            end
            draw.RoundedBox(0, 0, 0, ScrW(), ScrH(), Color(0, 0, 0, ui.Alpha * 0.8))
            ui:SetAlpha(ui.Alpha)
        end
        local iconoffs = 0
        local vertical_margin = ScrH() * 0.4
        local horizontal_margin = ScrW() * 0.2
        local inner = GTetris.CreatePanel(ui, horizontal_margin, vertical_margin, ScrW() - (horizontal_margin * 2), ScrH() - (vertical_margin * 2), Color(40, 40, 40, 255))
        local text_margin = ScreenScaleH(8)
        local text1 = GTetris.CreateLabelBG(inner, text_margin, text_margin, data.t1, "GTetris_Popup_1x", data.tcolor, data.t1color, nil)
        GTetris.CreateLabelBG(inner, GTetris.GetGUINextPos(text1).x, text_margin, data.t2, "GTetris_Popup_1x", data.tcolor2 || data.tcolor, data.t2color, GTetris.GetCachedMaterial(data.tmat || "zombie scenario/ui/icon_input.png"))
        local _, _, text = GTetris.CreateLabel(inner, inner:GetWide() * 0.5, inner:GetTall() * 0.5, data.centertext, "GTetris_ConfirmText", color_white)
        text.CentPos()
        local buttonWidth, buttonHeight = inner:GetWide() * 0.5, ScreenScaleH(24)
        local cancel_button = GTetris.CreateButtonTextIcon(ui, inner:GetX(), inner:GetY() + inner:GetTall(), buttonWidth, buttonHeight, Color(20, 20, 20, 255), "Cancel", "GTetris_Popup_1x", Color(255, 255, 255, 255), GTetris.GetCachedMaterial("zombie scenario/arknights/btn_icon_cancel.png"), {x = 0, y = -iconoffs}, function()
            if(ui.Exiting) then return end
            ui.Exiting = true
        end)
        local confirmbutton = GTetris.CreateButtonTextIcon(ui, inner:GetX() + inner:GetWide() * 0.5, inner:GetY() + inner:GetTall(), buttonWidth, buttonHeight, Color(40, 120, 200, 255), "Confirm", "GTetris_Popup_1x", Color(255, 255, 255, 255), GTetris.GetCachedMaterial("zombie scenario/arknights/btn_icon_confirm.png"), {x = 0, y = -iconoffs}, function()
            if(ui.Exiting) then return end
            if(data.passfunc) then
                data.passfunc()
            end
            ui.Exiting = true
        end)
        ui.InnerPanel = inner
end

function GTetris.APNGRenderer(parent, x, y, w, h, apng) -- Fuck awsomium
    local html = vgui.Create("DHTML", parent)
        html:SetPos(x, y)
        html:SetSize(w, h)
        html:SetHTML([[
            <html lang="en">
                <body>
                    <img src="data:image/png;base64,]]..util.Base64Encode(apng, true)..[[" alt="Animated PNG">
                </body>
            </html>
        ]])
    return html
end

local star1 = Material("zombie scenario/arknights/star_02.png")
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_SetDrawColor = surface.SetDrawColor
function GTetris.ParticleLayer(parent, x, y, w, h, data)
    local side = data.side
    local gap = data.gap
    local decay = data.decay || 10
    local mins, maxs = data.mins, data.maxs
    local minsa, maxsa = data.minsa || 100, data.maxsa || 255
    local layer = GTetris.CreatePanel(parent, x, y, w, h, Color(0, 0, 0, 0))
        layer.NextParticle = 0
        layer.PreRender = function() return true end
        layer.Particles = {}
        layer.data = data
        layer.Paint = function()
            if(!layer.PreRender()) then return end
            if(layer.NextParticle < SysTime()) then
                local vel = ScreenScaleH(data.vel)
                local velh = ScreenScaleH(data.hvel)
                for _ = 1, 2 do
                    if(_ == 1) then
                        if(side == 2) then continue end
                        table.insert(layer.Particles, {
                            x = 0,
                            y = math.random(gap, layer:GetTall() - gap * 2),
                            vel = Vector(math.random(velh, vel), 0, 0),
                            alpha = math.random(minsa, maxsa),
                            size = ScreenScaleH(math.random(mins, maxs)),
                        })
                    else
                        if(side == 1) then continue end
                        table.insert(layer.Particles, {
                            x = layer:GetWide(),
                            y = math.random(gap, layer:GetTall() - gap * 2),
                            vel = Vector(math.random(-vel, -velh), 0, 0),
                            alpha = math.random(minsa, maxsa),
                            size = ScreenScaleH(math.random(mins, maxs)),
                        })
                    end
                end
                local scl = 1
                layer.NextParticle = SysTime() + (math.Rand(0.2, 0.3) * data.rate)
            end
            surface.SetMaterial(star1)
            local _decay = GTetris.GetFixedValue(decay)
            local tierColor = data.color
            for _, particle in pairs(layer.Particles) do
                if(particle.alpha <= 0) then
                    table.remove(layer.Particles, _)
                    continue
                end
                particle.x = particle.x + GTetris.GetFixedValue(particle.vel.x)
                particle.y = particle.y + GTetris.GetFixedValue(particle.vel.y)
                particle.alpha = math.Clamp(particle.alpha - _decay, 0, 255)
                surface_SetDrawColor(tierColor.r, tierColor.g, tierColor.b, particle.alpha)
                surface_DrawTexturedRect(particle.x, particle.y, particle.size, particle.size)
            end
        end
    return layer
end
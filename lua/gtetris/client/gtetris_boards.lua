GTetris.BoardLayer = GTetris.BoardLayer || {}

function GTetris.GetAngle(p1, p2)
	local ang = math.atan2(p2.y - p1.y, p1.x - p2.x)
	local deg = math.deg(ang)
	return deg + 90
end

function GTetris.TraceLinear(p1, p2, t)
	local x, y = p2.x - p1.x, p2.y - p1.y
	return Vector(p1.x + x * t, p1.y + y * t, 0)
end

function GTetris.CircumCircle(p, t)
	local a0, a1 ,c0, c1, det, asq, csq, ctr0, ctr1, rad2

	a0 = p[1].x - p[2].x
	a1 = p[1].y - p[2].y

	c0 = p[3].x - p[2].x
	c1 = p[3].y - p[2].y

	det = a0 * c1 - c0 * a1

	if(det == 0) then return false end
	det = 0.5 / det
	asq = a0 * a0 + a1 * a1
	csq = c0 * c0 + c1 * c1
	ctr0 = det * (asq * c1 - csq * a1)
	ctr1 = det * (csq * a0 - asq * c0)
	rad2 = ctr0 * ctr0 + ctr1 * ctr1

	local pos = {x = ctr0 + p[2].x, y = ctr1 + p[2].y}
	local sta, eda = math.floor(math.deg(math.atan2(pos.y - p[1].y, p[1].x - pos.x)) + 90) ,math.floor(math.deg(math.atan2(pos.y - p[3].y, p[3].x - pos.x)) + 90)
	local segs = sta - eda
	local step1 = 1
	local r = math.sqrt(rad2)
	if(sta > eda) then
		step1 = -1
	end
	local ta = {}
	for i = sta, eda, step1 do
		local a = math.rad(i)
		table.insert(ta, {x = pos.x + math.sin( a ) * r, y = pos.y + math.cos( a ) * r, Color(0, 0, 255, 255)})
	end

	local inx = math.max(math.floor(#ta * t), 1)
	return ta[inx]
end

local draw_RoundedBox = draw.RoundedBox
local blockMat = Material("gtetris/block.png")
local allclearMat = Material("gtetris/allclear.png")
function GTetris.SetupBoardLayer(attachTo)
	if(!IsValid(GTetris.MainUI)) then return end
	local scrw, scrh = ScrW(), ScrH()
	local layer = GTetris.CreateFrame(attachTo, 0, 0, scrw, scrh, color_transparent)
		layer:SetZPos(1)
		layer.Boards = {}
		layer.FocusingBoard = nil
		layer.Amount = 0

		layer.BoardWidth = GTetris.Rulesets.Width
		layer.BoardHeight = GTetris.Rulesets.Height
		layer.BoardBlockSize = ScreenScaleH(16)

		layer.BoardWide = layer.BoardBlockSize * layer.BoardWidth
		layer.BoardTall = layer.BoardBlockSize * layer.BoardHeight
		layer.InputBlockTime = 0
		layer.AnimLayer = GTetris.CreateFrame(layer, 0, 0, scrw, scrh, color_transparent)
		layer.AnimLayer:SetZPos(32767)

		layer.GetLocalPlayer = function()
			local localply = layer.Boards[LocalPlayer():SteamID64()]
			return localply || layer.Boards[layer.LocalPlayerID]
		end

		layer.UpdateBoardAmounts = function(amount)
			if(!IsValid(layer)) then return end
			layer.Amount = amount
		end

		layer.GetBoardRenderTarget = function(index)
			return GetRenderTarget("GTetrisBoardRT"..index, scrw, scrh)
		end

		layer.GetBoard = function(boardID)
			return layer.Boards[boardID]
		end

		layer.SetupDefaultBoard = function(boardID)
			if(!IsValid(layer.Boards[boardID])) then return end
			local board = layer.Boards[boardID]
			for rows = 0, layer.BoardWidth - 1 do
				for cols = -20, layer.BoardHeight - 1 do
					if(!board.CurrentBoard[cols]) then
						board.CurrentBoard[cols] = {}
					end
					board.CurrentBoard[cols][rows] = 0
				end
			end
		end

		layer.Sorting = false
		layer.SortingTime = 0.45
		layer.CurrentSortingTime = 0
		layer.SortBoards = function(instant)
			layer.CurrentSortingTime = SysTime() + layer.SortingTime
			if(instant) then
				layer.CurrentSortingTime = -1
			end
			layer.Sorting = true
			local amount = layer.Amount
			local centerX, centerY = ScrW() * 0.5, ScrH() * 0.5
			local maxColumns = 3
			local currentCol = 0
			local currentRow = 0
			local _x, _y = 0, 0
			local pad_offset = 0
			local init = true
			local scale = 1 / (math.Clamp(amount - 1, 1, 3))
			local rows = math.ceil((amount - 1) / maxColumns) -- -1 for the local player or the focused board
			local scaled_tall = layer.BoardTall * scale
			local gap = ScreenScaleH(16)
			local _w = math.max(layer.BoardBlockSize * 10, layer.BoardWide)
			local _h = layer.BoardBlockSize * 20
			local center = centerX - _w * 0.5
			_x = center + _w * 1.75
			_y = scrh * 0.5 - layer.BoardTall * 0.5 - gap
			pad_offset = (scrh * 0.5) * (1 - scale)

			for _, board in pairs(layer.Boards) do
				board.PreSortPosX = board:GetX() + (board.CurrentXOffset || 0)
				board.PreSortPosY = board:GetY() + (board.CurrentYOffset || 0)
				if(amount <= 1) then
					board.TargetScale = 1
					board.TargetX = centerX - board:GetWide() * 0.5
					board.TargetY = centerY - board:GetTall() * 0.5
				elseif(amount <= 2) then
					local center = centerX - _w * 0.5
					if(board == layer.FocusingBoard) then
						board.TargetX = center - _w * 1.15
					else
						board.TargetX = center + _w * 1.15
					end
					board.TargetY = centerY - board:GetTall() * 0.5
					board.TargetScale = 1
				elseif(amount <= 10) then
					if(board == layer.FocusingBoard) then
						board.TargetX = center
						board.TargetY = centerY - board:GetTall() * 0.5
						board.TargetScale = 1
					else
						board.TargetX = _x
						board.TargetY = _y
						board.TargetScale = scale
						_y = _y + scaled_tall + gap
						currentCol = currentCol + 1
						if(currentCol >= maxColumns) then
							_x = _x + _w * scale + gap
							_y = scrh * 0.5 - layer.BoardTall * 0.5 - gap
							currentCol = 0
						end
					end
				else
					if(board == layer.FocusingBoard) then
						board.TargetX = center
						board.TargetY = centerY - board:GetTall() * 0.5
						board.TargetScale = 1
					else
						board.TargetX = _x
						board.TargetY = _y
						board.TargetScale = scale
						_y = _y + scaled_tall + gap
						currentCol = currentCol + 1
						if(currentCol >= maxColumns) then
							_x = _x + layer.BoardWide * scale + gap
							_y = scrh * 0.5 - layer.BoardTall * 0.5 - gap
							currentCol = 0
							currentRow = currentRow + 1
							if(currentRow >= 3) then
								_x = centerX - _w * 1.75 - _w * 0.5 - ScreenScaleH(24)
								currentRow = 0
							end
						end
					end
				end
			end
		end

		layer.AttackTracers = {}
		layer.Particles = {}
		layer.InsertAttackTrace = function(from, to)
			from = Vector(from.x, from.y, 0)
			to = Vector(to.x, to.y, 0)
			local offset = from - to
			local _3rdvector = (from + offset * 0.5) + Vector(0, offset.y * math.Rand(-0.5, 0.5), 0)
			local targetTime = GTetris.Rulesets.AttackArriveTime
			table.insert(layer.AttackTracers, {
				v1 = from,
				v2 = _3rdvector,
				v3 = to,
				alpha = 255,
				time = SysTime() + targetTime,
				wscale = 0.5,
				hscale = 1,
				sx = ScreenScale(16),
				rotate = GTetris.GetAngle(from, _3rdvector),
				oldvec = from,
				trans = 0,
				target_trans = targetTime,
			})
		end

		local tracerMaterial = Material("gtetris/garbageparticle.png", "smooth")
		layer.AnimLayer.Paint = function()
			surface.SetMaterial(tracerMaterial)
			for k,v in next, layer.Particles do
				if(v.time < SysTime()) then
					table.remove(layer.Particles, k)
				end
				local t = math.max(v.time - SysTime(), 0) / v.target_trans
				surface.SetDrawColor(255, 155, 155, v.alpha * t)
				surface.DrawTexturedRectRotated(v.vec.x, v.vec.y, (v.sx * t) * v.ws, (v.sx * t) * v.hs, v.rotate)
			end

			for k,v in next, layer.AttackTracers do
				if(v.time < SysTime()) then
					v.alpha = math.Clamp(v.alpha - GTetris.GetFixedValue(20), 0, 255)
					v.wscale = v.wscale + GTetris.GetFixedValue(0.05)
					v.hscale = v.hscale + GTetris.GetFixedValue(0.05)
					if(v.alpha <= 0) then
						table.remove(layer.AttackTracers, k)
					end
				end

				local t = math.max(v.time - SysTime(), 0.01) / v.target_trans
				--local vec = GTetris.CircumCircle({v.v1, v.v2, v.v3}, 1 - t)
				local vec = math.QuadraticBezier(1 - t, v.v1, v.v2, v.v3)
				if(!vec) then continue end
				surface.SetDrawColor(255, 70, 70, v.alpha)
				surface.DrawTexturedRectRotated(vec.x, vec.y, (v.sx * 1.5) * v.wscale, (v.sx * 1.5) * v.hscale, v.rotate)

				local dst = math.Distance(v.oldvec.x, v.oldvec.y, vec.x, vec.y)

				if(dst > 0) then
					v.rotate = GTetris.GetAngle(v.oldvec, vec)
					local oldpos = v.oldvec
					for i = 0, 1, 1 / dst do
						local vec = GTetris.TraceLinear(v.oldvec, vec, i)
						table.insert(layer.Particles, {
							time = SysTime() + v.target_trans / 2,
							target_trans = v.target_trans / 2,
							rotate = v.rotate,
							sx = v.sx * 0.6,
							ws = v.wscale,
							hs = v.hscale,
							vec = vec,
							alpha = 10,
						})
					end
				end

				v.oldvec = vec
			end
		end

		layer.BoardIndex = 1
		layer.ScaleSpeed = 1
		layer.CreateBoard = function(boardID, localplayer)
			local board = GTetris.CreatePanel(layer, 0, 0, 1, 1, Color(255, 0, 0, 255))
				board.TargetWidth = layer.BoardBlockSize * layer.BoardWidth
				board.TargetHeight = layer.BoardBlockSize * layer.BoardHeight
				board:SetSize(layer.BoardBlockSize * layer.BoardWidth, layer.BoardBlockSize * layer.BoardHeight)
				board.TargetX = 0
				board.TargetY = 0
				board.TargetScale = 1
				board.CurrentScale = 0.0
				board.boardID = boardID

				board:NoClipping(true)

				board.PlayerNick = nil
				board.Alive = true
				board.CurrentBoard = {}

				board.CurrentRotationState = 4
				board.CurrentSeed = GTetris.Rulesets.Seed
				board.CurrentPieces = GTetris.GeneratePieces(GTetris.Rulesets.BagSystem, board.CurrentSeed)
				board.CurrentPiece = board.CurrentPieces[1]
				board.CurrentPosition = {x = math.floor((GTetris.Rulesets.Width - GTetris.BlockWidth[board.CurrentPiece]) * 0.5), y = -3}
				board.CurrentHoldPiece = -1
				board.ClearlineBonus = false
				board.HoldUsed = false

				board.RotationRule = GTetris.Rulesets.SpinSystem

				board.Index = layer.BoardIndex
				board.CurrentCombo = -1
				board.CurrentB2B = 0
				board.CurrentB2BAlpha = 0
				board.CurrentB2BFlash = false
				board.CurrentB2BFlashTime = 0
				board.AutolockTime = GTetris.Rulesets.AutolockTime
				board.GravityTime = 0
				board.ShakeScale = 0

				board.LastSpin = ""

				board.TotalAttacks = 0
				board.TotalBlockPlaced = 0
				board.StartPlayingTime = SysTime() + 5

				board.SpinText = ""
				board.SpinTextColor = color_white
				board.SpinTextAlpha = 0
				board.SpinXOffset = 0

				board.ComboAlpha = 0

				board.ClearText = ""
				board.ClearTextAlpha = 0
				board.ClearXOffset = 0

				board.Numbers = {}
				board.AllClears = {}
				board.ReceivedAttacks = {}

				board.UpdateBoard = function()
					board.ShouldRenderBoard = true
				end

				board.DeathAnimationY = 0
				board.DeathAnimationYSpeed = 5
				board.DeathAnimationRotation = 0
				board.DeathAnimationRotationSide = false
				board.StartDeathAnimation = function()
					if(board == GTetris.GetLocalPlayer() || board == layer.FocusingBoard) then
						GTetris.DeathSound(true, 4)
					else
						if(layer.Amount <= 2) then
							GTetris.DeathSound(true, 4)
						else
							GTetris.DeathSound(false, 2)
						end
					end
					if(math.random(0, 1) == 1) then
						board.DeathAnimationRotationSide = true
					else
						board.DeathAnimationRotationSide = false
					end
					board.ShakeScale = 30
					board.FallTime = SysTime() + 0.25
					board.PlayingDeathAnimation = true
					board.Alive = false
					board.InputEnabled = false

					layer.Boards[board.boardID] = nil
					layer.Amount = layer.Amount - 1

					if(board == GTetris.GetLocalPlayer() || board == layer.FocusingBoard) then
						local boards = layer.Boards
						layer.FocusingBoard = table.Random(boards)
					end

					layer.SortBoards()
				end

				local AttackBarWide = layer.BoardBlockSize * 0.75
				board.PreRender = function(board) end
				board.PostRender = function(board) end
				board.Paint2x = function()
					local BlockSize = layer.BoardBlockSize
					local CurrentFraction = board:GetTall() / board.TargetHeight
					board.CurrentBlockSize = BlockSize
					board.InputEnabled = layer.InputBlockTime < SysTime()

					if(!layer.WinnerAnim) then
						if(board.FullyScaled) then
							if(board.TargetScale < board.CurrentScale) then
								board.CurrentScale = GTetris.IncFV(board.CurrentScale, (board.TargetScale - board.CurrentScale) * 0.2, board.TargetScale, board.CurrentScale)
							else
								board.CurrentScale = GTetris.IncFV(board.CurrentScale, (board.TargetScale - board.CurrentScale) * 0.2, board.CurrentScale, board.TargetScale)
							end
						else
							if(board.TargetScale < board.CurrentScale) then
								board.CurrentScale = GTetris.IncFV(board.CurrentScale, (board.TargetScale - board.CurrentScale) * 0.2 * layer.ScaleSpeed, board.TargetScale, board.CurrentScale)
							else
								board.CurrentScale = GTetris.IncFV(board.CurrentScale, (board.TargetScale - board.CurrentScale) * 0.2 * layer.ScaleSpeed, board.CurrentScale, board.TargetScale)
							end
							if(math.abs(board.TargetScale - board.CurrentScale) <= 0.01) then
								board.FullyScaled = true
							end
						end
					else
						board.CurrentScale = board.CurrentScale + GTetris.GetFixedValue(0.004)
					end

					if(board.ShouldRenderBoard) then
						local rt = layer.GetBoardRenderTarget(board.Index)

						render.PushRenderTarget(rt)
							cam.Start2D()
								for col, rows in ipairs(board.CurrentBoard) do
									for row, id in ipairs(rows) do
										local color = GTetris.Blocks_Colors[id]
										if(color) then
											local x = (row - 1) * BlockSize
											local y = (col - 1) * BlockSize
											draw_RoundedBox(0, x, y, BlockSize, BlockSize, color)
										end
									end
								end
							cam.End2D()
						render.PopRenderTarget()

						if(!board.RTReference) then
							board.RTReference = CreateMaterial("GTetrisBoardRT"..math.random(1, 2147483646), "VertexLitGeneric", {
							    ["$basetexture"] = rt:GetName(),
							    ["$translucent"] = 1,
							})
						end
						board.ShouldRenderBoard = nil
					end

					if(board.RTReference) then
						local totalWide = layer.BoardWidth * BlockSize
						local totalTall = layer.BoardHeight * BlockSize
						local lineSize = ScreenScaleH(1)
						local lineTall = totalTall + lineSize

						local gridColor = Color(155, 155, 155, 255)
						if(layer.Amount >= 4 && board != layer.FocusingBoard) then
							gridColor = Color(80, 80, 80, 255)
						end
						board.ShakeScale = GTetris.IncFV(board.ShakeScale, -2, 0, 100)
						if(board.PlayingDeathAnimation) then
							if(board.FallTime < SysTime()) then
								if(board.DeathAnimationRotationSide) then
									board.DeathAnimationRotation = GTetris.IncFV(board.DeathAnimationRotation, 1 * board.CurrentScale, 0, 360)
								else
									board.DeathAnimationRotation = GTetris.IncFV(board.DeathAnimationRotation, -1 * board.CurrentScale, -360, 0)
								end
								board.DeathAnimationYSpeed = board.DeathAnimationYSpeed + GTetris.GetFixedValue(1)
								board.DeathAnimationY = GTetris.IncFV(board.DeathAnimationY, board.DeathAnimationYSpeed, 0, ScrH() * 2)

								if(board.DeathAnimationY >= ScrH()) then
									board:Remove()
									return
								end
							end
						end
						local shake = ScreenScaleH(board.ShakeScale) * board.CurrentScale
						local matrix = Matrix()
							matrix:SetScale(Vector(board.CurrentScale, board.CurrentScale, 1))
							matrix:SetTranslation(Vector((board.CurrentXOffset || 0) + math.random(-shake, shake), (board.CurrentYOffset || 0) + board.DeathAnimationY + math.random(-shake, shake), 0))
							matrix:Rotate(Angle(0, board.DeathAnimationRotation, 0))

							if(layer.WinnerAnim) then
								local scaleoffs = math.max(board.CurrentScale - board.TargetScale, 0)
								local x, y = (board.TargetWidth * board.CurrentScale) * scaleoffs * 0.2, (board.TargetHeight * board.CurrentScale) * scaleoffs * 0.2 -- This is probably incorrect, but it works
								matrix:Translate(Vector(-x, -y, 0))
							end

							cam.PushModelMatrix(matrix)
								draw_RoundedBox(0, 0, 0, totalWide, totalTall, Color(30, 30, 30, 255))
								if(!GTetris.OldRenderingMethod) then
									surface.SetDrawColor(255, 255, 255, 255)
									surface.SetMaterial(board.RTReference)
									surface.DrawTexturedRect(0, 0, scrw, scrh)
								else
									surface.SetMaterial(blockMat)
									board.PreRender(board)
									for i = -20, layer.BoardHeight  do
										local rows = board.CurrentBoard[i]
										if(!rows) then continue end
										for col = 0, layer.BoardWidth - 1 do
											local id = rows[col]
											if(id == 0) then continue end
											local color = GTetris.Blocks_Colors[id]
											local x = col * BlockSize
											local y = i * BlockSize
											surface.SetDrawColor(color.r, color.g, color.b, color.a)
											surface.DrawTexturedRect(x, y, BlockSize, BlockSize)
										end
									end
								end

								if(layer.Amount <= 4 || board == layer.FocusingBoard) then
									local nextPiece_Width = layer.BoardBlockSize * 5
									local nextPiece_Height = layer.BoardBlockSize * 16
									local x = board:GetX() + board:GetWide()
									local y = board:GetY()
									local piece_padding = BlockSize * 3
									local tw, th = GTetris.GetTextSize("GTetris_UIFontMedium", "#gtetris.nextpieces")
									draw_RoundedBox(0, x, y, nextPiece_Width, nextPiece_Height, gridColor)
									draw.DrawText("#gtetris.nextpieces", "GTetris_UIFontMedium", x + nextPiece_Width * 0.5, 0, color_black, TEXT_ALIGN_CENTER)
									x = x + lineSize * 2
									y = y + th + lineSize
									nextPiece_Width = nextPiece_Width - lineSize * 3
									nextPiece_Height = nextPiece_Height - th - lineSize * 2
									draw_RoundedBox(0, x, y, nextPiece_Width, nextPiece_Height, Color(0, 0, 0, 255))

									y = y + BlockSize * 0.45

									surface.SetMaterial(blockMat)

									local count = 0
									for num, piece in ipairs(board.CurrentPieces) do
										if(num == 1) then continue end
										local shape = GTetris.Blocks[piece][4]
										local color = GTetris.Blocks_Colors[piece]
										local draw_x = x + (nextPiece_Width - (GTetris.BlockWidth[piece] * BlockSize)) * 0.5
										surface.SetDrawColor(color.r, color.g, color.b, color.a)
										for _, shape in ipairs(shape) do
											local x = shape[1] * BlockSize + draw_x
											surface.DrawTexturedRect(x, y + shape[2] * BlockSize + (count * piece_padding), BlockSize, BlockSize)
										end
										count = count + 1
										if(count >= 5) then
											break
										end
									end

									x = board:GetX() - AttackBarWide
									y = board:GetY()
									local nextPiece_Width = layer.BoardBlockSize * 5
									local nextPiece_Height = layer.BoardBlockSize * 4
									local tw, th = GTetris.GetTextSize("GTetris_UIFontMedium", "#gtetris.holdpiece")
									draw_RoundedBox(0, x - nextPiece_Width, y, nextPiece_Width, nextPiece_Height, gridColor)
									draw.DrawText("#gtetris.holdpiece", "GTetris_UIFontMedium", x - nextPiece_Width * 0.5, 0, color_black, TEXT_ALIGN_CENTER)
									x = x - nextPiece_Width + lineSize * 2
									y = y + th + lineSize
									nextPiece_Width = nextPiece_Width - lineSize * 3
									nextPiece_Height = nextPiece_Height - th - lineSize * 2
									draw_RoundedBox(0, x, y, nextPiece_Width, nextPiece_Height, Color(0, 0, 0, 255))
									y = y + BlockSize * 0.5
									if(board.CurrentHoldPiece != -1) then
										local shape = GTetris.Blocks[board.CurrentHoldPiece][4]
										local color = GTetris.Blocks_Colors[board.CurrentHoldPiece]
										local draw_x = x + (nextPiece_Width - (GTetris.BlockWidth[board.CurrentHoldPiece] * BlockSize)) * 0.5
										if(!board.HoldUsed) then
											surface.SetDrawColor(color.r, color.g, color.b, color.a)
										else
											surface.SetDrawColor(100, 100, 100, 255)
										end
										for _, shape in ipairs(shape) do
											local x = shape[1] * BlockSize + draw_x
											surface.DrawTexturedRect(x, y + shape[2] * BlockSize, BlockSize, BlockSize)
										end
									end
								end

								for i = 0, layer.BoardWidth do
									draw_RoundedBox(0, i * BlockSize, 0, lineSize, lineTall, gridColor)
								end
								for i = 0, layer.BoardHeight do
									draw_RoundedBox(0, 0, i * BlockSize, totalWide, lineSize, gridColor)
								end

							if(board == layer.FocusingBoard) then
								local PlaceY = GTetris.TraceToBottom(board)
								local shape = GTetris.Blocks[board.CurrentPiece][board.CurrentRotationState]
								local origin = board.CurrentPosition
								local color = GTetris.Blocks_Colors[board.CurrentPiece]
								surface.SetMaterial(blockMat)
								surface.SetDrawColor(color.r, color.g, color.b, 50)
								for _, block in ipairs(shape) do
									local x = (block[1] + origin.x) * BlockSize
									local y = (block[2] + PlaceY) * BlockSize
									surface.DrawTexturedRect(x, y, BlockSize, BlockSize)
								end
							end

							if(board.Alive && (layer.Amount <= 4 || board == layer.FocusingBoard)) then
								local origin, shape, rotation = board.CurrentPosition, GTetris.Blocks[board.CurrentPiece], board.CurrentRotationState
								surface.SetMaterial(blockMat)
								for _, block in ipairs(shape[rotation]) do
									local x = (block[1] + origin.x) * BlockSize
									local y = (block[2] + origin.y) * BlockSize
									local color = GTetris.Blocks_Colors[board.CurrentPiece]
									surface.SetDrawColor(color.r, color.g, color.b, color.a)
									surface.DrawTexturedRect(x, y, BlockSize, BlockSize)
								end

								if(board.PlayerNick) then
									local gap = ScreenScaleH(4)
									local tw, th = GTetris.GetTextSize("GTetris_UIFontMedium", board.PlayerNick)
									tw = tw + gap * 2
									th = th + gap * 2
									local x, y = board:GetWide() * 0.5, board:GetTall() + gap
									draw_RoundedBox(0, x - (tw * 0.5), y, tw, th, Color(0, 0, 0, 200))
									draw.DrawText(board.PlayerNick, "GTetris_UIFontMedium", x, y + gap, color_white, TEXT_ALIGN_CENTER)
								end

								local x, y = -AttackBarWide, board:GetTall()
								local systime = SysTime()
								draw_RoundedBox(0, x, 0, AttackBarWide, board:GetTall(), Color(30, 30, 30, 255))
								draw_RoundedBox(0, x, y - GTetris.Rulesets.AttackCap * BlockSize, AttackBarWide, lineSize, gridColor)
								y = y + lineSize
								local _t = CurTime()
								for _, attack in ipairs(board.ReceivedAttacks) do
									local tall = attack.amount * BlockSize - lineSize
									if(attack.time < _t) then
										draw_RoundedBox(0, x, y - tall, AttackBarWide, tall, Color(255, 50, 50, 255))
									else
										draw_RoundedBox(0, x, y - tall, AttackBarWide, tall, Color(255, 50, 50, 50))
									end
									y = y - tall - lineSize
								end
								surface.SetDrawColor(gridColor.r, gridColor.g, gridColor.b, 255)
								surface.DrawOutlinedRect(x, 0, AttackBarWide, board:GetTall() + lineSize, lineSize)

								local blockSize = BlockSize * board.CurrentScale
								for _, number in ipairs(board.Numbers) do
									if(number.time > systime) then
										number.alpha = GTetris.IncFV(number.alpha, 15, 0, 255)
									else
										number.alpha = GTetris.IncFV(number.alpha, -15, 0, 255)
										if(number.alpha <= 0) then
											table.remove(board.Numbers, _)
										end
									end
									number.scale = GTetris.IncFV(number.scale, 0.075, 0, 0.5)
									local scale = number.scale * board.CurrentScale
									local color = color_white
									if(number.cancel) then
										color = Color(120, 180, 255, 255)
									end
									local translation = matrix:GetTranslation()
									local numMatrix = Matrix()
										numMatrix:SetTranslation(Vector(translation.x + (number.x + 2) * blockSize, translation.y + number.y * blockSize, 0))
										numMatrix:SetScale(Vector(scale, scale, 1))
										numMatrix:Rotate(Angle(0, number.rotation, 0))
										cam.PushModelMatrix(numMatrix)
											draw.SimpleTextOutlined(number.num, "GTetris_AttackNumberFont", 0, 0, Color(color.r, color.g, color.b, number.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
										cam.PopModelMatrix()
								end
							end

							if(localplayer && board.Alive && board.InputEnabled) then
								local origin = board.CurrentPosition
								local shape = GTetris.Blocks[board.CurrentPiece][board.CurrentRotationState]
								if(!GTetris.TestCollision(board.CurrentBoard, shape, origin.x, origin.y + 1)) then
									board.AutolockTime = board.AutolockTime - RealFrameTime()
									if(board.AutolockTime <= 0) then
										GTetris.PlacePiece(board)
									end
								end

								local time = SysTime()
								if(board.GravityTime < time && GTetris.Rulesets.Gravity > 0) then
									if(GTetris.MovePiece(board, 0, 1)) then
										GTetris.PieceMoved(board, true)
									end
									board.GravityTime = time + (1 / GTetris.Rulesets.Gravity)
								end

								if(!GTetris.TestCollision(board.CurrentBoard, shape, math.floor((GTetris.Rulesets.Width - GTetris.BlockWidth[board.CurrentPiece]) * 0.5), -4)) then
									if(layer.Multiplayer) then
										board.Alive = false
										board.InputEnabled = false
										board.StartDeathAnimation()
										GTetris.SendDeathAnimation()
									else
										layer.SetupDefaultBoard(board.boardID)
									end
								end
							end

							local gap = ScreenScaleH(14)
							local text_x = -gap
							local text_y = board:GetTall() * 0.235

							if(board.SpinTextAlpha > 0) then
								local clr = board.SpinTextColor
								draw.DrawText(board.SpinText, "GTetris_BoardSpin", text_x - board.SpinXOffset, text_y, Color(clr.r, clr.g, clr.b, board.SpinTextAlpha), TEXT_ALIGN_RIGHT)
								board.SpinTextAlpha = GTetris.IncFV(board.SpinTextAlpha, -3, 0, 255)
								board.SpinXOffset = board.SpinXOffset + GTetris.GetFixedValue(ScreenScaleH(1)) * 0.125
							end

							text_y = board:GetTall() * 0.285

							if(board.ClearTextAlpha > 0) then
								draw.DrawText(board.ClearText, "GTetris_BoardClearLine", text_x - board.ClearXOffset, text_y, Color(255, 255, 255, board.ClearTextAlpha), TEXT_ALIGN_RIGHT)
								board.ClearTextAlpha = GTetris.IncFV(board.ClearTextAlpha, -3, 0, 255)
								board.ClearXOffset = board.ClearXOffset + GTetris.GetFixedValue(ScreenScaleH(1)) * 0.125
							end

							text_y = board:GetTall() * 0.365

							if(board.CurrentB2B > 0) then
								board.CurrentB2BAlpha = GTetris.IncFV(board.CurrentB2BAlpha, 15, 0, 255)
							else
								board.CurrentB2BAlpha = GTetris.IncFV(board.CurrentB2BAlpha, -5, 0, 255)
							end

							if(board.CurrentB2BAlpha > 0) then
								if(board.CurrentB2B > 0) then
									draw.DrawText("B2B x "..board.CurrentB2B, "GTetris_BoardSpin", text_x, text_y, Color(255, 160, 0, board.CurrentB2BAlpha), TEXT_ALIGN_RIGHT)
								else 
									if(((SysTime() % 0.2) / 0.2) > 0.5) then
										draw.DrawText("B2B x "..board.CurrentB2B, "GTetris_BoardSpin", text_x, text_y, Color(255, 50, 50, board.CurrentB2BAlpha), TEXT_ALIGN_RIGHT)
									end
								end
							end

							text_y = board:GetTall() * 0.425

							if(board.CurrentCombo > 0) then
								board.ComboAlpha = GTetris.IncFV(board.ComboAlpha, 15, 0, 255)
							else
								board.ComboAlpha = GTetris.IncFV(board.ComboAlpha, -10, 0, 255)
							end

							if(board.ComboAlpha > 0) then
								if(board.CurrentCombo > 0) then
									draw.DrawText("Combo x "..board.CurrentCombo, "GTetris_BoardCombo", text_x, text_y, Color(255, 255, 255, board.ComboAlpha), TEXT_ALIGN_RIGHT)
								else
									draw.DrawText("Combo x 0", "GTetris_BoardCombo", text_x, text_y, Color(255, 50, 50, board.ComboAlpha), TEXT_ALIGN_RIGHT)
								end
							end

								local timepassed = math.max(SysTime() - board.StartPlayingTime, 0)
								if(timepassed <= 0) then
									timepassed = 1
								end
								local apm = board.TotalAttacks * (60 / timepassed)
								local pps = board.TotalBlockPlaced / timepassed
								local _, tall = GTetris.GetTextSize("GTetris_NotifyDesc", "100")
								local _text_y = board:GetTall() * 0.6
								draw.DrawText("Attacks : ", "GTetris_NotifyDesc", text_x, _text_y, color_white, TEXT_ALIGN_RIGHT)
								draw.DrawText(string.format("%05.2f", math.Round(apm, 2)).."/m", "GTetris_NotifyDesc", text_x, _text_y + tall, color_white, TEXT_ALIGN_RIGHT)
								_text_y = board:GetTall() * 0.725
								draw.DrawText("Pieces : ", "GTetris_NotifyDesc", text_x, _text_y, color_white, TEXT_ALIGN_RIGHT)
								draw.DrawText(string.format("%05.2f", math.Round(pps, 2)).."/s", "GTetris_NotifyDesc", text_x, _text_y + tall, color_white, TEXT_ALIGN_RIGHT)


							local ax, ay = board:GetWide() * 0.5, board:GetTall() * 0.5
							local size = board:GetTall() * 0.5
							surface.SetMaterial(allclearMat)
							--[[
								scale = 0.2,
								scale2 = 1,
								decaytime = SysTime() + 1,
								rotation = 360,
								alpha1 = 255,
								alpha2 = 255,
							]]
							for _, pc in ipairs(board.AllClears) do
								if(pc.decaytime < SysTime()) then
									pc.scale = GTetris.IncFV(pc.scale, -0.015, 0.1, 1.5)
									pc.alpha1 = GTetris.IncFV(pc.alpha1, -6, 0, 255)
									if(pc.alpha1 <= 0) then
										table.remove(board.AllClears, _)
									end
								else
									if(pc.rotation <= 0) then
										pc.scale = GTetris.IncFV(pc.scale, -0.002, 0.1, 1.5)
									else
										pc.scale = GTetris.IncFV(pc.scale, 0.075, 0.2, 1.5)
									end
								end

								if(pc.rotation <= 0) then
									surface.SetDrawColor(51, 43, 0, pc.alpha2)
									surface.DrawTexturedRectRotated(ax, ay, size * pc.scale2, size * pc.scale2, pc.rotation)
									pc.scale2 = pc.scale2 + GTetris.GetFixedValue(0.02)
									pc.alpha2 = GTetris.IncFV(pc.alpha2, -4, 0, 255)
								else
									pc.scale2 = pc.scale
								end

								pc.rotation = GTetris.IncFV(pc.rotation, -30, 0, 360)
								surface.SetDrawColor(255, 215, 0, pc.alpha1)
								surface.DrawTexturedRectRotated(ax, ay, size * pc.scale, size * pc.scale, pc.rotation)
							end

							board.PostRender(board)
							cam.PopModelMatrix()
					end
				end

			layer.Amount = layer.Amount + 1
			layer.BoardIndex = layer.BoardIndex + 1
			layer.Boards[boardID] = board
			if(localplayer) then
				layer.FocusingBoard = board
			end
			layer.SetupDefaultBoard(boardID)
			board.UpdateBoard()
			return board
		end

		layer.Alpha = 0
		layer.WinnerAnimAlpha = 255
		layer.Paint = function() end
		layer.Think = function()
			if(!layer.Exiting) then
				layer.Alpha = GTetris.IncFV(layer.Alpha, 15, 0, 255)
			else
				layer.Alpha = GTetris.IncFV(layer.Alpha, -15, 0, 255)
				if(layer.Alpha <= 0) then
					layer:Remove()
					return
				end
			end
			layer:SetAlpha(layer.Alpha)
			if(layer.WinnerAnim) then
				layer.WinnerAnimAlpha = GTetris.IncFV(layer.WinnerAnimAlpha, -3, 0, 255)
				layer:SetAlpha(layer.WinnerAnimAlpha)
			end
			if(layer.Sorting) then
				local fraction = math.Clamp(math.ease.OutQuad(1 - (layer.CurrentSortingTime - SysTime()) / layer.SortingTime), 0, 1)
				if(fraction >= 1) then
					fraction = 0
				end
				for _, board in pairs(layer.Boards) do
					local offsetX = board.PreSortPosX - board.TargetX
					local offsetY = board.PreSortPosY - board.TargetY
					board.CurrentXOffset = board.PreSortPosX - offsetX * fraction
					board.CurrentYOffset = board.PreSortPosY - offsetY * fraction
				end
				if(layer.CurrentSortingTime < SysTime()) then
					for _, board in pairs(layer.Boards) do
						board.CurrentXOffset = board.TargetX
						board.CurrentYOffset = board.TargetY
					end
					layer.Sorting = false
				end
			end
		end

	GTetris.BoardLayer = layer
	return layer
end

function GTetris.SetupDefaultBoard(board)
	if(!IsValid(GTetris.BoardLayer)) then return end

end

function GTetris.GetLocalPlayer()
	if(!IsValid(GTetris.BoardLayer)) then return end
	return GTetris.BoardLayer.GetLocalPlayer()
end

function GTetris.DestroyBoardLayer()
	if(!IsValid(GTetris.BoardLayer)) then return end
	GTetris.BoardLayer:Remove()
end

function GTetris.SortBoards(instant)
	if(!IsValid(GTetris.BoardLayer)) then return end
	GTetris.BoardLayer.SortBoards(instant)
end

function GTetris.UpdateBoardAmounts(amount)
	if(!IsValid(GTetris.BoardLayer)) then return end

end

function GTetris.CreateBoard(boardID, localplayer)
	if(!IsValid(GTetris.BoardLayer)) then return end
	local board = GTetris.BoardLayer.CreateBoard(boardID, localplayer)
	return board
end

function GTetris.RemoveBoardFromSortList(boardID)
	if(!IsValid(GTetris.BoardLayer)) then return end

end

function GTetris.SetSpinText(boardID, piece)
	if(!IsValid(GTetris.BoardLayer)) then return end
	local board = GTetris.BoardLayer.GetBoard(boardID)
	if(!IsValid(board)) then return end
	board.SpinText = (GTetris.BlockIDs[piece] || "?").." - Spin"
	board.SpinTextAlpha = 255
	board.SpinTextColor = GTetris.Blocks_Colors[piece] || color_white
	board.SpinXOffset = 0
end

local texts = {
	"Single",
	"Double",
	"Triple",
	"Quad",
}
function GTetris.SetClearText(boardID, lines)
	if(!IsValid(GTetris.BoardLayer)) then return end
	local board = GTetris.BoardLayer.GetBoard(boardID)
	if(!IsValid(board)) then return end
	local text = texts[lines] || lines
	board.ClearText = text
	board.ClearTextAlpha = 255
	board.ClearXOffset = 0
end

function GTetris.InsertAllClears(boardID)
	if(!IsValid(GTetris.BoardLayer)) then return end
	local board = GTetris.BoardLayer.GetBoard(boardID)
	if(!IsValid(board)) then return end
	table.insert(board.AllClears, {
		scale = 0.1,
		scale2 = 1,
		decaytime = SysTime() + 1.5,
		rotation = 360,
		alpha1 = 255,
		alpha2 = 175,
	})
end

function GTetris.GetBoard(boardID)
	if(!IsValid(GTetris.BoardLayer)) then return end
	return GTetris.BoardLayer.GetBoard(boardID)
end

function GTetris.Playsound(sd, pvol)
	local vol = 4
	if(pvol) then
		vol = pvol
	end
	sound.PlayFile(sd, "noplay", function(station, errCode, errStr)
		if(IsValid(station)) then
			station:SetVolume(vol)
			station:Play()
		end
	end)
end

function GTetris.PlaceblockSound(vol)
	GTetris.Playsound("sound/gtetris/general/place.mp3", vol)
end

function GTetris.ComboBreakSound()
	GTetris.Playsound("sound/gtetris/combo/combobreak.mp3")
end

function GTetris.HoldSound(vol)
	GTetris.Playsound("sound/gtetris/general/hold.mp3", vol)
end

function GTetris.RotateSound(bonus, vol)
	if(!bonus) then
		GTetris.Playsound("sound/gtetris/general/rotate.mp3", vol)
	else
		GTetris.Playsound("sound/gtetris/general/rotatebonus.mp3", vol)
	end
end

function GTetris.MoveSound(vol)
	GTetris.Playsound("sound/gtetris/general/move.mp3", vol)
end

function GTetris.SoftDropSound(vol)
	GTetris.Playsound("sound/gtetris/general/softdrop.mp3", vol)
end

function GTetris.BoardHitSound(vol)
	local index = math.random(1, 3)
	GTetris.Playsound("sound/gtetris/garbage/hit"..index..".mp3", vol)
end

function GTetris.BoardUpSound(vol)
	GTetris.Playsound("sound/gtetris/garbage/up.mp3", vol)
end

function GTetris.SendAttackSound(lines, vol)
	local index = 1
	if(lines > 5) then
		index = 3
	elseif(lines >=4) then
		index = 2
	else
		index = 1
	end
	GTetris.Playsound("sound/gtetris/garbage/send"..index..".mp3", vol)
end

function GTetris.ReceiveAttackSound(lines, vol)
	local index = 1
	if(lines > 6) then
		index = 3
	elseif(lines >=4) then
		index = 2
	else
		index = 1
	end
	GTetris.Playsound("sound/gtetris/garbage/receive"..index..".mp3", vol)
end

function GTetris.AllClearSound(vol)
	GTetris.Playsound("sound/gtetris/general/allclear.mp3", vol)
end

function GTetris.PlayClearSound(lines, spinBonus, combo, attackBonus, vol)
	if(spinBonus) then
		GTetris.Playsound("sound/gtetris/general/clearbonus.mp3", vol)
	else
		if(lines >= 4) then
			GTetris.Playsound("sound/gtetris/general/quad.mp3", vol)
		else
			GTetris.Playsound("sound/gtetris/general/clear.mp3", vol)
		end
	end

	if(combo > 0) then
		local index = "combo"..math.min(combo, 16)
		if(attackBonus) then
			index = index.."bonus"
		end
		GTetris.Playsound("sound/gtetris/combo/"..index..".mp3", vol)
	end
end
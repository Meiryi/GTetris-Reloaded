function GTetris.ProcessAttacks(localplayer, attacks)
	if(SERVER) then
		
	else

	end
end

function GTetris.GetComboBonus(combo, ruleset)
	if(ruleset == GTetris.Enums.COMBOTABLE_MULTIPLIER) then
		return math.floor(combo * 0.4)
	elseif(ruleset == GTetris.Enums.COMBOTABLE_INCREMENT) then
		return combo
	elseif(ruleset == GTetris.Enums.COMBOTABLE_SQUARING) then
		return combo * combo
	else -- None
		return 0
	end
end

function GTetris.GetAttacks(lines, combo, bonus, b2b, ruleset)
	local baseAttack = math.max(lines - 1, 0)
	if(lines >= 4) then
		baseAttack = 4
	end
	if(bonus) then
		baseAttack = lines * 2
	end
	local ComboBonus = GTetris.GetComboBonus(combo, ruleset)
	local B2BBonus = math.min(math.floor(b2b / 3), 4)
	if(lines <= 0) then
		B2BBonus = 0
	end
	local attack = baseAttack + ComboBonus + B2BBonus
	return attack
end

function GTetris.OnB4BChainBreak(b4b, mincharge)
	return math.max(b4b - mincharge, 0)
end

function GTetris.OnComboBreak(combo)

end
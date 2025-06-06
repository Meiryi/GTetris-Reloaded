GTetris.Enums = {}
GTetris.Enums.ROTATIONSYS_SRS = 1
GTetris.Enums.ROTATIONSYS_ARS = 2
GTetris.Enums.ROTATIONSYS_CLS = 3

GTetris.Enums.ENDING_WINNER = 1
GTetris.Enums.ENDING_ABORTED = 2

GTetris.Enums.SOUND_MOVE = 1
GTetris.Enums.SOUND_ROTATE = 2
GTetris.Enums.SOUND_ROTATEBONUS = 3
GTetris.Enums.SOUND_HOLD = 4
GTetris.Enums.SOUND_PLACE = 5
GTetris.Enums.SOUND_DROP = 6
GTetris.Enums.SOUND_COMBOBREAK = 7
GTetris.Enums.SOUND_BOARDUP = 8
GTetris.Enums.SOUND_CLEARLINE = 9
GTetris.Enums.SOUND_CLEARQUAD = 10

GTetris.Enums.RotationSystems = {
	{
		title = "SRS",
		value = GTetris.Enums.ROTATIONSYS_SRS,
	},
	{
		title = "ARS",
		value = GTetris.Enums.ROTATIONSYS_ARS,
	},
	{
		title = "Classic",
		value = GTetris.Enums.ROTATIONSYS_CLS,
	},
}

GTetris.Enums.ALLOWEDSPINS_TSPIN = 1
GTetris.Enums.ALLOWEDSPINS_ALL = 2
GTetris.Enums.ALLOWEDSPINS_NONE = 3
GTetris.Enums.ALLOWEDSPINS_STUPID = 4
GTetris.Enums.AllowedSpins = {
	{
		title = "T-Spin",
		value = GTetris.Enums.ALLOWEDSPINS_TSPIN,
	},
	{
		title = "All",
		value = GTetris.Enums.ALLOWEDSPINS_ALL,
	},
	{
		title = "None",
		value = GTetris.Enums.ALLOWEDSPINS_NONE,
	},
	{
		title = "Everything is a spin",
		value = GTetris.Enums.ALLOWEDSPINS_STUPID,
	},
}

GTetris.Enums.COMBOTABLE_MULTIPLIER = 1
GTetris.Enums.COMBOTABLE_INCREMENT = 2
GTetris.Enums.COMBOTABLE_SQUARING = 3
GTetris.Enums.COMBOTABLE_NONE = 4
GTetris.Enums.ComboTables = {
	{
		title = "Multiplier",
		value = GTetris.Enums.COMBOTABLE_MULTIPLIER,
	},
	{
		title = "Increment",
		value = GTetris.Enums.COMBOTABLE_INCREMENT,
	},
	{
		title = "Squaring",
		value = GTetris.Enums.COMBOTABLE_SQUARING,
	},
	{
		title = "None",
		value = GTetris.Enums.COMBOTABLE_NONE,
	},

}

GTetris.Enums.ATTACKENTRY_INSTANT = 1
GTetris.Enums.ATTACKENTRY_CONTINUOUS = 2
GTetris.Enums.AttackEntry = {
	{
		title = "Instant",
		value = GTetris.Enums.ATTACKENTRY_INSTANT,
	},
	{
		title = "Continuous",
		value = GTetris.Enums.ATTACKENTRY_CONTINUOUS,
	},
}

GTetris.Enums.BAGSYS_7BAG = 1
GTetris.Enums.BAGSYS_14BAG = 2
GTetris.Enums.BAGSYS_35BAG = 3
GTetris.Enums.BAGSYS_RANDOM = 4
GTetris.Enums.BagSystems = {
	{
		title = "7-Bag",
		value = GTetris.Enums.BAGSYS_7BAG,
	},
	{
		title = "14-Bag",
		value = GTetris.Enums.BAGSYS_14BAG,
	},
	{
		title = "35-Bag",
		value = GTetris.Enums.BAGSYS_35BAG,
	},
	{
		title = "Random",
		value = GTetris.Enums.BAGSYS_RANDOM,
	},
}



GTetris.Rulesets = {}

-- Gameplay
GTetris.Rulesets.Width = 10
GTetris.Rulesets.Height = 20
GTetris.Rulesets.Gravity = 1
GTetris.Rulesets.AutolockTime = 1
GTetris.Rulesets.BagSystem = GTetris.Enums.BAGSYS_7BAG
GTetris.Rulesets.Seed = 1024

-- Spin System
GTetris.Rulesets.AllowedSpins = GTetris.Enums.ALLOWEDSPINS_TSPIN
GTetris.Rulesets.SpinSystem = GTetris.Enums.ROTATIONSYS_SRS

-- Attacks
GTetris.Rulesets.B4BCharge = true
GTetris.Rulesets.B4BChargeAmount = 3
GTetris.Rulesets.AttackMultiplier = 1
GTetris.Rulesets.AttackArriveTime = 0.25
GTetris.Rulesets.AttackApplyDelay = 0.5
GTetris.Rulesets.AttackCap = 8
GTetris.Rulesets.AttacksEntry = GTetris.Enums.ATTACKENTRY_INSTANT
GTetris.Rulesets.ComboTable = GTetris.Enums.COMBOTABLE_MULTIPLIER

GTetris.Rulesets.Default = {}
GTetris.Rulesets.Default.Width = 10
GTetris.Rulesets.Default.Height = 20
GTetris.Rulesets.Default.Gravity = 1
GTetris.Rulesets.Default.AutolockTime = 1
GTetris.Rulesets.Default.BagSystem = GTetris.Enums.BAGSYS_7BAG
GTetris.Rulesets.Default.Seed = 1024

-- Spin System
GTetris.Rulesets.Default.AllowedSpins = GTetris.Enums.ALLOWEDSPINS_TSPIN
GTetris.Rulesets.Default.SpinSystem = GTetris.Enums.ROTATIONSYS_SRS

-- Attacks
GTetris.Rulesets.Default.B4BCharge = true
GTetris.Rulesets.Default.B4BChargeAmount = 3
GTetris.Rulesets.Default.AttackMultiplier = 1
GTetris.Rulesets.Default.AttackArriveTime = 0.25
GTetris.Rulesets.Default.AttackApplyDelay = 0.5
GTetris.Rulesets.Default.AttackCap = 8
GTetris.Rulesets.Default.AttacksEntry = GTetris.Enums.ATTACKENTRY_INSTANT
GTetris.Rulesets.Default.ComboTable = GTetris.Enums.COMBOTABLE_MULTIPLIER

function GTetris.ApplyRulesets(rulesets)
	for key, value in pairs(rulesets) do
		if(GTetris.Rulesets[key] != nil) then
			GTetris.Rulesets[key] = value
		end
	end
end

function GTetris.ResetRulesets()
	for key, value in pairs(GTetris.Rulesets.Default) do
		if(GTetris.Rulesets[key] != nil) then
			GTetris.Rulesets[key] = value
		end
	end
end
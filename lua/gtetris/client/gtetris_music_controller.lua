GTetris.OSTs = {
	calm = {
		{
			title = "Wind Trail - Chika",
			path = "gtetris/ost/calm/windtrail.mp3",
		},
		{
			title = "Muscat and White Dishes - Takahashi Takashi",
			path = "gtetris/ost/calm/muscat.mp3",
		},
		{
			title = "Summer Sky and Homework - Takahashi Takashi",
			path = "gtetris/ost/calm/summersky.mp3",
		},
		{
			title = "Step on the Scarlet Soil - Kamoking",
			path = "gtetris/ost/calm/steponthescarlet.mp3",
		},
		{
			title = "Hanging Out In Tokyo - Meesan",
			path = "gtetris/ost/calm/tokyo.mp3",
		},
		{
			title = "Main Street - Chika",
			path = "gtetris/ost/calm/mainstreet.mp3",
		},
		{
			title = "Twenty-First Century People - Omegane",
			path = "gtetris/ost/calm/centurypeople.mp3",
		},
		{
			title = "Waiting for Spring to Come - Omegane",
			path = "gtetris/ost/calm/spring.mp3",
		},
		{
			title = "Cherry Blossom Season - Chika",
			path = "gtetris/ost/calm/cherry.mp3",
		},
		{
			title = "Entrance Wreath - Chika",
			path = "gtetris/ost/calm/wreath.mp3",
		},
	},
	battle = {
		{
			title = "Backwater - Kamoking",
			path = "gtetris/ost/battle/backwater.mp3",
		},
		{
			title = "Ice Eyes - Kamoking",
			path = "gtetris/ost/battle/iceeyes.mp3",
		},
		{
			title = "Maze of the Abyss - Kamoking",
			path = "gtetris/ost/battle/maze.mp3",
		},
		{
			title = "Over The Horizon - Kamoking",
			path = "gtetris/ost/battle/horizon.mp3",
		},
		{
			title = "Samurai Sword - Kamoking",
			path = "gtetris/ost/battle/samurai.mp3",
		},
		{
			title = "Storm Spirit - Kamoking",
			path = "gtetris/ost/battle/storm.mp3",
		},
		{
			title = "Super Machine Soul - Kamoking",
			path = "gtetris/ost/battle/machine.mp3",
		},
		{
			title = "The Time is Now - Tomoki",
			path = "gtetris/ost/battle/time.mp3",
		},
		{
			title = "Ultra Super Heroes - Kamoking",
			path = "gtetris/ost/battle/heroes.mp3",
		},
		{
			title = "Universe 5239 - Kamoking",
			path = "gtetris/ost/battle/universe.mp3",
		},
	},
}

GTetris.CurrentVolume = GTetris.CurrentVolume || 0
GTetris.DesiredMusic = "null"

function GTetris.PlayMusic(music)
	if(!music) then
		return
	end

	if(IsValid(GTetris.CurrentMusicChannel)) then
		GTetris.CurrentMusicChannel:Stop()
	end

	sound.PlayFile("sound/"..music, "noplay", function(station, errCode, errStr)
		if(IsValid(station)) then
			station:SetVolume(GTetris.CurrentVolume)
			station:Play()
			station:EnableLooping(true)
			GTetris.CurrentMusicChannel = station
			GTetris.CurrentMusic = music
		end
	end)
end

function GTetris.ChooseCalmMusic()
	GTetris.DesiredMusic = GTetris.OSTs.calm[math.random(1, #GTetris.OSTs.calm)].path
end

function GTetris.ChooseBattleMusic()
	GTetris.DesiredMusic = GTetris.OSTs.battle[math.random(1, #GTetris.OSTs.battle)].path
end

hook.Add("DrawOverlay", "GTetris_MusicController", function()
	if(IsValid(GTetris.MainUI)) then
		if(IsValid(GTetris.CurrentMusicChannel)) then
			if(GTetris.CurrentMusic == GTetris.DesiredMusic) then
				GTetris.CurrentVolume = math.Clamp(GTetris.CurrentVolume + GTetris.GetFixedValue(0.025), 0, 1)
			else
				GTetris.CurrentVolume = math.Clamp(GTetris.CurrentVolume - GTetris.GetFixedValue(0.025), 0, 1)
				if(GTetris.CurrentVolume <= 0) then
					GTetris.PlayMusic(GTetris.DesiredMusic)
				end
			end
			if(IsValid(GTetris.CurrentMusicChannel)) then
				GTetris.CurrentMusicChannel:SetVolume(GTetris.CurrentVolume)
			end
		else
			GTetris.CurrentVolume = 0
			GTetris.PlayMusic(GTetris.DesiredMusic)
		end
	else
		if(IsValid(GTetris.CurrentMusicChannel)) then
			GTetris.CurrentMusicChannel:Stop()
			GTetris.CurrentMusicChannel = nil
		end
		GTetris.CurrentMusic = nil
		GTetris.DesiredMusic = "null"
	end
end)
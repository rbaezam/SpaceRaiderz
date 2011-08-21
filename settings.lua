module(..., package.seeall)

local _W = display.contentWidth
local _H = display.contentHeight

local titleFontName = "Harrowprint"

-- Main function - MUST return a display.newGroup()
function new()

	local musicOptionPosY = 100
	local soundOptionPosY = 150
	local showTutorialPosY = 200
	local resetScoresPosY = 250

	local localGroup = display.newGroup()
	
	-- Background
	local background = display.newImageRect("images/background.png", _W, _H)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	localGroup:insert(background)
	
	-- Title
	local title = display.newText("Settings", 0, 0, titleFontName, 32)
	title:setTextColor( 255,255,255)
	title.x = display.contentCenterX
	title.y = title.height
	title.name = "title"
	localGroup:insert(title)
--[[
	local musicOption = display.newImage("music_on.png")
	musicOption.x = display.contentCenterX
	musicOption.y = musicOptionPosY
	localGroup:insert(musicOption)

	local soundOption = display.newImage("sound_on.png")
	soundOption.x = display.contentCenterX
	soundOption.y = soundOptionPosY
	localGroup:insert(soundOption)

	local showTutorial = display.newImage("show_tutorial.png")
	showTutorial.x = display.contentCenterX
	showTutorial.y = showTutorialPosY
	localGroup:insert(showTutorial)

	local resetScores = display.newImage("reset_highscores.png")
	resetScores.x = display.contentCenterX
	resetScores.y = resetScoresPosY
	localGroup:insert(resetScores)
]]
	-- Return to menu
	local returnMenu = display.newImage("images/return_menu.png")
	returnMenu.x = display.contentCenterX
	returnMenu.y = _H - returnMenu.height/2 - 48
	localGroup:insert(returnMenu)
	
	local function onReturnMenu ( event )
		if ("ended" == event.phase) then
			director:changeScene("menu","fade")
		end
	end
	returnMenu:addEventListener("touch", onReturnMenu)
	
	unloadMe = function()
	end	
	
	-- MUST return a display.newGroup()
	return localGroup
end

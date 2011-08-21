module(..., package.seeall)

local scores = require("scores")
local _W = display.contentWidth
local _H = display.contentHeight

local titleFontName = "Harrowprint"
local scoreFontName = native.systemFont

-- Main function - MUST return a display.newGroup()
function new()
	local localGroup = display.newGroup()
	
	-- Background
	local background = display.newImageRect("images/background.png", _W, _H)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	localGroup:insert(background)
	
	local highScores = {}
	highScores = scores.readHighScores()

	local titleText = display.newText("Top scores", 10, 10, titleFontName, 32)
	localGroup:insert(titleText)

	local yPos = 70

	for index,score in ipairs(highScores) do

		local scoreText = score.pos .. " - " .. score.name .. ": " .. score.score
		local scoreDisplay = display.newText(scoreText, 0, 0, scoreFontName, 16)
		scoreDisplay:setReferencePoint(display.CenterLeftReferencePoint)
		scoreDisplay.x = 40
		scoreDisplay.y = yPos
		yPos = yPos + scoreDisplay.height/1.5
		localGroup:insert(scoreDisplay)

	end

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


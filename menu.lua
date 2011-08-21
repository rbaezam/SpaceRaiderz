module(..., package.seeall)

local _W = display.contentWidth
local _H = display.contentHeight

local playButton
local helpButton
local aboutButton
local settingsButton
local scoresButton

local rotationScoresButton = 0.2
local rotationSettingsButton = 0.2
local rotationPlayButton = 0.2
local rotationHelpButton = 0.2
local rotationAboutButton = 0.2

local maxRotationButton = 5

local function onUpdate(event)

    scoresButton.rotation = scoresButton.rotation + rotationScoresButton
    if math.abs(scoresButton.rotation) > maxRotationButton then
        rotationScoresButton = rotationScoresButton * -1
    end

    settingsButton.rotation = settingsButton.rotation + rotationSettingsButton
    if math.abs(settingsButton.rotation) > maxRotationButton then
        rotationSettingsButton = rotationSettingsButton * -1
    end

    playButton.rotation = playButton.rotation + rotationPlayButton
    if math.abs(playButton.rotation) > maxRotationButton then
        rotationPlayButton = rotationPlayButton * -1
    end

    helpButton.rotation = helpButton.rotation + rotationHelpButton
    if math.abs(helpButton.rotation) > maxRotationButton then
        rotationHelpButton = rotationHelpButton * -1
    end

    aboutButton.rotation = aboutButton.rotation + rotationAboutButton
    if math.abs(aboutButton.rotation) > maxRotationButton then
        rotationAboutButton = rotationAboutButton * -1
    end
end

local function cleanUp()
    Runtime:removeEventListener("enterFrame", onUpdate)
end

local function gotoScene(target)
    cleanUp()
    director:changeScene(target.scene, "overFromTop")
end

                        
-- Main function - MUST return a display.newGroup()
function new()
	local ui = require("ui")

	local localGroup = display.newGroup()
	
	-- Background
	local background = display.newImage("images/background.png")
	localGroup:insert(background)
	
	-- Menu Buttons - Start

    playButton = display.newImage("images/btn_play.png")
    playButton.x = _W/2
    playButton.y = 160
    playButton.scene = "play"

    local function onPlayButton(event)

        transition.to(playButton, {time=100, xScale=2, yScale=2})
        transition.to(playButton, {time=400, delay=400, xScale=0.1, yScale=0.1, onComplete=gotoScene})

    end

    playButton:addEventListener("touch", onPlayButton)
    localGroup:insert(playButton)

    scoresButton = display.newImage("images/btn_scores.png")
    scoresButton.x = 80
    scoresButton.y = 60
    scoresButton.scene = "highscores"

    local function onScoresButton(event)

        transition.to(scoresButton, {time=100, xScale=2, yScale=2})
        transition.to(scoresButton, {time=400, delay=100, xScale=0.1, yScale=0.1, onComplete=gotoScene})
    end

    scoresButton:addEventListener("touch", onScoresButton)
    localGroup:insert(scoresButton)

    settingsButton = display.newImage("images/btn_settings.png")
    settingsButton.x = 240
    settingsButton.y = 60
    settingsButton.scene = "settings"

    local function onSettingsButton(event)

        transition.to(settingsButton, {time=100, xScale=2, yScale=2})
        transition.to(settingsButton, {time=400, delay=100, xScale=0.1, yScale=0.1, onComplete=gotoScene})

    end

    settingsButton:addEventListener("touch", onSettingsButton)
    localGroup:insert(settingsButton)

    helpButton = display.newImage("images/btn_help.png")
    helpButton.x = 80
    helpButton.y = 260
    helpButton.scene = "help"

    local function onHelpButton(event)

        transition.to(helpButton, {time=100, xScale=2, yScale=2})
        transition.to(helpButton, {time=400, delay=100, xScale=0.1, yScale=0.1, onComplete=gotoScene})
    end

    helpButton:addEventListener("touch", onHelpButton)
    localGroup:insert(helpButton)

    aboutButton = display.newImage("images/btn_about.png")
    aboutButton.x = 240
    aboutButton.y = 260
    aboutButton.scene = "about"

    local function onAboutButton(event)

        transition.to(aboutButton, {time=100, xScale=2, yScale=2})
        transition.to(aboutButton, {time=400, delay=100, xScale=0.1, yScale=0.1, onComplete=gotoScene})

    end

    aboutButton:addEventListener("touch", onAboutButton)
    localGroup:insert(aboutButton)

    scoresButton.rotation = -4
    settingsButton.rotation = -2
    playButton.rotation = 0
    helpButton.rotation = 2
    aboutButton.rotation = 4

    --Runtime:removeEventListener("enterFrame", onUpdate)
    Runtime:addEventListener("enterFrame", onUpdate)

	-- MUST return a display.newGroup()
	return localGroup
end

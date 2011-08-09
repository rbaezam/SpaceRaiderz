module(..., package.seeall)

-- Main function - MUST return a display.newGroup()
function new()
	local ui = require("ui")
	
	local localGroup = display.newGroup()
	
	-- Background
	local background = display.newImage("images/bk-default.png")
	localGroup:insert(background)
	
	-- Menu Buttons - Start

  local playButton = nil
  local function onPlay ( event )
    if event.phase == "release" and playButton.isActive then
      director:changeScene("play", "fade", 30.0,60.0,90.0)
    end
  end	
  playButton = ui.newButton{
		defaultSrc = "images/btn-play.png",
		defaultX = 160,
		defaultY = 32,		
		overSrc = "images/btn-play-over.png",
		overX = 160,
		overY = 32,		
		onEvent = onPlay,
		id = "playButton",
		text = "",
		font = "Helvetica",
		textColor = { 255, 255, 255, 255 },
		emboss = false
	}
	playButton.x = 160
	playButton.y = 80
	playButton.isActive = true
	localGroup:insert(playButton)
  

  local settingsButton = nil
  local function onSettings ( event )
    if event.phase == "release" and settingsButton.isActive then
      director:changeScene("settings", "fade", "green")
    end
  end	
  settingsButton = ui.newButton{
		defaultSrc = "images/btn-settings.png",
		defaultX = 160,
		defaultY = 32,		
		overSrc = "images/btn-settings-over.png",
		overX = 160,
		overY = 32,		
		onEvent = onSettings,
		id = "settingsButton",
		text = "",
		font = "Helvetica",
		textColor = { 255, 255, 255, 255 },
		emboss = false
	}
	settingsButton.x = 160
	settingsButton.y = 130
	settingsButton.isActive = true
	localGroup:insert(settingsButton)
  

  local helpButton = nil
  local function onHelp ( event )
    if event.phase == "release" and helpButton.isActive then
      director:changeScene("help", "overFromTop")
    end
  end	
  helpButton = ui.newButton{
		defaultSrc = "images/btn-help.png",
		defaultX = 160,
		defaultY = 32,		
		overSrc = "images/btn-help-over.png",
		overX = 160,
		overY = 32,		
		onEvent = onHelp,
		id = "helpButton",
		text = "",
		font = "Helvetica",
		textColor = { 255, 255, 255, 255 },
		emboss = false
	}
	helpButton.x = 160
	helpButton.y = 180
	helpButton.isActive = true
	localGroup:insert(helpButton)
  

  local aboutButton = nil
  local function onAbout ( event )
    if event.phase == "release" and aboutButton.isActive then
      director:changeScene("about", "moveFromLeft")
    end
  end	
  aboutButton = ui.newButton{
		defaultSrc = "images/btn-about.png",
		defaultX = 160,
		defaultY = 32,		
		overSrc = "images/btn-about-over.png",
		overX = 160,
		overY = 32,		
		onEvent = onAbout,
		id = "aboutButton",
		text = "",
		font = "Helvetica",
		textColor = { 255, 255, 255, 255 },
		emboss = false
	}
	aboutButton.x = 160
	aboutButton.y = 230
	aboutButton.isActive = true
	localGroup:insert(aboutButton)
  
	-- Menu Buttons - End
					
	unloadMe = function()
	end
						
	-- MUST return a display.newGroup()
	return localGroup
end

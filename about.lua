module(..., package.seeall)

local _W = display.contentWidth
local _H = display.contentHeight

-- Main function - MUST return a display.newGroup()
function new()
	local localGroup = display.newGroup()
	
	-- Background
	local background = display.newImageRect("images/background.png", _W, _H)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	localGroup:insert(background)

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

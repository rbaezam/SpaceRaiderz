display.setStatusBar( display.HiddenStatusBar )

local ads = require("ads")

local director = require("director")
local mainGroup = display.newGroup()

local _W = display.contentWidth
local _H = display.contentHeight

--local appID = "4028cba631d63df10131d9596b270026"
local appID = "4028cb962895efc50128fc99d4b7025b"
local adNetwork = "inmobi"

local function main()
    ads.init(adNetwork, appID, nil)

    ads.show("banner320x48", {x=0, y=_H-48, interval=20, testMode=true})

	mainGroup:insert(director.directorView)
	director:changeScene("loadmenu")	
	return true
end

main()
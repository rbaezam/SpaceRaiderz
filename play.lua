module(..., package.seeall)

local physics = require 'physics'
physics.start()
--physics.setScale(60)
physics.setGravity(0, 0)
--physics.setDrawMode("hybrid")

_W = display.contentWidth
_H = display.contentHeight

local player
local playerMovementSpeed = 2

local background1
local background2

local enemyTypes = {"car1", "car2", "car3", "truck", "bus"}
local enemies={}
local maxEnemies = 5
local minEnemySpeed = 1
local maxEnemySpeed = 50

local goodTypes = {"good1", "good2", "good3"}
local goods = {}
local maxGoods = 3

system.setAccelerometerInterval(50)
if system.getInfo("environment") == "simulator" then
	local rcorona = require("rcorona")
	rcorona.startServer(8181)
end

function startGame()
	for i=1,maxEnemies do
		enemies[i] = nil
	end
end

function initPlayer(group)
	player = display.newImage("images/nave.png")
	player.x = _W / 2
	player.y = _H - player.contentHeight
	physics.addBody(player, "static")
	group:insert(player)
end

local createGood = function()
	local good
	local type = math.random(1, #goodTypes)
	local x = math.random(0, _W-30)
	
	if type == 1 then
		good = display.newCircle(x, 0, 10)
		good.type = goodTypes[1]
		good:setFillColor(100,0,0)
	elseif type == 2 then
		good = display.newCircle(x, 0, 20)
		good.type = goodTypes[2]
		good:setFillColor(0,100,0)
	elseif type == 3 then
		good = display.newCircle(x, 0, 30)
		good.type = goodTypes[3]
		good:setFillColor(0,0,100)
	end
	
	physics.addBody(good, "static")
	
	return good
end

local createEnemy = function()

	local availLeftPos = {0, _W-30}
	local availDirection = {"right", "left"}

	local y = math.random(0, _H/2)
	local enemy
	
	local type = math.random(1, #enemyTypes)
	if type == 1 then
		enemy = display.newRect(0, y, 30, 30)
		enemy.type = enemyTypes[1]
		enemy:setFillColor(255,0,0)
		enemy.speed = 0.5
	elseif type == 2 then
		enemy = display.newRect(0, y, 35, 30)
		enemy.type = enemyTypes[2]
		enemy:setFillColor(0,255,0)
		enemy.speed = 1
	elseif type == 3 then
		enemy = display.newRect(0, y, 30, 30)
		enemy.type = enemyTypes[3]
		enemy:setFillColor(0,0,255)
		enemy.speed = 5
	elseif type == 4 then
		enemy = display.newRect(0, y, 50, 30)
		enemy.type = enemyTypes[4]
		enemy:setFillColor(255,255,0)
		enemy.speed = 3
	elseif type == 5 then
		enemy = display.newRect(0, y, 40, 30)
		enemy.type = enemyTypes[5]
		enemy:setFillColor(255,0,255)
		enemy.speed = 2
	end
	
	enemy.speed = math.random(minEnemySpeed, maxEnemySpeed) / 10

	if math.random(1, 2) == 1 then
		enemy.x = availLeftPos[1]
		enemy.direction = availDirection[1]
	else
		enemy.x = availLeftPos[2]
		enemy.direction = availDirection[2]
	end

	physics.addBody(enemy, "dynamic")

	return enemy
end

-- Main function - MUST return a display.newGroup()
function new()
	local localGroup = display.newGroup()

	-- Background
	background1 = display.newImage("images/bg_game.png")
	background1:setReferencePoint(display.CenterLeftReferencePoint)
	background1.x = 0
	background1.y = 0
	localGroup:insert(background1)

	background2 = display.newImage("images/bg_game.png")
	background2:setReferencePoint(display.CenterLeftReferencePoint)
	background2.x = 0
	background2.y = _H
	localGroup:insert(background2)

	-- Title
	local title = display.newText("Touch to go back", 0, 0, native.systemFontBold, 16)
	title:setTextColor(255, 255, 255)
	title.x = display.contentCenterX
	title.y = display.contentCenterY
	title.name = "title"
	localGroup:insert(title)

	local tPrevious = system.getTimer()

	local function update(event)
		-- Hacer scrolling del background
		local tDelta = event.time - tPrevious
		tPrevious = event.time

		local yOffset = (0.15*tDelta)

		background1.y = background1.y + yOffset
		background2.y = background2.y + yOffset

		if background1.y > 720 then
			background1:translate(0, -_H*2)
		end
		if background2.y > 720 then
			background2:translate(0, -_H*2)
		end

		-- Mostrar nuevos enemigos
		for i=1,maxEnemies do
			if enemies[i] == nil then
				local newEnemy = createEnemy()
				localGroup:insert(newEnemy)
				enemies[i] = newEnemy
			else
				enemies[i].y = enemies[i].y + playerMovementSpeed
				if enemies[i].direction == "left" then
					enemies[i].x = enemies[i].x - enemies[i].speed
				elseif enemies[i].direction == "right" then
					enemies[i].x = enemies[i].x + enemies[i].speed
				end
			end

			if enemies[i] ~= nil then
				if enemies[i].x > _W or enemies[i].x < 0 or enemies[i].y > _H or enemies[i].y < 0 then
					enemies[i]:removeSelf()
					enemies[i] = nil
				end
			end
		end
		
		-- Mostrar nuevos objetos
		for i=1,maxGoods do
			if goods[i] == nil then
				
				local spawnRate = math.random(1,500)
				local newGood
				
				if spawnRate > 0 and spawnRate <= 3 then
					newGood = createGood("good1")
				elseif spawnRate >= 4 and spawnRate <= 6 then
					newGood = createGood("good2")
				elseif spawnRate >= 7 and spawnRate <= 9 then
					newGood = createGood("good3")
				else
					newGood = nil
				end
				
				if newGood ~= nil then
					localGroup:insert(newGood)
					goods[i] = newGood
				end
			else
				goods[i].y = goods[i].y + playerMovementSpeed
			end

			if goods[i] ~= nil then
				if goods[i].y > _H then
					goods[i]:removeSelf()
					goods[i] = nil
				end
			end

		end

		-- Eliminar objetos desaparecidos
	end

	startGame()
	initPlayer(localGroup)

	local acc = {}

	function acc:accelerometer(e)
		local centerX = _W / 2
		player.x = centerX + (centerX * e.xGravity)
	end

	Runtime:addEventListener("accelerometer", acc)
	Runtime:addEventListener("enterFrame", update)

	local cleanUp = function()
		--background:removeEventListener("touch", touched)
		Runtime:removeEventListener("accelerometer", acc)
		Runtime:removeEventListener("enterFrame", update)
	end

	-- Touch to go back
	local function touched(event)
		if ("ended" == event.phase) then
			cleanUp()
			--director:changeScene("menu", "fade")
			director:changeScene("menu", "fade")
		end
	end

	background1:addEventListener("touch", touched)
	background2:addEventListener("touch", touched)
	if system.getInfo("environment") == "simulator" then
		-- Register object to rcorona
		rcorona.registerTouch(background1)
		rcorona.registerTouch(background2)
	end	

	-- MUST return a display.newGroup()
	return localGroup
end

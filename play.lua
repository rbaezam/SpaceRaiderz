module(..., package.seeall)

local physics = require 'physics'
physics.start()
--physics.setScale(60)
physics.setGravity(0, 0)
--physics.setDrawMode("hybrid")

_W = display.contentWidth
_H = display.contentHeight

local isPlaying
local gameSpeed = 1

local player
local playerMovementSpeed = 10

local playerScore = 0

local scoreText

local background1
local background2

local enemyTypes = {"car1", "car2", "car3", "truck", "bus"}
local enemies={}
local maxEnemies = 2
local minEnemySpeed = 5
local maxEnemySpeed = 20

local goodTypes = {"good1", "good2", "good3"}
local goodsToRemove = {}
local goods = {}
local maxGoods = 2

system.setAccelerometerInterval(70)
if system.getInfo("environment") == "simulator" then
	local rcorona = require("rcorona")
	rcorona.startServer(8181)
end

-- THE EXPLOSION FUNCTION
local particles = {} -- particle table
local function explosion (theX, theY, blood)  -- blood is BOOL
	local particleCount = 50 -- number of particles per explosion 
	for  i = 1, particleCount do
		local theParticle = {}
		theParticle.object = display.newRect(theX,theY,3,3)
		if blood == true then
			theParticle.object:setFillColor(250,0,0)
		else
			theParticle.object:setFillColor(200,200,0)
		end
		theParticle.xMove = math.random (10) - 5
		theParticle.yMove = math.random (5) * - 1
		theParticle.gravity = 0.5
		table.insert(particles, theParticle)
	end
end

local showEndGame = function()

	local cleanUp = function()
		--background:removeEventListener("touch", touched)
		Runtime:removeEventListener("accelerometer", onTilt)
		Runtime:removeEventListener("enterFrame", update)
		system.setIdleTimer(true)
	end

	cleanUp()
	director:changeScene("menu", "fade")

end

local createGood = function(type)
	local good
	local x = math.random(0, _W-30)
	
	if type == 1 then
		good = display.newCircle(x, 0, 3)
		good.type = goodTypes[1]
		good.points = 1
		good:setFillColor(100,0,0)
	elseif type == 2 then
		good = display.newCircle(x, 0, 5)
		good.type = goodTypes[2]
		good.points = 2
		good:setFillColor(0,100,0)
	elseif type == 3 then
		good = display.newCircle(x, 0, 7)
		good.type = goodTypes[3]
		good.points = 3
		good:setFillColor(0,0,100)
	end
	
	good.name = "good"
	physics.addBody(good, "dynamic", {bounce=0})

	good.collision = onCollision
	good:addEventListener("collision", good)
	
	return good
end

local createEnemy = function()

	local availLeftPos = {0, _W-30}
	local availDirection = {"right", "left"}

	local y = math.random(0, _H/2)
	local enemy
	
	local type = math.random(1, #enemyTypes)
	if type == 1 then
		enemy = display.newRect(0, y, 10, 10)
		enemy.type = enemyTypes[1]
		enemy:setFillColor(255,0,0)
		enemy.speed = 0.5
	elseif type == 2 then
		enemy = display.newRect(0, y, 15, 10)
		enemy.type = enemyTypes[2]
		enemy:setFillColor(0,255,0)
		enemy.speed = 1
	elseif type == 3 then
		enemy = display.newRect(0, y, 12, 10)
		enemy.type = enemyTypes[3]
		enemy:setFillColor(0,0,255)
		enemy.speed = 4
	elseif type == 4 then
		enemy = display.newRect(0, y, 18, 10)
		enemy.type = enemyTypes[4]
		enemy:setFillColor(255,255,0)
		enemy.speed = 3
	elseif type == 5 then
		enemy = display.newRect(0, y, 5, 10)
		enemy.type = enemyTypes[5]
		enemy:setFillColor(255,0,255)
		enemy.speed = 2
	end
	
	--enemy.speed = math.random(minEnemySpeed, maxEnemySpeed) / 10
	enemy.name = "enemy"

	if math.random(1, 2) == 1 then
		enemy.x = availLeftPos[1]
		enemy.direction = availDirection[1]
	else
		enemy.x = availLeftPos[2]
		enemy.direction = availDirection[2]
	end

	physics.addBody(enemy, "dynamic", {bounce=0, friction=0, density=0, isSensor=true})

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

	scoreText = display.newText("Score: " .. playerScore, 0, 0, native.systemFontBold, 12)
	localGroup:insert(scoreText)

	local tPrevious = system.getTimer()

	local function update(event)

		if isPlaying then
			local tDelta = event.time - tPrevious
			tPrevious = event.time

			local yOffset = ((gameSpeed/10)*tDelta)

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
					enemies[i].y = enemies[i].y + (gameSpeed/10 * tDelta)
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
					
					local spawnRate = math.random(1,(gameSpeed*tDelta)*500)
					local newGood
					
					if spawnRate > 0 and spawnRate <= 3 then
						newGood = createGood(1)
					elseif spawnRate >= 4 and spawnRate <= 6 then
						newGood = createGood(2)
					elseif spawnRate >= 7 and spawnRate <= 9 then
						newGood = createGood(3)
					else
						newGood = nil
					end
					
					if newGood ~= nil then
						localGroup:insert(newGood)
						goods[i] = newGood
					end
				else
					goods[i].y = goods[i].y + gameSpeed
				end

				if goods[i] ~= nil then
					if goods[i].y > _H then
						goods[i]:removeSelf()
						goods[i] = nil
					end
				end

			end

			-- Eliminar objetos desaparecidos
			for i=1, #goodsToRemove do

				if goodsToRemove[i] ~= nil then
					for j=1,maxGoods do
						if goods[j] == goodsToRemove[i] then
							goods[j]:removeSelf()
							goods[j] = nil
						end
					end

					--if goodsToRemove[i] ~= nil then
						--goodsToRemove[i].removeSelf()
						--goodsToRemove[i] = nil
					--end
				end
			end


			-- Show score
			scoreText.text = "Score: " .. playerScore
		end

			-- PARTICLES MOVING
			for i,val in pairs(particles) do
				-- move each particle
		        val.yMove = val.yMove + val.gravity
		        val.object.x = val.object.x + val.xMove
		        val.object.y = val.object.y + val.yMove
			   
			   -- remove particles that are out of bound                            
			   if val.object.y > _H or val.object.x > _W or val.object.x < 0 or val.object.y < 0 then 
			        val.object:removeSelf();
			        particles [i] = nil
			   end
			end
	end

	local function onCollision(self, event)

		if self.name == "player" and event.other.name == "good" then

			local good = event.other
			table.insert(goodsToRemove, good)

			playerScore = playerScore + good.points

		elseif self.name == "player" and event.other.name == "enemy" then

			--print("collision " .. self.name .. " " .. event.other.name)
			local enemy = event.other
			
			player:removeSelf()
			enemy:removeSelf()

			explosion(player.x, player.y)

			isPlaying = false
			
			local endGame = function()
				showEndGame()
				timer.cancel(tmrEndGame)
			end
			local tmrEndGame = timer.performWithDelay(1000, endGame, 1)
			--showEndGame()
		end

	end

	function initPlayer(group)
		player = display.newImage("images/nave.png")
		player.x = _W / 2
		player.y = _H - player.contentHeight
		player.name = "player"

		player.collision = onCollision
		player:addEventListener("collision", player)
		
		physics.addBody(player, "kinematic", {bounce=0, isSensor=true})
		group:insert(player)
	end

	initPlayer(localGroup)

	function onTilt(e)
		if isPlaying then
			if player.x <= 0 then
				player.x = _W - 1
			elseif player.x >= _W then
				player.x = 1
			end
			player.x = player.x + (playerMovementSpeed * e.xGravity)
		end
	end

	local cleanUp = function()
		--background:removeEventListener("touch", touched)
		Runtime:removeEventListener("accelerometer", onTilt)
		Runtime:removeEventListener("enterFrame", update)
		system.setIdleTimer(true)
	end

	-- Touch to go back
	local function touched(event)
		if ("ended" == event.phase) then
			cleanUp()
			--director:changeScene("menu", "fade")
			director:changeScene("menu", "fade")
		end
	end

	function startGame()
		system.setIdleTimer(false)

		Runtime:addEventListener("accelerometer", onTilt)
		Runtime:addEventListener("enterFrame", update)

		isPlaying = true
		playerScore = 0
		for i=1,maxEnemies do
			if enemies[i] ~= nil then
				enemies[i]:removeSelf()
				enemies[i] = nil
			end
		end
		for i=1,maxGoods do
			if goods[i] ~= nil then
				goods[i]:removeSelf()
				goods[i] = nil
			end
		end

	end

	--[[background1:addEventListener("touch", touched)
	background2:addEventListener("touch", touched)
	if system.getInfo("environment") == "simulator" then
		-- Register object to rcorona
		rcorona.registerTouch(background1)
		rcorona.registerTouch(background2)
	end	
	--]]
	startGame()

	-- MUST return a display.newGroup()
	return localGroup
end

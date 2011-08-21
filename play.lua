module(..., package.seeall)

local ui = require("ui")
local physics = require("physics")
local ads = require("ads")

local scores = require("scores")

physics.start()
--physics.setScale(60)
physics.setGravity(0, 0)
--physics.setDrawMode("hybrid")

_W = display.contentWidth
_H = display.contentHeight

local isPlaying
local gameSpeed = 1
local oldGameSpeed
local gameNormalSpeed = 1
local gameFastSpeed = 3
local gameSlowSpeed = -3
local gameLimitSlowSpeed = 0.3

local player
local playerMovementSpeed = 10
local shouldMakePlayerSmaller
local shouldMakePlayerBigger
local shouldMakePlayerNormal

local playerScore = 0

local scoreText

local background1
local background2

local enemyTypes = {"car1", "car2", "car3", "truck", "bus"}
local enemies={}
local maxEnemies = 1
local minEnemySpeed = 1
local maxEnemySpeed = 1

local goodTypes = {"good1", "good2", "good3"}
local goodsToRemove = {}
local goods = {}
local maxGoods = 3

local powerUpTypes = {"shield", "faster", "slower", "bigger", "smaller", "freeze"}
local powerUp
local powerUpProgressBar

local localGroup
local tPrevious
local shieldCirclePowerUp
local enemiesFrozen

local tmrAdvanceLevel
local tmrGainPointPerSecond
local tmrCancelPowerUp
local tmrProgressBarPowerUp

local highScores = {}

local scoreFontName = "Harrowprint"

system.setAccelerometerInterval(75)
if system.getInfo("environment") == "simulator" then
	local rcorona = require("rcorona")
	rcorona.startServer(8181)
end

local function cleanUp()
	--background:removeEventListener("touch", touched)
	Runtime:removeEventListener("accelerometer", onTilt)
	Runtime:removeEventListener("enterFrame", update)
	system.setIdleTimer(true)

    ads.show("banner320x48", {x=0, y=_H-48, interval=20, testMode=true})
end

local function advanceLevel()

	local incrementGameSpeed

	playerMovementSpeed = playerMovementSpeed + 0.5
	minEnemySpeed = minEnemySpeed + 0.1
	maxEnemySpeed = maxEnemySpeed + 0.1
	gameSpeed = gameSpeed + 0.1

	local integer, fractional = math.modf(gameSpeed)

	if maxEnemies == 0 then
		if fractional >= 0.3 then
			maxEnemies = maxEnemies + 1
		end
	end

	if (fractional < 0.1) then
		maxEnemies = maxEnemies + 1
	end
end

local function gainPointPerSecond()
	playerScore = playerScore + 10
end

local function gotoMenu()
	cleanUp()
	director:changeScene("menu", "fade")
end

local function makePlayerNormal()
	player.xScale = 1
	player.yScale = 1
	physics.removeBody(player)
	physics.addBody(player, "kinematic", {bounce=0, isSensor=true, radius=22})
end

local function makePlayerSmaller()
	player.xScale = 0.5
	player.yScale = 0.5
	physics.removeBody(player)
	physics.addBody(player, "kinematic", {bounce=0, isSensor=true, radius=11})
end

local function makePlayerBigger()
	player.xScale = 2
	player.yScale = 2
	physics.removeBody(player)
	physics.addBody(player, "kinematic", {bounce=0, isSensor=true, radius=44})
end

local displayGameOver = function()

	local yPosGameOver = 50
	local yPosScore = 120
	local yPosHighScore = 150
	local yPosReplayButton = 250
	local yPosMenuButton = 330
	
	local group = display.newGroup()

	local back = display.newRect(0, 0, display.contentWidth, display.contentHeight)
	back:setFillColor(0,0,0, 255*.1)
	group:insert(back)

	local gameOver = display.newImage("images/gameover.png")
	gameOver.x = display.contentWidth/2
	gameOver.y = yPosGameOver
	group:insert(gameOver)

	local textScore = "Your score: " .. playerScore .. "!"
	local scoreDisplay = display.newText(textScore, 0, 0, scoreFontName, 24)
	scoreDisplay:setReferencePoint(display.CenterReferencePoint)
	scoreDisplay.x = _W/2
	scoreDisplay.y = yPosScore
	group:insert(scoreDisplay)

	local highScorePlace = scores.isNewHighScore(playerScore, highScores)
	if highScorePlace ~= 0 then

		local textNewScore
		if highScorePlace == 1 then
			textNewScore = "New highscore!!!"
		else
			textNewScore = "You made the top ten list!"
		end
		local newHighScoreDisplay = display.newText(textNewScore, 0, 0, scoreFontName, 24)
		newHighScoreDisplay:setReferencePoint(display.CenterReferencePoint)
		newHighScoreDisplay.x = _W/2
		newHighScoreDisplay.y = yPosHighScore
		group:insert(newHighScoreDisplay)

	end

	local replayButton = ui.newButton({
		defaultSrc = "images/play_again.png",
		defaultX = 160,
		defaultY = 80,
		overSrc = "images/play_again.png",
		overX = 160,
		overY = 80,
		onRelease = function(event) group:removeSelf(); startGame() end
	})
	replayButton.x = display.contentWidth/2
	replayButton.y = yPosReplayButton
	group:insert(replayButton)

	local menuButton = ui.newButton({
		defaultSrc = "images/return_menu.png",
		defaultX = 160,
		defaultY = 80,
		overSrc = "images/return_menu.png",
		overX = 160,
		overY = 80,
		onRelease = function(event) group:removeSelf(); gotoMenu(); end
	})
	menuButton.x = display.contentWidth/2
	menuButton.y = yPosMenuButton
	group:insert(menuButton)

	return group

end

local blankOutScreen = function(player)

	local gameOver = displayGameOver()

	local circle = display.newCircle(_W/2, _H/2, 5)
	local circleGrowthTime = 300
	local dissolveDuration = 1000

	local dissolve = function(event) transition.to(circle, {alpha=0, time=dissolveDuration, delay=0, onComplete=function(event) gameOver.alpha=1 end}); gameOver.alpha=1 end

	circle.alpha = 0
	transition.to(circle, {time=circleGrowthTime, alpha=1, width=display.contentWidth*3, height=display.contentWidth*3, onComplete=dissolve})

	system.vibrate()

	enemies = {}
	goods = {}

	localGroup:removeSelf()

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

	cleanUp()
	--director:changeScene("menu", "fade")
	blankOutScreen(player)

end

local createGood = function(type)
	local good
	local x = math.random(0, _W-30)
	
	if type == 1 then
		good = display.newCircle(x, 0, 3)
		good.type = goodTypes[1]
		good.points = 50
		good:setFillColor(100,0,0)
	elseif type == 2 then
		good = display.newCircle(x, 0, 5)
		good.type = goodTypes[2]
		good.points = 40
		good:setFillColor(0,100,0)
	elseif type == 3 then
		good = display.newCircle(x, 0, 7)
		good.type = goodTypes[3]
		good.points = 30
		good:setFillColor(0,0,100)
	end
	
	good.name = "good"
	physics.addBody(good, "dynamic", {bounce=0, isSentor=true, radius=good.width/2})

--	good.collision = onCollision
--	good:addEventListener("collision", good)
	
	return good
end

local function createPowerUp()
	--local x = math.random(0, _W-20)

	-- Si no hay enemigos no se crean powerups
	if maxEnemies == 0 then
		return
	end

	local x = _W/2

	local type = math.random(1, #powerUpTypes*100)

	if type == 1 then -- Shield
		powerUp = display.newCircle(x, 0, 10)
		powerUp:setFillColor(255,0,0)
		powerUp.description = "You're now invincible!"
		powerUp.delay = 10000
	elseif type == 2 then -- Faster
		powerUp = display.newCircle(x, 0, 10)
		powerUp:setFillColor(255,0,0)
		powerUp.description = "You're now faster!"
		powerUp.delay = 10000
	elseif type == 3 then -- Slower
		powerUp = display.newCircle(x, 0, 10)
		powerUp:setFillColor(255,0,0)
		powerUp.description = "You're now slower!"
		powerUp.delay = 10000
	elseif type == 4 then -- Bigger
		powerUp = display.newCircle(x, 0, 10)
		powerUp:setFillColor(255,0,0)
		powerUp.description = "You're now bigger!"
		powerUp.delay = 10000
	elseif type == 5 then -- Smaller
		powerUp = display.newCircle(x, 0, 10)
		powerUp:setFillColor(255, 0, 0)
		powerUp.description = "You're now smaller!"
		powerUp.delay = 10000
	elseif type == 6 then -- Freeze
		powerUp = display.newCircle(x, 0, 10)
		powerUp:setFillColor(255, 0, 0)
		powerUp.description = "All enemies are frozen!"
		powerUp.delay = 10000
	else
		powerUp = nil
	end

	if powerUp ~= nil then
		powerUp.name = "powerUp"
		powerUp.type = powerUpTypes[type]

		physics.addBody(powerUp, "dynamic", {bounce=0, isSensor=true, radius=powerUp.width/2})
	end

	return powerUp
end

local createEnemy = function()

	local availLeftPos = {0, _W-30, math.random(0, _W)}
	local availDirection = {"right", "left", "down"}

	local y = math.random(0, _H/2)
	local enemy
	
	local type = math.random(1, #enemyTypes)
	if type == 1 then
		enemy = display.newRect(0, y, 20, 20)
		enemy.type = enemyTypes[1]
		enemy.points = 10
		enemy:setFillColor(255,0,0)
		enemy.speed = 0.5
	elseif type == 2 then
		enemy = display.newRect(0, y, 25, 20)
		enemy.type = enemyTypes[2]
		enemy.points = 15
		enemy:setFillColor(0,255,0)
		enemy.speed = 1
	elseif type == 3 then
		enemy = display.newRect(0, y, 22, 20)
		enemy.type = enemyTypes[3]
		enemy.points = 20
		enemy:setFillColor(0,0,255)
		enemy.speed = 1.5
	elseif type == 4 then
		enemy = display.newRect(0, y, 28, 20)
		enemy.type = enemyTypes[4]
		enemy.points = 15
		enemy:setFillColor(255,255,0)
		enemy.speed = 1.2
	elseif type == 5 then
		enemy = display.newRect(0, y, 15, 20)
		enemy.type = enemyTypes[5]
		enemy.points = 25
		enemy:setFillColor(255,0,255)
		enemy.speed = 0.8
	end
	
	--enemy.speed = math.random(minEnemySpeed, maxEnemySpeed) / 10
	enemy.name = "enemy"

	local direction = availDirection[math.random(1, #availDirection)]
	if direction == "right" then
		enemy.x = availLeftPos[1]
		enemy.direction = direction
	elseif direction == "left" then
		enemy.x = availLeftPos[2]
		enemy.direction = direction
	elseif direction == "down" then
		enemy.x = availLeftPos[3]
		enemy.y = 0
		enemy.direction = direction
	end

	physics.addBody(enemy, "dynamic", {bounce=0, friction=0, density=0, isSensor=true})

	return enemy
end

local function update(event)

	if isPlaying then
		local tDelta = event.time - tPrevious
		tPrevious = event.time

		local yOffset = ((gameSpeed/10)*tDelta)
		--local yOffset = 2

		background1.y = background1.y + yOffset
		background2.y = background2.y + yOffset

		if background1.y >= 720 then
			background1:translate(0, -_H*2)
		end
		if background2.y >= 720 then
			background2:translate(0, -_H*2)
		end

		if player.powerUp ~= "" then
			if player.powerUp == "shield" then
			end
		end

		if shouldMakePlayerNormal then
			makePlayerNormal()
			shouldMakePlayerNormal = false
		elseif shouldMakePlayerBigger then
			makePlayerBigger()
			shouldMakePlayerBigger = false
		elseif shouldMakePlayerSmaller then
			makePlayerSmaller()
			shouldMakePlayerSmaller = false
		end

		-- Mostrar nuevos enemigos
		for i=1,maxEnemies do
			if enemies[i] == nil then
				local newEnemy = createEnemy()
				localGroup:insert(newEnemy)
				enemies[i] = newEnemy
			else
				-- Mover a los enemigos hacia abajo para simular movimiento del player
				enemies[i].y = enemies[i].y + (gameSpeed/10 * tDelta)

				-- Mover a los enemigos en su dirección para simular su propio movimiento
				-- Si está activo el powerUp "freeze" no mover nada
				if enemiesFrozen == false then
					if enemies[i].direction == "left" then
						enemies[i].x = enemies[i].x - enemies[i].speed
					elseif enemies[i].direction == "right" then
						enemies[i].x = enemies[i].x + enemies[i].speed
					elseif enemies[i].direction == "down" then
						enemies[i].y = enemies[i].y + enemies[i].speed
					end
				end
			end

			-- Eliminar a los enemigos que salgan de la pantalla
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
				
				--if tDelta == 0 then
					--tDelta = 1
				--end
				local spawnRate = math.random(1,(gameSpeed*tDelta)*100)
				local newGood
				
				if spawnRate > 0 and spawnRate <= 2 then
					newGood = createGood(1)
				elseif spawnRate >= 3 and spawnRate <= 6 then
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

		if powerUp == nil and player.powerUp == "" then
			powerUp = createPowerUp()
			if powerUp ~= nil then
				localGroup:insert(powerUp)
			end
		end

		if powerUp ~= nil then
			powerUp.y = powerUp.y + gameSpeed

			if powerUp.y > _H then
				powerUp:removeSelf()
				powerUp = nil
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

local function hidePowerUpProgressBar()
	if powerUpProgressBar ~= nil then
		powerUpProgressBar:removeSelf()
		powerUpProgressBar = nil
	end
end

local function showPowerUpProgressBar()
	powerUpProgressBar = display.newRect(0, _H-10, _W, _H)
	powerUpProgressBar:setFillColor(255,0,0, 120)
	powerUpProgressBar:setReferencePoint(display.TopLeftReferencePoint)
	localGroup:insert(powerUpProgressBar)
end

local function onCollision(self, event)

	if self.name == "player" and event.other.name == "good" then

		local good = event.other
		table.insert(goodsToRemove, good)

		playerScore = playerScore + good.points

	elseif self.name == "player" and event.other.name == "enemy" then

		local enemy = event.other
			
		if player.powerUp == "shield" then

			for i=1,maxEnemies do
				if enemies[i] == enemy then

					local points = enemy.points
					local x = enemy.x
					local y = enemy.y

					enemies[i]:removeSelf()
					enemies[i] = nil

					explosion(x, y)
					playerScore = playerScore + points

					break

				end
			end

		else

			--print("collision " .. self.name .. " " .. event.other.name)
			player:removeSelf()
			enemy:removeSelf()

			explosion(player.x, player.y)

			powerUp = nil
			isPlaying = false

			timer.cancel(tmrAdvanceLevel)
			timer.cancel(tmrGainPointPerSecond)
			if tmrCancelPowerUp ~= nil then
				timer.cancel(tmrCancelPowerUp)
			end
			if tmrProgressBarPowerUp ~= nil then
				timer.cancel(tmrProgressBarPowerUp)
			end
			
			local endGame = function()
				showEndGame()
			end
			local tmrEndGame = timer.performWithDelay(1000, endGame, 1)
			--showEndGame()
		end

	elseif event.other.name == "powerUp" then
		
		local power = event.other
		local dissolveDuration = 2000
		local powerUpGroup = display.newGroup()
		local newX = powerUp.x
		local newY = powerUp.y
		local oldPowerUp = player.powerUp

		powerUp:removeSelf()
		powerUp = nil

		local function cancelShieldPowerUp()
			shieldCirclePowerUp:removeSelf()
			shieldCirclePowerUp = nil
		end

		local function cancelPowerUp()

			hidePowerUpProgressBar()

			if player.powerUp == "faster" then
				gameSpeed = oldGameSpeed
			elseif player.powerUp == "slower" then
				gameSpeed = oldGameSpeed
			elseif player.powerUp == "bigger" then
				shouldMakePlayerNormal = true
			elseif player.powerUp == "smaller" then
				shouldMakePlayerNormal = true
			elseif player.powerUp == "freeze" then
				enemiesFrozen = false
			end

			if shieldCirclePowerUp ~= nil then
				cancelShieldPowerUp()
			end

			player.powerUp = ""
			--timer.cancel(tmrCancelPowerUp)
		end

		local progressPowerUp = 0

		local function advancePowerUpProgressBar()
			if powerUpProgressBar ~= nil then
				progressPowerUp = progressPowerUp + 1000
				local timeLeft = power.delay-progressPowerUp
				local percent = timeLeft/power.delay
				local widthBar = percent*_W
				powerUpProgressBar.xScale = percent
				powerUpProgressBar.x = 0
			end
		end


		if player.powerUp == "shield" and power.type ~= "shield" then
			cancelShieldPowerUp()
			timer.cancel(tmrCancelPowerUp)
		end

		--timer.cancel(tmrCancelPowerUp)
		tmrCancelPowerUp = timer.performWithDelay(power.delay, cancelPowerUp, 1)
		tmrProgressBarPowerUp = timer.performWithDelay(1000, advancePowerUpProgressBar, power.delay/1000)
		showPowerUpProgressBar()

		local powerUpText = display.newText(power.description, 0, 0, scoreFontName, 20)
		powerUpText.x = newX
		powerUpText.y = newY

		player.powerUp = power.type
		if power.type == "shield" then
			shieldCirclePowerUp = display.newCircle(player.x, player.y, 30)
			shieldCirclePowerUp:setFillColor(255,255,255,50)
			localGroup:insert(shieldCirclePowerUp)
		elseif power.type == "faster" and oldPowerUp ~= "faster" then
			oldGameSpeed = gameSpeed
			gameSpeed = gameSpeed + gameFastSpeed
		elseif power.type == "slower" and oldPowerUp ~= "slower" then
			oldGameSpeed = gameSpeed
			gameSpeed = gameSpeed + gameSlowSpeed
			if gameSpeed < gameLimitSlowSpeed then
				gameSpeed = gameLimitSlowSpeed
			end
		elseif power.type == "bigger" and oldPowerUp ~= "bigger" then
			shouldMakePlayerBigger = true
		elseif power.type == "smaller" and oldPowerUp ~= "smaller" then
			shouldMakePlayerSmaller = true
		elseif power.type == "freeze" and oldPowerUp ~= "freeze" then
			enemiesFrozen = true
		end

		local dissolve = function(event)
			powerUpGroup:removeSelf()
		end

		transition.to(powerUpText, {time=dissolveDuration, alpha=0, onComplete=dissolve})
	end

end

local function initVars()
	-- Inicializar valores de variables
	gameSpeed = 1
	playerMovementSpeed = 10
	maxEnemies = 0
	minEnemySpeed = 1
	maxEnemySpeed = 1
	maxGoods = 3

	shouldMakePlayerSmaller = false
	shouldMakePlayerBigger = false
	shouldMakePlayerNormal = false

	enemiesFrozen = false
end

function startGame()

	ads.hide()

	initVars()

	localGroup = display.newGroup()

	-- Background
	background1 = display.newImage("images/bg1.png")
	background1:setReferencePoint(display.CenterLeftReferencePoint)
	background1.x = 0
	background1.y = 0
	localGroup:insert(background1)

	background2 = display.newImage("images/bg2.png")
	background2:setReferencePoint(display.CenterLeftReferencePoint)
	background2.x = 0
	background2.y = _H
	localGroup:insert(background2)

	scoreText = display.newText("Score: " .. playerScore, 20, 10, scoreFontName, 14)
	localGroup:insert(scoreText)

	highScores = scores.readHighScores(numHighScores)

	tPrevious = system.getTimer()

	system.setIdleTimer(false)

	Runtime:removeEventListener("enterFrame", update)
	Runtime:addEventListener("accelerometer", onTilt)
	Runtime:addEventListener("enterFrame", update)

	--timer.cancel(tmrAdvanceLevel)
	--timer.cancel(tmrGainPointPerSecond)
	tmrAdvanceLevel = timer.performWithDelay(5000, advanceLevel, -1)
	tmrGainPointPerSecond = timer.performWithDelay(1000, gainPointPerSecond, -1)

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

	initPlayer(localGroup)
end


function new()

	function initPlayer(group)
		player = display.newImage("images/nave.png")
		player.x = _W / 2
		player.y = _H - player.contentHeight
		player.name = "player"
		player.powerUp = ""

		player.collision = onCollision
		player:addEventListener("collision", player)
		
		physics.addBody(player, "kinematic", {bounce=0, isSensor=true, radius=22})
		group:insert(player)
	end

	function onTilt(e)
		if isPlaying then
			if player.x <= 0 then
				player.x = _W - 1
				shieldCirclePowerUp.x = _W - 1
			elseif player.x >= _W then
				player.x = 1
				shieldCirclePowerUp.x = 1
			end
			player.x = player.x + (playerMovementSpeed * e.xGravity)
			shieldCirclePowerUp.x = shieldCirclePowerUp.x + (playerMovementSpeed * e.xGravity)
		end
	end

	-- Touch to go back
	local function touched(event)
		if ("ended" == event.phase) then
			cleanUp()
			--director:changeScene("menu", "fade")
			director:changeScene("menu", "fade")
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

	-- Código para imprimir las letras del sistema
	--local sysFonts = native.getFontNames()
	--for k,v in pairs(sysFonts) do print(v) end

	-- MUST return a display.newGroup()
	return localGroup
end

--[[
rCorona
created by Charles Wong
v1.2 7/21/2011
Fixed if object removed from stage will get error
Fixed if object is not visible still dispatch event
]]
module(..., package.seeall)

local socket = require("socket")
local udpSocket = nil
local isShake = false
local focus = {}-- focused event targets
local touchTargets = {}
local oldMessage = ""

local function shutdownSocket()
	udpSocket:close()
	udpSocket = nil
	timer.cancel(tick)
end

local function decodeMessage(str)
	local pos, t = 1, {}
	for s, e in function() return string.find(str, ",", pos) end do
		table.insert(t, (string.gsub(string.sub(str, pos, s-1), "^%s*(.-)%s*$", "%1")))
		pos = e+1
	end
	table.insert(t, (string.gsub(string.sub(str, pos), "^%s*(.-)%s*$", "%1")))
	return t
end

function registerTouch(target)
	touchTargets[#touchTargets + 1] = target
end

-- by cmote modified by rCorona
local function touchEvent(tphase, tid, tx, ty, txStart, tyStart)
	local e = {}
	local dispatched = false
	e = { name="touch", id=tid, phase=tphase, time=system.getTimer(), x=tx, xStart=txStart, y=ty, yStart=tyStart}
	if focus[e.id] then
		local tgt = focus[e.id]
		e.target=tgt
		local status,ret = pcall(function () return tgt:dispatchEvent(e) end)
		if status and ret then
			if e.phase == "ended" then
				focus[e.id] = nil
			end
			return true
		end
		focus[e.id] = nil
	end

	for i=1, #touchTargets do
		local o = touchTargets[i]
		if o ~= nil and o.contentBounds ~= nil then
			if tx > o.contentBounds.xMin and tx < o.contentBounds.xMax and ty > o.contentBounds.yMin and ty < o.contentBounds.yMax and o.isVisible then
				e.target=o
				if o:dispatchEvent(e) then
					dispatched = true
					if e.phase == "began" then
						focus[e.id] = o
					end
					break
				end
			end
		else
			table.remove(touchTargets, i) -- if object is removed
		end
	end

	if not dispatched then
		e.target = nil
		Runtime:dispatchEvent(e)
	end
end

local function receiveMessage(event)
	-- Get Message
	if udpSocket ~= nil then
		local udpMessage = udpSocket:receive()
		if udpMessage ~= nil and udpMessage ~= oldMessage then
			local msg = decodeMessage(udpMessage)
			local messageType = msg[1]
			local isShake = false
			if messageType == "0" then
				if msg[8] == "1" then
					isShake = true
				end
				Runtime:dispatchEvent( { name = "accelerometer", xGravity = tonumber(msg[2]), yGravity = tonumber(msg[3]), zGravity = tonumber(msg[4]), xInstant = tonumber(msg[5]), yInstant = tonumber(msg[6]), zInstant = tonumber(msg[7]), isShake = isShake} )
				local newWidth = msg[15] / display.contentWidth
				local newHeight = msg[16] / display.contentHeight
				touchEvent(msg[9], msg[10], msg[11] * newWidth, msg[12] * newHeight, msg[13] * newWidth, msg[14] * newHeight)
			elseif messageType == "1" then
				if msg[8] == "1" then
					isShake = true
				end
				Runtime:dispatchEvent( { name = "accelerometer", xGravity = tonumber(msg[2]), yGravity = tonumber(msg[3]), zGravity = tonumber(msg[4]), xInstant = tonumber(msg[5]), yInstant = tonumber(msg[6]), zInstant = tonumber(msg[7]), isShake = isShake} )
				width = msg[9]
				height = msg[10]
			elseif messageType == "2" then
				local newWidth = msg[8] / display.contentWidth
				local newHeight = msg[9] / display.contentHeight
				touchEvent(msg[2], msg[3], msg[4] * newWidth, msg[5] * newHeight, msg[6] * newWidth, msg[7] * newHeight)
			end
			oldMessage = udpMessage
		end
	else
		shutdownSocket()
	end
end

function startServer(port, speed)
	-- Set Port
	if system.getInfo("environment") == "simulator" then
		udpSocket = socket.udp()
		udpSocket:setsockname("*", port)
		udpSocket:settimeout(0)
		Runtime:addEventListener("enterFrame", receiveMessage)
	end
end
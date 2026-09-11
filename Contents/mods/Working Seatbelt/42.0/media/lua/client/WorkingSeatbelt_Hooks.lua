local WorkingSeatbelt = require("WorkingSeatbelt")
local SharedUtils = require("WorkingSeatbelt_SharedUtils")
------------------------------------------------------------------------------------
-- This section disables exiting the vehicle while the seatbelt is fastened, if the relevant sandbox option is on

local _ISVehicleMenu_onExit = ISVehicleMenu.onExit
function ISVehicleMenu.onExit(player)
	if player:getModData().Seatbelt_sbStatus then
		if SandboxVars.workingSeatbelt.exitVehicleAutoUnfasten then
			WorkingSeatbelt.onDoSeatbelt(player, false)
		else
			player:Say(getText("IGUI_PlayerSayExitVehicle"))
			return
		end
	end

	return _ISVehicleMenu_onExit(player)
end

------------------------------------------------------------------------------------
-- This section disables switching seats while the seatbelt is fastened, if the relevant sandbox option is on

local _ISVehicleMenu_onSwitchSeat = ISVehicleMenu.onSwitchSeat
function ISVehicleMenu.onSwitchSeat(playerObj, seatTo)
	if playerObj:getModData().Seatbelt_sbStatus then
		if SandboxVars.workingSeatbelt.switchSeatAutoUnfasten then
			WorkingSeatbelt.onDoSeatbelt(playerObj, false)
		else
			playerObj:Say(getText("IGUI_PlayerSaySwitchSeat"))
			return
		end
	end

	return _ISVehicleMenu_onSwitchSeat(playerObj, seatTo)
end

------------------------------------------------------------------------------------

local function toggleSeatbeltChime(vehicle, character)
	local vehicleId = vehicle:getId()
	local state

	local seatbeltChimeState = SharedUtils.getSeatbeltChimeState(vehicle)
	if seatbeltChimeState then
		state = false
		if vehicle:getEmitter():isPlaying("Chime") then -- If the chime warning sound is not playing
			vehicle:getEmitter():stopSoundByName("Chime") -- Stop chime warning sound
		end
	else
		state = true
		if vehicle:isEngineRunning() then
			if vehicle:isDriver(character) then
				if not SharedUtils.isWearingSeatbelt(character) then
					if not vehicle:getEmitter():isPlaying("Chime") then
						local speed = vehicle:getCurrentSpeedKmHour()
						if speed >= SandboxVars.workingSeatbelt.chimeMinimumSpeed then
							vehicle:getEmitter():playSound("Chime", character:getX(), character:getY(), character:getZ())
						end
					end
				end
			end
		end
	end

	sendClientCommand('WorkingSeatbelt', 'setChimeState', { vehicleId = vehicleId, state = state })
end

local function doContextMenu()
	local character = getPlayer()
	if not character then return end
	local playerNum = character:getIndex()
	local vehicle = character:getVehicle()
	if not vehicle then return end
	local enginePart = vehicle:getPartById("Engine")

	if not enginePart then return end

	local seatbeltChimeState = SharedUtils.getSeatbeltChimeState(vehicle)

	local context = ISContextMenu.get(
		playerNum, ISVehicleDashboard.sbTex:getAbsoluteX() - 40, ISVehicleDashboard.sbTex:getAbsoluteY() - 40
	)
	context:addOption(getText("ContextMenu_ToggleSeatbeltChime"), vehicle, toggleSeatbeltChime, character)
	context:setOptionChecked(context.options[1], seatbeltChimeState)
end

------------------------------------------------------------------------------------

-- This section adds the "seatbelt" indicator to the vehicle dashboard, however makes it invisible at the beginning
local sbIndicator = getTexture("media/ui/seatbelt_indicator.png")
-- Save the original createChildren function
local _ISVehicleDashboard_createChildren = ISVehicleDashboard.createChildren
function ISVehicleDashboard:createChildren()
	local ret = _ISVehicleDashboard_createChildren(self)

	if SandboxVars.workingSeatbelt.seatbeltWarningIndicator then
		ISVehicleDashboard.sbTex = ISImage:new(
			370, 97, sbIndicator:getWidthOrig(), sbIndicator:getHeightOrig(), sbIndicator
		)
		ISVehicleDashboard.sbTex:initialise()
		ISVehicleDashboard.sbTex:instantiate()
		ISVehicleDashboard.sbTex:setVisible(false)
		ISVehicleDashboard.sbTex.mouseovertext = getText("UI_buckleAlert")
		-- ISVehicleDashboard.sbTex.onclick = stopSeatbeltChime;
		if SandboxVars.workingSeatbelt.seatbeltWarningChime then
			if SandboxVars.workingSeatbelt.playersToggleChime then
				ISVehicleDashboard.sbTex.onRightMouseUp = doContextMenu
			end
		end
		ISVehicleDashboard.sbTex.target = self
		self:addChild(self.sbTex)
	end

	return ret
end

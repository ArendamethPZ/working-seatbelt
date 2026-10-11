local WorkingSeatbelt = require("WorkingSeatbelt")
local SharedUtils = require("WorkingSeatbelt_SharedUtils")
------------------------------------------------------------------------------------
-- This section disables exiting the vehicle while the seatbelt is fastened, if the relevant sandbox option is on

-- Extra args are passed through: vanilla's seat menu calls onExit(player, seat) to leave through another seat's door
local _ISVehicleMenu_onExit = ISVehicleMenu.onExit
function ISVehicleMenu.onExit(player, ...)
	if player:getModData().Seatbelt_sbStatus then
		if SandboxVars.workingSeatbelt.exitVehicleAutoUnfasten then
			WorkingSeatbelt.onDoSeatbelt(player, false)
		else
			player:Say(getText("IGUI_PlayerSayExitVehicle"))
			return
		end
	end

	return _ISVehicleMenu_onExit(player, ...)
end

------------------------------------------------------------------------------------
-- This section disables switching seats while the seatbelt is fastened, if the relevant sandbox option is on

local _ISVehicleMenu_onSwitchSeat = ISVehicleMenu.onSwitchSeat
function ISVehicleMenu.onSwitchSeat(playerObj, seatTo, ...)
	if playerObj:getModData().Seatbelt_sbStatus then
		if SandboxVars.workingSeatbelt.switchSeatAutoUnfasten then
			WorkingSeatbelt.onDoSeatbelt(playerObj, false)
		else
			playerObj:Say(getText("IGUI_PlayerSaySwitchSeat"))
			return
		end
	end

	return _ISVehicleMenu_onSwitchSeat(playerObj, seatTo, ...)
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

-- Right-click handler of the dashboard light itself, so `light` is the light's ISImage
local function doContextMenu(light)
	local character = getPlayer()
	if not character then return end
	local playerNum = character:getIndex()
	local vehicle = character:getVehicle()
	if not vehicle then return end
	local enginePart = vehicle:getPartById("Engine")

	if not enginePart then return end

	local seatbeltChimeState = SharedUtils.getSeatbeltChimeState(vehicle)

	local context = ISContextMenu.get(playerNum, light:getAbsoluteX() - 40, light:getAbsoluteY() - 40)
	context:addOption(getText("ContextMenu_ToggleSeatbeltChime"), vehicle, toggleSeatbeltChime, character)
	context:setOptionChecked(context.options[1], seatbeltChimeState)
end

------------------------------------------------------------------------------------
-- Dashboard seatbelt warning light. It gets its own slot at the end of the left warning-light strip (engine,
-- battery, doors) and behaves like those vanilla lights: always shown, grey normally, red while the engine is
-- running and the driver isn't belted.

-- Offsets from the dashboard background, the same way vanilla lays out its lights in onResolutionChange
-- (engine +105, battery +137, doors +169: 32px apart, so the next slot is +201). The strip image extends the
-- background's black strip under that slot.
local LIGHT_X, LIGHT_Y = 201, 26
local STRIP_X, STRIP_Y = 194, 22

local function layoutSeatbeltIndicator(dashboard)
	local bg = dashboard.backgroundTex
	if not bg or not dashboard.sbTex then return end
	dashboard.sbStrip:setX(bg:getX() + STRIP_X)
	dashboard.sbStrip:setY(bg:getY() + STRIP_Y)
	dashboard.sbTex:setX(bg:getX() + LIGHT_X)
	dashboard.sbTex:setY(bg:getY() + LIGHT_Y)
end

local function createSeatbeltIndicator(dashboard)
	local vars = SandboxVars.workingSeatbelt
	if not vars or not vars.seatbeltWarningIndicator then return end

	local stripTex = getTexture("media/ui/seatbelt_indicator_strip.png")
	local lightTex = getTexture("media/ui/seatbelt_indicator_light.png")
	if not stripTex or not lightTex then return end

	local strip = ISImage:new(0, 0, stripTex:getWidthOrig(), stripTex:getHeightOrig(), stripTex)
	strip:initialise()
	strip:instantiate()
	dashboard:addChild(strip)

	-- white glyph, tinted every frame in prerender like vanilla's lights
	local light = ISImage:new(0, 0, lightTex:getWidthOrig(), lightTex:getHeightOrig(), lightTex)
	light:initialise()
	light:instantiate()
	light.mouseovertext = getText("UI_buckleAlert")
	if vars.seatbeltWarningChime and vars.playersToggleChime then
		light.onRightMouseUp = doContextMenu
	end
	dashboard:addChild(light)

	dashboard.sbStrip = strip
	dashboard.sbTex = light
	layoutSeatbeltIndicator(dashboard)
end

local _ISVehicleDashboard_createChildren = ISVehicleDashboard.createChildren
function ISVehicleDashboard:createChildren()
	local ret = _ISVehicleDashboard_createChildren(self)
	createSeatbeltIndicator(self)
	return ret
end

local _ISVehicleDashboard_onResolutionChange = ISVehicleDashboard.onResolutionChange
function ISVehicleDashboard:onResolutionChange()
	_ISVehicleDashboard_onResolutionChange(self)
	layoutSeatbeltIndicator(self)
end

local _ISVehicleDashboard_prerender = ISVehicleDashboard.prerender
function ISVehicleDashboard:prerender()
	_ISVehicleDashboard_prerender(self)
	if not self.vehicle or not ISUIHandler.allUIVisible then return end

	if not self.sbTex then
		createSeatbeltIndicator(self) -- e.g. the dashboard was built before the sandbox options had synced
		if not self.sbTex then return end
	end

	local hasSeatbelt = not WorkingSeatbelt.seatbeltBlacklist[self.vehicle:getScript():getFullName()]
	self.sbStrip:setVisible(hasSeatbelt)
	self.sbTex:setVisible(hasSeatbelt)
	if not hasSeatbelt then return end

	-- same alpha (including the crash flicker) and colours vanilla just used for its own lights this frame
	local alpha = self.batteryTex.backgroundColor.a
	if self.vehicle:isEngineRunning() and not SharedUtils.isWearingSeatbelt(self.character) then
		local bad = getCore():getBadHighlitedColor()
		self.sbTex.backgroundColor = { r = bad:getR(), g = bad:getG(), b = bad:getB(), a = alpha }
	else
		self.sbTex.backgroundColor = { r = 0.5, g = 0.5, b = 0.5, a = alpha }
	end
end

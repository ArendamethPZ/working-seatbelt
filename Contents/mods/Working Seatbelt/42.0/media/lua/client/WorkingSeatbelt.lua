local WorkingSeatbelt = {}

-- Vehicles that are not supposed to have a seatbelt
WorkingSeatbelt.seatbeltBlacklist = {
	-- Autotsar Motorclub
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=2778576730
	["Base.AMC_Waverunner"] = true,
	["Base.AMC_Waverunner_Ground"] = true,
	["Base.AMC_bmw_classic"] = true,
	["Base.AMC_bmw_custom"] = true,
	["Base.AMC_harley"] = true,
	["Base.AMC_quad"] = true,

	-- APOCALYPSE MACHINES 2 WHEELZ
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=2638496761
	["Base.AM2_Balrog"] = true,
	["Base.AM2_Balrog_Sidecar"] = true,
	["Base.AM2_Camel"] = true,
	["Base.AM2_Camel2"] = true,
	["Base.AM2_Courier"] = true,
	["Base.AM2_DirtDemon"] = true,
	["Base.AM2_DirtDemon2"] = true,
	["Base.AM2_Fireball"] = true,
	["Base.AM2_Kaiju"] = true,
	["Base.AM2_SkullKing"] = true,
	["Base.AM2_Steelhorse"] = true,
	["Base.AM2_Steelhorse2"] = true,
	["Base.AM2_Vesper"] = true,
	["Base.AM2_Vesper2"] = true,
	["Base.AM2_Vesper3"] = true,
	["Base.AM2_Warhorse"] = true,
	["Base.AM2_Warhorse2"] = true,
	["Base.AM2_Warhorse3"] = true,
	["Base.AM2_Wendigo"] = true,
	["Base.AM2_Yeti"] = true,

	-- Braven's Bicycles Redux
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=2988491347
	["Base.BicycleMTB"] = true,
	["Base.BicycleMTBScrap"] = true,
	["Base.BicycleRegular"] = true,
	["Base.BicycleRegularScrap"] = true,
	["Base.BicycleTrailer"] = true,

	--'28 Brough Superior SS100
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=2913634132
	["Base.28ss100"] = true,
	["Base.28ss100hermes"] = true,

	--'80 Kawasaki Kz1000 Police
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=2818847163
	["Base.80kz1000"] = true,

	--'13 Yamaha Vino 125 + PizzaBoy
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=2878374713
	["Base.vino125"] = true,
	["Base.vino125b"] = true,
	["Base.vino125pizza"] = true,

	--'90 Zanella 50cc Delivery Scooter
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=2922441474
	["Base.90zanella50cc"] = true,

	-- Aquatsar Yacht Club
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=2392987599
	["Base.BoatMotor"] = true,
	["Base.BoatMotor_Ground"] = true,
	["Base.BoatSailingYacht"] = true,
	["Base.BoatSailingYacht_Ground"] = true,
	["Base.BoatSailingYacht_shipwreckland"] = true,
	["Base.BoatSailingYacht_shipwreckwater"] = true,
	["Base.BoatZeroPatient"] = true,

	-- Skateboard
	-- Multiple mods
	["Base.Skateboard"] = true
}

---@param character IsoPlayer
---@param fasten    boolean
function WorkingSeatbelt.onDoSeatbelt(character, fasten)
	-- Skip if the same action is already queued, e.g. the seat menu's "exit through another door" switches seats
	-- and then exits, and both of those auto-unfasten
	local queue = ISTimedActionQueue.queues[character]
	if queue then
		for _, action in ipairs(queue.queue) do
			if action.Type == "ArenSeatbeltTimedAction" and action.fasten == fasten then return end
		end
	end
	ISTimedActionQueue.add(ArenSeatbeltTimedAction:new(character, fasten))
end

local old_ISVehicleMenu_showRadialMenu = ISVehicleMenu.showRadialMenu
function ISVehicleMenu.showRadialMenu(character)
	old_ISVehicleMenu_showRadialMenu(character)
	local vehicle = character:getVehicle()

	if vehicle ~= nil then
		local fullName = vehicle:getScript():getFullName()
		if not WorkingSeatbelt.seatbeltBlacklist[fullName] then
			local menu = getPlayerRadialMenu(character:getIndex())

			-- Gamepad stuff
			if menu:isReallyVisible() then
				if menu.joyfocus then
					setJoypadFocus(character:getplayerObjNum(), nil)
				end
				menu:undisplay()
				return
			end

			local sbStatus = character:getModData().Seatbelt_sbStatus

			menu:addSlice(
				sbStatus and getText('ContextMenu_UnfastenSeatbelt') or getText('ContextMenu_FastenSeatbelt'),
				getTexture("media/ui/unfastened_seatbelt.png"), WorkingSeatbelt.onDoSeatbelt, character, not sbStatus
			)
		end
	end
end

return WorkingSeatbelt

--
-- GlobalCompany - AddOn - RealisticMilkingTime
--
-- @Interface: --
-- @Author: LS-Modcompany / kevink98
-- @Date: 15.02.2020
-- @Version: 1.0.0.0
--
-- @Support: LS-Modcompany
--
-- Changelog:
--
-- 	v1.0.0.0 (15.02.2020):
-- 		- initial Script Fs19
--
-- Notes:
--
--
-- ToDo:
-- 
--
--

GC_AddOnRealisticMilkingTime = {}
GC_AddOnRealisticMilkingTime.TIMES = {6,18}

function GC_AddOnRealisticMilkingTime:initGlobalCompany(customEnvironment, baseDirectory, xmlFile)
	if (g_company == nil) or (GC_AddOnRealisticMilkingTime.isInitiated ~= nil) then
		return;
	end

	GC_AddOnRealisticMilkingTime.debugIndex = g_company.debug:registerScriptName("GC_AddOnRealisticMilkingTime");
	GC_AddOnRealisticMilkingTime.modName = customEnvironment;
	GC_AddOnRealisticMilkingTime.isInitiated = true;

	
	GC_AddOnRealisticMilkingTime.old_HusbandryModuleBase_changeFillLevels = HusbandryModuleBase.changeFillLevels
	HusbandryModuleBase.changeFillLevels = function(modul, fillDelta, fillTypeIndex) return GC_AddOnRealisticMilkingTime:changeFillLevels(modul, fillDelta, fillTypeIndex) end
	
	AnimalHusbandry.loadFromXMLFile = g_company.utils.appendedFunction(AnimalHusbandry.loadFromXMLFile, GC_AddOnRealisticMilkingTime.loadFromXMLFile)
	AnimalHusbandry.saveToXMLFile = g_company.utils.appendedFunction(AnimalHusbandry.saveToXMLFile, GC_AddOnRealisticMilkingTime.saveToXMLFile)

	g_company.addInit(GC_AddOnRealisticMilkingTime, GC_AddOnRealisticMilkingTime.init);

	GC_AddOnRealisticMilkingTime.registeredModules = {}
end

function GC_AddOnRealisticMilkingTime:init()	
	g_currentMission.environment:addHourChangeListener(GC_AddOnRealisticMilkingTime)		
end

function GC_AddOnRealisticMilkingTime:changeFillLevels(modul, fillDelta, fillTypeIndex)
	if fillTypeIndex == FillType.MILK and fillDelta > 0 then
		local delta = 0.0
		if modul.fillLevels[fillTypeIndex] ~= nil then
			if GC_AddOnRealisticMilkingTime.registeredModules[modul] == nil then
				GC_AddOnRealisticMilkingTime.registeredModules[modul] = true
			end
			if modul.realisticMilkingTimeLevel == nil then
				modul.realisticMilkingTimeLevel = 0
			end
			local oldFillLevel = modul.realisticMilkingTimeLevel
			local newFillLevel = oldFillLevel + fillDelta				
			newFillLevel = math.max(newFillLevel, 0.0)
			delta = newFillLevel - oldFillLevel
			modul.realisticMilkingTimeLevel = MathUtil.clamp(newFillLevel, 0.0, modul:getCapacity())
			print(fillDelta)
		end
		return delta
	else
		return GC_AddOnRealisticMilkingTime.old_HusbandryModuleBase_changeFillLevels(modul, fillDelta, fillTypeIndex)
	end
end

function GC_AddOnRealisticMilkingTime:hourChanged()
	local currentHour = g_currentMission.environment.currentHour
	for _,time in pairs(GC_AddOnRealisticMilkingTime.TIMES) do
		if time == currentHour then
			for _, husbandry in pairs(g_currentMission:getHusbandries()) do
				local modul = husbandry.modulesByName["milk"]	
				if modul.realisticMilkingTimeLevel ~= nil and modul.realisticMilkingTimeLevel > 0 then
					fillDelta = modul.realisticMilkingTimeLevel
					local oldFillLevel = modul.fillLevels[FillType.MILK]
					local newFillLevel = oldFillLevel + fillDelta
					newFillLevel = math.max(newFillLevel, 0.0)
					delta = newFillLevel - oldFillLevel
					local oldTotalFillLevel = modul:getTotalFillLevel()
					local capacity = modul:getCapacity()
					local newTotalFillLevel = oldTotalFillLevel + delta
					newTotalFillLevel = MathUtil.clamp(newTotalFillLevel, 0.0, capacity)
					delta = newTotalFillLevel - oldTotalFillLevel
					modul:setFillLevel(FillType.MILK, newTotalFillLevel)
					modul.realisticMilkingTimeLevel = 0   
				end
			end
		end
	end
end

function GC_AddOnRealisticMilkingTime:loadFromXMLFile(husbandry, ret, xmlFile, key)
	if ret then
		local modul = husbandry.modulesByName["milk"]	
		modul.realisticMilkingTimeLevel = getXMLFloat(xmlFile, key .. "#realisticMilkingTimeLevel")
		return true
	end
	return ret
end

function GC_AddOnRealisticMilkingTime:saveToXMLFile(husbandry, ret, xmlFile, key, usedModNames)
	local modul = husbandry.modulesByName["milk"]
	if modul.realisticMilkingTimeLevel ~= nil and modul.realisticMilkingTimeLevel > 0 then
		setXMLFloat(xmlFile, key .. "#realisticMilkingTimeLevel", modul.realisticMilkingTimeLevel)
	end
end
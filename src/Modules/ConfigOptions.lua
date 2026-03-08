-- Path of Building
--
-- Module: Config Options
-- List of options for the Configuration tab.
--

local m_min = math.min
local m_max = math.max
local s_format = string.format

local function applyPantheonDescription(tooltip, mode, index, value)
	tooltip:Clear()
	if value.val == "None" then
		return
	end
	local applyModes = { BODY = true, HOVER = true }
	if applyModes[mode] then
		local god = data.pantheons[value.val]
		for _, soul in ipairs(god.souls) do
			local name = soul.name
			local lines = { }
			for _, mod in ipairs(soul.mods) do
				table.insert(lines, mod.line)
			end
			tooltip:AddLine(20, '^8'..name)
			tooltip:AddLine(14, '^6'..table.concat(lines, '\n'))
			tooltip:AddSeparator(10)
		end
	end
end

local function banditTooltip(tooltip, mode, index, value)
	local banditBenefits = {
		["None"] = "패시브 스킬 포인트 1 부여",
		["Oak"] = "최대 ^xE05030생명력 ^7+40",
		["Kraityn"] = "이동 속도 8% 증가",
		["Alira"] = "모든 원소 저항 +15%",
	}
	local applyModes = { BODY = true, HOVER = true }
	tooltip:Clear()
	if applyModes[mode] then
		tooltip:AddLine(14, '^8'..banditBenefits[value.val])
	end
end

local function bossSkillsTooltip(tooltip, mode, index, value)
	local applyModes = { BODY = true, HOVER = true }
	tooltip:Clear()
	if applyModes[mode] then
		tooltip:AddLine(14, [[
^7Used to fill in defaults for specific boss skills if the boss config is not set

Bosses' damage is modified by roll range configuration, defaulted at a 70% roll, at the normal monster level for your character level (capped at 85)
Fill in the exact damage numbers if more precision is needed]])
		if value.val ~= "None" then
			tooltip:AddLine(14, '\n^7'..value.val..": "..data.bossSkills[value.val].tooltip)
		end
	end
end

local function LowLifeTooltip(modList, build)
	local out = 'You will automatically be considered to be on Low ^xE05030Life ^7if you have at least '..100 - build.calcsTab.mainOutput.LowLifePercentage..'% ^xE05030Life ^7reserved'
	out = out..'\nbut you can use this option to force it if necessary.'
	return out
end

local function FullLifeTooltip(modList, build)
	local out = 'You can be considered to be on Full ^xE05030Life ^7if you have at least '..build.calcsTab.mainOutput.FullLifePercentage..'% ^xE05030Life ^7left.'
	out = out..'\nYou will automatically be considered to be on Full ^xE05030Life ^7if you have Chaos Inoculation,'
	out = out..'\nbut you can use this option to force it if necessary.'
	return out
end

local function mapAffixTooltip(tooltip, mode, index, value)
	tooltip:Clear()
	if value.val == "NONE" then
		return
	end
	local applyModes = { BODY = true, HOVER = true }
	if applyModes[mode] then
		tooltip:AddLine(14, '^7'..value.val)
		local affixData = data.mapMods.AffixData[value.val] or {}
		if #affixData.tooltipLines > 0 then
			if affixData.type == "check" then
				for _, line in ipairs(affixData.tooltipLines) do
					tooltip:AddLine(14, '^7'..line)
				end
			elseif affixData.type == "list" then
				for i, tier in ipairs({"Low", "Med", "High"}) do
					tooltip:AddLine(16, '^7'..tier..": ")
					for j, line in ipairs(affixData.tooltipLines) do
						local modValue = (#affixData.tooltipLines > 1) and affixData.values[i][j] or affixData.values[i]
						if modValue == nil then
							tooltip:AddLine(14, '   ^7'..line)
						elseif modValue ~= 0 then
							tooltip:AddLine(14, '   ^7'..s_format(line, modValue))
						end
					end
				end
			elseif affixData.type == "count" then
				for i, tier in ipairs({"Low", "Med", "High"}) do
					tooltip:AddLine(16, '^7'..tier..": ")
					for j, line in ipairs(affixData.tooltipLines) do
						local modValue = {(#affixData.tooltipLines > 1) and (affixData.values[i][j] and affixData.values[i][j][1] or nil) or affixData.values[i][1], (#affixData.tooltipLines > 1) and (affixData.values[i][j] and affixData.values[i][j][2] or nil) or affixData.values[i][2]}
						if modValue[2] == nil then
							tooltip:AddLine(14, '   ^7'..line)
						elseif modValue[2] ~= 0 then
							tooltip:AddLine(14, '   ^7'..s_format(line, modValue[1], modValue[2]))
						end
					end
				end
			end
		end
	end
end

local function mapAffixDropDownFunction(val, modList, enemyModList, build)
	if val ~= "NONE" then
		local affixData = data.mapMods.AffixData[val] or {}
		if affixData.apply then
			if affixData.type == "check" then
				affixData.apply(var, (1 + (build.configTab.input['multiplierMapModEffect'] or 0)/100), modList, enemyModList)
			elseif affixData.type == "list" then
				affixData.apply(4 - (build.configTab.varControls['multiplierMapModTier'].selIndex or 1), (1 + (build.configTab.input['multiplierMapModEffect'] or 0)/100), affixData.values, modList, enemyModList)
			elseif affixData.type == "count" then
				affixData.apply(4 - (build.configTab.varControls['multiplierMapModTier'].selIndex or 1), 100, (1 + (build.configTab.input['multiplierMapModEffect'] or 0)/100), affixData.values, modList, enemyModList)
			end
		end
	end
end

return {
	-- Section: General options
	{ section = "일반", col = 1 },
	{ var = "resistancePenalty", type = "list", label = "저항 패널티:", list = {{val=0,label="없음"},{val=-30,label="5장 (-30%)"},{val=-60,label="10장 (-60%)"}}, defaultIndex = 3 },
	{ var = "bandit", type = "list", defaultIndex = 1, label = "산적 퀘스트:", tooltipFunc = banditTooltip, list = {{val="None",label="모두 처치"},{val="Oak",label="오크 도움"},{val="Kraityn",label="크레이틴 도움"},{val="Alira",label="알리라 도움"}} },
	{ var = "pantheonMajorGod", type = "list", defaultIndex = 1, label = "주요 신:", tooltipFunc = applyPantheonDescription, list = {
		{ label = "없음", val = "None" },
		{ label = "소금왕의 영혼", val = "TheBrineKing" },
		{ label = "루나리스의 영혼", val = "Lunaris" },
		{ label = "솔라리스의 영혼", val = "Solaris" },
		{ label = "아라칼리의 영혼", val = "Arakaali" },
	} },
	{ var = "pantheonMinorGod", type = "list", defaultIndex = 1, label = "보조 신:", tooltipFunc = applyPantheonDescription, list = {
		{ label = "없음", val = "None" },
		{ label = "그루스쿨의 영혼", val = "Gruthkul" },
		{ label = "유굴의 영혼", val = "Yugul" },
		{ label = "아버라스의 영혼", val = "Abberath" },
		{ label = "투코하마의 영혼", val = "Tukohama" },
		{ label = "가루칸의 영혼", val = "Garukhan" },
		{ label = "랄라케쉬의 영혼", val = "Ralakesh" },
		{ label = "리슬라사의 영혼", val = "Ryslatha" },
		{ label = "샤카리의 영혼", val = "Shakari" },
	} },
	{ var = "detonateDeadCorpseLife", type = "count", label = "적 시체 ^xE05030생명력:", ifSkillData = "explodeCorpse", tooltip = "Sets the maximum ^xE05030life ^7of the target corpse for Detonate Dead and similar skills.\nFor reference, a level 70 monster has "..data.monsterLifeTable[70].." base ^xE05030life^7, and a level 80 monster has "..data.monsterLifeTable[80]..".", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "corpseLife", value = val }, "Config")
	end },
	{ var = "conditionStationary", type = "count", label = "정지 상태 시간", ifCond = "Stationary",
		tooltip = "Applies mods that use `while stationary` and `per / every second while stationary`",
		apply = function(val, modList, enemyModList)
		if type(val) == "boolean" then
			-- Backwards compatibility with older versions that set this condition as a boolean
			val = val and 1 or 0
		end
		local sanitizedValue = m_max(0, val)
		modList:NewMod("Multiplier:StationarySeconds", "BASE", sanitizedValue, "Config")
		if sanitizedValue > 0 then
			modList:NewMod("Condition:Stationary", "FLAG", true, "Config")
		end
	end },
	{ var = "conditionMoving", type = "check", label = "항상 이동 중인가요?", ifCond = "Moving", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Moving", "FLAG", true, "Config")
	end },
	{ var = "conditionFullLife", type = "check", label = "항상 최대 ^xE05030생명력^7인가요?", ifCond = "FullLife", tooltip = FullLifeTooltip, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FullLife", "FLAG", true, "Config")
	end },
	{ var = "conditionLowLife", type = "check", label = "항상 최저 ^xE05030생명력^7인가요?", ifCond = "LowLife", tooltip = LowLifeTooltip, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LowLife", "FLAG", true, "Config")
	end },
	{ var = "conditionFullMana", type = "check", label = "항상 최대 ^x7070FF마나^7인가요?", ifCond = "FullMana", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FullMana", "FLAG", true, "Config")
	end },
	{ var = "conditionLowMana", type = "check", label = "항상 최저 ^x7070FF마나^7인가요?", ifCond = "LowMana", tooltip = "You will automatically be considered to be on Low ^x7070FFMana ^7if you have at least 50% ^x7070FFmana ^7reserved,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LowMana", "FLAG", true, "Config")
	end },
	{ var = "conditionFullEnergyShield", type = "check", label = "항상 최대 ^x88FFFF에너지 보호막^7인가요?", ifCond = "FullEnergyShield", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FullEnergyShield", "FLAG", true, "Config")
	end },
	{ var = "conditionLowEnergyShield", type = "check", label = "항상 최저 ^x88FFFF에너지 보호막^7인가요?", ifCond = "LowEnergyShield", tooltip = "You will automatically be considered to be on Low ^x88FFFFEnergy Shield ^7if you have at least 50% ^x88FFFFES ^7reserved,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LowEnergyShield", "FLAG", true, "Config")
	end },
	{ var = "conditionHaveEnergyShield", type = "check", label = "항상 ^x88FFFF에너지 보호막^7이 있나요?", ifCond = "HaveEnergyShield", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HaveEnergyShield", "FLAG", true, "Config")
	end },
	{ var = "minionsConditionFullLife", type = "check", label = "소환수가 항상 최대 ^xE05030생명력^7인가요?", ifMinionCond = "FullLife", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:FullLife", "FLAG", true, "Config") }, "Config")
	end },
	{ var = "minionsConditionLowLife", type = "check", label = "소환수가 항상 최저 ^xE05030생명력^7인가요?", ifMinionCond = "LowLife", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:LowLife", "FLAG", true, "Config") }, "Config")
	end },
	{ var = "minionsConditionFullEnergyShield", type = "check", label = "소환수가 항상 최대 ^x88FFFF에너지 보호막^7인가요?", ifMinionCond = "FullEnergyShield", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:FullEnergyShield", "FLAG", true, "Config") }, "Config")
	end },
	{ var = "minionsConditionCreatedRecently", type = "check", label = "최근 소환수를 생성했나요?", ifCond = "MinionsCreatedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:MinionsCreatedRecently", "FLAG", true, "Config")
	end },
	{ var = "ailmentMode", type = "list", label = "상태 이상 계산 모드:", tooltip = "Controls how the base damage for applying Ailments is calculated:\n\tAverage: damage is based on the average application, including both crits and non-crits\n\tCrits Only: damage is based solely on Ailments inflicted with crits", list = {{val="AVERAGE",label="평균"},{val="CRIT",label="치명타만"}} },
	{ var = "physMode", type = "list", label = "무작위 원소 모드:", ifFlag = "randomPhys", tooltip = "Controls how modifiers which choose a random element will function.\n\tAverage: Modifiers will grant one third of their value to ^xB97123Fire^7, ^x3F6DB3Cold^7, and ^xADAA47Lightning ^7simultaneously\n\t^xB97123Fire ^7/ ^x3F6DB3Cold ^7/ ^xADAA47Lightning^7: Modifiers will grant their full value as the specified element\nIf a modifier chooses between just two elements, the full value can only be given as those two elements.", list = {{val="AVERAGE",label="평균"},{val="FIRE",label="^xB97123화염"},{val="COLD",label="^x3F6DB3냉기"},{val="LIGHTNING",label="^xADAA47번개"}} },
	{ var = "lifeRegenMode", type = "list", label = "^xE05030생명력 ^7재생 계산 모드:", ifCond = { "LifeRegenBurstAvg", "LifeRegenBurstFull" }, tooltip = "Controls how ^xE05030life ^7regeneration is calculated:\n\tMinimum: does not include burst regen\n\tAverage: includes burst regen, averaged based on uptime\n\tBurst: includes full burst regen", list = {{val="MIN",label="최소"},{val="AVERAGE",label="평균"},{val="FULL",label="순간"}}, apply = function(val, modList, enemyModList)
		if val == "AVERAGE" then
			modList:NewMod("Condition:LifeRegenBurstAvg", "FLAG", true, "Config")
		elseif val == "FULL" then
			modList:NewMod("Condition:LifeRegenBurstFull", "FLAG", true, "Config")
		end
	end },
	{ var = "resourceGainMode", type = "list", label = "자원 획득 계산 모드:", ifCond = "AverageResourceGain", defaultIndex = 2, tooltip = "Controls how resource on hit/kill is calculated:\n\tMinimum: does not include chances\n\tAverage: includes chance gains, averaged based on uptime\n\tMaximum: treats all chances as certain", list = {{val="MIN",label="최소"},{val="AVERAGE",label="평균"},{val="MAX",label="최대"}}, apply = function(val, modList, enemyModList)
		if val == "AVERAGE" then
			modList:NewMod("Condition:AverageResourceGain", "FLAG", true, "Config")
		elseif val == "MAX" then
			modList:NewMod("Condition:MaxResourceGain", "FLAG", true, "Config")
		end
	end },
	{ var = "EHPUnluckyWorstOf", type = "list", label = "유효 생명력 불운 계산:", tooltip = "Sets the EHP calc to pretend its unlucky and reduce the effects of random events such as\n\tBlock/Spell Block Chance\n\tDodge/Spell Dodge Chance\n\tSpell Suppression Chance\n\tAvoidance Chance", list = {{val=1,label="평균"},{val=2,label="불운"},{val=4,label="매우 불운"}} },
	{ var = "DisableEHPGainOnBlock", type = "check", label = "피격 시 유효 생명력 획득 비활성화:", ifMod = {"LifeOnBlock", "ManaOnBlock", "EnergyShieldOnBlock", "EnergyShieldOnSpellBlock", "LifeOnSuppress", "EnergyShieldOnSuppress", "MissingLifeBeforeEnemyHit", "MissingManaBeforeEnemyHit"}, tooltip = "Sets the EHP calc to not apply gain on block, suppress or Defiance of Destiny effects"},
	{ var = "armourCalculationMode", type = "list", label = "방어구 계산 모드:", ifCond = { "ArmourMax", "ArmourAvg" }, tooltip = "Controls how Defending with Double Armour is calculated:\n\tMinimum: never Defend with Double Armour\n\tAverage: Damage Reduction from Defending with Double Armour is proportional to chance\n\tMaximum: always Defend with Double Armour\nThis setting has no effect if you have 100% chance to Defend with Double Armour.", list = {{val="MIN",label="최소"},{val="AVERAGE",label="평균"},{val="MAX",label="최대"}}, apply = function(val, modList, enemyModList)
		if val == "MAX" then
			modList:NewMod("Condition:ArmourMax", "FLAG", true, "Config")
		elseif val == "AVERAGE" then
			modList:NewMod("Condition:ArmourAvg", "FLAG", true, "Config")
		end
	end },
	{ var = "warcryMode", type = "list", label = "강화/증폭 계산 모드:", ifSkill = { "Fist of War", "Infernal Cry", "Ancestral Cry", "Enduring Cry", "General's Cry", "Intimidating Cry", "Rallying Cry", "Seismic Cry", "Battlemage's Cry", "Vengeful Cry" }, tooltip = "Controls how exerted attacks from Warcries are calculated:\nAverage: Averages out Warcry usage with cast time, attack speed and warcry cooldown.\nMax Hit: Shows maximum hit for lining up all warcries.", list = {{val="AVERAGE",label="평균"},{val="MAX",label="최대 적중"}}, apply = function(val, modList, enemyModList)
		if val == "MAX" then
			modList:NewMod("Condition:WarcryMaxHit", "FLAG", true, "Config")
		end
	end },
	{ var = "EVBypass", type = "check", label = "황제의 경계심 우회 비활성화", ifCond = "EVBypass", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:EVBypass", "FLAG", true, "Config")
	end },
	{ var = "ignoreItemDisablers", type = "check", label = "아이템 비활성화 하지 않기", ifTagType = "DisablesItem", tooltip = "Ignore the effects of things which disable items, like Bringer of Rain" },
	{ var = "ignoreJewelLimits", type = "check", label = "주얼 제한 무시", tooltip = "Ignore the limits on jewels" },
	{ var = "overrideEmptyRedSockets", type = "count", label = "빈 ^xE05030빨강^7 소켓 수", ifMult = "EmptyRedSocketsInAnySlot",  tooltip = "This option allows you to override the default calculation for the number of Empty ^xE05030Red^7 Sockets.\nThe default calculation assumes enabled gems in skill socket groups fill the item in socket order disregarding gem colour.\nLeave blank for default calculation." },
	{ var = "overrideEmptyGreenSockets", type = "count", label = "빈 ^x70FF70녹색^7 소켓 수", ifMult = "EmptyGreenSocketsInAnySlot", tooltip = "This option allows you to override the default calculation for the number of Empty ^x70FF70Green^7 Sockets.\nThe default calculation assumes enabled gems in skill socket groups fill the item in socket order disregarding gem colour.\nLeave blank for default calculation." },
	{ var = "overrideEmptyBlueSockets", type = "count", label = "빈 ^x7070FF파랑^7 소켓 수", ifMult = "EmptyBlueSocketsInAnySlot", tooltip = "This option allows you to override the default calculation for the number of Empty ^x7070FFBlue^7 Sockets.\nThe default calculation assumes enabled gems in skill socket groups fill the item in socket order disregarding gem colour.\nLeave blank for default calculation." },
	{ var = "overrideEmptyWhiteSockets", type = "count", label = "빈 흰색 소켓 수", ifMult = "EmptyWhiteSocketsInAnySlot", tooltip = "This option allows you to override the default calculation for the number of Empty White Sockets.\nThe default calculation assumes enabled gems in skill socket groups fill the item in socket order disregarding gem colour.\nLeave blank for default calculation." },

	-- Section: Skill-specific options
	{ section = "스킬 옵션", col = 2 },
	{ label = "비전 보호막:", ifSkill = "Arcane Cloak"},
	{ var = "arcaneCloakUsedRecentlyCheck", type = "check", label = "최근 소모한 ^x7070FF마나^7에 포함?", ifSkill = "Arcane Cloak", tooltip = "When enabled, the mana spent by Arcane Cloak used at full mana \nwill be added to the value provided in # of ^x7070FFMana ^7spent Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ArcaneCloakUsedRecently", "FLAG", true, "Config")
	end },
	{ label = "조류의 화신:", ifSkill = "Aspect of the Avian" },
	{ var = "aspectOfTheAvianAviansMight", type = "check", label = "조류의 힘이 활성화 중인가요?", ifSkill = "Aspect of the Avian", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AviansMightActive", "FLAG", true, "Config")
	end },
	{ var = "aspectOfTheAvianAviansFlight", type = "check", label = "조류의 비행이 활성화 중인가요?", ifSkill = "Aspect of the Avian", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AviansFlightActive", "FLAG", true, "Config")
	end },
	{ label = "고양이의 화신:", ifSkill = "Aspect of the Cat" },
	{ var = "aspectOfTheCatCatsStealth", type = "check", label = "고양이의 은밀함이 활성화 중인가요?", ifSkill = "Aspect of the Cat", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CatsStealthActive", "FLAG", true, "Config")
	end },
	{ var = "aspectOfTheCatCatsAgility", type = "check", label = "고양이의 민첩이 활성화 중인가요?", ifSkill = "Aspect of the Cat", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CatsAgilityActive", "FLAG", true, "Config")
	end },
	{ label = "게의 화신:", ifSkill = "Aspect of the Crab" },
	{ var = "overrideCrabBarriers", type = "countAllowZero", label = "게 방벽 수 (최대가 아닌 경우):", ifSkill = "Aspect of the Crab", apply = function(val, modList, enemyModList)
		modList:NewMod("CrabBarriers", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ label = "거미의 화신:", ifSkill = "Aspect of the Spider" },
	{ var = "aspectOfTheSpiderWebStacks", type = "countAllowZero", label = "거미줄 중첩 수:", ifSkill = "Aspect of the Spider", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraSkillMod", "LIST", { mod = modLib.createMod("Multiplier:SpiderWebApplyStack", "BASE", val) }, "Config", { type = "SkillName", skillName = "Aspect of the Spider" })
		if val > 0 then
			modList:NewMod("Condition:AspectOfTheSpiderActive", "FLAG", true, "Config")
		end
	end },
	{ label = "깃발 스킬:", ifSkill = { "Dread Banner", "War Banner", "Defiance Banner" } },
	{ var = "bannerPlanted", type = "check", label = "깃발을 꽂았나요?", ifSkill = { "Dread Banner", "War Banner", "Defiance Banner" }, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BannerPlanted", "FLAG", true, "Config")
	end },
	{ var = "bannerValour", type = "count", label = "깃발 무훈:", tooltip = "The amount of valour consumed for the placed banner", ifSkill = { "Dread Banner", "War Banner", "Defiance Banner" }, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ValourStacks", "BASE", val, "Config", { type = "IgnoreCond" }, { type = "Condition", var = "Combat" })
	end },
	{ label = "나무 껍질:", ifSkill = "Barkskin" },
	{ var = "barkskinStacks", type = "count", label = "나무 껍질 중첩 수:", ifSkill = "Barkskin", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:BarkskinStacks", "BASE",  m_min(val, 10), "Config")
		modList:NewMod("Multiplier:MissingBarkskinStacks", "BASE", m_max(-val, -10), "Config")
	end },
	{ label = "해방된 화신:", ifSkill = "Unbound Avatar" },
	{ var = "Unbound", type = "check", label = "해방 상태인가요?", ifSkill = "Unbound Avatar", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Unbound", "FLAG", true, "Config")
	end },
	{ label = "칼날 폭풍:", ifSkill = "Bladestorm", includeTransfigured = true },
	{ var = "bladestormInBloodstorm", type = "check", label = "피바람 안에 있나요?", ifSkill = "Bladestorm", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BladestormInBloodstorm", "FLAG", true, "Config", { type = "SkillName", skillName = "Bladestorm", includeTransfigured = true })
	end },
	{ var = "bladestormInSandstorm", type = "check", label = "모래폭풍 안에 있나요?", ifSkill = "Bladestorm", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BladestormInSandstorm", "FLAG", true, "Config", { type = "SkillName", skillName = "Bladestorm", includeTransfigured = true })
	end },
	{ label = "피의 성찬:", ifSkill = "Blood Sacrament" },
	{ var = "bloodSacramentReservationEHP", type = "check", label = "스킬 점유를 유효 생명력에 포함?", ifSkill = "Blood Sacrament", tooltip = "Use this option to disable the skill reservation factoring into eHP calculations",apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BloodSacramentReservationEHP", "FLAG", true, "Config")
	end },
	{ label = "낙인 스킬:", ifSkill = { "Armageddon Brand", "Storm Brand", "Arcanist Brand", "Penance Brand", "Wintertide Brand" }, includeTransfigured = true }, -- I barely resisted the temptation to label this "Generic Brand:"
	{ var = "ActiveBrands", type = "count", label = "활성화된 낙인 수:", ifSkill = { "Armageddon Brand", "Storm Brand", "Arcanist Brand", "Penance Brand", "Wintertide Brand" }, includeTransfigured = true , apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ConfigActiveBrands", "BASE", val, "Config")
	end },
	{ var = "BrandsAttachedToEnemy", type = "count", label = "적에게 부착된 낙인 수:", ifEnemyMult = "BrandsAttached", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ConfigBrandsAttachedToEnemy", "BASE", val, "Config")
	end },
	{ var = "targetBrandedEnemy", type = "check", label = "스킬이 낙인 적을 대상으로 함", ifCond = "TargetingBrandedEnemy", defaultState = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TargetingBrandedEnemy", "FLAG", true, "Config")
	end },
	{ var = "BrandsInLastQuarter", type = "check", label = "부착 지속시간의 마지막 25%?", ifCond = "BrandLastQuarter", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BrandLastQuarter", "FLAG", true, "Config")
		modList:NewMod("Condition:BrandLastHalf", "FLAG", true, "Config")
	end },
	{ var = "BrandsInLastHalf", type = "check", label = "부착 지속시간의 마지막 50%?", ifCond = "BrandLastHalf", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BrandLastHalf", "FLAG", true, "Config")
	end },
	{ label = "시체 먹는 골렘:", ifSkill = "Summon Carrion Golem", includeTransfigured = true },
	{ var = "carrionGolemNearbyMinion", type = "count", label = "주변 골렘 외 소환수 수:", ifSkill = "Summon Carrion Golem", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyNonGolemMinion", "BASE", val, "Config")
	end },
	{ var = "carrionGolemEqualsChaosGolem", type = "check", label = "# 시체 먹는 골렘 = # 카오스 골렘:", ifCond = "CarrionEqualChaosGolem", ifSkill = "Summon Chaos Golem", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CarrionEqualChaosGolem", "FLAG", true, "Config")
	end },
	{ var = "chaosGolemEqualsStoneGolem", type = "check", label = "# 카오스 골렘 = # 바위 골렘:", ifCond = "ChaosEqualStoneGolem", ifSkill = "Summon Stone Golem", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ChaosEqualStoneGolem", "FLAG", true, "Config")
	end },
	{ var = "stoneGolemEqualsCarrionGolem", type = "check", label = "# 바위 골렘 = # 시체 먹는 골렘:", ifCond = "StoneEqualCarrionGolem", ifSkill = "Summon Carrion Golem", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StoneEqualCarrionGolem", "FLAG", true, "Config")
	end },
	{ label = "근접 전투:", ifSkill = "Close Combat" },
	{ var = "closeCombatCombatRush", type = "check", label = "전투 돌진이 활성화 중인가요?", ifSkill = "Close Combat", tooltip = "Combat Rush grants 20% more Attack Speed to Travel Skills not Supported by Close Combat.",apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CombatRushActive", "FLAG", true, "Config")
	end },
	{ label = "한파:", ifSkill = "Cold Snap", includeTransfigured = true },
	{ var = "ColdSnapBypassCD", type = "check", label = "재사용 대기시간 무시?", ifSkill = "Cold Snap", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("CooldownRecovery", "OVERRIDE", 0, "Config", { type = "SkillName", skillName = "Cold Snap", includeTransfigured = true })
	end },
	{ label = "인내의 신성한 길:", ifSkill = "Consecrated Path of Endurance" },
	{ var = "ConcPathBypassCD", type = "check", label = "재사용 대기시간 무시?", ifSkill = "Consecrated Path of Endurance", defaultState = true, apply = function(val, modList, enemyModList)
		modList:NewMod("CooldownRecovery", "OVERRIDE", 0, "Config", { type = "SkillName", skillName = "Consecrated Path of Endurance" })
	end },
	{ label = "타락의 외침:", ifSkill = "Corrupting Cry" },
	{ var = "conditionCorruptingCryStages", type = "count", label = "적에 대한 타락의 외침 중첩 수", ifSkill = "Corrupting Cry", defaultState = 1, apply = function(val, modList, enemyModList)
		-- 10 is the maximum amount of Corrupting Blood Stages. modList does not contain skill base mods at this point so hard coding it here is the cleanest way to handle the cap.
		-- It's set to 9 here with val -1 to so that it defaults to 1 stage and has max 10 stages.
		modList:NewMod("Multiplier:CorruptingCryStageAfterFirst", "BASE", m_min(val-1, 9), "Config", { type = "Condition", var = "Effective" })
	end },
	{ label = "잔혹:", ifSkill = "Cruelty" },
	{ var = "overrideCruelty", type = "count", label = "피해 % (최대가 아닌 경우):", ifSkill = "Cruelty", tooltip = "Cruelty is a buff provided by Cruelty Support which grants\nup to 40% more damage over time to the skills it supports.", apply = function(val, modList, enemyModList)
		modList:NewMod("Cruelty", "OVERRIDE", m_min(val, 40), "Config", { type = "Condition", var = "Combat" })
	end },
	{ label = "회오리:", ifSkill = "Cyclone", includeTransfigured = true },
	{ var = "channellingCycloneCheck", type = "check", label = "회오리를 집중 유지 중인가요?", ifSkill = "Cyclone", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ChannellingCyclone", "FLAG", true, "Config")
	end },
	{ label = "어둠의 서약:", ifSkill = "Dark Pact" },
	{ var = "darkPactSkeletonLife", type = "count", label = "해골 ^xE05030생명력:", ifSkill = "Dark Pact", tooltip = "Sets the maximum ^xE05030Life ^7of the Skeleton that is being targeted.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "skeletonLife", value = val }, "Config", { type = "SkillName", skillName = "Dark Pact" })
	end },
	{ label = "파멸 폭발:", ifSkill = "Doom Blast" },
	{ var = "doomBlastSource", type = "list", label = "파멸 폭발 발동 원천:", ifSkill = "Doom Blast", list = {{val="expiration",label="저주 만료"},{val="replacement",label="저주 교체"},{val="vixen",label="빅슨의 저주"},{val="hexblast",label="사술 폭발 교체"}}, defaultIndex = 3},
	{ var = "curseOverlaps", type = "count", label = "저주 겹침:", ifSkill = "Doom Blast", ifFlag = "UsesCurseOverlaps", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:CurseOverlaps", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ label = "원소 군대:", ifSkill = "Elemental Army" },
	{ var = "elementalArmyExposureType", type = "list", label = "노출 유형:", ifSkill = "Elemental Army", list = {{val=0,label="없음"},{val="Fire",label="^xB97123화염"},{val="Cold",label="^x3F6DB3냉기"},{val="Lightning",label="^xADAA47번개"}}, apply = function(val, modList, enemyModList)
		if val == "Fire" then
			modList:NewMod("FireExposureChance", "BASE", 100, "Config")
		elseif val == "Cold" then
			modList:NewMod("ColdExposureChance", "BASE", 100, "Config")
		elseif val == "Lightning" then
			modList:NewMod("LightningExposureChance", "BASE", 100, "Config")
		end
	end },
	{ label = "광기 수용:", ifSkill = "Embrace Madness" },
	{ var = "embraceMadnessActive", type = "check", label = "광기 수용이 활성화 중인가요?", ifSkill = "Embrace Madness", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AffectedByGloriousMadness", "FLAG", true, "Config")
	end },
	{ var = "touchedDebuffsCount", type = "countAllowZero", label = "영광의 광기 중첩", ifOption = "embraceMadnessActive", defaultState = 10, tooltip = "Glorious Madness Stacks grants:\n\tEroding Touch: 6% inc Damage Taken per stack\n\tParalysing Touch: 6% reduced Action Speed per stack\n\tDiluting Touch: 9% reduced Flask charges gained and 9% reduced Flask Effect per stack\n\tWasting Touch: 9% reduced ^xE05030Life ^7and ^x88FFFFEnergy Shield ^7recovery rate per stack", apply = function(val, modList, enemyModList)
		val = m_min(val, 10)
		modList:NewMod("DamageTaken", "INC", val * 6, val.." Eroding Touch Stacks", { type = "GlobalEffect", effectType = "Debuff" }, { type = "Condition", var = "AffectedByGloriousMadness" })
		modList:NewMod("ActionSpeed", "INC", -val * 6, val.." Paralysing Touch Stacks", { type = "GlobalEffect", effectType = "Debuff" }, { type = "Condition", var = "AffectedByGloriousMadness" })
		modList:NewMod("FlaskChargesGained", "INC", -val * 9, val.." Diluting Touch Stacks", { type = "GlobalEffect", effectType = "Debuff" }, { type = "Condition", var = "AffectedByGloriousMadness" })
		modList:NewMod("FlaskEffect", "INC", -val * 9, val.." Diluting Touch Stacks", { type = "GlobalEffect", effectType = "Debuff" }, { type = "Condition", var = "AffectedByGloriousMadness" })
		modList:NewMod("LifeRecoveryRate", "INC", -val * 9, val.." Wasting Touch Stacks", { type = "GlobalEffect", effectType = "Debuff" }, { type = "Condition", var = "AffectedByGloriousMadness" })
		modList:NewMod("EnergyShieldRecoveryRate", "INC", -val * 9, val.." Wasting Touch Stacks", { type = "GlobalEffect", effectType = "Debuff" }, { type = "Condition", var = "AffectedByGloriousMadness" })
	end },
	{ label = "광란의 포식:", ifSkill = "Feeding Frenzy" },
	{ var = "feedingFrenzyFeedingFrenzyActive", type = "check", label = "광란의 포식이 활성화 중인가요?", ifSkill = "Feeding Frenzy", tooltip = "Feeding Frenzy grants:\n\t10% more Minion Damage\n\t10% increased Minion Movement Speed\n\t10% increased Minion Attack and Cast Speed", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FeedingFrenzyActive", "FLAG", true, "Config")
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Damage", "MORE", 10, "Feeding Frenzy") }, "Config")
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("MovementSpeed", "INC", 10, "Feeding Frenzy") }, "Config")
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Speed", "INC", 10, "Feeding Frenzy") }, "Config")
	end },
	{ label = "화염의 벽:", ifSkill = "Flame Wall" },
	{ var = "flameWallAddedDamage", type = "check", label = "투사체가 화염의 벽을 통과했나요?", ifSkill = "Flame Wall", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FlameWallAddedDamage", "FLAG", true, "Config")
	end },
	{ label = "깜박임 타격:", ifSkill = "Flicker Strike", includeTransfigured = true },
	{ var = "FlickerStrikeBypassCD", type = "check", label = "재사용 대기시간 무시?", ifSkill = "Flicker Strike", includeTransfigured = true, defaultState = true, apply = function(val, modList, enemyModList)
		modList:NewMod("CooldownRecovery", "OVERRIDE", 0, "Config", { type = "SkillName", skillName = "Flicker Strike", includeTransfigured = true })
	end },
	{ label = "신선한 고기:", ifSkill = "Fresh Meat" },
	{ var = "freshMeatBuffs", type = "check", label = "신선한 고기가 활성화 중인가요?", ifSkill = "Fresh Meat", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FreshMeatActive", "FLAG", true, "Config")
	end },
	{ label = "서리 방패:", ifSkill = "Frost Shield" },
	{ var = "frostShieldStages", type = "count", label = "단계:", ifSkill = "Frost Shield", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:FrostShieldStage", "BASE", val, "Config")
	end },
	{ label = "시간의 상급 전령:", ifSkill =  "Summon Greater Harbinger of Time" },
	{ var = "greaterHarbingerOfTimeSlipstream", type = "check", label = "역류가 활성화 중인가요?:", ifSkill =  "Summon Greater Harbinger of Time", tooltip = "Greater Harbinger of Time Slipstream buff grants:\n10% increased Action Speed\nBuff affects the player and allies\nBuff has a base duration of 8s with a 10s Cooldown", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:GreaterHarbingerOfTime", "FLAG", true, "Config")
	end },
	{ label = "시간의 전령:", ifSkill =  "Summon Harbinger of Time" },
	{ var = "harbingerOfTimeSlipstream", type = "check", label = "역류가 활성화 중인가요?:", ifSkill =  "Summon Harbinger of Time", tooltip = "Harbinger of Time Slipstream buff grants:\n10% increased Action Speed\nBuff affects the player, allies and enemies in a small radius\nBuff has a base duration of 8s with a 20s Cooldown", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HarbingerOfTime", "FLAG", true, "Config")
	end },
	{ label = "사술:", ifSkillFlag = "hex", ifMult = "MaxDoom" },
	{ var = "multiplierHexDoom", type = "count", label = "사술의 파멸:", ifSkillFlag = "hex", ifMult = "MaxDoom", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:HexDoomStack", "BASE", val, "Config")
	end },
	{ label = "고통의 전령:", ifSkill = "Herald of Agony" },
	{ var = "heraldOfAgonyVirulenceStack", type = "count", label = "독성 중첩 수:", ifSkill = "Herald of Agony", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:VirulenceStack", "BASE", val, "Config")
	end },
	{ label = "재의 전령:", ifSkill = "Herald of Ash" },
	{ var = "hoaOverkill", type = "count", label = "초과 피해:", tooltip = "Herald of Ash's base ^xB97123Burning ^7damage is equal to 25% of Overkill damage.", ifSkill = "Herald of Ash", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "hoaOverkill", value = val }, "Config", { type = "SkillName", skillName = "Herald of Ash" })
	end },
	{ label = "벌떼의 전령:", ifSkill = "Herald of the Hive" },
	{ var = "heraldOfTheHivePressure", type = "count", label = "이세계의 압력 중첩 수:", ifSkill = "Herald of the Hive", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:OtherworldlyPressure", "BASE", val, "Config")
	end },
	{ label = "얼음 회오리:", ifSkill = "Ice Nova of Frostbolts" },
	{ var = "iceNovaCastOnFrostbolt", type = "check", label = "얼음 화살에 시전?", ifSkill = "Ice Nova of Frostbolts", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastOnFrostbolt", "FLAG", true, "Config", { type = "SkillName", skillName = "Ice Nova of Frostbolts" })
	end },
	{ label = "주입:", ifSkill = "Infused Channelling" },
	{ var = "infusedChannellingInfusion", type = "check", label = "주입이 활성화 중인가요?", ifSkill = "Infused Channelling", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:InfusionActive", "FLAG", true, "Config")
	end },
	{ label = "내면의 힘:", ifSkill = "Innervate" },
	{ var = "innervateInnervation", type = "check", label = "내면의 활력이 활성화 중인가요?", ifSkill = "Innervate", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:InnervationActive", "FLAG", true, "Config")
	end },
	{ label = "집중화:", ifSkill = { "Intensify", "Crackling Lance", "Pinpoint" } },
	{ var = "intensifyIntensity", type = "count", label = "강도 수:", ifSkill = { "Intensify", "Crackling Lance", "Pinpoint" }, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:Intensity", "BASE", val, "Config")
	end },
	{ label = "연결 스킬:", ifSkill = { "Destructive Link", "Flame Link", "Intuitive Link", "Protective Link", "Soul Link", "Vampiric Link" } },
	{ var = "multiplierLinkedTargets", type = "count", label = "연결된 대상 수:", ifSkill = { "Destructive Link", "Flame Link", "Intuitive Link", "Protective Link", "Soul Link", "Vampiric Link" }, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:LinkedTargets", "BASE", val, "Config")
	end },
	{ var = "linkedToMinion", type = "check", label = "소환수에 연결되었나요?", ifSkill = { "Destructive Link", "Flame Link", "Intuitive Link", "Protective Link", "Soul Link", "Vampiric Link" }, ifFlag = "Condition:CanLinkToMinions", ifFlag = "Condition:HaveDamageableMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LinkedToMinion", "FLAG", true, "Config")
	end },
	{ var = "linkedSourceRate", type = "float", label = "직관적 연결의 원천 속도", ifSkill = "Intuitive Link", apply = function(val, modList, enemyModList)
		modList:NewMod("IntuitiveLinkSourceRate", "BASE", val, "Config")
	end },
	{ label = "마나 결속:", ifSkill = "Manabond" },
	{ var = "manabondMissingUnreservedManaPercentage", type = "count", label = "비점유 ^x7070FF마나^7 부족 %:", tooltip = "Ignores values outside the 0-100 range, defaults to 100% if not specified. \nA more realistic value would be to match your Arcane Cloak spend %.", ifSkill = "Manabond", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "ManabondMissingUnreservedManaPercentage", value = m_max(m_min(val,100), 0) }, "Config", { type = "SkillName", skillName = "Manabond" })
	end },
	{ label = "육체 방패:", ifSkill = "Meat Shield" },
	{ var = "meatShieldEnemyNearYou", type = "check", label = "적이 근처에 있나요?", ifSkill = "Meat Shield", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:MeatShieldEnemyNearYou", "FLAG", true, "Config")
	end },
	{ label = "안개의 반영:", ifSkill = "Misty Reflection" },
	{ var = "enemyHitMistyReflection", type = "check", label = "적이 안개의 반영에 맞았나요?", ifSkill = "Misty Reflection", tooltip = "Misty Reflection debuff lasts 4 seconds and makes enemies have:\n\t30% increased Damage Taken\n\tDeal 30% less Damage", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:MistyReflection", "FLAG", true, "Config")
	end },
	{ label = "추진력:", ifSkill = "Momentum" },
	{ var = "MomentumStacks", type = "count", label = "추진력 수 (평균이 아닌 경우):", ifSkill = "Momentum", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:MomentumStacks", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "MomentumSwiftnessStacks", type = "count", label = "신속함 제거된 추진력 수:", ifSkill = "Momentum", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:MomentumStacksRemoved", "BASE", val, "Config")
	end },
	{ label = "역병 보균자:", ifSkill = "Plague Bearer"},
	{ var = "plagueBearerState", type = "list", label = "상태:", defaultIndex = 1, ifSkill = "Plague Bearer", list = {{val="INC",label="잠복 중"},{val="INF",label="감염 중"}}, apply = function(val, modList, enemyModList)
		if val == "INC" then
			modList:NewMod("Condition:PlagueBearerIncubating", "FLAG", true, "Config")
		elseif val == "INF" then
			modList:NewMod("Condition:PlagueBearerInfecting", "FLAG", true, "Config")
		end
	end },
	{ label = "관통상:", ifSkill = "Perforate", includeTransfigured = true },
	{ var = "perforateSpikeOverlap", type = "count", label = "겹치는 가시 수:", tooltip = "Affects the DPS of Perforate in Blood Stance.\nMaximum is limited by the number of Spikes of Perforate.", ifSkill = "Perforate", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:PerforateSpikeOverlap", "BASE", val, "Config", { type = "SkillName", skillName = "Perforate", includeTransfigured = true })
	end },
	{ label = "물리 에기스:", ifSkill = "Physical Aegis" },
	{ var = "physicalAegisDepleted", type = "check", label = "물리 에기스가 고갈되었나요?", ifSkill = "Physical Aegis", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:PhysicalAegisDepleted", "FLAG", true, "Config")
	end },
	{ label = "포식자:", ifSkill = "Predator" },
	{ var = "deathmarkDeathmarkActive", type = "check", label = "적이 먹잇감 신호로 표시되었나요?", ifSkill = "Predator", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:EnemyHasDeathmark", "FLAG", true, "Config")
	end },
	{ label = "긍지:", ifSkill = "Pride" },
	{ var = "prideEffect", type = "list", label = "긍지 오라 효과:", ifSkill = { "Pride", "AzmeriDemonPhysicalDamageAura" }, list = {{val="MIN",label="초기 효과"},{val="MAX",label="최대 효과"}}, apply = function(val, modList, enemyModList)
		if val == "MAX" then
			modList:NewMod("Condition:PrideMaxEffect", "FLAG", true, "Config")
		end
	end },
	{ label = "분노의 소용돌이:", ifSkill = "Rage Vortex" },
	{ var = "sacrificedRageCount", type = "count", label = "희생한 ^xFF9922분노 ^7양 (최대가 아닌 경우):", ifSkill = "Rage Vortex", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:RageSacrificedStacks", "BASE", val, "Config")
	end },
	{ label = "환영 소환:", ifSkill = "Raise Spectre", includeTransfigured = true },
	{ var = "raiseSpectreEnableBuffs", type = "check", defaultState = true, label = "버프 활성화:", ifSkill = "Raise Spectre", includeTransfigured = true, tooltip = "Enable any buff skills that your spectres have.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillType", skillType = SkillType.Buff }, { type = "SkillName", skillName = "Raise Spectre", includeTransfigured = true, summonSkill = true })
	end },
	{ var = "raiseSpectreEnableCurses", type = "check", defaultState = true, label = "저주 활성화:", ifSkill = "Raise Spectre", includeTransfigured = true, tooltip = "Enable any curse skills that your spectres have.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillType", skillType = SkillType.Hex }, { type = "SkillName", skillName = "Raise Spectre", includeTransfigured = true, summonSkill = true })
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillType", skillType = SkillType.Mark }, { type = "SkillName", skillName = "Raise Spectre", includeTransfigured = true, summonSkill = true })
	end },
	{ var = "conditionSummonedSpectreInPast8Sec", type = "check", label = "지난 8초간 환영을 소환했나요?", ifCond = "SummonedSpectreInPast8Sec", ifSkill = "Raise Spectre", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SummonedSpectreInPast8Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "raiseSpectreBladeVortexBladeCount", type = "count", label = "칼날 소용돌이 칼날 수:", ifSkill = {"DemonModularBladeVortexSpectre","GhostPirateBladeVortexSpectre"}, tooltip = "Sets the blade count for Blade Vortex skills used by spectres.\nDefault is 1; maximum is 5.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "dpsMultiplier", value = val }, "Config", { type = "SkillId", skillId = "DemonModularBladeVortexSpectre" })
		modList:NewMod("SkillData", "LIST", { key = "dpsMultiplier", value = val }, "Config", { type = "SkillId", skillId = "GhostPirateBladeVortexSpectre" })
	end },
	{ var = "raiseSpectreKaomFireBeamTotemStage", type = "count", label = "작열 광선 토템 단계 수:", ifSkill = "KaomFireBeamTotemSpectre", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:KaomFireBeamTotemStage", "BASE", val, "Config")
	end },
	{ var = "raiseSpectreEnableSummonedUrsaRallyingCry", type = "check", label = "소환된 곰의 결집의 외침 활성화:", ifSkill = "DropBearSummonedRallyingCry", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "DropBearSummonedRallyingCry" })
	end },
	{ var = "raiseSpectreEnableSlashingHorrorEnrage", type = "check", label = "참격 공포의 격노 비활성화:", ifSkill = "AzmeriDualStrikeDemonFireEnrage", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = false }, "Config", { type = "SkillId", skillId = "AzmeriDualStrikeDemonFireEnrage" })
	end },
	{ var = "raiseSpectreEnableSanguimancerDemonLowLife", type = "check", label = "혈술사 악마가 빈사 상태가 아님:", ifSkill = "ABTTAzmeriShepherdSpellDamage", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = false }, "Config", { type = "SkillId", skillId = "ABTTAzmeriShepherdSpellDamage" })
	end },
	{ label = "거미 소환:", ifSkill = "Raise Spiders" },
	{ var = "raiseSpidersSpiderCount", type = "count", label = "거미 수:", ifSkill = "Raise Spiders", tooltip = "Sets the number of active Spiders.\nThe base maximum number of Spiders is 20.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:RaisedSpiderConfig", "BASE", val, "Config")
		modList:NewMod("Multiplier:RaisedSpider", "BASE", 1, "Config", { type = "Multiplier", var = "RaisedSpiderConfig", limitStat = "ActiveSpiderLimit" })
	end },
	{ label = "좀비 소환:", ifSkill = "Raise Zombie", includeTransfigured = true, ifCond = "SummonedZombieInPast8Sec" },
	{ var = "conditionSummonedZombieInPast8Sec", type = "check", label = "지난 8초간 좀비를 소환했나요?", ifCond = "SummonedZombieInPast8Sec", ifSkill = "Raise Zombie", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SummonedZombieInPast8Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "animateWeaponLingeringBlade", type = "check", label = "잔존 칼날을 소환 중인가요?", ifSkill = "Animate Weapon", tooltip = "Enables additional damage given to Lingering Blades\nThe exact weapon is unknown but should be similar to Glass Shank", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AnimatingLingeringBlades", "FLAG", true, "Config")
	end },
	{ label = "파편 발리스타:", ifSkill = "Shrapnel Ballista", includeTransfigured = true },
	{ var = "ShrapnelBallistaProjectileOverlap", type = "count", label = "산탄 투사체 수:", tooltip = "Maximum is limited by the number of Projectiles., default of 1, if Arrow nova then default of maximum projectiles", ifSkill = "Shrapnel Ballista", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "ShrapnelBallistaProjectileOverlap", value = val }, "Config", { type = "SkillName", skillName = "Shrapnel Ballista", includeTransfigured = true })
	end },
	{ label = "권능의 인장:", ifSkill = "Sigil of Power" },
	{ var = "sigilOfPowerStages", type = "countAllowZero", label = "단계:", ifSkill = "Sigil of Power", defaultPlaceholderState = 1, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SigilOfPowerStage", "BASE", val, "Config")
	end },
	{ label = "흡수 덫:", ifSkill = "Siphoning Trap" },
	{ var = "siphoningTrapAffectedEnemies", type = "count", label = "영향받는 적 수:", ifSkill = "Siphoning Trap", tooltip = "Sets the number of enemies affected by Siphoning Trap.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnemyAffectedBySiphoningTrap", "BASE", val, "Config")
		modList:NewMod("Condition:SiphoningTrapSiphoning", "FLAG", true, "Config")
	end },
	{ label = "저격:", ifSkill = "Snipe" },
	{ var = "configSnipeStages", type = "count", label = "저격 단계 수:", ifSkill = "Snipe", tooltip = "Sets the number of stages reached before releasing Snipe.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SnipeStage", "BASE", val, "Config")
	end },
	{ label = "유령 호랑이:", ifSkill = "Summon Spectral Tiger" },
	{ var = "configSpectralTigerCount", type = "count", label = "활성 유령 호랑이 수:", ifSkill = "Summon Spectral Tiger", defaultPlaceholderState = 5, tooltip = "Sets the number of active Spectral Tigers.\nThe base maximum number of Spectral Tigers is 5.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SpectralTigerConfig", "BASE", val, "Config")
		modList:NewMod("Multiplier:SpectralTigerCount", "BASE", 1, "Config", { type = "Multiplier", var = "SpectralTigerConfig", limitStat = "ActiveTigerLimit" })
	end },
	{ label = "유령 늑대:", ifSkill = "Summon Spectral Wolf" },
	{ var = "configSpectralWolfCount", type = "count", label = "활성 유령 늑대 수:", ifSkill = "Summon Spectral Wolf", tooltip = "Sets the number of active Spectral Wolves.\nThe base maximum number of Spectral Wolves is 10.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SpectralWolfConfig", "BASE", val, "Config")
		modList:NewMod("Multiplier:SpectralWolfCount", "BASE", 1, "Config", { type = "Multiplier", var = "SpectralWolfConfig", limitStat = "ActiveWolfLimit" })
	end },
	{ label = "자세 스킬:", ifSkill = { "Blood and Sand", "Flesh and Stone", "Lacerate", "Bladestorm", "Perforate", "Perforate of Duality" } },
	{ var = "bloodSandStance", type = "list", label = "자세:", ifSkill = { "Blood and Sand", "Flesh and Stone", "Lacerate", "Bladestorm", "Perforate", "Perforate of Duality" }, list = {{val="BLOOD",label="피의 자세"},{val="SAND",label="모래의 자세"}}, apply = function(val, modList, enemyModList)
		if val == "SAND" then
			modList:NewMod("Condition:SandStance", "FLAG", true, "Config")
		end
	end },
	{ var = "changedStance", type = "check", label = "최근에 자세를 변경했나요?", ifCond = "ChangedStanceRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ChangedStanceRecently", "FLAG", true, "Config")
	end },
	{ label = "강철 스킬:", ifSkill = { "Splitting Steel of Ammunition", "Shattering Steel of Ammunition", "Lancing Steel", "Shrapnel Ballista of Steel" } },
	{ var = "shardsConsumed", type = "count", label = "소모한 강철 파편:", ifSkill = { "Splitting Steel of Ammunition", "Shattering Steel of Ammunition", "Lancing Steel", "Shrapnel Ballista of Steel" }, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SteelShardConsumed", "BASE", m_min(val, 12), "Config")
	end },
	{ var = "steelWards", type = "count", label = "강철 방벽:", ifSkill = "Shattering Steel of Ammunition", tooltip = "Steel Wards are gained from using Shattering Steel of Ammunition with at least 2 Steel Shards.\nYou can have up to 6 Steel Wards, and each grants +8% chance to Block Projectile Attack Damage.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SteelWardCount", "BASE", val, "Config")
	end },
	{ label = "폭풍 비:", ifSkill = "Storm Rain" },
	{ var = "stormRainBeamOverlap", type = "count", label = "겹치는 광선 수:", ifSkill = "Storm Rain", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "beamOverlapMultiplier", value = val }, "Config", { type = "SkillName", skillName = "Storm Rain" })
	end },
	{ label = "도관의 폭풍 비:", ifSkill = "Storm Rain of the Conduit" },
	{ var = "stormRainActiveArrows", type = "count", label = "활성화된 화살 수:", ifSkill = "Storm Rain of the Conduit", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "activeArrowMultiplier", value = val }, "Config", { type = "SkillName", skillName = "Storm Rain of the Conduit" })
	end },
	{ label = "원소 유물 소환:", ifSkill = "Summon Elemental Relic" },
	{ var = "summonElementalRelicEnableAngerAura", type = "check", defaultState = true, label = "분노 오라 활성화:", ifSkill = "Summon Elemental Relic", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "Anger" }, { type = "SkillName", skillName = "Summon Elemental Relic", summonSkill = true })
	end },
	{ var = "summonElementalRelicEnableHatredAura", type = "check", defaultState = true, label = "증오 오라 활성화:", ifSkill = "Summon Elemental Relic", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "Hatred" }, { type = "SkillName", skillName = "Summon Elemental Relic", summonSkill = true })
	end },
	{ var = "summonElementalRelicEnableWrathAura", type = "check", defaultState = true, label = "진노 오라 활성화:", ifSkill = "Summon Elemental Relic", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "Wrath" }, { type = "SkillName", skillName = "Summon Elemental Relic", summonSkill = true })
	end },
	{ label = "신성한 유물 소환:", ifSkill = "Summon Holy Relic" },
	{ var = "summonHolyRelicEnableHolyRelicBoon", type = "check", label = "신성한 유물의 은혜 오라 활성화:", ifSkill = "Summon Holy Relic", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HolyRelicBoonActive", "FLAG", true, "Config")
	end },
	{ label = "번개 골렘 소환:", ifSkill = "Summon Lightning Golem", includeTransfigured = true },
	{ var = "summonLightningGolemEnableWrath", type = "check", label = "진노 오라 활성화:", ifSkill = "Summon Lightning Golem", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "LightningGolemWrath" })
	end },
	{ label = "사신 소환:", ifSkill = "Summon Reaper", includeTransfigured = true },
	{ var = "summonReaperConsumeRecently", type = "check", label = "최근에 사신이 소모되었나요?", ifSkill = "Summon Reaper", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "ReaperConsumeMinionForBuff" })
	end },
	{ label = "피의 갈증:", ifSkill = "Thirst for Blood" },
	{ var = "nearbyBleedingEnemies", type = "count", label = "주변 출혈 중인 적 수:", ifSkill = "Thirst for Blood", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyBleedingEnemies", "BASE", val, "Config" )
	end },
	{ label = "회오리 사격:", ifSkill = "Tornado Shot" },
	{ var = "tornadoShotSecondaryHitChance", type = "count", label = "두 번째 투사체 적중 확률 %:", tooltip = "Override to the percent chance for the secondary projectiles to hit, default of 60% or 80% with helm enchant. (20% per secondary projectile)", ifSkill = "Tornado Shot", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "tornadoShotSecondaryHitChance", value = val }, "Config", { type = "SkillName", skillName = "Tornado Shot" })
	end },
	{ label = "독성 비:", ifSkill = "Toxic Rain", includeTransfigured = true },
	{ var = "toxicRainPodOverlap", type = "count", label = "겹치는 포드 수:", tooltip = "Maximum is limited by the number of Projectiles.", ifSkill = "Toxic Rain", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "podOverlapMultiplier", value = val }, "Config", { type = "SkillName", skillName = "Toxic Rain", includeTransfigured = true })
	end },
	{ label = "외상:", ifFlag = "HasTrauma" },
	{ var = "traumaStacks", type = "count", label = "외상 중첩 수:", ifFlag = "HasTrauma", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:TraumaStacks", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ label = "삼위일체 보조:", ifSkill = "Trinity" },
	{ var = "configResonanceCount", type = "count", label = "최저 공명 수:", ifSkill = "Trinity", tooltip = "Sets the amount of resonance on the lowest element.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ResonanceCount", "BASE", m_max(m_min(val, 50), 0), "Config")
	end },
	{ label = "경첩 해제:", ifSkill = "Unhinge" },
	{ var = "conditionInsane", type = "check", label = "광기 상태인가요?", ifCond = "Insane", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Insane", "FLAG", true, "Config")
	end },
	{ label = "경계 타격:", ifSkill = "Vigilant Strike" },
	{ var = "VigilantStrikeBypassCD", type = "check", label = "재사용 대기시간 무시?", ifSkill = "Vigilant Strike", defaultState = true, apply = function(val, modList, enemyModList)
		modList:NewMod("CooldownRecovery", "OVERRIDE", 0, "Config", { type = "SkillName", skillName = "Vigilant Strike" })
	end },
	{ label = "볼택식 폭발:", ifSkill = "Voltaxic Burst" },
	{ var = "voltaxicBurstSpellsQueued", type = "count", label = "현재 대기 중인 시전 수:", ifSkill = "Voltaxic Burst", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:VoltaxicWaitingStages", "BASE", val, "Config")
	end },
	{ label = "소용돌이:", ifSkill = "Vortex of Projection" },
	{ var = "vortexCastOnFrostbolt", type = "check", label = "얼음 화살에 시전?", ifSkill = "Vortex of Projection", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastOnFrostbolt", "FLAG", true, "Config", { type = "SkillName", skillName = "Vortex of Projection" })
	end },
	{ label = "함성 스킬:", ifFlag = "UsesWarcryPower" },
	{ var = "multiplierWarcryPower", type = "count", label = "함성 위력:", ifFlag = "UsesWarcryPower", tooltip = "Power determines how strong your Warcry buffs will be, and is based on the total strength of nearby enemies.\nPower is assumed to be 20 if your target is a Boss, but you can override it here if necessary.\n\tEach Normal enemy grants 1 Power\n\tEach Magic enemy grants 2 Power\n\tEach Rare enemy grants 10 Power\n\tEach Unique enemy grants 20 Power", apply = function(val, modList, enemyModList)
		modList:NewMod("WarcryPower", "OVERRIDE", val, "Config")
	end },
	{ label = "유죄 판결의 파도:", ifSkill = "Wave of Conviction" },
	{ var = "waveOfConvictionExposureType", type = "list", label = "노출 유형:", ifSkill = "Wave of Conviction", list = {{val=0,label="없음"},{val="Fire",label="^xB97123화염"},{val="Cold",label="^x3F6DB3냉기"},{val="Lightning",label="^xADAA47번개"}}, apply = function(val, modList, enemyModList)
		if val == "Fire" then
			modList:NewMod("Condition:WaveOfConvictionFireExposureActive", "FLAG", true, "Config")
		elseif val == "Cold" then
			modList:NewMod("Condition:WaveOfConvictionColdExposureActive", "FLAG", true, "Config")
		elseif val == "Lightning" then
			modList:NewMod("Condition:WaveOfConvictionLightningExposureActive", "FLAG", true, "Config")
		end
	end },
	{ var = "multiplierWoCExpiredDuration", type = "count", label = "유죄 판결의 파도 지속시간 경과 %:", ifMod = "WaveOfConvictionDurationDotMulti", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:WoCDurationExpired", "BASE", m_min(val, 100), "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "absolutionSkillDamageCountedOnce", type = "check", label = "사면: 스킬 피해 한 번만 계산", ifSkill = "Absolution", includeTransfigured = true, tooltip = "Your Absolution Skill Damage will not be scaled with Count setting.\nBy default it multiplies both minion count and skill hit count which leads to incorrect\nTotal DPS calculation since Absolution cannot inherently shotgun.\nDo not enable if you use Spell Totem support, Spell Cascade support or similar supports", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AbsolutionSkillDamageCountedOnce", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "dominatingBlowSkillDamageCountedOnce", type = "check", label = "지배의 강타: 스킬 피해 한 번만 계산", ifSkill = "Dominating Blow", includeTransfigured = true, tooltip = "Your Dominating Blow Skill Damage will not be scaled with Count setting.\nBy default it multiplies both minion count and skill hit count which leads to incorrect\nTotal DPS calculation since Dominating Blow cannot inherently shotgun.\nDo not enable if you use Spell Totem support, Spell Cascade support or similar supports", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:DominatingBlowSkillDamageCountedOnce", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ label = "용암 방패:", ifSkill = "Molten Shell" },
	{ var = "MoltenShellDamageMitigated", type = "count", label = "경감된 피해:", tooltip = "Molten Shell reflects damage to the enemy,\nbased on the amount of damage it has mitigated.", ifSkill = "Molten Shell", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "MoltenShellDamageMitigated", value = val }, "Config", { type = "SkillName", skillName = "Molten Shell" })
	end },
	{ label = "바알 용암 방패:", ifSkill = "Vaal Molten Shell" },
	{ var = "VaalMoltenShellDamageMitigated", type = "count", label = "경감된 피해:", tooltip = "Vaal Molten Shell reflects damage to the enemy,\nbased on the amount of damage it has mitigated in the last second.", ifSkill = "Vaal Molten Shell", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "VaalMoltenShellDamageMitigated", value = val }, "Config", { type = "SkillName", skillName = "Molten Shell" })
	end },
	{ label = "다중 범위 스킬:", ifSkill = { "Seismic Trap", "Lightning Spire Trap", "Explosive Trap", "Molten Strike" }, includeTransfigured = true },
	{ var = "enemySizePreset", type = "list", label = "적 크기 프리셋:", ifSkill = { "Seismic Trap", "Lightning Spire Trap", "Explosive Trap", "Molten Strike" }, includeTransfigured = true, defaultIndex = 2, tooltip = [[
Configure the radius of an enemy hitbox which is used in calculating some area multi-hitting (shotgunning) effects.

Small sets the radius to 2.
	Most monsters and the players' character are this size.
Medium sets the radius to 3.
	This is the size of most humanoid bosses (i.e. The Maven; The Shaper; Izaro)
Large sets the radius to 5.
	This is the size of some larger bosses (i.e. King Kaom; Vaal Oversoul)
Huge sets the radius to 11.
	This is the size of some of the largest bosses (i.e. Nucleus of the Maven; Tsoagoth, The Brine King)]], list = {{val="Small",label="소형"},{val="Medium",label="중형"},{val="Large",label="대형"},{val="Huge",label="초대형"}}, apply = function(val, modList, enemyModList, build)
		if val == "Small" then
			build.configTab.varControls['enemyRadius']:SetPlaceholder(2, false)
			modList:NewMod("EnemyRadius", "BASE", 2, "Config")
		elseif val == "Medium" then
			build.configTab.varControls['enemyRadius']:SetPlaceholder(3, false)
			modList:NewMod("EnemyRadius", "BASE", 3, "Config")
		elseif val == "Large" then
			build.configTab.varControls['enemyRadius']:SetPlaceholder(5, false)
			modList:NewMod("EnemyRadius", "BASE", 5, "Config")
		elseif val == "Huge" then
			build.configTab.varControls['enemyRadius']:SetPlaceholder(11, false)
			modList:NewMod("EnemyRadius", "BASE", 11, "Config")
		end
	end },
	{ var = "enemyRadius", type = "integer", label = "적 반경:", ifSkill = { "Seismic Trap", "Lightning Spire Trap", "Explosive Trap", "Molten Strike" }, includeTransfigured = true, tooltip = "Configure the radius of an enemy hitbox to calculate some area overlapping (shotgunning) effects.", apply = function(val, modList, enemyModList)
		modList:NewMod("EnemyRadius", "OVERRIDE", m_max(val, 1), "Config")
	end },
	{ var = "TotalSpectreLife", type = "integer", label = "환영 총 생명력:", ifMod = "takenFromSpectresBeforeYou", ifSkill = "Raise Spectre", includeTransfigured = true, tooltip = "The total life of your Spectres that can be taken before yours (used by jinxed juju)", apply = function(val, modList, enemyModList)
		modList:NewMod("TotalSpectreLife", "BASE", val, "Config")
	end },
	{ var = "TotalTotemLife", type = "integer", label = "토템 총 생명력:", ifOption = "conditionHaveTotem", ifMod = "takenFromTotemsBeforeYou", tooltip = "The total life of your Totems (excluding Vaal Rejuvenation Totem) that can be taken before yours (used by totem mastery)", apply = function(val, modList, enemyModList)
		modList:NewMod("TotalTotemLife", "BASE", val, "Config")
	end },
	{ var = "TotalRadianceSentinelLife", type = "integer", label = "광휘의 파수꾼 총 생명력", ifMod = "takenFromRadianceSentinelBeforeYou", apply = function(val, modList, enemyModList)
		modList:NewMod("TotalRadianceSentinelLife", "BASE", val, "Config")
	end },
	{ var = "TotalVoidSpawnLife", type = "integer", label = "공허 생성체 총 생명력", ifMod = "takenFromVoidSpawnBeforeYou", apply = function(val, modList, enemyModList)
		modList:NewMod("TotalVoidSpawnLife", "BASE", val, "Config")
	end },
	{ var = "TotalVaalRejuvenationTotemLife", type = "integer", label = "바알 회춘 토템 총 생명력:", ifSkill = { "Vaal Rejuvenation Totem" }, ifMod = "takenFromVaalRejuvenationTotemsBeforeYou", tooltip = "The total life of your Vaal Rejuvenation Totems that can be taken before yours", apply = function(val, modList, enemyModList)
		modList:NewMod("TotalVaalRejuvenationTotemLife", "BASE", val, "Config")
	end },
	{ label = "^xAF6025공포의 균형 ^7저주 비활성화:", ifCond = { "SelfCastConductivity", "SelfCastDespair", "SelfCastElementalWeakness", "SelfCastEnfeeble", "SelfCastFlammability", "SelfCastFrostbite", "SelfCastPunishment", "SelfCastTemporalChains", "SelfCastVulnerability" } },
	{ var = "balanceOfTerrorSelfCastConductivity", type = "check", label = "전도성 자기 자신만", ifSkill = "Conductivity", ifCond = "SelfCastConductivity", tooltip = "Counts Conductivity as self-cast for Balance of Terror without applying it to enemies." },
	{ var = "balanceOfTerrorSelfCastDespair", type = "check", label = "절망 자기 자신만", ifSkill = "Despair", ifCond = "SelfCastDespair", tooltip = "Counts Despair as self-cast for Balance of Terror without applying it to enemies." },
	{ var = "balanceOfTerrorSelfCastElementalWeakness", type = "check", label = "원소 약화 자기 자신만", ifSkill = "Elemental Weakness", ifCond = "SelfCastElementalWeakness", tooltip = "Counts Elemental Weakness as self-cast for Balance of Terror without applying it to enemies." },
	{ var = "balanceOfTerrorSelfCastEnfeeble", type = "check", label = "허약화 자기 자신만", ifSkill = "Enfeeble", ifCond = "SelfCastEnfeeble", tooltip = "Counts Enfeeble as self-cast for Balance of Terror without applying it to enemies." },
	{ var = "balanceOfTerrorSelfCastFlammability", type = "check", label = "인화성 자기 자신만", ifSkill = "Flammability", ifCond = "SelfCastFlammability", tooltip = "Counts Flammability as self-cast for Balance of Terror without applying it to enemies." },
	{ var = "balanceOfTerrorSelfCastFrostbite", type = "check", label = "동상 자기 자신만", ifSkill = "Frostbite", ifCond = "SelfCastFrostbite", tooltip = "Counts Frostbite as self-cast for Balance of Terror without applying it to enemies." },
	{ var = "balanceOfTerrorSelfCastPunishment", type = "check", label = "응징 자기 자신만", ifSkill = "Punishment", ifCond = "SelfCastPunishment", tooltip = "Counts Punishment as self-cast for Balance of Terror without applying it to enemies." },
	{ var = "balanceOfTerrorSelfCastTemporalChains", type = "check", label = "시간의 사슬 자기 자신만", ifSkill = "Temporal Chains", ifCond = "SelfCastTemporalChains", tooltip = "Counts Temporal Chains as self-cast for Balance of Terror without applying it to enemies." },
	{ var = "balanceOfTerrorSelfCastVulnerability", type = "check", label = "취약성 자기 자신만", ifSkill = "Vulnerability", ifCond = "SelfCastVulnerability", tooltip = "Counts Vulnerability as self-cast for Balance of Terror without applying it to enemies." },
	-- Section: Map modifiers/curses
	{ section = "지도 속성 부여 및 플레이어 디버프", col = 2 },
	{ var = "multiplierSextant", type = "count", label = "해당 지역에 영향을 주는 육분의 수", ifMult = "Sextant", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:Sextant", "BASE", m_min(val, 5), "Config")
	end },
	{ var = "multiplierMapModEffect", type = "count", label = "지도 속성 부여 효과 증가 %" },
	{ var = "multiplierMapModTier", type = "list", label = "지도 등급", list = { {val = "HIGH", label = "빨강"}, {val = "MED", label = "노랑"}, {val = "LOW", label = "흰색"} } },
	{ label = "지도 접두어 속성 부여:" },
	{ var = "MapPrefix1", type = "list", label = "접두어", tooltipFunc = mapAffixTooltip, list = data.mapMods.Prefix, apply = mapAffixDropDownFunction },
	{ var = "MapPrefix2", type = "list", label = "접두어", tooltipFunc = mapAffixTooltip, list = data.mapMods.Prefix, apply = mapAffixDropDownFunction },
	{ var = "MapPrefix3", type = "list", label = "접두어", tooltipFunc = mapAffixTooltip, list = data.mapMods.Prefix, apply = mapAffixDropDownFunction },
	{ var = "MapPrefix4", type = "list", label = "접두어", tooltipFunc = mapAffixTooltip, list = data.mapMods.Prefix, apply = mapAffixDropDownFunction },
	{ label = "지도 접미어 속성 부여:" },
	{ var = "MapSuffix1", type = "list", label = "접미어", tooltipFunc = mapAffixTooltip, list = data.mapMods.Suffix, apply = mapAffixDropDownFunction },
	{ var = "MapSuffix2", type = "list", label = "접미어", tooltipFunc = mapAffixTooltip, list = data.mapMods.Suffix, apply = mapAffixDropDownFunction },
	{ var = "MapSuffix3", type = "list", label = "접미어", tooltipFunc = mapAffixTooltip, list = data.mapMods.Suffix, apply = mapAffixDropDownFunction },
	{ var = "MapSuffix4", type = "list", label = "접미어", tooltipFunc = mapAffixTooltip, list = data.mapMods.Suffix, apply = mapAffixDropDownFunction },
	{ label = "고유 지도 속성 부여:" },
	{ var = "PvpScaling", type = "check", label = "PvP 피해 배율 적용 중", tooltip = "'Hall of Grandmasters'", apply = function(val, modList, enemyModList)
		modList:NewMod("HasPvpScaling", "FLAG", true, "Config")
	end },
	{ label = "플레이어에 걸린 저주:" },
	{ var = "playerCursedWithAssassinsMark", type = "count", label = "암살자의 표식:", tooltip = "Sets the level of Assassin's Mark to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "AssassinsMark", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithConductivity", type = "count", label = "전도성:", tooltip = "Sets the level of Conductivity to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Conductivity", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithDespair", type = "count", label = "절망:", tooltip = "Sets the level of Despair to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Despair", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithElementalWeakness", type = "count", label = "원소 약화:", tooltip = "Sets the level of Elemental Weakness to apply to the player.\nIn mid tier maps, 'of Elemental Weakness' applies level 10.\nIn high tier maps, 'of Elemental Weakness' applies level 15.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "ElementalWeakness", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithEnfeeble", type = "count", label = "허약화:", tooltip = "Sets the level of Enfeeble to apply to the player.\nIn mid tier maps, 'of Enfeeblement' applies level 10.\nIn high tier maps, 'of Enfeeblement' applies level 15.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Enfeeble", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithFlammability", type = "count", label = "인화성:", tooltip = "Sets the level of Flammability to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Flammability", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithFrostbite", type = "count", label = "동상:", tooltip = "Sets the level of Frostbite to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Frostbite", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithPoachersMark", type = "count", label = "밀렵꾼의 표식:", tooltip = "Sets the level of Poacher's Mark to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "PoachersMark", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithProjectileWeakness", type = "count", label = "투사체 약화:", tooltip = "Sets the level of Projectile Weakness to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "ProjectileWeakness", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithPunishment", type = "count", label = "응징:", tooltip = "Sets the level of Punishment to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Punishment", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithTemporalChains", type = "count", label = "시간의 사슬:", tooltip = "Sets the level of Temporal Chains to apply to the player.\nIn mid tier maps, 'of Temporal Chains' applies level 10.\nIn high tier maps, 'of Temporal Chains' applies level 15.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "TemporalChains", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithVulnerability", type = "count", label = "취약성:", tooltip = "Sets the level of Vulnerability to apply to the player.\nIn mid tier maps, 'of Vulnerability' applies level 10.\nIn high tier maps, 'of Vulnerability' applies level 15.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Vulnerability", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithWarlordsMark", type = "count", label = "전쟁군주의 표식:", tooltip = "Sets the level of Warlord's Mark to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "WarlordsMark", level = val, applyToPlayer = true })
	end },

	-- Section: Combat options
	{ section = "전투", col = 1 },
	{ var = "usePowerCharges", type = "check", label = "권능 충전을 사용하나요?", apply = function(val, modList, enemyModList)
		modList:NewMod("UsePowerCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overridePowerCharges", type = "count", label = "권능 충전 수 (최대가 아닌 경우):", ifOption = "usePowerCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("PowerCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useFrenzyCharges", type = "check", label = "격분 충전을 사용하나요?", apply = function(val, modList, enemyModList)
		modList:NewMod("UseFrenzyCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideFrenzyCharges", type = "count", label = "격분 충전 수 (최대가 아닌 경우):", ifOption = "useFrenzyCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("FrenzyCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useEnduranceCharges", type = "check", label = "인내 충전을 사용하나요?", apply = function(val, modList, enemyModList)
		modList:NewMod("UseEnduranceCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideEnduranceCharges", type = "count", label = "인내 충전 수 (최대가 아닌 경우):", ifOption = "useEnduranceCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("EnduranceCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useSiphoningCharges", type = "check", label = "흡수 충전을 사용하나요?", ifMult = "SiphoningCharge", apply = function(val, modList, enemyModList)
		modList:NewMod("UseSiphoningCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideSiphoningCharges", type = "count", label = "흡수 충전 수 (최대가 아닌 경우):", ifOption = "useSiphoningCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("SiphoningCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useChallengerCharges", type = "check", label = "도전자 충전을 사용하나요?", ifMult = "ChallengerCharge", apply = function(val, modList, enemyModList)
		modList:NewMod("UseChallengerCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideChallengerCharges", type = "count", label = "도전자 충전 수 (최대가 아닌 경우):", ifOption = "useChallengerCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("ChallengerCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useBlitzCharges", type = "check", label = "전격 충전을 사용하나요?", ifMult = "BlitzCharge", apply = function(val, modList, enemyModList)
		modList:NewMod("UseBlitzCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideBlitzCharges", type = "count", label = "전격 충전 수 (최대가 아닌 경우):", ifOption = "useBlitzCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("BlitzCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierGaleForce", type = "count", label = "돌풍의 힘 수:", ifFlag = "Condition:CanGainGaleForce", tooltip = "Base maximum Gale Force is 10.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:GaleForce", "BASE", val, "Config", { type = "IgnoreCond" }, { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanGainGaleForce" })
	end },
	{ var = "overrideInspirationCharges", type = "countAllowZero", label = "영감 충전 수 (최대가 아닌 경우):", ifMult = "InspirationCharge", apply = function(val, modList, enemyModList)
		modList:NewMod("InspirationCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useGhostShrouds", legacy = true, type = "check", label = "유령 장막을 사용하나요?", ifMult = "GhostShroud", apply = function(val, modList, enemyModList)
		modList:NewMod("UseGhostShrouds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideGhostShrouds", type = "count", label = "유령 장막 수 (최대가 아닌 경우):", ifOption = "useGhostShrouds", apply = function(val, modList, enemyModList)
		modList:NewMod("GhostShrouds", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "waitForMaxSeals", type = "check", label = "최대 해방 인장을 기다리나요?", ifFlag = "HasSeals", apply = function(val, modList, enemyModList)
		modList:NewMod("UseMaxUnleash", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "repeatMode", type = "list", label = "반복 모드:", ifCond = "alwaysFinalRepeat", list = {
		{val="NONE",label="없음"},
		{val="AVERAGE",label="평균"},
		{val="FINAL",label="마지막만"},
		{val="FINAL_DPS",label="마지막 (모든 적중이 마지막 사용)"}
	}, defaultIndex = 2, apply = function(val, modList, enemyModList)
		if val == "AVERAGE" then
			modList:NewMod("Condition:averageRepeat", "FLAG", true, "Config")
			modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:averageRepeat", "FLAG", true, "Config") })
		elseif val == "FINAL" or val == "FINAL_DPS" then
			modList:NewMod("Condition:alwaysFinalRepeat", "FLAG", true, "Config")
			modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:alwaysFinalRepeat", "FLAG", true, "Config") })
		end
	end },
	{ var = "ruthlessSupportMode", type = "list", label = "무자비 보조 모드:", ifSkill = "Ruthless", tooltip = "Controls how the hit/ailment effect of Ruthless Support is calculated:\n\tAverage: damage is based on the average application\n\tMax Effect: damage is based on maximum effect", list = {{val="AVERAGE",label="평균"},{val="MAX",label="최대 효과"}} },
	{ var = "ChanceToIgnoreEnemyPhysicalDamageReductionMode", type = "list", label = "물리 피해 감소 무시 확률 모드:", ifMod = "ChanceToIgnoreEnemyPhysicalDamageReduction", tooltip = "Controls how the chance on hit to ignore enemy physical damage reduction is calculated:\n\tMinimum: never ignores unless chance is at least 100%\n\tAverage: damage is based on the average application\n\tMax Effect: always ignores if you have any chance", list = {{val="MIN",label="최소"},{val="AVERAGE",label="평균"},{val="MAX",label="최대 효과"}}, defaultIndex = 2 },
	{ var = "overrideBloodCharges", type = "countAllowZero", label = "핏빛 충전 수 (최대가 아닌 경우):", ifMult = "BloodCharge", apply = function(val, modList, enemyModList)
		modList:NewMod("BloodCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideSpiritCharges", type = "countAllowZero", label = "영혼 충전 수:", ifMult = "SpiritCharge", apply = function(val, modList, enemyModList)
		modList:NewMod("SpiritCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "minionsUsePowerCharges", type = "check", label = "소환수가 권능 충전을 사용하나요?", ifFlag = "haveMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("UsePowerCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "minionsUseFrenzyCharges", type = "check", label = "소환수가 격분 충전을 사용하나요?", ifFlag = "haveMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("UseFrenzyCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "minionsUseEnduranceCharges", type = "check", label = "소환수가 인내 충전을 사용하나요?", ifFlag = "haveMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("UseEnduranceCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "minionsOverridePowerCharges", type = "count", label = "권능 충전 수 (최대가 아닌 경우):", ifFlag = "haveMinion", ifOption = "minionsUsePowerCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("PowerCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "minionsOverrideFrenzyCharges", type = "count", label = "격분 충전 수 (최대가 아닌 경우):", ifFlag = "haveMinion", ifOption = "minionsUseFrenzyCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("FrenzyCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "minionsOverrideEnduranceCharges", type = "count", label = "인내 충전 수 (최대가 아닌 경우):", ifFlag = "haveMinion", ifOption = "minionsUseEnduranceCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("EnduranceCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "multiplierRampage", type = "count", label = "광란 처치 수:", ifFlag = "Condition:Rampage", tooltip = "Rampage grants the following, up to 1000 stacks:\n\t1% increased Movement Speed per 20 Rampage\n\t2% increased Damage per 20 Rampage\nYou lose Rampage if you do not get a Kill within 5 seconds.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:Rampage", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierSoulEater", type = "count", label = "영혼 포식자 중첩 수:", ifFlag = "Condition:CanHaveSoulEater", tooltip = "Soul Eater grants the following, up to a base of 45 stacks:\n\t5% increased Attack Speed\n\t5% increased Cast Speed\n\t1% increased character size per stack.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SoulEaterStack", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionFocused", type = "check", label = "집중 상태인가요?", ifCond = "Focused", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Focused", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffLifetap", type = "check", label = "생명력 전환 상태인가요?", ifCond = "Lifetap", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Lifetap", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("FlaskLifeRecovery", "INC", 20, "Lifetap")
	end },
	{ var = "buffOnslaught", type = "check", label = "맹공 상태인가요?", tooltip = "In addition to allowing any 'while you have Onslaught' modifiers to apply,\nthis will enable the Onslaught buff itself. (Grants 20% increased Attack, Cast, and Movement Speed)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Onslaught", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffArcaneSurge", type = "check", label = "비전 쇄도 상태인가요?", tooltip = "In addition to allowing any 'while you have Arcane Surge' modifiers to apply,\nthis will enable the Arcane Surge buff itself. (Grants 20% increased cast speed and 30% increased Mana Regeneration rate)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ArcaneSurge", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "minionBuffOnslaught", type = "check", label = "소환수가 맹공 상태인가요?", ifFlag = "haveMinion", tooltip = "In addition to allowing any 'while your minions have Onslaught' modifiers to apply,\nthis will enable the Onslaught buff itself. (Grants 20% increased Attack, Cast, and Movement Speed)", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:Onslaught", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) })
	end },
	{ var = "buffUnholyMight", type = "check", label = "사악한 힘 상태인가요?", tooltip = "This will enable the Unholy Might buff.\n(Grants 100% of Physical Damage converted to ^xD02090Chaos ^7Damage)\n(25% chance to apply Wither on Hit)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UnholyMight", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:CanWither", "FLAG", true, "Unholy Might", { type = "Condition", var = "Combat" })
	end },
	{ var = "minionbuffUnholyMight", type = "check", label = "소환수가 사악한 힘 상태인가요?", ifFlag = "haveMinion", tooltip = "This will enable the Unholy Might buff on your minions.\n(Grants 100% of Physical Damage converted to ^xD02090Chaos ^7Damage)\n(25% chance to apply Wither on Hit)", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:UnholyMight", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) })
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:CanWither", "FLAG", true, "Unholy Might", { type = "Condition", var = "Combat" }) })
	end },
	{ var = "buffChaoticMight", type = "check", label = "혼돈의 힘 상태인가요?", tooltip = "This will enable the Chaotic Might buff.\n(Grants 30% of Physical Damage as Extra ^xD02090Chaos ^7Damage)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ChaoticMight", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffSacrificialZeal", type = "check", label = "희생적 열정 상태인가요?", ifFlag = "SacrificialZeal", tooltip = "This will enable the Sacrificial Zeal buff.\n(Grants 25% of the skill's mana cost as Physical Damage and causes you to take physical damage over time equal to a percentage of the skill's mana cost.)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SacrificialZeal", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "minionbuffChaoticMight", type = "check", label = "소환수가 혼돈의 힘 상태인가요?", ifFlag = "haveMinion", tooltip = "This will enable the Chaotic Might buff on your minions.\n(Grants 30% of Physical Damage as Extra ^xD02090Chaos ^7Damage)", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:ChaoticMight", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) })
	end },
	{ var = "buffPhasing", type = "check", label = "위상 상태인가요?", ifCond = "Phasing", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Phasing", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffFortification", type = "check", label = "방어 상승 상태인가요?", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Fortified", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideFortification", type = "count", label = "방어 상승 중첩 수 (최대가 아닌 경우):", ifFlag = "Condition:Fortified", tooltip = "You have 1% less damage taken from hits per stack of fortification:\nHas a default cap of 20 stacks.", apply = function(val, modList, enemyModList)
		modList:NewMod("FortificationStacks", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffTailwind", type = "check", label = "순풍 상태인가요?", tooltip = "In addition to allowing any 'while you have Tailwind' modifiers to apply,\nthis will enable the Tailwind buff itself. (Grants 8% increased Action Speed)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Tailwind", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffAdrenaline", type = "check", label = "아드레날린 상태인가요?", tooltip = "This will enable the Adrenaline buff, which grants:\n\t100% increased Damage\n\t25% increased Attack, Cast and Movement Speed\n\t10% additional Physical Damage Reduction", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Adrenaline", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionChangedStanceLastSecond", type = "check", label = "지난 1초간 자세를 변경했나요?", ifCond = "StanceChangeLastSecond", tooltip = "'Changing Stance' occurs by activating a Stance skill while it's toggled on", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StanceChangeLastSecond", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffAlchemistsGenius", type = "check", label = "연금술사의 천재성 상태인가요?", ifFlag = "Condition:CanHaveAlchemistGenius", tooltip = "This will enable the Alchemist's Genius buff:\n20% increased Flask Charges gained\n10% increased effect of Flasks", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AlchemistsGenius", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanHaveAlchemistGenius" })
	end },
	{ var = "buffVaalArcLuckyHits", type = "check", label = "바알 전기불꽃의 행운 버프가 있나요?", ifFlag = "Condition:CanBeLucky",  tooltip = "Causes Damage with Arc Hits to be rolled twice, and the maximum roll used.", apply = function(val, modList, enemyModList)
		modList:NewMod("LuckyHits", "FLAG", true, "Config", { type = "Condition", varList = { "Combat", "CanBeLucky" } }, { type = "SkillName", skillName = "Arc", includeTransfigured = true })
	end },
	{ var = "buffElusive", type = "check", label = "은밀 상태인가요?", ifFlag = "Condition:CanBeElusive", tooltip = "In addition to allowing any 'while Elusive' modifiers to apply,\nthis will enable the Elusive buff itself:\n\t15% Chance to Avoid all Damage from Hits\n\t30% increased Movement Speed\nThe effect of Elusive decays over time.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Elusive", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanBeElusive" })
		modList:NewMod("Elusive", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanBeElusive" })
	end },
	{ var = "overrideBuffElusive", type = "count", label = "은밀 효과 (평균이 아닌 경우):", ifOption = "buffElusive", tooltip = "If you have a guaranteed source of Elusive, the strongest one will apply. \nYou can change this to see various buff values", apply = function(val, modList, enemyModList)
		modList:NewMod("ElusiveEffect", "OVERRIDE", val, "Config", {type = "GlobalEffect", effectType = "Buff" })
	end },
	{ var = "buffDivinity", type = "check", label = "신성 상태인가요?", ifCond = "Divinity", tooltip = "This will enable the Divinity buff, which grants:\n\t75% more Elemental Damage\n\t25% less Elemental Damage taken", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Divinity", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierDefiance", type = "count", label = "반항:", ifMult = "Defiance", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:Defiance", "BASE", m_min(val, 10), "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierRage", type = "count", label = "^xFF9922분노:", ifFlag = "Condition:CanGainRage", tooltip = "Base Maximum ^xFF9922Rage ^7is 30, and inherently grants 1% More Attack Damage per 1 ^xFF9922Rage^7\nYou lose 10 ^xFF9922Rage ^7every second if you have not been Hit or gained ^xFF9922Rage ^7in the last 2 seconds.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:RageStack", "BASE", val, "Config", { type = "IgnoreCond" }, { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanGainRage" })
	end },
	{ var = "buffWildSavagery", type = "check", label = "야생의 잔인함 상태인가요?", ifFlag = "WildSavagery", tooltip = "From Oshabi's Bloodline, grants:\n\t100% increased Physical Damage\n\t10% increased Action Speed\n\tHits ignore Enemy Physical Damage Reduction\n\tCannot be Stunned", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:WildSavagery", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLeeching", type = "check", label = "흡수 중인가요?", ifCond = "Leeching", tooltip = "You will automatically be considered to be Leeching if you have '^xE05030Life ^7Leech effects are not removed at Full ^xE05030Life^7',\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Leeching", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLeechingLife", type = "check", label = "^xE05030생명력^7을 흡수 중인가요?", ifCond = "LeechingLife", implyCond = "Leeching", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LeechingLife", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Leeching", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLeechingEnergyShield", type = "check", label = "^x88FFFF에너지 보호막^7을 흡수 중인가요?", ifCond = "LeechingEnergyShield", implyCond = "Leeching", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LeechingEnergyShield", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Leeching", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLeechingMana", type = "check", label = "^x7070FF마나^7를 흡수 중인가요?", ifCond = "LeechingMana", implyCond = "Leeching", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LeechingMana", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Leeching", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "minionsConditionLeechingEnergyShield", type = "check", label = "소환수가 ^x88FFFF에너지 보호막^7을 흡수 중인가요?", ifMinionCond = "LeechingEnergyShield", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:LeechingEnergyShield", "FLAG", true, "Config") }, "Config")
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:Leeching", "FLAG", true, "Config") }, "Config")
	end },
	{ var = "conditionUsingFlask", type = "check", label = "플라스크가 활성화 중인가요?", ifCond = "UsingFlask", tooltip = "This is automatically enabled if you have a flask active,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsingFlask", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsingTincture", type = "check", label = "팅크처가 활성화 중인가요?", ifCond = "UsingTincture", tooltip = "This is automatically enabled if you have a tincture active,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsingTincture", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierManaBurnStacks", type = "count", label = "마나 연소 중첩:", tooltip = "Mana Burn Applies a 1% of mana degen per stack\nThis also applies Weeping Wounds if the Keystone is Allocated"},
	{ var = "conditionHaveTotem", type = "check", label = "토템을 소환했나요?", ifCond = "HaveTotem", tooltip = "You will automatically be considered to have a Totem if your main skill is a Totem,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HaveTotem", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSummonedTotemRecently", type = "check", label = "최근에 토템을 소환했나요?", ifCond = "SummonedTotemRecently", tooltip = "You will automatically be considered to have Summoned a Totem Recently if your main skill is a Totem,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SummonedTotemRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "TotemsSummoned", type = "count", label = "소환된 토템 수 (최대가 아닌 경우):", ifStat = "TotemsSummoned", ifFlag = "totem", implyCond = "HaveTotem", tooltip = "This also implies that you have a Totem summoned.\nThis will affect all 'per Summoned Totem' modifiers, even for non-Totem skills.", apply = function(val, modList, enemyModList)
		modList:NewMod("TotemsSummoned", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:HaveTotem", "FLAG", val >= 1, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSummonedGolemInPast8Sec", type = "check", label = "지난 8초간 골렘을 소환했나요?", ifCond = "SummonedGolemInPast8Sec", implyCond = "SummonedGolemInPast10Sec", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SummonedGolemInPast8Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSummonedGolemInPast10Sec", type = "check", label = "지난 10초간 골렘을 소환했나요?", ifCond = "SummonedGolemInPast10Sec", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SummonedGolemInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierNearbyAlly", type = "count", label = "주변 아군 수:", ifMult = "NearbyAlly", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyAlly", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierNearbyCorpse", type = "count", label = "주변 시체 수:", ifMult = "NearbyCorpse", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyCorpse", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierSummonedMinion", type = "count", label = "소환된 소환수 수:", ifMult = "SummonedMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SummonedMinion", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierNonVaalSummonedMinion", type = "count", label = "바알 스킬 외 소환된 소환수 수:", ifMult = "NonVaalSummonedMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NonVaalSummonedMinion", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnConsecratedGround", type = "check", label = "신성한 대지 위에 있나요?", tooltip = "In addition to allowing any 'while on Consecrated Ground' modifiers to apply,\nConsecrated Ground grants 5% ^xE05030Life ^7Regeneration to players and allies.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnConsecratedGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:OnConsecratedGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) })
	end },
	{ var = "conditionOnProfaneGround", type = "check", label = "불경한 대지 위에 있나요?", ifCond = "OnProfaneGround", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnProfaneGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "minionConditionOnProfaneGround", type = "check", label = "소환수가 불경한 대지 위에 있나요?", ifMinionCond = "OnProfaneGround", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:OnProfaneGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) })
	end },
	{ var = "conditionOnCausticGround", type = "check", label = "부식 대지 위에 있나요?", ifCond = "OnCausticGround", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnCausticGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnFungalGround", type = "check", label = "균사 대지 위에 있나요?", ifCond = { "OnFungalGround", "CreateFungalGround" }, tooltip = "Allies on your Fungal Ground gain +25% ^xD02090Chaos ^7Resistance.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnFungalGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnBurningGround", type = "check", label = "^xB97123불타는 ^7대지 위에 있나요?", ifCond = "OnBurningGround", implyCond = "Burning", tooltip = "This also implies that you are ^xB97123Burning.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnBurningGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Burning", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnChilledGround", type = "check", label = "^x3F6DB3냉각된 ^7대지 위에 있나요?", ifCond = "OnChilledGround", implyCond = "Chilled", tooltip = "This also implies that you are ^x3F6DB3Chilled.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnChilledGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnShockedGround", type = "check", label = "^xADAA47감전된 ^7대지 위에 있나요?", ifCond = "OnShockedGround", implyCond = "Shocked", tooltip = "This also implies that you are ^xADAA47Shocked.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnShockedGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlinded", type = "check", label = "실명 상태인가요?", ifCond = "Blinded", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Blinded", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBurning", type = "check", label = "^xB97123타고^7 있나요?", ifCond = "Burning", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Burning", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionIgnited", type = "check", label = "^xB97123점화^7 상태인가요?", ifCond = "Ignited", implyCond = "Burning", tooltip = "This also implies that you are ^xB97123Burning.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Ignited", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionScorched", type = "check", label = "^xB97123그을림^7 상태인가요?", ifCond = "Scorched", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Scorched", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionChilled", type = "check", label = "^x3F6DB3냉각^7 상태인가요?", ifCond = "Chilled", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionChilledEffect", type = "count", label = "^x3F6DB3냉각^7 효과:", ifOption = "conditionChilled", apply = function(val, modList, enemyModList)
		modList:NewMod("ChillVal", "OVERRIDE", val, "Chill", { type = "Condition", var = "Chilled" })
	end },
	{ var = "conditionFrozen", type = "check", label = "^x3F6DB3동결^7 상태인가요?", ifCond = "Frozen", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Frozen", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBrittle", type = "check", label = "^x3F6DB3균열^7 상태인가요?", ifCond = "Brittle", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Brittle", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionShocked", type = "check", label = "^xADAA47감전^7 상태인가요?", ifCond = "Shocked", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionPlayerShockEffect", type = "count", label = "^xADAA47감전^7 효과:", ifOption = "conditionShocked", apply = function(val, modList, enemyModList)
		modList:NewMod("ShockVal", "OVERRIDE", val, "Shock", { type = "Condition", var = "Shocked" })
	end },
	{ var = "conditionSapped", type = "check", label = "^xADAA47수액^7 상태인가요?", ifCond = "Sapped", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Sapped", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBleeding", type = "check", label = "출혈 상태인가요?", ifCond = "Bleeding", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Bleeding", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionPoisoned", type = "check", label = "중독 상태인가요?", ifCond = "Poisoned", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Poisoned", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCanBeCurseImmune", type = "check", label = "저주 면역인가요?", ifFlag = "Condition:CanBeCurseImmune", apply = function(val, modList, enemyModList)
		modList:NewMod("AvoidCurse", "BASE", 100, "Config", { type = "Condition", var = "Combat" }, { type = "GlobalEffect", effectType = "Global", unscalable = true })
	end },
	{ var = "multiplierPoisonOnSelf", type = "count", label = "자신에 대한 독 수:", ifMult = "PoisonStack", implyCond = "Poisoned", tooltip = "This also implies that you are Poisoned.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:PoisonStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierWitheredStackCountSelf", type = "countAllowZero", label = "자신에 대한 시들음 중첩 수:", ifFlag = "Condition:CanBeWithered", tooltip = "Withered applies 6% increased ^xD02090Chaos ^7Damage Taken to the self, up to 15 stacks.", defaultPlaceholderState = 15, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:WitheredStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierNearbyEnemies", type = "count", label = "주변 적 수:", ifMult = "NearbyEnemies", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyEnemies", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:OnlyOneNearbyEnemy", "FLAG", val == 1, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierNearbyRareOrUniqueEnemies", type = "countAllowZero", label = "주변 희귀 또는 고유 적 수:", ifMult = "NearbyRareOrUniqueEnemies", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyRareOrUniqueEnemies", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Multiplier:NearbyEnemies", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:AtMostOneNearbyRareOrUniqueEnemy", "FLAG", val <= 1, "Config", { type = "Condition", var = "Combat" })
		enemyModList:NewMod("Condition:NearbyRareOrUniqueEnemy", "FLAG", val >= 1, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitRecently", type = "check", label = "최근에 적중했나요?", ifCond = "HitRecently", tooltip = "You will automatically be considered to have Hit Recently if your main skill Hits and is self-cast,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitSpellRecently", type = "check", label = "최근에 주문으로 적중했나요?", ifCond = "HitSpellRecently", implyCond = "HitRecently", tooltip = "This also implies that you have Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitSpellRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:HitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCritRecently", type = "check", label = "최근에 치명타를 가했나요?", ifCond = "CritRecently", implyCond = "SkillCritRecently", tooltip = "This also implies that your Skills have Crit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:SkillCritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSkillCritRecently", type = "check", label = "최근에 스킬이 치명타를 가했나요?", ifCond = "SkillCritRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SkillCritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCritWithHeraldSkillRecently", type = "check", label = "최근에 전령 스킬이 치명타를 가했나요?", ifCond = "CritWithHeraldSkillRecently", implyCond = "SkillCritRecently", tooltip = "This also implies that your Skills have Crit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CritWithHeraldSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "LostNonVaalBuffRecently", type = "check", label = "최근에 바알이 아닌 방어 스킬 버프를 잃었나요?", ifCond = "LostNonVaalBuffRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LostNonVaalBuffRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionNonCritRecently", type = "check", label = "최근에 비치명타를 가했나요?", ifCond = "NonCritRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:NonCritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionChannelling", type = "check", label = "집중 유지 중인가요?", ifCond = "Channelling", tooltip = "You will automatically be considered to be Channeling if your main skill is a channelled skill,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Channelling", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierChannelling", type = "count", label = "집중 유지 시간(초):", ifMult = "ChannellingTime", implyCond = "Channelling", tooltip = "This also implies that you are channelling", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ChannellingTime", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Channelling", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitRecentlyWithWeapon", type = "check", label = "최근에 무기로 적중했나요?", ifCond = "HitRecentlyWithWeapon", tooltip = "This also implies that you have Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitRecentlyWithWeapon", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledRecently", type = "check", label = "최근에 처치했나요?", ifCond = "KilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierKilledRecently", type = "count", label = "최근 처치한 적 수:", ifMult = "EnemyKilledRecently", implyCond = "KilledRecently", tooltip = "This also implies that you have Killed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnemyKilledRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:KilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledLast3Seconds", type = "check", label = "지난 3초간 처치했나요?", ifCond = "KilledLast3Seconds", implyCond = "KilledRecently", tooltip = "This also implies that you have Killed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledLast3Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledPoisonedLast2Seconds", type = "check", label = "지난 2초간 중독된 적을 처치했나요?", ifCond = "KilledPoisonedLast2Seconds", implyCond = "KilledRecently", tooltip = "This also implies that you have Killed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledPoisonedLast2Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledTauntedEnemyRecently", type = "check", label = "최근에 도발된 적을 처치했나요?", ifCond = "KilledTauntedEnemyRecently", implyCondList = {"KilledRecently", "TauntedEnemyRecently" }, tooltip = "This also implies that you have killed and taunted recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledTauntedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTotemsNotSummonedInPastTwoSeconds", type = "check", label = "지난 2초간 토템을 소환하지 않았나요?", ifCond = "NoSummonedTotemsInPastTwoSeconds", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:NoSummonedTotemsInPastTwoSeconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTotemsKilledRecently", type = "check", label = "최근에 토템이 처치했나요?", ifCond = "TotemsKilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TotemsKilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTotemsHitRecently", type = "check", label = "최근에 토템이 적중했나요?", ifCond = "HitRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TotemsHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTotemsHitSpellRecently", type = "check", label = "최근에 토템이 주문으로 적중했나요?", ifCond = "TotemsHitSpellRecently", implyCond = "TotemsHitRecently", tooltip = "This also implies that you Totems have Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TotemsHitSpellRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:TotemsHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedBrandRecently", type = "check", label = "최근에 낙인 스킬을 사용했나요?", ifCond = "UsedBrandRecently",  apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedBrandRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierTotemsKilledRecently", type = "count", label = "최근 토템이 처치한 적 수:", ifMult = "EnemyKilledByTotemsRecently", implyCond = "TotemsKilledRecently", tooltip = "This also implies that your Totems have Killed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnemyKilledByTotemsRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:TotemsKilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionMinionsKilledRecently", type = "check", label = "최근에 소환수가 처치했나요?", ifCond = "MinionsKilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:MinionsKilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionMinionsDiedRecently", type = "check", label = "최근에 소환수가 죽었나요?", ifCond = "MinionsDiedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:MinionsDiedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierMinionsKilledRecently", type = "count", label = "최근 소환수가 처치한 적 수:", ifMult = "EnemyKilledByMinionsRecently", implyCond = "MinionsKilledRecently", tooltip = "This also implies that your Minions have Killed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnemyKilledByMinionsRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:MinionsKilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledAffectedByDoT", type = "check", label = "최근에 지속 피해를 받는 적을 처치했나요?", ifCond = "KilledAffectedByDotRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledAffectedByDotRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierShockedEnemyKilledRecently", type = "count", label = "최근 처치한 ^xADAA47감전 ^7상태 적 수:", ifMult = "ShockedEnemyKilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ShockedEnemyKilledRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierShockedNonShockedEnemyRecently", type = "count", label = "최근 ^xADAA47감전^7하지 않은 적을 ^xADAA47감전^7시킨 수:", ifMult = "ShockedNonShockedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ShockedNonShockedEnemyRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionFrozenEnemyRecently", type = "check", label = "최근에 적을 ^x3F6DB3동결^7시켰나요?", ifCond = "FrozenEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FrozenEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionChilledEnemyRecently", type = "check", label = "최근에 적을 ^x3F6DB3냉각^7시켰나요?", ifCond = "ChilledEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ChilledEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionShatteredEnemyRecently", type = "check", label = "최근에 적을 ^x3F6DB3산산조각^7 냈나요?", ifCond = "ShatteredEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ShatteredEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionIgnitedEnemyRecently", type = "check", label = "최근에 적을 ^xB97123점화^7시켰나요?", ifCond = "IgnitedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:IgnitedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierIgniteAppliedRecently", type = "count", label = "최근 부여한 ^xB97123점화 ^7수:", ifMult = "IgniteAppliedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:IgniteAppliedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionShockedEnemyRecently", type = "check", label = "최근에 적을 ^xADAA47감전^7시켰나요?", ifCond = "ShockedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ShockedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionStunnedEnemyRecently", type = "check", label = "최근에 적을 기절시켰나요?", ifCond = "StunnedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StunnedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionStunnedRecently", type = "check", label = "최근에 기절했나요?", ifCond = "StunnedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StunnedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierPoisonAppliedRecently", type = "count", label = "최근 적용한 독 수:", ifMult = "PoisonAppliedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:PoisonAppliedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierLifeSpentRecently", type = "count", label = "최근 소모한 ^xE05030생명력 ^7양:", ifMult = "LifeSpentRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:LifeSpentRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierManaSpentRecently", type = "count", label = "최근 소모한 ^x7070FF마나 ^7양:", ifMult = "ManaSpentRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ManaSpentRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionWardBrokenPast2Seconds", type = "check", label = "지난 2초간 ^xFFFF77수호^7가 깨졌나요?", ifCond = "WardBrokenPast2Seconds", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:WardBrokenPast2Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenHitRecently", type = "check", label = "최근에 피격당했나요?", ifCond = "BeenHitRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierBeenHitRecently", type = "count", label = "최근 피격 횟수:", ifMult = "BeenHitRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:BeenHitRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", 1 <= val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenHitByAttackRecently", type = "check", label = "최근에 공격에 피격당했나요?", ifCond = "BeenHitByAttackRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenHitByAttackRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenCritRecently", type = "check", label = "최근에 치명타를 당했나요?", ifCond = "BeenCritRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenCritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionConsumed12SteelShardsRecently", type = "check", label = "최근에 강철 파편 12개를 소모했나요?", ifCond = "Consumed12SteelShardsRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Consumed12SteelShardsRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionGainedPowerChargeRecently", type = "check", label = "최근에 권능 충전을 획득했나요?", ifCond = "GainedPowerChargeRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:GainedPowerChargeRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionGainedFrenzyChargeRecently", type = "check", label = "최근에 격분 충전을 획득했나요?", ifCond = "GainedFrenzyChargeRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:GainedFrenzyChargeRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenSavageHitRecently", type = "check", label = "최근에 격렬한 피격을 당했나요?", ifCond = "BeenSavageHitRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenSavageHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByFireDamageRecently", type = "check", label = "최근에 ^xB97123화염 ^7피해를 받았나요?", ifCond = "HitByFireDamageRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitByFireDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByColdDamageRecently", type = "check", label = "최근에 ^x3F6DB3냉기 ^7피해를 받았나요?", ifCond = "HitByColdDamageRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitByColdDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByLightningDamageRecently", type = "check", label = "최근에 ^xADAA47번개 ^7피해를 받았나요?", ifCond = "HitByLightningDamageRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitByLightningDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitBySpellDamageRecently", type = "check", label = "최근에 주문 피해를 받았나요?", ifCond = "HitBySpellDamageRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitBySpellDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTakenFireDamageFromEnemyHitRecently", type = "check", label = "최근에 적의 적중으로 ^xB97123화염 ^7피해를 받았나요?", ifCond = "TakenFireDamageFromEnemyHitRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TakenFireDamageFromEnemyHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedRecently", type = "check", label = "최근에 막기를 했나요?", ifCond = "BlockedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedAttackRecently", type = "check", label = "최근에 공격을 막았나요?", ifCond = "BlockedAttackRecently", implyCond = "BlockedRecently", tooltip = "This also implies that you have Blocked Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedAttackRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BlockedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedSpellRecently", type = "check", label = "최근에 주문을 막았나요?", ifCond = "BlockedSpellRecently", implyCond = "BlockedRecently", tooltip = "This also implies that you have Blocked Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedSpellRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BlockedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionEnergyShieldRechargeRecently", type = "check", label = "최근 ^x88FFFF에너지 보호막 ^7충전이 시작되었나요?", ifCond = "EnergyShieldRechargeRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:EnergyShieldRechargeRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionEnergyShieldRechargePastTwoSec", type = "check", label = "지난 2초간 ^x88FFFF에너지 보호막 ^7충전이 시작되었나요?", ifCond = "EnergyShieldRechargePastTwoSec", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:EnergyShieldRechargePastTwoSec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionStoppedTakingDamageOverTimeRecently", type = "check", label = "최근에 지속 피해를 받지 않게 되었나요?", ifCond = "StoppedTakingDamageOverTimeRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StoppedTakingDamageOverTimeRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionConvergence", type = "check", label = "수렴 상태인가요?", ifFlag = "Condition:CanGainConvergence", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Convergence", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanGainConvergence" })
	end },
	{ var = "buffPendulum", type = "list", label = "파괴의 추가 활성화 중인가요?", ifCond = "PendulumOfDestructionAreaOfEffect", list = {{val=0,label="없음"},{val="AREA",label="효과 범위"},{val="DAMAGE",label="원소 피해"}}, apply = function(val, modList, enemyModList)
		if val == "AREA" then
			modList:NewMod("Condition:PendulumOfDestructionAreaOfEffect", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		elseif val == "DAMAGE" then
			modList:NewMod("Condition:PendulumOfDestructionElementalDamage", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		end
	end },
	{ var = "buffConflux", type = "list", label = "합류 버프:", ifCond = "ChillingConflux", list = {{val=0,label="없음"},{val="CHILLING",label="^x3F6DB3냉각"},{val="SHOCKING",label="^xADAA47감전"},{val="IGNITING",label="^xB97123점화"},{val="ALL",label="^x3F6DB3냉각 ^7+ ^xADAA47감전 ^7+ ^xB97123점화"}}, apply = function(val, modList, enemyModList)
		if val == "CHILLING" or val == "ALL" then
			modList:NewMod("Condition:ChillingConflux", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		end
		if val == "SHOCKING" or val == "ALL" then
			modList:NewMod("Condition:ShockingConflux", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		end
		if val == "IGNITING" or val == "ALL" then
			modList:NewMod("Condition:IgnitingConflux", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		end
	end },
	{ var = "highestDamageType", type = "list", ifFlag = "ChecksHighestDamage", label = "최고 피해 유형 덮어쓰기:", tooltip = "Determines whether modifiers that depend on the highest damage type apply.", list = {{val="NONE",label="기본"},{val="Physical",label="물리"},{val="Lightning",label="번개"},{val="Cold",label="냉기"},{val="Fire",label="화염"},{val="Chaos",label="카오스"}}, apply = function(val, modList, enemyModList)
		if val ~= "NONE" then
			modList:NewMod("Condition:"..val.."IsHighestDamageType", "FLAG", true, "Config")
			modList:NewMod("IsHighestDamageTypeOVERRIDE", "FLAG", true, "Config")
		end
	end },
	{ var = "buffHeartstopper", type = "list", label = "심장 멈춤 모드:", ifCond = "HeartstopperHIT", list = {{val=0,label="없음"},{val="AVERAGE",label="평균"},{val="HIT",label="적중"},{val="DOT",label="지속 피해"}}, apply = function(val, modList, enemyModList)
		if val == "HIT" then
			modList:NewMod("Condition:HeartstopperHIT", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		elseif val == "DOT" then
			modList:NewMod("Condition:HeartstopperDOT", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		elseif val == "AVERAGE" then
			modList:NewMod("Condition:HeartstopperAVERAGE", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		end
	end },
	{ var = "buffBastionOfHope", type = "check", label = "희망의 보루가 활성화 중인가요?", ifCond = "BastionOfHopeActive", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BastionOfHopeActive", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffNgamahuFlamesAdvance", type = "check", label = "마그마 타격이 활성화 중인가요?", ifCond = "NgamahuFlamesAdvance", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:NgamahuFlamesAdvance", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffHerEmbrace", type = "check", label = "그녀의 품 안에 있나요?", ifCond = "HerEmbrace", tooltip = "This option is specific to Oni-Goroshi.", apply = function(val, modList, enemyModList)
		modList:NewMod("HerEmbrace", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanGainHerEmbrace" })
	end },
	{ var = "conditionChampionIntimidate", type = "check", label = "투사의 위협이 활성화 중인가요?", ifEnemyCond = "ChampionIntimidate", defaultState = true, apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:ChampionIntimidate", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedSkillRecently", type = "check", label = "최근에 스킬을 사용했나요?", ifCond = "UsedSkillRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierSkillUsedRecently", type = "count", label = "최근 사용한 스킬 수:", ifMult = "SkillUsedRecently", implyCond = "UsedSkillRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SkillUsedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionAttackedRecently", type = "check", label = "최근에 공격했나요?", ifCond = "AttackedRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.\nYou will automatically be considered to have Attacked Recently if your main skill is an attack,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AttackedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCastSpellRecently", type = "check", label = "최근에 주문을 시전했나요?", ifCond = "CastSpellRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.\nYou will automatically be considered to have Cast a Spell Recently if your main skill is a spell,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastSpellRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierNonInstantSpellCastRecently", type = "count", label = "최근 시전한 즉발이 아닌 주문 수:", ifMult = "NonInstantSpellCastRecently", implyCond = "CastSpellRecently", tooltip = "Only the number of different spells you cast count", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NonInstantSpellCastRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierAppliedAilmentsRecently", type = "count", label = "최근 적용한 상태 이상 수:", ifMult = "AppliedAilmentsRecently", tooltip = "Number of recently applied ailments", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:AppliedAilmentsRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLinkedRecently", type = "check", label = "최근에 연결했나요?", ifCond = "LinkedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LinkedRecently", "FLAG", true, "Config")
	end },
	{ var = "conditionStunnedWhileCastingRecently", type = "check", label = "최근에 시전 중 기절했나요?", ifCond = "StunnedWhileCastingRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StunnedWhileCastingRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCastLast1Seconds", type = "check", label = "지난 1초간 주문을 시전했나요?", ifCond = "CastLast1Seconds", implyCond = "CastSpellRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastLast1Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierCastLast8Seconds", type = "count", label = "지난 8초간 시전한 주문 수?", ifMult = "CastLast8Seconds", tooltip = "Only non-instant spells you cast count", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:CastLast8Seconds", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSuppressedRecently", type = "check", label = "최근에 억제했나요?", ifCond = "SuppressedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SuppressedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierHitsSuppressedRecently", type = "count", label = "최근 억제한 피격 수:", ifMult = "HitsSuppressedRecently", implyCond = "SuppressedRecently", tooltip = "This also implies that you have Suppressed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:HitsSuppressedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:SuppressedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedFireSkillRecently", type = "check", label = "최근에 ^xB97123화염 ^7스킬을 사용했나요?", ifCond = "UsedFireSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedFireSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedColdSkillRecently", type = "check", label = "최근에 ^x3F6DB3냉기 ^7스킬을 사용했나요?", ifCond = "UsedColdSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedColdSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedMinionSkillRecently", type = "check", label = "최근에 소환수 스킬을 사용했나요?", ifCond = "UsedMinionSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.\nYou will automatically be considered to have used a Minion skill Recently if your main skill is a Minion skill,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedMinionSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedTravelSkillRecently", type = "check", label = "최근에 이동 스킬을 사용했나요?", ifCond = "UsedTravelSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently..", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedTravelSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedMovementSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedDashRecently", type = "check", label = "최근에 질주를 시전했나요?", ifCond = "CastDashRecently", implyCondList = { "UsedTravelSkillRecently", "UsedMovementSkillRecently", "UsedSkillRecently"}, tooltip = "This also implies that you have used a Skill Recently..", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastDashRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedTravelSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedMovementSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedMovementSkillRecently", type = "check", label = "최근에 이동 스킬을 사용했나요?", ifCond = "UsedMovementSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.\nYou will automatically be considered to have used a Movement skill Recently if your main skill is a movement skill,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedMovementSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedVaalSkillRecently", type = "check", label = "최근에 바알 스킬을 사용했나요?", ifCond = "UsedVaalSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.\nYou will automatically be considered to have used a Vaal skill Recently if your main skill is a Vaal skill,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedVaalSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierUsedVaalSkillInPast8Seconds", type = "count", label = "지난 8초간 사용한 바알 스킬 수:", ifMult = "VaalSkillsUsedInPast8Seconds", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:VaalSkillsUsedInPast8Seconds", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSoulGainPrevention", type = "check", label = "영혼 획득 방지 상태인가요?", ifCond = "SoulGainPrevention", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SoulGainPrevention", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSacrificeMinion", type = "check", label = "공격 시 소환수 희생", ifCond = "SacrificeMinionOnAttack", ifFlag = "Condition:HaveDamageableMinion", defaultState = true, tooltip = "Each Attack is sacrificing a damage minion to grant you extra projectiles.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SacrificeMinionOnAttack", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedWarcryRecently", type = "check", label = "최근에 함성을 사용했나요?", {ifFlag = "warcry", ifCond = "UsedWarcryRecently"}, implyCondList = {"UsedWarcryInPast8Seconds", "UsedSkillRecently"}, tooltip = "This also implies that you have used a Skill Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedWarcryRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedWarcryInPast8Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedWarcryInPast8Seconds", type = "check", label = "지난 8초간 함성을 사용했나요?", ifCond = "UsedWarcryInPast8Seconds", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedWarcryInPast8Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierAffectedByWarcryBuffDuration", type = "count", label = "함성 버프의 영향을 받은 시간(초):", ifMult = "AffectedByWarcryBuffDuration", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:AffectedByWarcryBuffDuration", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "DetonatedMinesRecently", type = "check", label = "최근에 지뢰를 기폭했나요", ifCond = "DetonatedMinesRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:DetonatedMinesRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierMineDetonatedRecently", type = "count", label = "최근 기폭한 지뢰 수:", ifMult = "MineDetonatedRecently", implyCond = "DetonatedMinesRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:MineDetonatedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "minesPerThrow", type = "count", label = "투척당 지뢰 수:", ifFlag = "mine", tooltip = "This will override the number of Mines per throw", apply = function(val, modList, enemyModList)
		modList:NewMod("MineThrowCount", "OVERRIDE", val, "Config", {type = "Condition", var = "Combat"})
	end },
	{ var = "TriggeredTrapsRecently", type = "check", label = "최근에 덫을 발동시켰나요?", ifCond = "TriggeredTrapsRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TriggeredTrapsRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierTrapTriggeredRecently", type = "count", label = "최근 발동된 덫 수:", ifMult = "TrapTriggeredRecently", implyCond = "TriggeredTrapRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:TrapTriggeredRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionThrownTrapOrMineRecently", type = "check", label = "최근에 덫이나 지뢰를 투척했나요?", ifCond = "TrapOrMineThrownRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TrapOrMineThrownRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "trapsPerThrow", type = "count", label = "투척당 덫 수:", ifFlag = "trap", tooltip = "This will override the number of Traps per throw", apply = function(val, modList, enemyModList)
		modList:NewMod("TrapThrowCount", "OVERRIDE", val, "Config", {type = "Condition", var = "Combat"})
	end },
	{ var = "conditionCursedEnemyRecently", type = "check", label = "최근에 적에게 저주를 걸었나요?",  ifCond="CursedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CursedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionCastMarkRecently", type = "check", label = "최근에 표식 주문을 시전했나요?", ifCond = "CastMarkRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastMarkRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSpawnedCorpseRecently", type = "check", label = "최근에 시체를 생성했나요?", ifCond = "SpawnedCorpseRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SpawnedCorpseRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionConsumedCorpseRecently", type = "check", label = "최근에 시체를 소모했나요?", ifCond = "ConsumedCorpseRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ConsumedCorpseRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionConsumedCorpseInPast2Sec", type = "check", label = "지난 2초간 시체를 소모했나요?", ifCond = "ConsumedCorpseInPast2Sec", implyCond = "ConsumedCorpseRecently",tooltip = "This also implies you have 'Consumed a corpse Recently'", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ConsumedCorpseInPast2Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierCorpseConsumedRecently", type = "count", label = "최근 소모한 시체 수:", ifMult = "CorpseConsumedRecently", implyCond = "ConsumedCorpseRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:CorpseConsumedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:ConsumedCorpseRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionRavenousCorpseConsumed", type = "check", label = "탐식이 시체를 소모했나요?", ifSkill = "Ravenous", implyCond = "ConsumedCorpseRecently", tooltip = "Corpse must be the same type as the monster you're fighting.\nThis also implies you have 'Consumed a corpse Recently'", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:RavenousCorpseConsumed", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierWarcryUsedRecently", type = "count", label = "최근 사용한 함성 수:", {ifFlag = "warcry", ifMult = "WarcryUsedRecently"}, implyCondList = {"UsedWarcryRecently", "UsedWarcryInPast8Seconds", "UsedSkillRecently"}, tooltip = "This also implies you have 'Used a Warcry Recently', 'Used a Warcry in the past 8 seconds', and 'Used a Skill Recently'", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:WarcryUsedRecently", "BASE", m_min(val, 100), "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedWarcryRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedWarcryInPast8Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTauntedEnemyRecently", type = "check", label = "최근에 적을 도발했나요?", ifCond = "TauntedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TauntedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLostEnduranceChargeInPast8Sec", type = "check", label = "지난 8초간 인내 충전을 잃었나요?", ifCond = "LostEnduranceChargeInPast8Sec", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LostEnduranceChargeInPast8Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierEnduranceChargesLostRecently", type = "count", label = "최근 잃은 인내 충전 수:", ifMult = "EnduranceChargesLostRecently", implyCond = "LostEnduranceChargeInPast8Sec", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnduranceChargesLostRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:LostEnduranceChargeInPast8Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedHitFromUniqueEnemyInPast10Sec", type = "check", label = "지난 10초간 고유 적의 적중을 막았나요?", ifCond = "BlockedHitFromUniqueEnemyInPast10Sec", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedHitFromUniqueEnemyInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledUniqueEnemy", type = "check", label = "최근에 희귀 또는 고유 적을 처치했나요?", ifCond = "KilledUniqueEnemy", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledUniqueEnemy", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "BlockedPast10Sec", type = "count", label = "지난 10초간 막기 횟수", ifCond = "BlockedHitFromUniqueEnemyInPast10Sec", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:BlockedPast10Sec", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionImpaledRecently", type = "check", ifCond = "ImpaledRecently", label = "최근에 적을 꿰뚫었나요?", apply = function(val, modList, enemyModLIst)
		modList:NewMod("Condition:ImpaledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierImpalesOnEnemy", type = "countAllowZero", label = "적에 대한 꿰뚫기 수 (최대가 아닌 경우):", ifFlag = "impale", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:ImpaleStacks", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierBleedsOnEnemy", type = "count", label = "적에 대한 출혈 수 (최대가 아닌 경우):", ifFlag = "Condition:HaveCrimsonDance", tooltip = "Sets current number of Bleeds on the enemy if using the Crimson Dance keystone.\nThis also implies that the enemy is Bleeding.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:BleedStacks", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		enemyModList:NewMod("Condition:Bleeding", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierFragileRegrowth", type = "count", label = "취약한 재생 중첩 수:", ifMult = "FragileRegrowthCount", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:FragileRegrowthCount", "BASE", m_min(val,10), "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHaveArborix", type = "check", label = "강철 반사 상태인가요?", ifFlag = "Condition:HaveArborix", tooltip = "This option is specific to Arborix.",apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HaveIronReflexes", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Keystone", "LIST", "Iron Reflexes", "Config")
	end },	
	{ var = "conditionHaveAugyre", type = "list", label = "오기레 회전 버프:", ifFlag = "Condition:HaveAugyre", list = {{val="EleOverload",label="원소 과부하"},{val="ResTechnique",label="굳건한 기술"}}, tooltip = "This option is specific to Augyre.", apply = function(val, modList, enemyModList)
		if val == "EleOverload" then
			modList:NewMod("Condition:HaveElementalOverload", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
			modList:NewMod("Keystone", "LIST", "Elemental Overload", "Config")
		elseif val == "ResTechnique" then
			modList:NewMod("Condition:HaveResoluteTechnique", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
			modList:NewMod("Keystone", "LIST", "Resolute Technique", "Config")
		end
	end },	
	{ var = "conditionHaveVulconus", type = "check", label = "화염의 화신 상태인가요?", ifFlag = "Condition:HaveVulconus", tooltip = "This option is specific to Vulconus.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HaveAvatarOfFire", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Keystone", "LIST", "Avatar of Fire", "Config")
	end },
	{ var = "conditionHaveManaStorm", type = "check", label = "마나폭풍 버프가 있나요?", ifFlag = "Condition:HaveManaStorm", tooltip = "This option enables Manastorm's ^xADAA47Lightning ^7Damage Buff.\n(When you cast a Spell, Sacrifice all ^x7070FFMana ^7to gain Added Maximum ^xADAA47Lightning ^7Damage\nequal to 50% of Sacrificed ^x7070FFMana ^7for 4 seconds)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SacrificeManaForLightning", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "GamblesprintMovementSpeed", type = "list", label = "도박 질주 이동 속도", defaultIndex=5, list={{val=-40,label="-40%"},{val=-20,label="-20%"},{val=0,label="0%"},{val=20,label="20%"},{val=30,label="30%"},{val=40,label="40%"},{val=60,label="60%"},{val=80,label="80%"},{val=100,label="100%"}}, ifFlag = "Condition:HaveGamblesprint", tooltip = "This option sets the Movement Speed from Gamblesprint boots.", apply = function(val, modList, enemyModList)
		modList:NewMod("MovementSpeed", "INC", val, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "HaveGamblesprint" })
	end },
	{ var = "EverlastingSacrifice", type = "check", label = "영원한 희생 상태인가요?", ifFlag = "Condition:EverlastingSacrifice", tooltip = "This option enables the Everlasting Sacrifice buff that grants +5% to all maximum resists.", apply = function(val, modList , enemyModList)
		modList:NewMod("ElementalResistMax", "BASE", 5, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "EverlastingSacrifice"})
		modList:NewMod("ChaosResistMax", "BASE", 5, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "EverlastingSacrifice"})
	end },
	{ var = "buffFanaticism", type = "check", label = "광신 상태인가요?", ifFlag = "Condition:CanGainFanaticism", tooltip = "This will enable the Fanaticism buff itself. (Grants 75% more cast speed, reduced skill cost, and increased area of effect)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Fanaticism", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanGainFanaticism" })
	end },
	{ var = "conditionHitsAlwaysStun", type = "check", label = "적중이 항상 기절시키나요?", ifFlag = "Condition:maceMasteryStunCullSpecced", tooltip = "This enables the conditional culling strike from the mace mastery.", apply = function(val, modList, enemyModList)
		modList:NewMod("CullPercent", "MAX", 10, "Config", { type = "Condition", var = "Combat" }, {type = "Condition", var = "maceMasteryStunCullSpecced"})
	end },
	{ var = "multiplierPvpTvalueOverride", type = "count", label = "PvP T값 덮어쓰기 (ms):", ifFlag = "isPvP", tooltip = "Tvalue in milliseconds. This overrides the Tvalue of a given skill, for instance any with fixed Tvalues, or modified Tvalues", apply = function(val, modList, enemyModList)
		modList:NewMod("MultiplierPvpTvalueOverride", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierPvpDamage", type = "count", label = "사용자 정의 PvP 피해 배율 %:", ifFlag = "isPvP", tooltip = "This multiplies the damage of a given skill in pvp, for instance any with damage multiplier specific to pvp (from skill or support or item like sire of shards)", apply = function(val, modList, enemyModList)
		modList:NewMod("PvpDamageMultiplier", "MORE", val - 100, "Config")
	end },
	{ var = "buffAccelerationShrine", type = "check", label = "가속 성소가 있나요?", ifFlag = "Condition:CanHaveRegularShrines", tooltip = "This will enable the Acceleration Shrine buff.\n\t15% increased Action Speed\n\t80% increased Projectile Speed", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AccelerationShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffBrutalShrine", type = "check", label = "잔인한 성소가 있나요?", ifFlag = "Condition:CanHaveRegularShrines", tooltip = "This will enable the Brutal Shrine buff.\n\t50% increased Damage\n\tKnocks Enemies Back on Hit\n\t30% increased Stun Duration on Enemies", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BrutalShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffDiamondShrine", type = "check", label = "다이아몬드 성소가 있나요?", ifFlag = "Condition:CanHaveRegularShrines", tooltip = "This will enable the Diamond Shrine buff.\n\tAll hits are Critical Strikes", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:DiamondShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffDivineShrine", type = "check", label = "신성한 성소가 있나요?", ifFlag = "Condition:CanHaveRegularShrines", tooltip = "This will enable the Divine Shrine buff.\n\tCannot be Damaged", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:DivineShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffEchoingShrine", type = "check", label = "메아리 성소가 있나요?", ifFlag = "Condition:CanHaveRegularShrines", tooltip = "This will enable the Echoing Shrine buff.\n\t100% more Attack Speed\n\t100% more Cast Speed\n\tSkills Repeat an additional Time", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:EchoingShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffGloomShrine", type = "check", label = "음울한 성소가 있나요?", ifFlag = "Condition:CanHaveRegularShrines", tooltip = "This will enable the Gloom Shrine buff.\n\tGain 10% of Non-^xD02090Chaos ^7Damage as extra ^xD02090Chaos ^7Damage\n\tEnemies you Kill have a 40% chance to Explode, dealing a quarter of their maximum ^xE05030Life ^7as ^xD02090Chaos ^7Damage", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:GloomShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffImpenetrableShrine", type = "check", label = "난공불락 성소가 있나요?", ifFlag = "Condition:CanHaveRegularShrines", tooltip = "This will enable the Impenetrable Shrine buff.\n\t100% increased Armour\n\t100% increased ^x33FF77Evasion Rating^7\n\t100% increased maximum ^x88FFFFEnergy Shield", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ImpenetrableShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffMassiveShrine", type = "check", label = "거대한 성소가 있나요?", ifFlag = "Condition:CanHaveRegularShrines", tooltip = "This will enable the Massive Shrine buff.\n\t30% increased Character Size\n\t40% increased Area of Effect\n\t40% increased maximum ^xE05030Life", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:MassiveShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffReplenishingShrine", type = "check", label = "보충 성소가 있나요?", ifFlag = "Condition:CanHaveRegularShrines", tooltip = "This will enable the Replenishing Shrine buff.\n\t200% increased ^x7070FFMana ^7Regeneration Rate\n\t6.7% of ^xE05030Life ^7Regenerated per second", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ReplenishingShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffResistanceShrine", type = "check", label = "저항 성소가 있나요?", ifFlag = "Condition:CanHaveRegularShrines", tooltip = "This will enable the Resistance Shrine buff.\n\t+50% to all Elemental Resistances\n\t+10% to all maximum Resistances", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ResistanceShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffResonatingShrine", type = "check", label = "공명 성소가 있나요?", ifFlag = "Condition:CanHaveRegularShrines", tooltip = "This will enable the Resonating Shrine buff.\n\t20% chance to gain a Power, Frenzy or Endurance Charge on Hit\n\t60% chance to gain a Power, Frenzy or Endurance Charge on Kill\n\t+1 to Maximum Power Charges\n\t+1 to Maximum Frenzy Charges\n\t+1 to Maximum Endurance Charges", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ResonatingShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffLesserAccelerationShrine", type = "check", label = "하급 가속 성소가 있나요?", ifFlag = "Condition:CanHaveLesserShrines", tooltip = "This will enable the Lesser Acceleration Shrine buff.\n\t10% increased Action Speed\n\t30% increased Projectile Speed", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LesserAccelerationShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffLesserBrutalShrine", type = "check", label = "하급 잔인한 성소가 있나요?", ifFlag = "Condition:CanHaveLesserShrines", tooltip = "This will enable the Lesser Brutal Shrine buff.\n\t20% increased Damage\n\tKnocks Enemies Back on Hit\n\t20% increased Stun Duration on Enemies", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LesserBrutalShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffLesserImpenetrableShrine", type = "check", label = "하급 난공불락 성소가 있나요?", ifFlag = "Condition:CanHaveLesserShrines", tooltip = "This will enable the Lesser Impenetrable Shrine buff.\n\t50% increased Armour\n\t50% increased ^x33FF77Evasion Rating^7\n\t50% increased maximum ^x88FFFFEnergy Shield", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LesserImpenetrableShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffLesserMassiveShrine", type = "check", label = "하급 거대한 성소가 있나요?", ifFlag = "Condition:CanHaveLesserShrines", tooltip = "This will enable the Lesser Massive Shrine buff.\n\t10% increased Character Size\n\t20% increased Area of Effect\n\t20% increased maximum ^xE05030Life", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LesserMassiveShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffLesserReplenishingShrine", type = "check", label = "하급 보충 성소가 있나요?", ifFlag = "Condition:CanHaveLesserShrines", tooltip = "This will enable the Lesser Replenishing Shrine buff.\n\t100% increased ^x7070FFMana ^7Regeneration Rate\n\t3.3% of ^xE05030Life ^7Regenerated per second", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LesserReplenishingShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffLesserResistanceShrine", type = "check", label = "하급 저항 성소가 있나요?", ifFlag = "Condition:CanHaveLesserShrines", tooltip = "This will enable the Lesser Resistance Shrine buff.\n\t+25% to all Elemental Resistances\n\t+2% to all maximum Resistances", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LesserResistanceShrine", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	-- Section: Effective DPS options
	{ section = "유효 DPS", col = 1 },
	{ var = "skillForkCount", type = "count", label = "스킬 분기 횟수:", ifFlag = "forking", apply = function(val, modList, enemyModList)
		modList:NewMod("ForkedCount", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "skillChainCount", type = "count", label = "스킬 연쇄 횟수:", ifStat = { "Chain", "ChainRemaining" }, ifFlag = "chaining", apply = function(val, modList, enemyModList)
		modList:NewMod("ChainCount", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "skillPierceCount", type = "count", label = "스킬 관통 횟수:", ifStat = "PiercedCount", ifFlag = "piercing", apply = function(val, modList, enemyModList)
		modList:NewMod("PiercedCount", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "meleeDistance", type = "count", label = "적과의 근접 거리:", tooltip = "10 units equals 1 metre", ifTagType = "MeleeProximity", ifFlag = "melee", defaultPlaceholderState = 15 },
	{ var = "projectileDistance", type = "count", label = "투사체 이동 거리:", tooltip = "10 units equals 1 metre", ifTagType = "DistanceRamp", ifFlag = "projectile", defaultPlaceholderState = 40 },
	{ var = "conditionAtCloseRange", type = "check", label = "적이 근접 거리에 있나요?", ifCond = "AtCloseRange", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AtCloseRange", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "enemyMultiplierEnemyPresenceSeconds", type = "count", label = "적이 당신의 존재감 안에 있는 시간", tooltip = "Number of seconds the enemy has been in your presence.", ifEnemyMult = "EnemyPresenceSeconds", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:EnemyPresenceSeconds", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyMoving", type = "check", label = "적이 이동 중인가요?", ifMod = "BleedChance", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Moving", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFullLife", type = "check", label = "적이 최대 ^xE05030생명력^7인가요?", ifEnemyCond = "FullLife", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:FullLife", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyLowLife", type = "check", label = "적이 빈사 ^xE05030생명력^7인가요?", ifEnemyCond = "LowLife", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:LowLife", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyCursed", type = "check", label = "적이 저주 상태인가요?", ifEnemyCond = "Cursed", tooltip = "The enemy will automatically be considered to be Cursed if you have at least one curse enabled,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Cursed", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyStunned", type = "check", label = "적이 기절 상태인가요?", ifEnemyCond = "Stunned", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Stunned", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBleeding", type = "check", label = "적이 출혈 상태인가요?", ifEnemyCond = "Bleeding", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Bleeding", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "overrideBleedStackPotential", type = "count", label = "출혈 중첩 잠재력 덮어쓰기:", ifOption = "conditionEnemyBleeding", tooltip = "Allows you to manually set the Stack Potential value for a skill.\nStack Potential equates to the number of times you are able to inflict a Bleed on an enemy before the duration of your first Bleed expires", apply = function(val, modList, enemyModList)
		modList:NewMod("BleedStackPotentialOverride", "OVERRIDE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionSingleBleed", type = "check", label = "적에 대한 출혈을 단일로 제한?", ifCond = "SingleBleed", tooltip = "This is for Blood Sap Tincture, but will limit you to only applying a single Bleed on the enemy", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SingleBleed", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierRuptureStacks", type = "count", label = "파열 중첩 수?", ifFlag = "Condition:CanInflictRupture", tooltip = "Rupture applies more bleed damage and faster bleeds for 3 seconds, up to 4 stacks", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:RuptureStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyPoisoned", type = "check", label = "적이 중독 상태인가요?", ifEnemyCond = "Poisoned", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Poisoned", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierPoisonOnEnemy", type = "count", label = "적에 대한 독 수:", ifEnemyMult = "PoisonStack", implyCond = "Poisoned", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:PoisonStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionSinglePoison", type = "check", label = "적에 대한 독을 단일로 제한?", ifCond = "SinglePoison", tooltip = "This is for low tolerance, but will limit you to only applying a single poison on the enemy", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SinglePoison", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierCurseExpiredOnEnemy", type = "count", label = "적에 대한 저주 만료 %:", ifEnemyMult = "CurseExpired", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:CurseExpired", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierCurseDurationExpiredOnEnemy", type = "count", label = "적에 대한 저주 지속시간 경과:", ifEnemyMult = "CurseDurationExpired", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:CurseDurationExpired", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierWitheredStackCount", type = "count", label = "시들음 중첩 수:", ifFlag = "Condition:CanWither", tooltip = "Withered applies 6% increased ^xD02090Chaos ^7Damage Taken to the enemy, up to 15 stacks.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:WitheredStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierCorrosionStackCount", type = "count", label = "부식 중첩 수:", ifFlag = "Condition:CanCorrode", tooltip = "Each stack of Corrosion applies -5000 to total Armour and -1000 to total ^x33FF77Evasion Rating ^7to the enemy.\nCorrosion lasts 4 seconds and refreshes the duration of existing Corrosion stacks\nCorrosion has no stack limit", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:CorrosionStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Armour", "BASE", -5000, "Corrosion", { type = "Multiplier", var = "CorrosionStack" }, { type = "ActorCondition", actor = "enemy", var = "CanCorrode" })
		enemyModList:NewMod("Evasion", "BASE", -1000, "Corrosion", { type = "Multiplier", var = "CorrosionStack" }, { type = "ActorCondition", actor = "enemy", var = "CanCorrode" })
	end },
	{ var = "multiplierEnsnaredStackCount", type = "count", label = "올가미 중첩 수:", ifSkill = "Ensnaring Arrow", tooltip = "While ensnared, enemies take increased Projectile Damage from Attack Hits\nEnsnared enemies always count as moving, and have less movement speed while trying to break the snare.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnsnareStackCount", "BASE", val, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:Moving", "FLAG", true, "Config", { type = "MultiplierThreshold", actor = "enemy", var = "EnsnareStackCount", threshold = 1 })
	end },
	{ var = "conditionEnemyMaimed", type = "check", label = "적이 힘줄 절단 상태인가요?", ifEnemyCond = "Maimed", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Maimed", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyHindered", type = "check", label = "적이 방해 상태인가요?", ifEnemyCond = "Hindered", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Hindered", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyExcommunicated", type = "check", label = "적이 파문 상태인가요?", ifFlag = "Condition:CanExcommunicate", tooltip = "Excommunicated Enemies cannot deal ^xD02090Chaos ^7Damage.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Excommunicated", "FLAG", true, "Config", { type = "ActorCondition", actor = "enemy", var = "CanExcommunicate" })
	end },
	{ var = "conditionEnemyBlinded", type = "check", label = "적이 실명 상태인가요?", tooltip = "In addition to allowing 'against Blinded Enemies' modifiers to apply,\n Blind applies the following effects.\n -20% Accuracy \n -20% ^x33FF77Evasion", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Blinded", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "overrideBuffBlinded", type = "count", label = "실명 효과 (최대가 아닌 경우):", ifOption = "conditionEnemyBlinded", tooltip = "If you have a guaranteed source of Blind, the strongest one will apply.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("BlindEffect", "OVERRIDE", val, "Config", {type = "GlobalEffect", effectType = "Buff" })
	end },
	{ var = "conditionEnemyTaunted", type = "check", label = "적이 도발 상태인가요?", ifEnemyCond = "Taunted", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Taunted", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyDebilitated", type = "check", label = "적이 쇠약 상태인가요?", ifMod = "DebilitateChance", tooltip = "Debilitated enemies deal 10% less damage.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Debilitated", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyPacified", type = "check", label = "적이 진정 상태인가요?", ifSkill = "Pacify", tooltip = "Enemies are Pacified after 60% of Pacify's duration has expired", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Pacified", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBurning", type = "check", label = "적이 ^xB97123타고^7 있나요?", ifEnemyCond = "Burning", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Burning", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyIgnited", type = "check", label = "적이 ^xB97123점화^7 상태인가요?", ifEnemyCond = "Ignited", implyCond = "Burning", tooltip = "This also implies that the enemy is ^xB97123Burning.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Ignited", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "overrideIgniteStackPotential", type = "count", label = "^xB97123점화^7 중첩 잠재력 덮어쓰기:", ifOption = "conditionEnemyIgnited", tooltip = "Allows you to manually set the Stack Potential value for a skill.\nStack Potential equates to the number of times you are able to inflict an Ignite on an enemy before the duration of your first Ignite expires", apply = function(val, modList, enemyModList)
		modList:NewMod("IgniteStackPotentialOverride", "OVERRIDE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyScorched", type = "check", ifFlag = "inflictScorch", label = "적이 ^xB97123그을림^7 상태인가요?", tooltip = "^xB97123Scorched ^7enemies have lowered elemental resistances, up to -30%.\nThis option will also allow you to input the effect of ^xB97123Scorched.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Scorched", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:ScorchedConfig", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionScorchedEffect", type = "count", label = "^xB97123그을림^7 효과:", ifOption = "conditionEnemyScorched", tooltip = "This effect will only be applied while you can inflict ^xB97123Scorched.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ScorchVal", "BASE", val, "Config", { type = "Condition", var = "ScorchedConfig" })
		enemyModList:NewMod("DesiredScorchVal", "BASE", val, "Scorch", { type = "Condition", var = "ScorchedConfig", neg = true })
	end },
	{ var = "ScorchStacks", type = "integer", label = "^xB97123그을림 ^7중첩", ifFlag = "ScorchCanStack", ifOption = "conditionEnemyScorched", defaultPlaceholderState = 1, tooltip = "Amount of stacks of ^xB97123Scorch ^7applied to the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:ScorchStacks", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyOnScorchedGround", type = "check", label = "적이 ^xB97123그을림 ^7대지 위에 있나요?", tooltip = "This also implies that the enemy is ^xB97123Scorched.", ifEnemyCond = "OnScorchedGround", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Scorched", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:OnScorchedGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyChilled", type = "check", label = "적이 ^x3F6DB3한랭^7 상태인가요?", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:ChilledConfig", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierChilledByYouSeconds", type = "count", label = "적에 대한 냉각 시간(초)?", ifEnemyCond = "ChilledByYou", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:ChilledByYouSeconds", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		enemyModList:NewMod("Condition:ChilledByYou", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyChilledEffect", type = "count", label = "^x3F6DB3냉각^7 효과:", ifOption = "conditionEnemyChilled", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ChillVal", "BASE", val, "Chill", { type = "Condition", var = "ChilledConfig" })
		enemyModList:NewMod("DesiredChillVal", "BASE", val, "Chill", { type = "Condition", var = "ChilledConfig", neg = true })
	end },
	{ var = "conditionEnemyChilledByYourHits", type = "check", ifEnemyCond = "ChilledByYourHits", label = "적이 당신의 적중으로 ^x3F6DB3냉각^7 상태인가요?", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:ChilledByYourHits", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "HoarfrostStacks", type = "count", label = "^x3F6DB3서리 ^7중첩", ifFlag = "HitsCanInflictHoarfrost", tooltip = "Amount of stacks of ^x3F6DB3Hoarfrost ^7applied to the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("HoarfrostFreezeDuration", "INC", val * 20, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFrozen", type = "check", label = "적이 ^x3F6DB3동결^7 상태인가요?", ifEnemyCond = "Frozen", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Frozen", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierFrozenByYouSeconds", type = "count", label = "적에 대한 동결 시간(초)?", ifEnemyCond = "FrozenByYou", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:FrozenByYouSeconds", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		enemyModList:NewMod("Condition:FrozenByYou", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBrittle", type = "check", ifFlag = "inflictBrittle", label = "적이 ^x3F6DB3균열^7 상태인가요?", tooltip = "Hits against ^x3F6DB3Brittle ^7enemies have up to +6% Critical Strike Chance.\nThis option will also allow you to input the effect of ^x3F6DB3Brittle.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Brittle", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:BrittleConfig", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionBrittleEffect", type = "count", label = "^x3F6DB3균열^7 효과:", ifOption = "conditionEnemyBrittle", tooltip = "This effect will only be applied while you can inflict ^x3F6DB3Brittle.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("BrittleVal", "BASE", val, "Config", { type = "Condition", var = "BrittleConfig" })
		enemyModList:NewMod("DesiredBrittleVal", "BASE", val, "Brittle", { type = "Condition", var = "BrittleConfig", neg = true })
	end },
	{ var = "conditionEnemyOnBrittleGround", type = "check", label = "적이 ^xADAA47균열 ^7대지 위에 있나요?", tooltip = "This also implies that the enemy is ^xADAA47Brittle.", ifEnemyCond = "OnBrittleGround", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Brittle", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:OnBrittleGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyShocked", type = "check", label = "적이 ^xADAA47감전^7 상태인가요?", tooltip = "In addition to allowing any 'against ^xADAA47Shocked ^7Enemies' modifiers to apply,\nthis will allow you to input the effect of the ^xADAA47Shock ^7applied to the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:ShockedConfig", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionShockEffect", type = "count", label = "^xADAA47감전^7 효과:", ifOption = "conditionEnemyShocked", tooltip = "If you have a guaranteed source of ^xADAA47Shock^7,\nthe strongest one will apply instead unless this option would apply a stronger ^xADAA47Shock.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ShockVal", "BASE", val, "Shock", { type = "Condition", var = "ShockedConfig" })
		enemyModList:NewMod("DesiredShockVal", "BASE", val, "Shock", { type = "Condition", var = "ShockedConfig", neg = true })
	end },
	{ var = "ShockStacks", type = "count", label = "^xADAA47감전 ^7중첩", ifFlag = "ShockCanStack", ifOption = "conditionEnemyShocked", defaultPlaceholderState = 1, tooltip = "Amount of stacks of ^xADAA47Shock ^7applied to the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:ShockStacks", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyOnShockedGround", type = "check", label = "적이 ^xADAA47감전 ^7대지 위에 있나요?", tooltip = "This also implies that the enemy is ^xADAA47Shocked.", ifEnemyCond = "OnShockedGround", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:OnShockedGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemySapped", type = "check", ifFlag = "inflictSap", label = "적이 ^xADAA47수액^7 상태인가요?", tooltip = "^xADAA47Sapped ^7enemies deal less damage, up to 20%.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Sapped", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:SappedConfig", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionSapEffect", type = "count", label = "^xADAA47수액^7 효과:", ifOption = "conditionEnemySapped", tooltip = "If you have a guaranteed source of ^xADAA47Sap^7,\nthe strongest one will apply instead unless this option would apply a stronger ^xADAA47Sap.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("SapVal", "BASE", val, "Sap", { type = "Condition", var = "SappedConfig" })
		enemyModList:NewMod("DesiredSapVal", "BASE", val, "Sap", { type = "Condition", var = "SappedConfig", neg = true })
	end },
	{ var = "conditionEnemyOnSappedGround", type = "check", label = "적이 ^xADAA47수액 ^7대지 위에 있나요?", tooltip = "This also implies that the enemy is ^xADAA47Sapped.", ifEnemyCond = "OnSappedGround", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Sapped", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:OnSappedGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierFreezeShockIgniteOnEnemy", type = "count", label = "적에 대한 ^x3F6DB3동결 ^7/ ^xADAA47감전 ^7/ ^xB97123점화 ^7수:", ifMult = "FreezeShockIgniteOnEnemy", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:FreezeShockIgniteOnEnemy", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFireExposure", type = "check", label = "적이 ^xB97123화염^7에 노출되었나요?", ifFlag = "applyFireExposure", tooltip = "This applies -10% ^xB97123Fire Resistance ^7to the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("FireExposure", "BASE", -10, "Config", { type = "Condition", var = "Effective" }, { type = "ActorCondition", actor = "enemy", var = "CanApplyFireExposure" })
	end },
	{ var = "conditionEnemyColdExposure", type = "check", label = "적이 ^x3F6DB3냉기^7에 노출되었나요?", ifFlag = "applyColdExposure", tooltip = "This applies -10% ^x3F6DB3Cold Resistance ^7to the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ColdExposure", "BASE", -10, "Config", { type = "Condition", var = "Effective" }, { type = "ActorCondition", actor = "enemy", var = "CanApplyColdExposure" })
	end },
	{ var = "conditionEnemyLightningExposure", type = "check", label = "적이 ^xADAA47번개^7에 노출되었나요?", ifFlag = "applyLightningExposure", tooltip = "This applies -10% ^xADAA47Lightning Resistance ^7to the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("LightningExposure", "BASE", -10, "Config", { type = "Condition", var = "Effective" }, { type = "ActorCondition", actor = "enemy", var = "CanApplyLightningExposure" })
	end },
	{ var = "conditionEnemyIntimidated", type = "check", label = "적이 위협 상태인가요?", tooltip = "Intimidated enemies take 10% increased Attack Damage.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Intimidated", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyCrushed", type = "check", label = "적이 분쇄 상태인가요?", tooltip = "Crushed enemies have 15% reduced Physical Damage Reduction.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Crushed", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionNearLinkedTarget", type = "check", label = "적이 연결된 대상 근처에 있나요?", ifEnemyCond = "NearLinkedTarget", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:NearLinkedTarget", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyUnnerved", type = "check", label = "적이 불안 상태인가요?", tooltip = "Unnerved enemies take 10% increased Spell Damage.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Unnerved", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyCoveredInAsh", type = "check", label = "적이 재로 덮여 있나요?", tooltip = "Covered in Ash applies the following to the enemy:\n\t20% increased ^xB97123Fire ^7Damage taken\n\t20% less Movement Speed", apply = function(val, modList, enemyModList)
		modList:NewMod("CoveredInAshEffect", "BASE", 20, "Covered in Ash")
	end },
	{ var = "conditionEnemyCoveredInFrost", type = "check", label = "적이 서리로 덮여 있나요?", tooltip = "Covered in Frost applies the following to the enemy:\n\t20% increased ^x3F6DB3Cold ^7Damage taken\n\t50% less Critical Strike Chance", apply = function(val, modList, enemyModList)
		modList:NewMod("CoveredInFrostEffect", "BASE", 20, "Covered in Frost")
	end },
	{ var = "conditionEnemyOnConsecratedGround", type = "check", label = "적이 신성한 대지 위에 있나요?", ifEnemyCond = "OnConsecratedGround", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:OnConsecratedGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyHaveEnergyShield", type = "check", label = "적이 ^x88FFFF에너지 보호막^7이 있나요?", ifEnemyCond = "HaveEnergyShield", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:HaveEnergyShield", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyOnProfaneGround", type = "check", label = "적이 불경한 대지 위에 있나요?", ifFlag = "Condition:CreateProfaneGround", tooltip = "Enemies on Profane Ground receive the following modifiers:\n\t10% increased Effect of Curses\n\t100% increased chance to be Critically Hit", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:OnProfaneGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("CurseEffectOnSelf", "INC", 10, "Config", { type = "Condition", var = "OnProfaneGround" })
		enemyModList:NewMod("SelfCritChance", "INC", 100, "Config", { type = "Condition", var = "OnProfaneGround" })
	end },
	{ var = "multiplierEnemyAffectedByGraspingVines", type = "count", label = "적에게 영향을 주는 넝쿨 수:", ifMult = "GraspingVinesAffectingEnemy", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:GraspingVinesAffectingEnemy", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyOnFungalGround", type = "check", label = "적이 균사 대지 위에 있나요?", ifCond = { "OnFungalGround", "CreateFungalGround" }, tooltip = "Enemies on your Fungal Ground have -10% to all Resistances.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:OnFungalGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyInChillingArea", type = "check", label = "적이 ^x3F6DB3냉각 ^7지역에 있나요?", ifEnemyCond = "InChillingArea", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:InChillingArea", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyInFrostGlobe", type = "check", label = "적이 서리 방패 범위 안에 있나요?", ifEnemyCond = "EnemyInFrostGlobe", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:EnemyInFrostGlobe", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyLifeHigherThanPlayer", type = "check", label = "적의 ^xE05030생명력^7%가 당신보다 높나요?", ifEnemyCond = "HigherLifePercentThanPlayer", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:HigherLifePercentThanPlayer", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "enemyConditionHitByFireDamage", type = "check", label = "적이 ^xB97123화염 ^7피해를 받았나요?", ifFlag = "ElementalEquilibrium", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:HitByFireDamage", "FLAG", true, "Config")
	end },
	{ var = "enemyConditionHitByColdDamage", type = "check", label = "적이 ^x3F6DB3냉기 ^7피해를 받았나요?", ifFlag = "ElementalEquilibrium", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:HitByColdDamage", "FLAG", true, "Config")
	end },
	{ var = "enemyConditionHitByLightningDamage", type = "check", label = "적이 ^xADAA47번개 ^7피해를 받았나요?", ifFlag = "ElementalEquilibrium", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:HitByLightningDamage", "FLAG", true, "Config")
	end },
	{ var = "enemyInRFOrScorchingRay", type = "check", label = "적이 정의의 화염 또는 작열 광선 안에 있나요:", ifCond = "InRFOrScorchingRay", ifSkill = { "Righteous Fire", "Scorching Ray" }, includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:InRFOrScorchingRay", "FLAG", true, "Config")
	end },
	{ var = "EEIgnoreHitDamage", type = "check", label = "스킬 적중 피해 무시?", ifFlag = "ElementalEquilibrium", tooltip = "This option prevents EE from being reset by the hit damage of your main skill." },
	{ var = "conditionBetweenYouAndLinkedTarget", type = "check", label = "적이 연결 광선 안에 있나요?", ifEnemyCond = "BetweenYouAndLinkedTarget", tooltip = "This option sets whether an enemy is between you and your linked target.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:BetweenYouAndLinkedTarget", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFireResZero", type = "check", label = "적이 ^xB97123화염 피해^7로 공격했나요?", ifFlag = "Condition:HaveTrickstersSmile", tooltip = "This option sets whether or not the enemy has hit you with ^xB97123Fire Damage^7 in the last 4 seconds.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("FireResist", "OVERRIDE", 0, "Config", { type = "Condition", var = "Effective"}, { type = "ActorCondition", actor = "enemy", var = "HaveTrickstersSmile" })
	end },
	{ var = "conditionEnemyColdResZero", type = "check", label = "적이 ^x3F6DB3냉기 피해^7로 공격했나요?", ifFlag = "Condition:HaveTrickstersSmile", tooltip = "This option sets whether or not the enemy has hit you with ^x3F6DB3Cold Damage^7 in the last 4 seconds.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ColdResist", "OVERRIDE", 0, "Config", { type = "Condition", var = "Effective"}, { type = "ActorCondition", actor = "enemy", var = "HaveTrickstersSmile" })
	end },
	{ var = "conditionEnemyLightningResZero", type = "check", label = "적이 ^xADAA47번개 피해^7로 공격했나요?", ifFlag = "Condition:HaveTrickstersSmile", tooltip = "This option sets whether or not the enemy has hit you with ^xADAA47Lightning Damage^7 in the last 4 seconds.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("LightningResist", "OVERRIDE", 0, "Config", { type = "Condition", var = "Effective"}, { type = "ActorCondition", actor = "enemy", var = "HaveTrickstersSmile" })
	end },
	{ var = "maniaDebuffsCount", type = "countAllowZero", label = "광기 중첩 수", ifFlag = "Condition:CanInflictMania", defaultState = 15, tooltip = "Mania Stacks apply:\n\t4% inc Damage Taken per stack\n\t2% reduced Action Speed per stack\n\t10% reduced ^xE05030Life ^7and ^x88FFFFEnergy Shield ^7Recovery Rate per stack", apply = function(val, modList, enemyModList)
		val = m_min(val, 15)
		enemyModList:NewMod("DamageTaken", "INC", val * 4, val.." Mania Stacks", { type = "GlobalEffect", effectType = "Debuff" }, { type = "Condition", var = "AfflictedByMania" })
		enemyModList:NewMod("ActionSpeed", "INC", -val * 2, val.." Mania Stacks", { type = "GlobalEffect", effectType = "Debuff" }, { type = "Condition", var = "AfflictedByMania" })
		enemyModList:NewMod("LifeRecoveryRate", "INC", -val * 10, val.." Mania Stacks", { type = "GlobalEffect", effectType = "Debuff" }, { type = "Condition", var = "AfflictedByMania" })
		enemyModList:NewMod("EnergyShieldRecoveryRate", "INC", -val * 10, val.." Mania Stacks", { type = "GlobalEffect", effectType = "Debuff" }, { type = "Condition", var = "AfflictedByMania" })
	end },
	-- Section: Enemy Stats
	{ section = "적 상태", col = 3 },
	{ var = "enemyLevel", type = "count", label = "적 레벨:", tooltip = "This overrides the default enemy level used to estimate your hit and ^x33FF77evade ^7chance.\n\nThe default level for normal enemies and standard bosses is 83.\nTheir default level is capped by your character level.\n\nThe default level for pinnacle bosses is 84, and the default level for uber pinnacle bosses is 85.\nTheir default level is not capped by your character level." },
	{ var = "conditionEnemyRareOrUnique", type = "check", label = "적이 희귀 또는 고유인가요?", ifEnemyCond = "EnemyRareOrUnique", tooltip = "The enemy will automatically be considered to be Unique if they are a Boss,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "enemyIsBoss", type = "list", label = "적이 보스인가요?", defaultIndex = 3, tooltip = data.enemyIsBossTooltip, list = {{val="None",label="아니오"},{val="Boss",label="일반 보스"},{val="Pinnacle",label="수호자/정점 보스"},{val="Uber",label="우버 정점 보스"}}, apply = function(val, modList, enemyModList, build)
		-- These defaults are here so that the placeholders get reset correctly
		build.configTab.varControls['enemySpeed']:SetPlaceholder(700, true)
		build.configTab.varControls['enemyCritChance']:SetPlaceholder(5, true)
		build.configTab.varControls['enemyCritDamage']:SetPlaceholder(data.monsterConstants["base_critical_strike_multiplier"] - 100, true)
		if val == "None" then
			local defaultResist = ""
			build.configTab.varControls['enemyLightningResist']:SetPlaceholder(defaultResist, true)
			build.configTab.varControls['enemyColdResist']:SetPlaceholder(defaultResist, true)
			build.configTab.varControls['enemyFireResist']:SetPlaceholder(defaultResist, true)
			build.configTab.varControls['enemyChaosResist']:SetPlaceholder(defaultResist, true)

			local defaultLevel = 83
			build.configTab.varControls['enemyLevel']:SetPlaceholder("", true)
			build.configTab:UpdateLevel()
			if build.configTab.enemyLevel then
				defaultLevel = build.configTab.enemyLevel
			end

			local defaultDamage = round(data.monsterDamageTable[defaultLevel] * 1.5)
			build.configTab.varControls['enemyPhysicalDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyLightningDamage']:SetPlaceholder("", true)
			build.configTab.varControls['enemyColdDamage']:SetPlaceholder("", true)
			build.configTab.varControls['enemyFireDamage']:SetPlaceholder("", true)
			build.configTab.varControls['enemyChaosDamage']:SetPlaceholder("", true)

			local defaultPen = ""
			build.configTab.varControls['enemyPhysicalOverwhelm']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyLightningPen']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyColdPen']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyFirePen']:SetPlaceholder(defaultPen, true)

			build.configTab.varControls['enemyArmour']:SetPlaceholder(data.monsterArmourTable[defaultLevel], true)
			build.configTab.varControls['enemyEvasion']:SetPlaceholder(data.monsterEvasionTable[defaultLevel], true)
		elseif val == "Boss" then
			enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("AilmentThreshold", "MORE", 488, "Boss")
			modList:NewMod("WarcryPower", "BASE", 20, "Boss")
			modList:NewMod("Multiplier:EnemyPower", "BASE", 20, "Boss")

			local defaultEleResist = 40
			build.configTab.varControls['enemyLightningResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyColdResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyFireResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyChaosResist']:SetPlaceholder(25, true)

			local defaultLevel = 83
			build.configTab.varControls['enemyLevel']:SetPlaceholder("", true)
			build.configTab:UpdateLevel()
			if build.configTab.enemyLevel then
				defaultLevel = build.configTab.enemyLevel
			end

			local defaultDamage = round(data.monsterDamageTable[defaultLevel] * 1.5  * data.misc.stdBossDPSMult)
			build.configTab.varControls['enemyPhysicalDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyLightningDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyColdDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyFireDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyChaosDamage']:SetPlaceholder(round(defaultDamage / 2.5), true)

			local defaultPen = ""
			build.configTab.varControls['enemyPhysicalOverwhelm']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyLightningPen']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyColdPen']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyFirePen']:SetPlaceholder(defaultPen, true)

			build.configTab.varControls['enemyArmour']:SetPlaceholder(data.monsterArmourTable[defaultLevel], true)
			build.configTab.varControls['enemyEvasion']:SetPlaceholder(data.monsterEvasionTable[defaultLevel], true)
		elseif val == "Pinnacle" then
			enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("Condition:PinnacleBoss", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("AilmentThreshold", "MORE", 404, "Boss")
			modList:NewMod("WarcryPower", "BASE", 20, "Boss")
			modList:NewMod("Multiplier:EnemyPower", "BASE", 20, "Boss")

			local defaultEleResist = 50
			build.configTab.varControls['enemyLightningResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyColdResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyFireResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyChaosResist']:SetPlaceholder(30, true)

			local defaultLevel = 84
			build.configTab.varControls['enemyLevel']:SetPlaceholder(defaultLevel, true)
			build.configTab:UpdateLevel()
			if build.configTab.enemyLevel then
				defaultLevel = m_max(build.configTab.enemyLevel, defaultLevel)
			end

			local defaultDamage = round(data.monsterDamageTable[defaultLevel] * 1.5  * data.misc.pinnacleBossDPSMult)
			build.configTab.varControls['enemyPhysicalDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyLightningDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyColdDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyFireDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyChaosDamage']:SetPlaceholder(round(defaultDamage / 2.5), true)

			build.configTab.varControls['enemyLightningPen']:SetPlaceholder(data.misc.pinnacleBossPen, true)
			build.configTab.varControls['enemyColdPen']:SetPlaceholder(data.misc.pinnacleBossPen, true)
			build.configTab.varControls['enemyFirePen']:SetPlaceholder(data.misc.pinnacleBossPen, true)

			build.configTab.varControls['enemyArmour']:SetPlaceholder(round(data.monsterArmourTable[defaultLevel] * (data.bossStats.PinnacleArmourMean/100)), true)
			build.configTab.varControls['enemyEvasion']:SetPlaceholder(round(data.monsterEvasionTable[defaultLevel] * (data.bossStats.PinnacleEvasionMean/100)), true)
		elseif val == "Uber" then
			enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("Condition:PinnacleBoss", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("DamageTaken", "MORE", -70, "Boss")
			enemyModList:NewMod("AilmentThreshold", "MORE", 404, "Boss")
			modList:NewMod("WarcryPower", "BASE", 20, "Boss")
			modList:NewMod("Multiplier:EnemyPower", "BASE", 20, "Boss")

			local defaultEleResist = 50
			build.configTab.varControls['enemyLightningResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyColdResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyFireResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyChaosResist']:SetPlaceholder(30, true)

			local defaultLevel = 85
			build.configTab.varControls['enemyLevel']:SetPlaceholder(defaultLevel, true)
			build.configTab:UpdateLevel()
			if build.configTab.enemyLevel then
				defaultLevel = m_max(build.configTab.enemyLevel, defaultLevel)
			end

			local defaultDamage = round(data.monsterDamageTable[defaultLevel] * 1.5  * data.misc.uberBossDPSMult)
			build.configTab.varControls['enemyPhysicalDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyLightningDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyColdDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyFireDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyChaosDamage']:SetPlaceholder(round(defaultDamage / 4), true)

			build.configTab.varControls['enemyLightningPen']:SetPlaceholder(data.misc.uberBossPen, true)
			build.configTab.varControls['enemyColdPen']:SetPlaceholder(data.misc.uberBossPen, true)
			build.configTab.varControls['enemyFirePen']:SetPlaceholder(data.misc.uberBossPen, true)

			build.configTab.varControls['enemyArmour']:SetPlaceholder(round(data.monsterArmourTable[defaultLevel] * (data.bossStats.UberArmourMean/100)), true)
			build.configTab.varControls['enemyEvasion']:SetPlaceholder(round(data.monsterEvasionTable[defaultLevel] * (data.bossStats.UberEvasionMean/100)), true)
		end
	end },
	{ var = "deliriousPercentage", type = "list", label = "환영 효과:", list = {{val=0,label="없음"},{val="20Percent",label="20% 환영"},{val="40Percent",label="40% 환영"},{val="60Percent",label="60% 환영"},{val="80Percent",label="80% 환영"},{val="100Percent",label="100% 환영"}}, tooltip = "Delirium scales enemy 'less Damage Taken' as well as enemy 'increased Damage dealt'\nAt 100% effect:\nEnemies Deal 30% Increased Damage\nEnemies take 80% Less Damage", apply = function(val, modList, enemyModList)
		if val == "20Percent" then
			enemyModList:NewMod("DamageTaken", "MORE", -16, "20% Delirious")
			enemyModList:NewMod("Damage", "INC", 6, "20% Delirious")
		end
		if val == "40Percent" then
			enemyModList:NewMod("DamageTaken", "MORE", -32, "40% Delirious")
			enemyModList:NewMod("Damage", "INC", 12, "40% Delirious")
		end
		if val == "60Percent" then
			enemyModList:NewMod("DamageTaken", "MORE", -48, "60% Delirious")
			enemyModList:NewMod("Damage", "INC", 18, "60% Delirious")
		end
		if val == "80Percent" then
			enemyModList:NewMod("DamageTaken", "MORE", -64, "80% Delirious")
			enemyModList:NewMod("Damage", "INC", 24, "80% Delirious")
		end
		if val == "100Percent" then
			enemyModList:NewMod("DamageTaken", "MORE", -80, "100% Delirious")
			enemyModList:NewMod("Damage", "INC", 30, "100% Delirious")
		end
	end },
	{ var = "enemyPhysicalReduction", type = "integer", label = "적 물리 피해 감소:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("PhysicalDamageReduction", "BASE", val, "EnemyConfig")
	end },
	{ var = "enemyLightningResist", type = "integer", label = "적 ^xADAA47번개 저항:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("LightningResist", "BASE", val, "EnemyConfig")
	end },
	{ var = "enemyColdResist", type = "integer", label = "적 ^x3F6DB3냉기 저항:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ColdResist", "BASE", val, "EnemyConfig")
	end },
	{ var = "enemyFireResist", type = "integer", label = "적 ^xB97123화염 저항:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("FireResist", "BASE", val, "EnemyConfig")
	end },
	{ var = "enemyChaosResist", type = "integer", label = "적 ^xD02090카오스 저항:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ChaosResist", "BASE", val, "EnemyConfig")
	end },
	{ var = "enemyMaxResist", type = "check", label = "적 최대 저항이 항상 75%", tooltip = "Enemy Maximum resistance is increased by the resistance configurations \nThis locks it at the default value", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("DoNotChangeMaxResFromConfig", "FLAG", true, "EnemyConfig")
	end },
	{ var = "enemyBlockChance", type = "countAllowZero", label = "적 막기 확률:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("BlockChance", "BASE", val, "Config")
	end },
	{ var = "enemyEvasion", type = "countAllowZero", label = "적 기본 ^x33FF77회피:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Evasion", "BASE", val, "Config")
	end },
	{ var = "enemyArmour", type = "countAllowZero", label = "적 기본 방어구:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Armour", "BASE", val, "Config")
	end },
	{ var = "presetBossSkills", type = "list", defaultIndex = 1, label = "보스 스킬 프리셋", tooltipFunc = bossSkillsTooltip, list = data.bossSkillsList, apply = function(val, modList, enemyModList, build)
		if not (val == "None") then
			local bossData = data.bossSkills[val]
			local isUber = build.configTab.varControls['enemyIsBoss'].list[build.configTab.varControls['enemyIsBoss'].selIndex].val == "Uber"
			if bossData.earlierUber and build.configTab.varControls['enemyIsBoss'].list[build.configTab.varControls['enemyIsBoss'].selIndex].val == "Pinnacle" then
				isUber = true
			end
			local defaultDamage = ""
			build.configTab.varControls['enemyPhysicalDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyLightningDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyColdDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyFireDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyChaosDamage']:SetPlaceholder(defaultDamage, true)
			
			local rollRangeMult = m_min(m_max(build.configTab.input['enemyDamageRollRange'] or build.configTab.varControls['enemyDamageRollRange'].placeholder, 0), 100)
			for damageType, damageMult in pairs(bossData.DamageMultipliers) do
				if isUber and bossData.UberDamageMultiplier then
					build.configTab.varControls['enemy'..damageType..'Damage']:SetPlaceholder(round(data.monsterDamageTable[build.configTab.enemyLevel] * (damageMult[1] + rollRangeMult * damageMult[2]) * bossData.UberDamageMultiplier), true)
				else
					build.configTab.varControls['enemy'..damageType..'Damage']:SetPlaceholder(round(data.monsterDamageTable[build.configTab.enemyLevel] * (damageMult[1] + rollRangeMult * damageMult[2])), true)
				end
			end

			local defaultPen = ""
			build.configTab.varControls['enemyPhysicalOverwhelm']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyLightningPen']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyColdPen']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyFirePen']:SetPlaceholder(defaultPen, true)
			
			if bossData.DamagePenetrations then
				for penType, pen in pairs(bossData.DamagePenetrations) do
					if isUber and bossData.UberDamagePenetrations and bossData.UberDamagePenetrations[penType] then
						build.configTab.varControls['enemy'..penType]:SetPlaceholder(bossData.UberDamagePenetrations[penType], true)
					else
						build.configTab.varControls['enemy'..penType]:SetPlaceholder(pen, true)
					end
				end
			end
			
			if bossData.DamageType then
				build.configTab.varControls['enemyDamageType']:SelByValue(bossData.DamageType, "val")
				build.configTab.input['enemyDamageType'] = bossData.DamageType
			end
			build.configTab.varControls['enemyDamageType'].enabled = false
			
			if isUber and bossData.UberSpeed then
				build.configTab.varControls['enemySpeed']:SetPlaceholder(bossData.UberSpeed, true)
			elseif bossData.speed then
				build.configTab.varControls['enemySpeed']:SetPlaceholder(bossData.speed, true)
			end
			if bossData.critChance then
				build.configTab.varControls['enemyCritChance']:SetPlaceholder(bossData.critChance, true)
			end
			
			modList:NewMod("BossSkillActive", "FLAG", true, "Config")

			-- boss specific mods
			if val == "Atziri Flameblast" and isUber then
				enemyModList:NewMod("Damage", "INC", 60, "Alluring Abyss Map Mod")
			end
			if bossData.additionalStats then
				local additionalStats = isUber and bossData.additionalStats.uber or bossData.additionalStats.base
				if additionalStats then
					for k, v in pairs(additionalStats) do
						if tostring(v) == "flag" then
							enemyModList:NewMod(k, "FLAG", true, "BossSkillAdditionalData")
						else
							enemyModList:NewMod(k, "BASE", v, "BossSkillAdditionalData")
						end
					end
				end
			end
		else
			if build.configTab.varControls['enemyDamageType'].enabled == false then
				build.configTab.input['enemyDamageType'] = "Average"
				build.configTab.varControls['enemyDamageType']:SelByValue("Average", "val")
			end
			build.configTab.varControls['enemyDamageType'].enabled = true
		end
	end },
	{ var = "enemyDamageRollRange", type = "integer", label = "적 스킬 판정 범위 %:", ifFlag = "BossSkillActive", tooltip = "The percentage of the roll range the enemy hits for \n eg at 100% the enemy deals its maximum damage", defaultPlaceholderState = 70, hideIfInvalid = true },
	{ var = "enemyDamageType", type = "list", label = "적 피해 유형:", tooltip = "Controls which types of damage the EHP calculation uses:\n\tAverage: uses the Average of all typed damage types (except Damage Over Time and Untyped)\n\nIf a specific damage type is selected, that will be the only type used.", list = {
		{val="Average",label="평균"},
		{val="Untyped",label="미분류"},
		{val="DamageOverTime",label="지속 피해"},
		{val="Melee",label="근접"},
		{val="Projectile",label="투사체"},
		{val="Spell",label="주문"},
		{val="SpellProjectile",label="투사체 주문"}
	} },
	{ var = "enemySpeed", type = "countAllowZero", label = "적 공격/시전 시간 (ms):", defaultPlaceholderState = 700 },
	{ var = "enemyMultiplierPvpDamage", type = "count", label = "사용자 정의 PvP 피해 배율 %:", ifFlag = "isPvP", tooltip = "This multiplies the damage of a given skill in pvp, for instance any with damage multiplier specific to pvp (from skill or support or item like sire of shards)", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("MultiplierPvpDamage", "BASE", val, "Config")
	end },
	{ var = "enemyCritChance", type = "countAllowZero", label = "적 치명타 확률:", defaultPlaceholderState = 5 },
	{ var = "enemyCritDamage", type = "countAllowZero", label = "적 치명타 배율:", defaultPlaceholderState = data.monsterConstants["base_critical_strike_multiplier"] - 100 },
	{ var = "enemyPhysicalDamage", type = "countAllowZero", label = "적 스킬 물리 피해:", tooltip = "This overrides the default damage amount used to estimate your damage reduction from armour.\nThe default is 1.5 times the enemy's base damage, which is the same value\nused in-game to calculate the estimate shown on the character sheet.", defaultPlaceholderState = 7 },
	{ var = "enemyPhysicalOverwhelm", type = "countAllowZero", label = "적 스킬 물리 압도:"},
	{ var = "enemyLightningDamage", type = "countAllowZero", label = "적 스킬 ^xADAA47번개 피해:"},
	{ var = "enemyLightningPen", type = "countAllowZero", label = "적 스킬 ^xADAA47번개 관통:"},
	{ var = "enemyColdDamage", type = "countAllowZero", label = "적 스킬 ^x3F6DB3냉기 피해:"},
	{ var = "enemyColdPen", type = "countAllowZero", label = "적 스킬 ^x3F6DB3냉기 관통:"},
	{ var = "enemyFireDamage", type = "countAllowZero", label = "적 스킬 ^xB97123화염 피해:"},
	{ var = "enemyFirePen", type = "countAllowZero", label = "적 스킬 ^xB97123화염 관통:"},
	{ var = "enemyChaosDamage", type = "countAllowZero", label = "적 스킬 ^xD02090카오스 피해:"},
	
	-- Section: Custom mods
	{ section = "사용자 정의 속성 부여", col = 1 },
	{ var = "customMods", type = "text", label = "", doNotHighlight = true, resizable = true,
		apply = function(val, modList, enemyModList, build)
			for line in val:gmatch("([^\n]*)\n?") do
				local strippedLine = StripEscapes(line):gsub("^[%s?]+", ""):gsub("[%s?]+$", "")
				local mods, extra = modLib.parseMod(strippedLine)

				if mods and not extra then
					local source = "Custom"
					for i = 1, #mods do
						local mod = mods[i]

						if mod then
							mod = modLib.setSource(mod, source)
							modList:AddMod(mod)
						end
					end
				end
			end
		end,
		inactiveText = function(val)
			local inactiveText = ""
			for line in val:gmatch("([^\n]*)\n?") do
				local strippedLine = StripEscapes(line):gsub("^[%s?]+", ""):gsub("[%s?]+$", "")
				local mods, extra = modLib.parseMod(strippedLine)
				inactiveText = inactiveText .. ((mods and not extra) and colorCodes.MAGIC or colorCodes.UNSUPPORTED).. (IsKeyDown("ALT") and strippedLine or line) .. "\n"
			end
			return inactiveText
		end,
		tooltip = function(modList)
			if not launch.devModeAlt then
				return
			end

			local out
			for _, mod in ipairs(modList) do
				if mod.source == "Custom" then
					out = (out and out.."\n" or "") .. modLib.formatMod(mod) .. "|" .. mod.source
				end
			end
			return out
		end},
}

-- Path of Building
--
-- Class: Skill Set List
-- Skill set list control.
--
local t_insert = table.insert
local t_remove = table.remove
local m_max = math.max
local s_format = string.format

local SkillSetListClass = newClass("SkillSetListControl", "ListControl", function(self, anchor, rect, skillsTab)
	self.ListControl(anchor, rect, 16, "VERTICAL", true, skillsTab.skillSetOrderList)
	self.skillsTab = skillsTab
	self.controls.copy = new("ButtonControl", {"BOTTOMLEFT",self,"TOP"}, {2, -4, 60, 18}, "복사", function()
		local skillSet = skillsTab.skillSets[self.selValue]
		local newSkillSet = copyTable(skillSet, true)
		newSkillSet.socketGroupList = { }
		for socketGroupIndex, socketGroup in pairs(skillSet.socketGroupList) do
			local newGroup = copyTable(socketGroup, true)
			newGroup.gemList = { }
			for gemIndex, gem in pairs(socketGroup.gemList) do
				newGroup.gemList[gemIndex] = copyTable(gem, true)
			end
			t_insert(newSkillSet.socketGroupList, newGroup)
		end
		newSkillSet.id = 1
		while skillsTab.skillSets[newSkillSet.id] do
			newSkillSet.id = newSkillSet.id + 1
		end
		skillsTab.skillSets[newSkillSet.id] = newSkillSet
		self:RenameSet(newSkillSet, true)
	end)
	self.controls.copy.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.delete = new("ButtonControl", {"LEFT",self.controls.copy,"RIGHT"}, {4, 0, 60, 18}, "삭제", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil and #self.list > 1
	end
	self.controls.rename = new("ButtonControl", {"BOTTOMRIGHT",self,"TOP"}, {-2, -4, 60, 18}, "이름 변경", function()
		self:RenameSet(skillsTab.skillSets[self.selValue])
	end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.new = new("ButtonControl", {"RIGHT",self.controls.rename,"LEFT"}, {-4, 0, 60, 18}, "새로 만들기", function()
		self:RenameSet(skillsTab:NewSkillSet(), true)
	end)
end)

function SkillSetListClass:RenameSet(skillSet, addOnName)
	local controls = { }
	controls.label = new("LabelControl", nil, {0, 20, 0, 16}, "^7이 스킬 세트의 이름을 입력하세요:")
	controls.edit = new("EditControl", nil, {0, 40, 350, 20}, skillSet.title, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl", nil, {-45, 70, 80, 20}, "저장", function()
		skillSet.title = controls.edit.buf
		self.skillsTab.modFlag = true
		if addOnName then
			t_insert(self.list, skillSet.id)
			self.selIndex = #self.list
			self.selValue = skillSet.id
		end
		self.skillsTab:AddUndoState()
		self.skillsTab.build:SyncLoadouts()
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", nil, {45, 70, 80, 20}, "취소", function()
		if addOnName then
			self.skillsTab.skillSets[skillSet.id] = nil
		end
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, skillSet.title and "이름 변경" or "세트 이름", controls, "save", "edit", "cancel")
end

function SkillSetListClass:GetRowValue(column, index, skillSetId)
	local skillSet = self.skillsTab.skillSets[skillSetId]
	if column == 1 then
		return (skillSet.title or "Default") .. (skillSetId == self.skillsTab.activeSkillSetId and "  ^9(Current)" or "")
	end
end

function SkillSetListClass:OnOrderChange()
	self.skillsTab.modFlag = true
end

function SkillSetListClass:OnSelClick(index, skillSetId, doubleClick)
	if doubleClick and skillSetId ~= self.skillsTab.activeSkillSetId then
		self.skillsTab:SetActiveSkillSet(skillSetId)
		self.skillsTab:AddUndoState()
	end
end

function SkillSetListClass:OnSelDelete(index, skillSetId)
	local skillSet = self.skillsTab.skillSets[skillSetId]
	if #self.list > 1 then
		main:OpenConfirmPopup("스킬 세트 삭제", "'"..(skillSet.title or "Default").."'을(를) 정말 삭제하시겠습니까?", "삭제", function()
			t_remove(self.list, index)
			self.skillsTab.skillSets[skillSetId] = nil
			self.selIndex = nil
			self.selValue = nil
			if skillSetId == self.skillsTab.activeSkillSetId then
				self.skillsTab:SetActiveSkillSet(self.list[m_max(1, index - 1)])
			end
			self.skillsTab:AddUndoState()
			self.skillsTab.build:SyncLoadouts()
		end)
	end
end

function SkillSetListClass:OnSelKeyDown(index, skillSetId, key)
	if key == "F2" then
		self:RenameSet(self.skillsTab.skillSets[skillSetId])
	end
end

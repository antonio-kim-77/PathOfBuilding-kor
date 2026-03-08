-- Path of Building
--
-- Class: Config Set List
-- Config Set list control
--
local t_insert = table.insert
local t_remove = table.remove
local m_max = math.max

local ConfigSetListClass = newClass("ConfigSetListControl", "ListControl", function(self, anchor, rect, configTab)
	self.ListControl(anchor, rect, 16, "VERTICAL", true, configTab.configSetOrderList)
	self.configTab = configTab
	self.controls.copy = new("ButtonControl", {"BOTTOMLEFT",self,"TOP"}, {2, -4, 60, 18}, "복사", function()
		local configSet = configTab.configSets[self.selValue]
		local newConfigSet = copyTable(configSet)
		newConfigSet.id = 1
		while configTab.configSets[newConfigSet.id] do
			newConfigSet.id = newConfigSet.id + 1
		end
		configTab.configSets[newConfigSet.id] = newConfigSet
		self:RenameSet(newConfigSet, true)
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
		self:RenameSet(configTab.configSets[self.selValue])
	end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.new = new("ButtonControl", {"RIGHT",self.controls.rename,"LEFT"}, {-4, 0, 60, 18}, "새로 만들기", function()
		self:RenameSet(configTab:NewConfigSet(), true)
	end)
end)

function ConfigSetListClass:RenameSet(configSet, addOnName)
	local controls = { }
	controls.label = new("LabelControl", nil, {0, 20, 0, 16}, "^7이 설정 세트의 이름을 입력하세요:")
	controls.edit = new("EditControl", nil, {0, 40, 350, 20}, configSet.title, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl", nil, {-45, 70, 80, 20}, "저장", function()
		configSet.title = controls.edit.buf
		self.configTab.modFlag = true
		if addOnName then
			t_insert(self.list, configSet.id)
			self.selIndex = #self.list
			self.selValue = configSet.id
		end
		self.configTab:AddUndoState()
		self.configTab.build:SyncLoadouts()
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", nil, {45, 70, 80, 20}, "취소", function()
		if addOnName then
			self.configTab.configSets[configSet.id] = nil
		end
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, configSet.title and "이름 변경" or "세트 이름", controls, "save", "edit", "cancel")
end

function ConfigSetListClass:GetRowValue(column, index, configSetId)
	local configSet = self.configTab.configSets[configSetId]
	if column == 1 then
		return (configSet.title or "Default") .. (configSetId == self.configTab.activeConfigSetId and "  ^9(Current)" or "")
	end
end

function ConfigSetListClass:OnOrderChange()
	self.configTab.modFlag = true
end

function ConfigSetListClass:OnSelClick(index, configSetId, doubleClick)
	if doubleClick and configSetId ~= self.configTab.activeConfigSetId then
		self.configTab:SetActiveConfigSet(configSetId)
		self.configTab:AddUndoState()
	end
end

function ConfigSetListClass:OnSelDelete(index, configSetId)
	local configSet = self.configTab.configSets[configSetId]
	if #self.list > 1 then
		main:OpenConfirmPopup("설정 세트 삭제", "'"..(configSet.title or "Default").."'을(를) 정말 삭제하시겠습니까?", "삭제", function()
			t_remove(self.list, index)
			self.configTab.configSets[configSetId] = nil
			self.selIndex = nil
			self.selValue = nil
			if configSetId == self.configTab.activeConfigSetId then
				self.configTab:SetActiveConfigSet(self.list[m_max(1, index - 1)])
			end
			self.configTab:AddUndoState()
			self.configTab.build:SyncLoadouts()
		end)
	end
end

function ConfigSetListClass:OnSelKeyDown(index, configSetId, key)
	if key == "F2" then
		self:RenameSet(self.configTab.configSets[configSetId])
	end
end

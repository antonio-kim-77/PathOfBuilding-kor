-- Path of Building
--
-- Module: Import Tab
-- Import/Export tab for the current build.
--
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local b_rshift = bit.rshift
local band = bit.band

local realmList = {
	{ label = "PC", id = "PC", realmCode = "pc", hostName = "https://www.pathofexile.com/", profileURL = "account/view-profile/" },
	{ label = "Xbox", id = "XBOX", realmCode = "xbox", hostName = "https://www.pathofexile.com/", profileURL = "account/view-profile/" },
	{ label = "PS4", id = "SONY", realmCode = "sony", hostName = "https://www.pathofexile.com/", profileURL = "account/view-profile/" },
	{ label = "Hotcool", id = "PC", realmCode = "pc", hostName = "https://pathofexile.tw/", profileURL = "account/view-profile/" },
	{ label = "Tencent", id = "PC", realmCode = "pc", hostName = "https://poe.game.qq.com/", profileURL = "account/view-profile/" },
}

local influenceInfo = itemLib.influenceInfo.all

local ImportTabClass = newClass("ImportTab", "ControlHost", "Control", function(self, build)
	self.ControlHost()
	self.Control()

	self.build = build

	self.charImportMode = "GETACCOUNTNAME"
	self.charImportStatus = "대기 중"
	self.controls.sectionCharImport = new("SectionControl", {"TOPLEFT",self,"TOPLEFT"}, {10, 18, 650, 250}, "캐릭터 가져오기")
	self.controls.charImportStatusLabel = new("LabelControl", {"TOPLEFT",self.controls.sectionCharImport,"TOPLEFT"}, {6, 14, 200, 16}, function()
		return "^7캐릭터 가져오기 상태: "..self.charImportStatus
	end)

	-- Stage: input account name
	self.controls.accountNameHeader = new("LabelControl", {"TOPLEFT",self.controls.sectionCharImport,"TOPLEFT"}, {6, 40, 200, 16}, "^7캐릭터를 가져오려면 캐릭터의 계정 이름을 입력하세요:")
	self.controls.accountNameHeader.shown = function()
		return self.charImportMode == "GETACCOUNTNAME"
	end
	self.controls.accountRealm = new("DropDownControl", {"TOPLEFT",self.controls.accountNameHeader,"BOTTOMLEFT"}, {0, 4, 60, 20}, realmList )
	self.controls.accountRealm:SelByValue( main.lastRealm or "PC", "id" )
	self.controls.accountName = new("EditControl", {"LEFT",self.controls.accountRealm,"RIGHT"}, {8, 0, 200, 20}, main.lastAccountName or "", nil, "%c", nil, nil, nil, nil, true)
	self.controls.accountName.pasteFilter = function(text)
		return text:gsub(".", function(c)
			local byte = c:byte()
			if byte >= 128 then
				return string.format("%%%02X", byte)
			else
				return c
			end
		end)
	end
	-- accountHistory Control
	if not historyList then
		historyList = { }
		for accountName, account in pairs(main.gameAccounts) do
			t_insert(historyList, accountName)
			historyList[accountName] = true
		end
		table.sort(historyList, function(a,b)
			return a:lower() < b:lower()
		end)
	end -- don't load the list many times
	self.controls.accountNameGo = new("ButtonControl", {"LEFT",self.controls.accountName,"RIGHT"}, {8, 0, 60, 20}, "시작", function()
		self.controls.sessionInput.buf = ""
		self:DownloadCharacterList()
	end)
	self.controls.accountNameGo.enabled = function()
		return self.controls.accountName.buf:match("%S[#%-]%d%d%d%d$")
	end
	self.controls.accountNameGo.tooltipFunc = function(tooltip)
		tooltip:Clear()
		if not self.controls.accountName.buf:match("[#%-]%d%d%d%d$") and self.controls.accountName.buf ~= "" then
			tooltip:AddLine(16, "^7구분자가 누락되었습니다. 예: " .. self.controls.accountName.buf .. "#1234")
		end
	end

	self.controls.accountHistory = new("DropDownControl", {"LEFT",self.controls.accountNameGo,"RIGHT"}, {8, 0, 200, 20}, historyList, function()
		self.controls.accountName.buf = self.controls.accountHistory.list[self.controls.accountHistory.selIndex]
	end)
	self.controls.accountHistory:SelByValue(main.lastAccountName)
	self.controls.accountHistory:CheckDroppedWidth(true)

	self.controls.removeAccount = new("ButtonControl", {"LEFT",self.controls.accountHistory,"RIGHT"}, {8, 0, 20, 20}, "X", function()
		local accountName = self.controls.accountHistory.list[self.controls.accountHistory.selIndex]
		if (accountName ~= nil) then
		t_remove(self.controls.accountHistory.list, self.controls.accountHistory.selIndex)
		self.controls.accountHistory.list[accountName] = nil
		main.gameAccounts[accountName] = nil
		end
	end)

	self.controls.removeAccount.tooltipFunc = function(tooltip)
		tooltip:Clear()
		tooltip:AddLine(16, "^7드롭다운 목록에서 계정을 제거합니다")
	end

	self.controls.accountNameMissingDiscriminator = new("LabelControl", {"TOPLEFT",self.controls.accountName,"BOTTOMLEFT"}, {0, 8, 0, 16}, "^1구분자가 누락되었습니다. 예: #1234")
	self.controls.accountNameMissingDiscriminator.shown = function()
		return not self.controls.accountName.buf:match("[#%-]%d%d%d%d$") and self.controls.accountName.buf ~= ""
	end

	self.controls.accountNameUnicode = new("LabelControl", {"TOPLEFT",self.controls.accountRealm,"BOTTOMLEFT"}, {0, 34, 0, 14}, "^7참고: 계정 이름에 비ASCII 문자가 포함된 경우 직접 입력하지 말고\n텍스트 상자에 붙여넣어야 합니다.")

	-- Stage: input POESESSID
	self.controls.sessionHeader = new("LabelControl", {"TOPLEFT",self.controls.sectionCharImport,"TOPLEFT"}, {6, 40, 200, 14})
	self.controls.sessionHeader.label = function()
		return [[
^7']]..self.controls.accountName.buf..[[' 계정의 캐릭터 목록을 가져올 수 없습니다. 원인:
1. 계정 이름 끝에 구분자가 누락되었습니다 (예: #1234)
2. 계정 이름 대신 캐릭터 이름을 입력했습니다
3. 이 계정의 캐릭터 탭이 숨겨져 있습니다 (기본 설정).
본인 계정이라면:
1. 개인정보 설정에서 "캐릭터 숨기기"를 해제하거나
2. 아래에 POESESSID를 입력하세요.
Path of Exile 웹사이트에 로그인한 상태에서 웹 브라우저의 쿠키에서 가져올 수 있습니다.
		]]
	end
	self.controls.sessionHeader.shown = function()
		return self.charImportMode == "GETSESSIONID"
	end
	self.controls.sessionRetry = new("ButtonControl", {"TOPLEFT",self.controls.sessionHeader,"TOPLEFT"}, {0, 122, 60, 20}, "재시도", function()
		self:DownloadCharacterList()
	end)
	self.controls.sessionCancel = new("ButtonControl", {"LEFT",self.controls.sessionRetry,"RIGHT"}, {8, 0, 60, 20}, "취소", function()
		self.charImportMode = "GETACCOUNTNAME"
		self.charImportStatus = "대기 중"
	end)
	self.controls.sessionPrivacySettings = new("ButtonControl", {"LEFT",self.controls.sessionCancel,"RIGHT"}, {8, 0, 120, 20}, "개인정보 설정", function()
		OpenURL('https://www.pathofexile.com/my-account/privacy')
	end)
	self.controls.sessionInput = new("EditControl", {"TOPLEFT",self.controls.sessionRetry,"BOTTOMLEFT"}, {0, 8, 350, 20}, "", "POESESSID", "%X", 32)
	self.controls.sessionInput:SetProtected(true)
	self.controls.sessionGo = new("ButtonControl", {"LEFT",self.controls.sessionInput,"RIGHT"}, {8, 0, 60, 20}, "이동", function()
		self:DownloadCharacterList()
	end)
	self.controls.sessionGo.enabled = function()
		return #self.controls.sessionInput.buf == 32
	end

	-- Stage: select character and import data
	self.controls.charSelectHeader = new("LabelControl", {"TOPLEFT",self.controls.sectionCharImport,"TOPLEFT"}, {6, 40, 200, 16}, "^7데이터를 가져올 캐릭터를 선택하세요:")
	self.controls.charSelectHeader.shown = function()
		return self.charImportMode == "SELECTCHAR" or self.charImportMode == "IMPORTING"
	end
	self.controls.charSelectLeagueLabel = new("LabelControl", {"TOPLEFT",self.controls.charSelectHeader,"BOTTOMLEFT"}, {0, 6, 0, 14}, "^7리그:")
	self.controls.charSelectLeague = new("DropDownControl", {"LEFT",self.controls.charSelectLeagueLabel,"RIGHT"}, {4, 0, 150, 18}, nil, function(index, value)
		self:BuildCharacterList(value.league)
	end)
	self.controls.charSelect = new("DropDownControl", {"TOPLEFT",self.controls.charSelectHeader,"BOTTOMLEFT"}, {0, 24, 400, 18})
	self.controls.charSelect.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.charImportHeader = new("LabelControl", {"TOPLEFT",self.controls.charSelect,"BOTTOMLEFT"}, {0, 16, 200, 16}, "^7가져오기:")
	self.controls.charImportTree = new("ButtonControl", {"LEFT",self.controls.charImportHeader, "RIGHT"}, {8, 0, 170, 20}, "패시브 트리와 주얼", function()
		if self.build.spec:CountAllocNodes() > 0 then
			main:OpenConfirmPopup("캐릭터 가져오기", "패시브 트리를 가져오면 현재 트리를 덮어씁니다.", "가져오기", function()
				self:DownloadPassiveTree()
			end)
		else
			self:DownloadPassiveTree()
		end
		self:SetPredefinedBuildName()
	end)
	self.controls.charImportTree.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.charImportTreeClearJewels = new("CheckBoxControl", {"LEFT",self.controls.charImportTree,"RIGHT"}, {90, 0, 18}, "주얼 삭제:", nil, "가져올 때 기존 주얼을 모두 삭제합니다.", true)
	self.controls.charImportItems = new("ButtonControl", {"LEFT",self.controls.charImportTree, "LEFT"}, {0, 36, 110, 20}, "아이템과 스킬", function()
		self:DownloadItems()
		self:SetPredefinedBuildName()
	end)
	self.controls.charImportItems.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.charImportItemsClearSkills = new("CheckBoxControl", {"LEFT",self.controls.charImportItems,"RIGHT"}, {85, 0, 18}, "스킬 삭제:", nil, "가져올 때 기존 스킬을 모두 삭제합니다.", true)
	self.controls.charImportItemsClearItems = new("CheckBoxControl", {"LEFT",self.controls.charImportItems,"RIGHT"}, {220, 0, 18}, "장비 삭제:", nil, "가져올 때 장착된 아이템을 모두 삭제합니다.", true)
	self.controls.charImportItemsIgnoreWeaponSwap = new("CheckBoxControl", {"LEFT",self.controls.charImportItems,"RIGHT"}, {380, 0, 18}, "무기 교체 무시:", nil, "무기 교체의 아이템과 스킬을 무시합니다.", false)
	self.controls.charBanditNote = new("LabelControl", {"TOPLEFT",self.controls.charImportHeader,"BOTTOMLEFT"}, {0, 50, 200, 14}, "^7팁: 캐릭터 가져오기를 완료한 후 도적 선택을 업데이트하세요.\n도적 선택은 가져올 수 없습니다.")

	self.controls.charClose = new("ButtonControl", {"TOPLEFT",self.controls.charImportHeader,"BOTTOMLEFT"}, {0, 90, 60, 20}, "닫기", function()
		self.charImportMode = "GETACCOUNTNAME"
		self.charImportStatus = "대기 중"
	end)

	-- Build import/export
	self.controls.sectionBuild = new("SectionControl", {"TOPLEFT",self.controls.sectionCharImport,"BOTTOMLEFT"}, {0, 18, 650, 182}, "빌드 공유")
	self.controls.generateCodeLabel = new("LabelControl", {"TOPLEFT",self.controls.sectionBuild,"TOPLEFT"}, {6, 14, 0, 16}, "^7다른 Path of Building 사용자와 이 빌드를 공유할 코드를 생성하세요:")
	self.controls.generateCode = new("ButtonControl", {"LEFT",self.controls.generateCodeLabel,"RIGHT"}, {4, 0, 80, 20}, "생성", function()
		self.controls.generateCodeOut:SetText(common.base64.encode(Deflate(self.build:SaveDB("code"))):gsub("+","-"):gsub("/","_"))
	end)
	self.controls.enablePartyExportBuffs = new("CheckBoxControl", {"LEFT",self.controls.generateCode,"RIGHT"}, {100, 0, 18}, "서포트 내보내기", function(state)
		self.build.partyTab.enableExportBuffs = state
		self.build.buildFlag = true
	end, "파티 플레이용으로, 서포트 캐릭터를 내보냅니다. 오라, 저주 및 적 수정자를 내보낼 수 있습니다.", false)
	self.controls.generateCodeOut = new("EditControl", {"TOPLEFT",self.controls.generateCodeLabel,"BOTTOMLEFT"}, {0, 8, 250, 20}, "", "코드", "%Z")
	self.controls.generateCodeOut.enabled = function()
		return #self.controls.generateCodeOut.buf > 0
	end
	self.controls.generateCodeCopy = new("ButtonControl", {"LEFT",self.controls.generateCodeOut,"RIGHT"}, {8, 0, 60, 20}, "복사", function()
		Copy(self.controls.generateCodeOut.buf)
		self.controls.generateCodeOut:SetText("")
	end)
	self.controls.generateCodeCopy.enabled = function()
		return #self.controls.generateCodeOut.buf > 0
	end

	local getExportSitesFromImportList = function()
		local exportWebsites = { }
		for k,v in pairs(buildSites.websiteList) do
			-- if entry has fields needed for Export
			if buildSites.websiteList[k].postUrl and buildSites.websiteList[k].postFields and buildSites.websiteList[k].codeOut then
				table.insert(exportWebsites, v)
			end
		end
		return exportWebsites
	end
	local exportWebsitesList = getExportSitesFromImportList()

	self.controls.exportFrom = new("DropDownControl", { "LEFT", self.controls.generateCodeCopy,"RIGHT"}, {8, 0, 120, 20}, exportWebsitesList, function(_, selectedWebsite)
		main.lastExportedWebsite = selectedWebsite.id
		self.exportWebsiteSelected = selectedWebsite.id
	end)
	self.controls.exportFrom:SelByValue(self.exportWebsiteSelected or main.lastExportedWebsite or "Maxroll", "id")
	self.controls.generateCodeByLink = new("ButtonControl", { "LEFT", self.controls.exportFrom, "RIGHT"}, {8, 0, 100, 20}, "공유", function()
		local exportWebsite = exportWebsitesList[self.controls.exportFrom.selIndex]
		local subScriptId = buildSites.UploadBuild(self.controls.generateCodeOut.buf, exportWebsite)
		if subScriptId then
			self.controls.generateCodeOut:SetText("")
			self.controls.generateCodeByLink.label = "링크 생성 중..."
			launch:RegisterSubScript(subScriptId, function(pasteLink, errMsg)
				self.controls.generateCodeByLink.label = "공유"
				if errMsg then
					main:OpenMessagePopup(exportWebsite.id, "링크 생성 오류:\n"..errMsg)
				else
					self.controls.generateCodeOut:SetText(exportWebsite.codeOut..pasteLink)
				end
			end)
		end
	end)
	self.controls.generateCodeByLink.enabled = function()
		for _, exportSite in ipairs(exportWebsitesList) do
			if #self.controls.generateCodeOut.buf > 0 and self.controls.generateCodeOut.buf:match(exportSite.matchURL) then
				return false
			end
		end
		return #self.controls.generateCodeOut.buf > 0
	end
	self.controls.exportFrom.enabled = function()
		for _, exportSite in ipairs(exportWebsitesList) do
			if #self.controls.generateCodeOut.buf > 0 and self.controls.generateCodeOut.buf:match(exportSite.matchURL) then
				return false
			end
		end
		return #self.controls.generateCodeOut.buf > 0
	end
	self.controls.generateCodeNote = new("LabelControl", {"TOPLEFT",self.controls.generateCodeOut,"BOTTOMLEFT"}, {0, 4, 0, 14}, "^7참고: 이 코드는 매우 길 수 있습니다. '공유'를 사용하여 단축할 수 있습니다.")
	self.controls.importCodeHeader = new("LabelControl", {"TOPLEFT",self.controls.generateCodeNote,"BOTTOMLEFT"}, {0, 26, 0, 16}, "^7빌드를 가져오려면 여기에 URL 또는 코드를 입력하세요:")

	local importCodeHandle = function (buf)
		self.importCodeSite = nil
		self.importCodeDetail = ""
		self.importCodeXML = nil
		self.importCodeValid = false

		if #buf == 0 then
			return
		end

		if not self.build.dbFileName then
			self.controls.importCodeMode.selIndex = 2
		end

		self.importCodeDetail = colorCodes.NEGATIVE.."잘못된 입력"
		local urlText = buf:gsub("^[%s?]+", ""):gsub("[%s?]+$", "") -- Quick Trim
		if urlText:match("youtube%.com/redirect%?") or urlText:match("google%.com/url%?") then
			local nested_url = urlText:gsub(".*[?&]q=([^&]+).*", "%1")
			urlText = UrlDecode(nested_url)
		end

		for j=1,#buildSites.websiteList do
			if urlText:match(buildSites.websiteList[j].matchURL) then
				self.controls.importCodeIn.text = urlText
				self.importCodeValid = true
				self.importCodeDetail = colorCodes.POSITIVE.."유효한 URL ("..buildSites.websiteList[j].label..")"
				self.importCodeSite = j
				if buf ~= urlText then
					self.controls.importCodeIn:SetText(urlText, false)
				end
				return
			end
		end

		local xmlText = Inflate(common.base64.decode(buf:gsub("-","+"):gsub("_","/")))
		if not xmlText then
			return
		end
		if launch.devMode and IsKeyDown("SHIFT") then
			Copy(xmlText)
		end
		self.importCodeValid = true
		self.importCodeDetail = colorCodes.POSITIVE.."유효한 코드"
		self.importCodeXML = xmlText
	end

	local importSelectedBuild = function()
		if not self.importCodeValid or self.importCodeFetching then
			return
		end

		if self.controls.importCodeMode.selIndex == 1 then
			main:OpenConfirmPopup("빌드 가져오기", colorCodes.WARNING.."경고:^7 현재 빌드로 가져오면 이 빌드의 모든 기존 데이터가 삭제됩니다.", "가져오기", function()
				self.build:Shutdown()
				self.build:Init(self.build.dbFileName, self.build.buildName, self.importCodeXML, false, self.importCodeSite and self.controls.importCodeIn.buf or nil)
				self.build.viewMode = "TREE"
			end)
		else
			self.build:Shutdown()
			self.build:Init(false, "가져온 빌드", self.importCodeXML, false, self.importCodeSite and self.controls.importCodeIn.buf or nil)
			self.build.viewMode = "TREE"
		end
	end

	self.controls.importCodeIn = new("EditControl", {"TOPLEFT",self.controls.importCodeHeader,"BOTTOMLEFT"}, {0, 4, 328, 20}, "", nil, nil, nil, importCodeHandle, nil, nil, true)
	self.controls.importCodeIn.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeGo.onClick()
		end
	end
	self.controls.importCodeState = new("LabelControl", {"LEFT",self.controls.importCodeIn,"RIGHT"}, {8, 0, 0, 16})
	self.controls.importCodeState.label = function()
		return self.importCodeDetail or ""
	end
	self.controls.importCodeMode = new("DropDownControl", {"TOPLEFT",self.controls.importCodeIn,"BOTTOMLEFT"}, {0, 4, 160, 20}, { "현재 빌드에 가져오기", "새 빌드로 가져오기" })
	self.controls.importCodeMode.enabled = function()
		return self.build.dbFileName and self.importCodeValid
	end
	self.controls.importCodeGo = new("ButtonControl", {"LEFT",self.controls.importCodeMode,"RIGHT"}, {8, 0, 160, 20}, "가져오기", function()
		if self.importCodeSite and not self.importCodeXML then
			self.importCodeFetching = true
			local selectedWebsite = buildSites.websiteList[self.importCodeSite]
			buildSites.DownloadBuild(self.controls.importCodeIn.buf, selectedWebsite, function(isSuccess, data)
				self.importCodeFetching = false
				if not isSuccess then
					self.importCodeDetail = colorCodes.NEGATIVE..data
					self.importCodeValid = false
				else
					importCodeHandle(data)
					importSelectedBuild()
				end
			end)
			return
		end

		importSelectedBuild()
	end)
	self.controls.importCodeGo.label = function ()
		return self.importCodeFetching and "가져오는 중.." or "가져오기"
	end
	self.controls.importCodeGo.enabled = function()
		return self.importCodeValid and not self.importCodeFetching
	end
	self.controls.importCodeGo.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeGo.onClick()
		end
	end
end)

function ImportTabClass:Load(xml, fileName)
	self.lastRealm = xml.attrib.lastRealm
	self.controls.accountRealm:SelByValue( self.lastRealm or main.lastRealm or "PC", "id" )
	self.lastAccountHash = xml.attrib.lastAccountHash
	self.importLink = xml.attrib.importLink
	self.controls.enablePartyExportBuffs.state = xml.attrib.exportParty == "true"
	self.build.partyTab.enableExportBuffs = self.controls.enablePartyExportBuffs.state
	if self.lastAccountHash then
		for accountName in pairs(main.gameAccounts) do
			if common.sha1(accountName) == self.lastAccountHash then
				self.controls.accountName:SetText(accountName)
			end
		end
	end
	self.lastCharacterHash = xml.attrib.lastCharacterHash
end

function ImportTabClass:Save(xml)
	xml.attrib = {
		lastRealm = self.lastRealm,
		lastAccountHash = self.lastAccountHash,
		lastCharacterHash = self.lastCharacterHash,
		exportParty = tostring(self.controls.enablePartyExportBuffs.state),
		importLink = self.importLink
	}

	if self.build.importLink then
		xml.attrib.importLink = self.build.importLink
	end
	-- Gets rid of erroneous, potentially infinitely nested full base64 XML stored as an import link
	xml.attrib.importLink = (xml.attrib.importLink and xml.attrib.importLink:len() < 100) and xml.attrib.importLink or nil 
end

function ImportTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	self:ProcessControlsInput(inputEvents, viewPort)

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)
end

function ImportTabClass:DownloadCharacterList()
	self.charImportMode = "DOWNLOADCHARLIST"
	self.charImportStatus = "캐릭터 목록 가져오는 중..."
	local realm = realmList[self.controls.accountRealm.selIndex]
	local accountName
	-- Handle spaces in the account name
	if realm.realmCode == "pc" then
		accountName = self.controls.accountName.buf:gsub("%s+", "")
	else
		accountName = self.controls.accountName.buf:gsub("^[%s?]+", ""):gsub("[%s?]+$", ""):gsub("%s", "+")
	end
	accountName = accountName:gsub("(.*)[#%-]", "%1#")
	local sessionID = #self.controls.sessionInput.buf == 32 and self.controls.sessionInput.buf or (main.gameAccounts[accountName] and main.gameAccounts[accountName].sessionID)
	launch:DownloadPage(realm.hostName.."character-window/get-characters?accountName="..accountName:gsub("#", "%%23").."&realm="..realm.realmCode, function(response, errMsg)
		if errMsg == "Response code: 401" then
			self.charImportStatus = colorCodes.NEGATIVE.."로그인이 필요합니다."
			self.charImportMode = "GETSESSIONID"
			return
		elseif errMsg == "Response code: 403" then
			self.charImportStatus = colorCodes.NEGATIVE.."계정 프로필이 비공개입니다."
			self.charImportMode = "GETSESSIONID"
			return
		elseif errMsg == "Response code: 404" then
			self.charImportStatus = colorCodes.NEGATIVE.."계정 이름이 올바르지 않습니다."
			self.charImportMode = "GETACCOUNTNAME"
			return
		elseif errMsg then
			self.charImportStatus = colorCodes.NEGATIVE.."캐릭터 목록 가져오기 오류, 다시 시도하세요 ("..errMsg:gsub("\n"," ")..")"
			self.charImportMode = "GETACCOUNTNAME"
			return
		end
		local charList, errMsg = self:ProcessJSON(response.body)
		if errMsg then
			self.charImportStatus = colorCodes.NEGATIVE.."캐릭터 목록 처리 오류, 나중에 다시 시도하세요"
			self.charImportMode = "GETACCOUNTNAME"
			return
		end
		--ConPrintTable(charList)
		if #charList == 0 then
			self.charImportStatus = colorCodes.NEGATIVE.."이 계정에는 가져올 캐릭터가 없습니다."
			self.charImportMode = "GETACCOUNTNAME"
			return
		end
		-- GGG's character API has an issue where for /get-characters the account name is not case-sensitive, but for /get-passive-skills and /get-items it is.
		-- This workaround grabs the profile page and extracts the correct account name from one of the URLs.
		launch:DownloadPage(realm.hostName..realm.profileURL..accountName:gsub("#", "%%23"), function(response, errMsg)
			if errMsg then
				self.charImportStatus = colorCodes.NEGATIVE.."캐릭터 목록 가져오기 오류, 다시 시도하세요 ("..errMsg:gsub("\n"," ")..")"
				self.charImportMode = "GETACCOUNTNAME"
				return
			end
			local realAccountName = response.body:match("/view%-profile/([^/]+)/characters"):gsub(".", function(c) if c:byte(1) > 127 then return string.format("%%%2X",c:byte(1)) else return c end end)
			if not realAccountName then
				self.charImportStatus = colorCodes.NEGATIVE.."캐릭터 목록을 가져오지 못했습니다."
				self.charImportMode = "GETSESSIONID"
				return
			end
			realAccountName = realAccountName:gsub("(.*)[#%-]", "%1#")
			accountName = realAccountName
			self.controls.accountName:SetText(realAccountName)
			self.charImportStatus = "캐릭터 목록을 성공적으로 가져왔습니다."
			self.charImportMode = "SELECTCHAR"
			self.lastRealm = realm.id
			main.lastRealm = realm.id
			self.lastAccountHash = common.sha1(accountName)
			main.lastAccountName = accountName
			main.gameAccounts[accountName] = main.gameAccounts[accountName] or { }
			main.gameAccounts[accountName].sessionID = sessionID
			local leagueList = { }
			for i, char in ipairs(charList) do
				if not isValueInArray(leagueList, char.league) then
					t_insert(leagueList, char.league)
				end
			end
			table.sort(leagueList)
			wipeTable(self.controls.charSelectLeague.list)
			for _, league in ipairs(leagueList) do
				t_insert(self.controls.charSelectLeague.list, {
					label = league,
					league = league,
				})
			end
			t_insert(self.controls.charSelectLeague.list, {
				label = "전체",
			})
			if self.controls.charSelectLeague.selIndex > #self.controls.charSelectLeague.list then
				self.controls.charSelectLeague.selIndex = 1
			end
			self.lastCharList = charList
			self:BuildCharacterList(self.controls.charSelectLeague:GetSelValueByKey("league"))

			-- We only get here if the accountname was correct, found, and not private, so add it to the account history.
			self:SaveAccountHistory()
		end, sessionID and { header = "Cookie: POESESSID=" .. sessionID })
	end, sessionID and { header = "Cookie: POESESSID=" .. sessionID })
end

function ImportTabClass:BuildCharacterList(league)
	wipeTable(self.controls.charSelect.list)
	for i, char in ipairs(self.lastCharList) do
		if not league or char.league == league then
			charLvl = char.level or 0
			charLeague = char.league or "?"
			charName = char.name or "?"
			charClass = char.class or "?"

			classColor = colorCodes.DEFAULT
			if charClass ~= "?" then
				classColor = colorCodes[charClass:upper()]

				if classColor == nil then
					if (charClass == "Elementalist" or charClass == "Necromancer" or charClass == "Occultist" or
						charClass == "Harbinger" or charClass == "Herald" or charClass == "Bog Shaman") then
						classColor = colorCodes["WITCH"]
					elseif (charClass == "Guardian" or charClass == "Inquisitor" or charClass == "Hierophant" or
						charClass == "Architect of Chaos" or charClass == "Polytheist" or charClass == "Puppeteer") then
						classColor = colorCodes["TEMPLAR"]
					elseif (charClass == "Assassin" or charClass == "Trickster" or charClass == "Saboteur" or
						charClass == "Surfcaster" or charClass == "Servant of Arakaali" or charClass == "Blind Prophet") then
						classColor = colorCodes["SHADOW"]
					elseif (charClass == "Gladiator" or charClass == "Slayer" or charClass == "Champion" or
						charClass == "Gambler" or charClass == "Paladin" or charClass == "Aristocrat") then
						classColor = colorCodes["DUELIST"]
					elseif (charClass == "Raider" or charClass == "Pathfinder" or charClass == "Deadeye" or charClass == "Warden" or
						charClass == "Daughter of Oshabi" or charClass == "Whisperer" or charClass == "Wildspeaker") then
						classColor = colorCodes["RANGER"]
					elseif (charClass == "Juggernaut" or charClass == "Berserker" or charClass == "Chieftain" or
						charClass == "Antiquarian" or charClass == "Behemoth" or charClass == "Ancestral Commander") then
						classColor = colorCodes["MARAUDER"]
					elseif (charClass == "Ascendant" or charClass == "Reliquarian" or charClass == "Scavenger") then
						classColor = colorCodes["SCION"]
					end
				end
			end

			local detail
			if league == nil then
				detail = string.format("%s%s ^x808080lvl %d in %s", classColor, charClass, charLvl, charLeague)
			else
				detail = string.format("%s%s ^x808080lvl %d", classColor, charClass, charLvl)
			end
			t_insert(self.controls.charSelect.list, {
				label = charName,
				char = char,
				searchFilter = charName.." "..charClass,
				detail = detail
			})
		end
	end
	table.sort(self.controls.charSelect.list, function(a,b)
		return a.char.name:lower() < b.char.name:lower()
	end)
	self.controls.charSelect.selIndex = 1
	if self.lastCharacterHash then
		for i, char in ipairs(self.controls.charSelect.list) do
			if common.sha1(char.char.name) == self.lastCharacterHash then
				self.controls.charSelect.selIndex = i
				break
			end
		end
	end
end

function ImportTabClass:SaveAccountHistory()
	if not historyList[self.controls.accountName.buf] then
		t_insert(historyList, self.controls.accountName.buf)
		historyList[self.controls.accountName.buf] = true
		table.sort(historyList, function(a,b)
			return a:lower() < b:lower()
		end)
		self.controls.accountHistory:CheckDroppedWidth(true)
		self.controls.accountHistory:SelByValue(self.controls.accountName.buf)
	end
end

function ImportTabClass:DownloadPassiveTree()
	self.charImportMode = "IMPORTING"
	self.charImportStatus = "캐릭터 패시브 트리 가져오는 중..."
	local realm = realmList[self.controls.accountRealm.selIndex]
	local accountName = self.controls.accountName.buf
	local sessionID = #self.controls.sessionInput.buf == 32 and self.controls.sessionInput.buf or (main.gameAccounts[accountName] and main.gameAccounts[accountName].sessionID)
	local charSelect = self.controls.charSelect
	local charData = charSelect.list[charSelect.selIndex].char
	launch:DownloadPage(realm.hostName.."character-window/get-passive-skills?accountName="..accountName:gsub("#", "%%23").."&character="..urlEncode(charData.name).."&realm="..realm.realmCode, function(response, errMsg)
		self.charImportMode = "SELECTCHAR"
		if errMsg then
			self.charImportStatus = colorCodes.NEGATIVE.."캐릭터 데이터 가져오기 오류, 다시 시도하세요 ("..errMsg:gsub("\n"," ")..")"
			return
		elseif response.body == "false" then
			self.charImportStatus = colorCodes.NEGATIVE.."캐릭터 데이터를 가져오지 못했습니다. 다시 시도하세요."
			return
		end
		self.lastCharacterHash = common.sha1(charData.name)
		self:ImportPassiveTreeAndJewels(response.body, charData)
	end, sessionID and { header = "Cookie: POESESSID=" .. sessionID })
end

function ImportTabClass:DownloadItems()
	self.charImportMode = "IMPORTING"
	self.charImportStatus = "캐릭터 아이템 가져오는 중..."
	local realm = realmList[self.controls.accountRealm.selIndex]
	local accountName = self.controls.accountName.buf
	local sessionID = #self.controls.sessionInput.buf == 32 and self.controls.sessionInput.buf or (main.gameAccounts[accountName] and main.gameAccounts[accountName].sessionID)
	local charSelect = self.controls.charSelect
	local charData = charSelect.list[charSelect.selIndex].char
	launch:DownloadPage(realm.hostName.."character-window/get-items?accountName="..accountName:gsub("#", "%%23").."&character="..urlEncode(charData.name).."&realm="..realm.realmCode, function(response, errMsg)
		self.charImportMode = "SELECTCHAR"
		if errMsg then
			self.charImportStatus = colorCodes.NEGATIVE.."캐릭터 데이터 가져오기 오류, 다시 시도하세요 ("..errMsg:gsub("\n"," ")..")"
			return
		elseif response.body == "false" then
			self.charImportStatus = colorCodes.NEGATIVE.."캐릭터 데이터를 가져오지 못했습니다. 다시 시도하세요."
			return
		end
		self.lastCharacterHash = common.sha1(charData.name)
		self:ImportItemsAndSkills(response.body)
	end, sessionID and { header = "Cookie: POESESSID=" .. sessionID })
end

function ImportTabClass:ImportPassiveTreeAndJewels(json, charData)
	--local out = io.open("get-passive-skills.json", "w")
	--out:write(json)
	--out:close()
	local charPassiveData, errMsg = self:ProcessJSON(json)
	--local out = io.open("get-passive-skills.json", "w")
	--writeLuaTable(out, charPassiveData, 1)
	--out:close()

	-- 3.16+
	if charPassiveData.mastery_effects then
		local mastery, effect = 0, 0
		for key, value in pairs(charPassiveData.mastery_effects) do
			if type(value) ~= "string" then
				break
			end
			mastery = band(tonumber(value), 65535)
			effect = b_rshift(tonumber(value), 16)
			t_insert(charPassiveData.mastery_effects, mastery, effect)
		end
	end

	if charPassiveData.skill_overrides then
		for nodeId, override in pairs(charPassiveData.skill_overrides) do
			self.build.spec:ReplaceNode(override, self.build.spec.tree.tattoo.nodes[override.name])
			override.id = nodeId
		end
	end

	if errMsg then
		self.charImportStatus = colorCodes.NEGATIVE.."캐릭터 데이터 처리 오류, 나중에 다시 시도하세요."
		return
	end
	self.charImportStatus = colorCodes.POSITIVE.."패시브 트리와 주얼을 성공적으로 가져왔습니다."
	self.build.spec.jewel_data = copyTable(charPassiveData.jewel_data)
	self.build.spec.extended_hashes = copyTable(charPassiveData.hashes_ex)
	--ConPrintTable(charPassiveData)
	if self.controls.charImportTreeClearJewels.state then
		for _, slot in pairs(self.build.itemsTab.slots) do
			if slot.selItemId ~= 0 and slot.nodeId then
				self.build.itemsTab.build.spec.ignoreAllocatingSubgraph = true -- ignore allocated cluster nodes on Import when Delete Jewel is true, clean slate
				self.build.itemsTab:DeleteItem(self.build.itemsTab.items[slot.selItemId])
			end
		end
	end
	for _, itemData in pairs(charPassiveData.items) do
		self:ImportItem(itemData)
	end
	self.build.itemsTab:PopulateSlots()
	self.build.itemsTab:AddUndoState()

	-- Alternate trees don't have an identifier, so we're forced to look up something that is unique to that tree
	-- Hopefully this changes, because it's totally unmaintainable
	local function isAscendancyInTree(className, treeVersion)
		local classes = main.tree[treeVersion].classes
		for _, class in pairs(classes) do
			if class.name == className then
				return true
			end
			for i = 0, #class.classes do
				local ascendClass = class.classes[i]
				if ascendClass.name == className then
					return true
				end
			end
		end
	end

	self.build.spec:ImportFromNodeList(charPassiveData.character, 
		charPassiveData.ascendancy, 
		charPassiveData.alternate_ascendancy or 0, 
		charPassiveData.hashes, 
		charPassiveData.skill_overrides, 
		charPassiveData.mastery_effects or {}, 
		latestTreeVersion .. (charData.league:match("Ruthless") and "_ruthless" or "") .. (isAscendancyInTree(charData.class, latestTreeVersion) and "" or "_alternate")
	)
	self.build.treeTab:SetActiveSpec(self.build.treeTab.activeSpec)
	self.build.spec:BuildClusterJewelGraphs()
	self.build.spec:AddUndoState()
	self.build.characterLevel = charData.level
	self.build.characterLevelAutoMode = false
	self.build.configTab:UpdateLevel()
	self.build.controls.characterLevel:SetText(charData.level)
	self.build:EstimatePlayerProgress()
	local resistancePenaltyIndex = 3
	if self.build.Act then -- Estimate resistance penalty setting based on act progression estimate
		if type(self.build.Act) == "string" and self.build.Act == "Endgame" then resistancePenaltyIndex = 3
		elseif type(self.build.Act) == "number" then 
			if self.build.Act < 5 then resistancePenaltyIndex = 1
			elseif self.build.Act > 5 and self.build.Act < 11 then resistancePenaltyIndex = 2
			elseif self.build.Act > 10 then resistancePenaltyIndex = 3 end
		end
	end
	self.build.configTab.varControls["resistancePenalty"]:SetSel(resistancePenaltyIndex)
	main:SetWindowTitleSubtext(string.format("%s (%s, %s, %s)", self.build.buildName, charData.name, charData.class, charData.league))
end

function ImportTabClass:ImportItemsAndSkills(json)
	--local out = io.open("get-items.json", "w")
	--out:write(json)
	--out:close()
	local charItemData, errMsg = self:ProcessJSON(json)
	if errMsg then
		self.charImportStatus = colorCodes.NEGATIVE.."캐릭터 데이터 처리 오류, 나중에 다시 시도하세요."
		return
	end
	if self.controls.charImportItemsClearItems.state then
		for _, slot in pairs(self.build.itemsTab.slots) do
			if slot.selItemId ~= 0 and not slot.nodeId then
				self.build.itemsTab:DeleteItem(self.build.itemsTab.items[slot.selItemId])
			end
		end
	end

	local mainSkillEmpty = #self.build.skillsTab.socketGroupList == 0
	local skillOrder
	if self.controls.charImportItemsClearSkills.state then
		skillOrder = { }
		for _, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
			for _, gem in ipairs(socketGroup.gemList) do
				if gem.grantedEffect and not gem.grantedEffect.support then
					t_insert(skillOrder, gem.grantedEffect.name)
				end
			end
		end
		wipeTable(self.build.skillsTab.socketGroupList)
	end
	self.charImportStatus = colorCodes.POSITIVE.."아이템과 스킬을 성공적으로 가져왔습니다."
	--ConPrintTable(charItemData)
	for _, itemData in pairs(charItemData.items) do
		self:ImportItem(itemData)
	end
	if skillOrder then
		local groupOrder = { }
		for index, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
			groupOrder[socketGroup] = index
		end
		table.sort(self.build.skillsTab.socketGroupList, function(a, b)
			local orderA
			for _, gem in ipairs(a.gemList) do
				if gem.grantedEffect and not gem.grantedEffect.support then
					local i = isValueInArray(skillOrder, gem.grantedEffect.name)
					if i and (not orderA or i < orderA) then
						orderA = i
					end
				end
			end
			local orderB
			for _, gem in ipairs(b.gemList) do
				if gem.grantedEffect and not gem.grantedEffect.support then
					local i = isValueInArray(skillOrder, gem.grantedEffect.name)
					if i and (not orderB or i < orderB) then
						orderB = i
					end
				end
			end
			if orderA and orderB then
				if orderA ~= orderB then
					return orderA < orderB
				else
					return groupOrder[a] < groupOrder[b]
				end
			elseif not orderA and not orderB then
				return groupOrder[a] < groupOrder[b]
			else
				return orderA
			end
		end)
	end
	if mainSkillEmpty then
		self.build.mainSocketGroup = self:GuessMainSocketGroup()
	end
	self.build.itemsTab:PopulateSlots()
	self.build.itemsTab:AddUndoState()
	self.build.skillsTab:AddUndoState()
	self.build.characterLevel = charItemData.character.level
	self.build.configTab:UpdateLevel()
	self.build.controls.characterLevel:SetText(charItemData.character.level)
	self.build.buildFlag = true
	return charItemData.character -- For the wrapper
end

local rarityMap = { [0] = "NORMAL", "MAGIC", "RARE", "UNIQUE", [9] = "RELIC", [10] = "RELIC" }
local slotMap = { ["Weapon"] = "Weapon 1", ["Offhand"] = "Weapon 2", ["Weapon2"] = "Weapon 1 Swap", ["Offhand2"] = "Weapon 2 Swap", ["Helm"] = "Helmet", ["BodyArmour"] = "Body Armour", ["Gloves"] = "Gloves", ["Boots"] = "Boots", 
				  ["Amulet"] = "Amulet", ["Ring"] = "Ring 1", ["Ring2"] = "Ring 2", ["Ring3"] = "Ring 3", ["Belt"] = "Belt",  ["BrequelGrafts"] = "Graft 1", ["BrequelGrafts2"] = "Graft 2", }

function ImportTabClass:ImportItem(itemData, slotName)
	if not slotName then
		if itemData.inventoryId == "PassiveJewels" then
			slotName = "Jewel "..self.build.latestTree.jewelSlots[itemData.x + 1]
		elseif itemData.inventoryId == "Flask" then
			slotName = "Flask "..(itemData.x + 1)
		elseif not (self.controls.charImportItemsIgnoreWeaponSwap.state and (itemData.inventoryId == "Weapon2" or itemData.inventoryId == "Offhand2")) then
			slotName = slotMap[itemData.inventoryId]
		end
	end
	if not slotName then
		-- Ignore any items that won't go into known slots
		return
	end

	local item = new("Item")

	-- Determine rarity, display name and base type of the item
	item.rarity = rarityMap[itemData.frameType]
	if #itemData.name > 0 then
		item.title = sanitiseText(itemData.name)
		item.baseName = sanitiseText(itemData.typeLine):gsub("Synthesised ","")
		item.name = item.title .. ", " .. item.baseName
		if item.baseName == "Two-Toned Boots" then
			-- Hack for Two-Toned Boots
			item.baseName = "Two-Toned Boots (Armour/Energy Shield)"
		end
		item.base = self.build.data.itemBases[item.baseName]
		if item.base then
			item.type = item.base.type
		else
			ConPrintf("Unrecognised base in imported item: %s", item.baseName)
		end
	else
		item.name = sanitiseText(itemData.typeLine)
		if item.name:match("Energy Blade") then
			local oneHanded = false
			for _, p in ipairs(itemData.properties) do
				if self.build.data.weaponTypeInfo[p.name] and self.build.data.weaponTypeInfo[p.name].oneHand then
					oneHanded = true
					break
				end
			end
			item.name = oneHanded and "Energy Blade One Handed" or "Energy Blade Two Handed"
			item.rarity = "NORMAL"
			itemData.implicitMods = { }
			itemData.explicitMods = { }
		end
		for baseName, baseData in pairs(self.build.data.itemBases) do
			local s, e = item.name:find(baseName, 1, true)
			if s then
				item.baseName = baseName
				item.namePrefix = item.name:sub(1, s - 1)
				item.nameSuffix = item.name:sub(e + 1)
				item.type = baseData.type
				break
			end
		end
		if not item.baseName then
			local s, e = item.name:find("Two-Toned Boots", 1, true)
			if s then
				-- Hack for Two-Toned Boots
				item.baseName = "Two-Toned Boots (Armour/Energy Shield)"
				item.namePrefix = item.name:sub(1, s - 1)
				item.nameSuffix = item.name:sub(e + 1)
				item.type = "Boots"
			end
		end
		item.base = self.build.data.itemBases[item.baseName]
	end
	if not item.base or not item.rarity then
		return
	end

	-- Import item data
	item.uniqueID = itemData.id
	if itemData.influences then
		for _, curInfluenceInfo in ipairs(influenceInfo) do
			item[curInfluenceInfo.key] = itemData.influences[curInfluenceInfo.display:lower()]
		end
	end
	if itemData.searing then
		item.cleansing = true
	end
	if itemData.tangled then
		item.tangle = true
	end
	if itemData.ilvl > 0 then
		item.itemLevel = itemData.ilvl
	end
	if item.base.weapon or item.base.armour or item.base.flask or item.base.tincture then
		item.quality = 0
	end
	if itemData.properties then
		for _, property in pairs(itemData.properties) do
			if property.name == "Quality" then
				item.quality = tonumber(property.values[1][1]:match("%d+"))
			elseif property.name == "Radius" then
				item.jewelRadiusLabel = property.values[1][1]
			elseif property.name == "Limited to" then
				item.limit = tonumber(property.values[1][1])
			elseif property.name == "Evasion Rating" then
				if item.baseName == "Two-Toned Boots (Armour/Energy Shield)" then
					-- Another hack for Two-Toned Boots
					item.baseName = "Two-Toned Boots (Armour/Evasion)"
					item.base = self.build.data.itemBases[item.baseName]
				end
			elseif property.name == "Energy Shield" then
				if item.baseName == "Two-Toned Boots (Armour/Evasion)" then
					-- Yet another hack for Two-Toned Boots
					item.baseName = "Two-Toned Boots (Evasion/Energy Shield)"
					item.base = self.build.data.itemBases[item.baseName]
				end
			end
			if property.name == "Energy Shield" or property.name == "Ward" or property.name == "Armour" or property.name == "Evasion Rating" then
				item.armourData = item.armourData or { }
				for _, value in ipairs(property.values) do
					item.armourData[property.name:gsub(" Rating", ""):gsub(" ", "")] = (item.armourData[property.name:gsub(" Rating", ""):gsub(" ", "")] or 0) + tonumber(value[1])
				end
			end
		end
	end
	item.split = itemData.split
	item.mirrored = itemData.mirrored
	item.corrupted = itemData.corrupted
	item.fractured = itemData.fractured
	item.synthesised = itemData.synthesised
	if itemData.sockets and itemData.sockets[1] then
		item.sockets = { }
		for i, socket in pairs(itemData.sockets) do
			if socket.sColour == "A" then
				item.abyssalSocketCount = item.abyssalSocketCount or 0 + 1
			end
			item.sockets[i] = { group = socket.group, color = socket.sColour }
		end
		if item.abyssalSocketCount and item.abyssalSocketCount > 0 and item.name:match("Energy Blade") then
			t_insert(itemData.explicitMods, "Has " .. item.abyssalSocketCount .. " Abyssal Sockets")
		end
	end
	if itemData.socketedItems then
		self:ImportSocketedItems(item, itemData.socketedItems, slotName)
	end
	if itemData.requirements and (not itemData.socketedItems or not itemData.socketedItems[1]) then
		-- Requirements cannot be trusted if there are socketed gems, as they may override the item's natural requirements
		item.requirements = { }
		for _, req in ipairs(itemData.requirements) do
			if req.name == "Level" then
				item.requirements.level = req.values[1][1]
			elseif req.name == "Class:" then
				item.classRestriction = req.values[1][1]
			end
		end
	end
	item.enchantModLines = { }
	item.scourgeModLines = { }
	item.classRequirementModLines = { }
	item.implicitModLines = { }
	item.explicitModLines = { }
	item.crucibleModLines = { }
	if itemData.enchantMods then
		for _, line in ipairs(itemData.enchantMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.enchantModLines, { line = line, extra = extra, mods = modList or { }, crafted = true })
			end
		end
	end
	if itemData.scourgeMods then
		for _, line in ipairs(itemData.scourgeMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.scourgeModLines, { line = line, extra = extra, mods = modList or { }, scourge = true })
			end
		end
	end
	if itemData.implicitMods then
		for _, line in ipairs(itemData.implicitMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.implicitModLines, { line = line, extra = extra, mods = modList or { } })
			end
		end
	end
	if itemData.fracturedMods then
		for _, line in ipairs(itemData.fracturedMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.explicitModLines, { line = line, extra = extra, mods = modList or { }, fractured = true })
			end
		end
	end
	if itemData.explicitMods then
		for _, line in ipairs(itemData.explicitMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.explicitModLines, { line = line, extra = extra, mods = modList or { } })
			end
		end
	end
	if itemData.crucibleMods then
		for _, line in ipairs(itemData.crucibleMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.crucibleModLines, { line = line, extra = extra, mods = modList or { }, crucible = true })
			end
		end
	end
	if itemData.craftedMods then
		for _, line in ipairs(itemData.craftedMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.explicitModLines, { line = line, extra = extra, mods = modList or { }, crafted = true })
			end
		end
	end
	if itemData.mutatedMods then
		for _, line in ipairs(itemData.mutatedMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.explicitModLines, { line = line, extra = extra, mods = modList or { }, mutated = true })
			end
		end
	end
	-- Sometimes flavour text has actual mods that PoB cares about
	-- Right now, the only known one is "This item can be anointed by Cassia"
	if itemData.flavourText then
		for _, line in ipairs(itemData.flavourText) do
			for line in line:gmatch("[^\n]+") do
				-- Remove any text outside of curly braces, if they exist.
				-- This fixes lines such as:
				--   "<default>{This item can be anointed by Cassia}"
				-- To now be:
				--   "This item can be anointed by Cassia"
				local startBracket = line:find("{")
				local endBracket = line:find("}")
				if startBracket and endBracket and endBracket > startBracket then
					line = line:sub(startBracket + 1, endBracket - 1)
				end

				-- If the line parses, then it should be included as an explicit mod
				local modList, extra = modLib.parseMod(line)
				if modList then
					t_insert(item.explicitModLines, { line = line, extra = extra, mods = modList or { } })
				end
			end
		end
	end
	if itemData.foilVariation or itemData.isRelic then
		local foilVariants = {
			"Amethyst",
			"Verdant",
			"Ruby",
			"Cobalt",
			"Sunset",
			"Aureate",
			"Celestial Quartz",
			"Celestial Ruby",
			"Celestial Emerald",
			"Celestial Aureate",
			"Celestial Pearl",
			"Celestial Amethyst",
		}
		item.foilType = foilVariants[itemData.foilVariation] or "Rainbow"
	end

	-- Add and equip the new item
	item:BuildAndParseRaw()
	--ConPrintf("%s", item.raw)
	if item.base then
		local repIndex, repItem
		for index, item in pairs(self.build.itemsTab.items) do
			if item.uniqueID == itemData.id then
				repIndex = index
				repItem = item
				break
			end
		end
		if repIndex then
			-- Item already exists in the build, overwrite it
			item.id = repItem.id
			self.build.itemsTab.items[item.id] = item
			item:BuildModList()
		else
			self.build.itemsTab:AddItem(item, true)
		end
		self.build.itemsTab.slots[slotName]:SetSelItemId(item.id)
	end
end

function ImportTabClass:ImportSocketedItems(item, socketedItems, slotName)
	-- Build socket group list
	local itemSocketGroupList = { }
	local abyssalSocketId = 1
	for _, socketedItem in ipairs(socketedItems) do
		if socketedItem.abyssJewel then
			self:ImportItem(socketedItem, slotName .. " Abyssal Socket "..abyssalSocketId)
			abyssalSocketId = abyssalSocketId + 1
		else
			local normalizedBasename, qualityType = self.build.skillsTab:GetBaseNameAndQuality(socketedItem.typeLine, nil)
			local gemId = self.build.data.gemForBaseName[normalizedBasename:lower()]
			if socketedItem.hybrid then
				-- Used by transfigured gems and dual-skill gems (currently just Stormbind) 
				normalizedBasename, qualityType  = self.build.skillsTab:GetBaseNameAndQuality(socketedItem.hybrid.baseTypeName, nil)
				gemId = self.build.data.gemForBaseName[normalizedBasename:lower()]
				if gemId and socketedItem.hybrid.isVaalGem then
					gemId = self.build.data.gemGrantedEffectIdForVaalGemId[self.build.data.gems[gemId].grantedEffectId]
				end
			end
			if gemId then
				local gemInstance = { level = 20, quality = 0, enabled = true, enableGlobal1 = true, gemId = gemId }
				gemInstance.nameSpec = self.build.data.gems[gemId].name
				gemInstance.support = socketedItem.support
				gemInstance.qualityId = qualityType
				for _, property in pairs(socketedItem.properties) do
					if property.name == "Level" then
						gemInstance.level = tonumber(property.values[1][1]:match("%d+"))
					elseif property.name == "Quality" then
						gemInstance.quality = tonumber(property.values[1][1]:match("%d+"))
					end
				end
				local groupID = item.sockets[socketedItem.socket + 1].group
				if not itemSocketGroupList[groupID] then
					itemSocketGroupList[groupID] = { label = "", enabled = true, gemList = { }, slot = slotName }
				end
				local socketGroup = itemSocketGroupList[groupID]
				if not socketedItem.support and socketGroup.gemList[1] and socketGroup.gemList[1].support and not (item.title and item.title:match("Dialla's Malefaction")) then
					-- If the first gemInstance is a support gemInstance, put the first active gemInstance before it
					t_insert(socketGroup.gemList, 1, gemInstance)
				else
					t_insert(socketGroup.gemList, gemInstance)
				end
			end
		end
	end

	-- Import the socket groups
	for _, itemSocketGroup in pairs(itemSocketGroupList) do
		-- Check if this socket group matches an existing one
		local repGroup
		for index, socketGroup in pairs(self.build.skillsTab.socketGroupList) do
			if #socketGroup.gemList == #itemSocketGroup.gemList and (not socketGroup.slot or socketGroup.slot == slotName) then
				local match = true
				for gemIndex, gem in pairs(socketGroup.gemList) do
					if gem.nameSpec:lower() ~= itemSocketGroup.gemList[gemIndex].nameSpec:lower() then
						match = false
						break
					end
				end
				if match then
					repGroup = socketGroup
					break
				end
			end
		end
		if repGroup then
			-- Update the existing one
			for gemIndex, gem in pairs(repGroup.gemList) do
				local itemGem = itemSocketGroup.gemList[gemIndex]
				gem.level = itemGem.level
				gem.quality = itemGem.quality
			end
		else
			t_insert(self.build.skillsTab.socketGroupList, itemSocketGroup)
		end
		self.build.skillsTab:ProcessSocketGroup(itemSocketGroup)
	end
end

-- Return the index of the group with the most gems
function ImportTabClass:GuessMainSocketGroup()
	local largestGroupSize = 0
	local largestGroupIndex = 1
	for i, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
		if #socketGroup.gemList > largestGroupSize then
			largestGroupSize = #socketGroup.gemList
			largestGroupIndex = i
		end
	end
	return largestGroupIndex
end

function HexToChar(x)
	return string.char(tonumber(x, 16))
end

function UrlDecode(url)
	if url == nil then
		return
	end
	url = url:gsub("+", " ")
	url = url:gsub("%%(%x%x)", HexToChar)
	return url
end

function ImportTabClass:ProcessJSON(json)
	local func, errMsg = loadstring("return "..jsonToLua(json))
	if errMsg then
		return nil, errMsg
	end
	setfenv(func, { }) -- Sandbox the function just in case
	local data = func()
	if type(data) ~= "table" then
		return nil, "Return type is not a table"
	end
	return data
end

function ImportTabClass:SetPredefinedBuildName()
	local accountName = self.controls.accountName.buf:gsub('%s+', ''):gsub("#%d+", "")
	local charSelect = self.controls.charSelect
	local charData = charSelect.list[charSelect.selIndex].char
	local charName = charData.name
	main.predefinedBuildName = accountName.." - "..charName
end
local addon, ns = ...
local O3 = O3

local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local FACTION_BAR_COLORS = FACTION_BAR_COLORS
local floor = math.floor

local handler = O3:module({
	name = 'Plate',
	readable = 'Name Plates',
	weight = 98,
	nameplates = {},
	events = {
		PLAYER_ENTERING_WORLD = true,
	},
	config = {
		enabled = true,
		updateInterval = 1.0,
		width = 150,
		height = 12,
		castbarHeight = 7,
		gap = 5,
		font = O3.Media:font('Normal'),
		fontSize = 9,
		fontFlags = '',
		statusBar = O3.Media:statusBar('Default'),
		iconSize = 30,
		raidiconSize = 25,
		shieldSize = 16,
		nameplateShowEnemies = "1",
		nameplateShowEnemyGuardians = "0",
		nameplateShowEnemyPets = "0",
		nameplateShowEnemyTotems = "0",
		nameplateShowFriends = "0",
		smallPlates = "",
		tappedColor = { r = 0.65, g = 0.65, b = 0.65 },
	},
	smallPlates = {},
	settings = {
	},
	cvars = {
		'nameplateShowEnemies',
		'nameplateShowEnemyGuardians',
		'nameplateShowEnemyPets',
		'nameplateShowEnemyTotems',
		'nameplateShowFriends',
	},
	setCVar = function (self, token, value)
		O3:safe(function () 
			SetCVar(token, value)
		end)
	end,
	addOptions = function (self)
		self:addOption('_0', {
			type = 'Title',
			label = 'Visibility',
		})
		self:addOption('nameplateShowEnemies', {
			type = 'Toggle',
			label = 'Show enemy nameplates',
			off = "0",
			on = "1",
			setter = 'setCVar',
		})
		self:addOption('nameplateShowEnemyGuardians', {
			type = 'Toggle',
			label = 'Show enemy guardian nameplates',
			off = "0",
			on = "1",
			setter = 'setCVar',
		})
		self:addOption('nameplateShowEnemyPets', {
			type = 'Toggle',
			label = 'Show enemy pet nameplates',
			off = "0",
			on = "1",
			setter = 'setCVar',
		})
		self:addOption('nameplateShowEnemyTotems', {
			type = 'Toggle',
			label = 'Show enemy totem nameplates',
			off = "0",
			on = "1",
			setter = 'setCVar',
		})
		self:addOption('nameplateShowFriends', {
			type = 'Toggle',
			label = 'Show friendly nameplates',
			off = "0",
			on = "1",
			setter = 'setCVar',
		})		

		self:addOption('_1', {
			type = 'Title',
			label = 'Font',
		})
		self:addOption('font', {
			type = 'FontDropDown',
			label = 'Font',
			setter = 'fontSet'
		})
		self:addOption('fontSize', {
			type = 'Range',
			label = 'Font size',
			min = 6,
			max = 20,
			step = 1,
			setter = 'fontSet'
		})
		self:addOption('_2', {
			type = 'Title',
			label = 'Nameplate',
		})
		self:addOption('width', {
			type = 'Range',
			label = 'Width',
			min = 100,
			max = 200,
			step = 5,
			setter = 'sizeSet'
		})
		self:addOption('height', {
			type = 'Range',
			label = 'Height',
			min = 5,
			max = 20,
			step = 1,
			setter = 'sizeSet'
		})

		self:addOption('_3', {
			type = 'Title',
			label = 'Filters',
		})
		self:addOption('smallPlates', {
			lines = 5,
			type = 'String',
			label = 'Small plates for',
		})
	end,
	resize = function (self)
		for blizzPlate, newPlate in pairs(self.nameplates) do
			if blizzPlate:IsShown() then
				if (blizzPlate.nameFrame:GetScale() < 1) then
					newPlate:SetSize(self.settings.width/2, self.settings.height+self.settings.castbarHeight+self.settings.gap)
				else
					newPlate:SetSize(self.settings.width, self.settings.height+self.settings.castbarHeight+self.settings.gap)
				end
				blizzPlate.healthBar:SetHeight(self.settings.height)				
				blizzPlate.castbar:SetHeight(self.settings.castbarHeight)
			end
		end
	end,
	split = function (self, s, delimiter, result)
		result = result or {}
		for match in (s..delimiter):gmatch("(.-)"..delimiter) do
			result[match] = true
		end
		return result
	end,	
	smallPlatesSet = function (self)
		wipe(self.smallPlates)
		self:split(self.settings.smallPlates or "", ";", self.smallPlates)
		for blizzPlate, newPlate in pairs(self.nameplates) do
			self:onShow(blizzPlate)
		end
	end,
	sizeSet = function (self)
		self:resize(self.frame, self.nameplates)
	end,
	fontSet = function (self)
		for blizzPlate, newPlate in pairs(self.nameplates) do
			blizzPlate.castbar.name:SetFont(self.settings.font , self.settings.fontSize-1, self.settings.fontFlags)
			newPlate.name:SetFont(self.settings.font , self.settings.fontSize, self.settings.fontFlags)

		end
	end,
	isPlate = function (self, obj)
		local name = obj:GetName()
		if name and name:find("NamePlate") then
			return true
		end
		obj._plated = true
		return false
	end,
	initPlate = function (self, plate)
		plate.color = {}
		--the gathering
		plate.barFrame, plate.nameFrame = plate:GetChildren()

		plate.healthBar, plate.castbar = plate.barFrame:GetChildren()
		plate.threat, plate.border, plate.highlight, plate.level, plate.boss, plate.raid, plate.dragon = plate.barFrame:GetRegions()
		plate.name = plate.nameFrame:GetRegions()
		plate.healthBar.texture = plate.healthBar:GetRegions()
		plate.castbar.texture, plate.castbar.border, plate.castbar.shield, plate.castbar.icon, plate.castbar.name, plate.castbar.nameShadow = plate.castbar:GetRegions()
		plate.castbar.icon.layer, plate.castbar.icon.sublevel = plate.castbar.icon:GetDrawLayer()
		plate._plated = true
		--create a new plate
		self.nameplates[plate] = CreateFrame("Frame", "New"..plate:GetName(), UIParent)
		local newPlate = self.nameplates[plate]

		--keep the frame reference for later
		newPlate.blizzPlate = plate
		plate.newPlate = newPlate
		--barFrame
		--do not touch it
		--nameFrame
		plate.nameFrame:SetParent(self.bin)
		plate.nameFrame:Hide()
		--healthbar
		plate.healthBar:SetParent(newPlate)
		--plate.healthBar:SetStatusBarTexture(self.settings.healthbarTexture)
		plate.healthBar.texture = plate.healthBar:GetStatusBarTexture()
		plate.healthBar.texture:SetTexture(nil)
		--new fake healthbar
		plate.healthBar._texture = plate.healthBar:CreateTexture(nil, "BACKGROUND",nil,-6)
		plate.healthBar._texture:SetAllPoints(plate.healthBar.texture)
		plate.healthBar._texture:SetTexture(self.settings.statusBar) --texture file path
		plate.healthBar._texture:SetVertexColor(0,1,1)
		--[[
		--healthbar bg test
		plate.healthBar.bg = plate.healthBar:CreateTexture(nil, "BACKGROUND",nil,-6)
		plate.healthBar.bg:SetAllPoints(plate.healthBar)
		plate.healthBar.bg:SetTexture(1,1,1)
		plate.healthBar.bg:SetVertexColor(1,0,0,0.2)
		]]--
		O3.UI:shadow(plate.healthBar)

		plate.threatHolder = CreateFrame('Frame', nil, plate.healthBar)
		plate.threatHolder:SetPoint('RIGHT', plate.healthBar, 'LEFT', -3, 0)
		plate.threatHolder:SetSize(5, self.settings.height)
		O3.UI:shadow(plate.threatHolder)

		--threat
		plate.threat:SetParent(plate.threatHolder)
		plate.threat:SetTexture(O3.Media:statusBar('Default'))
		plate.threat:SetTexCoord(0,1,0,1)
		plate.threat:SetAllPoints()

		--level
		plate.level:SetParent(self.bin) --trash the level string, it will come back OnShow and OnDrunk otherwise ;)
		plate.level:Hide()
		--hide textures
		plate.border:SetTexture(nil)
		plate.highlight:SetTexture(nil)
		plate.boss:SetTexture(nil)
		plate.dragon:SetTexture(nil)
		--castbar
		plate.castbar:SetParent(newPlate)
		plate.castbar:SetStatusBarTexture(self.settings.statusBar)
		O3.UI:shadow(plate.castbar)
		--castbar border
		plate.castbar.border:SetTexture(nil)
		--castbar icon

		plate.castbar.iconHolder = CreateFrame('Frame', nil, plate.castbar)
		plate.castbar.iconHolder:SetPoint('LEFT', plate.castbar, 'RIGHT', self.settings.gap, 0)
		plate.castbar.iconHolder:SetSize(self.settings.iconSize, self.settings.iconSize)
		O3.UI:shadow(plate.castbar.iconHolder)

		--plate.castbar.icon:SetParent(plate.castbar.iconHolder)
		plate.castbar.icon:SetTexCoord(0.1,0.9,0.1,0.9)
		plate.castbar.icon:SetAllPoints(plate.castbar.iconHolder)

		--castbar spellname
		plate.castbar.name:ClearAllPoints()
		plate.castbar.name:SetPoint("BOTTOM",plate.castbar,0,-5)
		plate.castbar.name:SetPoint("LEFT",plate.castbar,5,0)
		plate.castbar.name:SetPoint("RIGHT",plate.castbar,-5,0)
		plate.castbar.name:SetFont(self.settings.font , self.settings.fontSize-1, self.settings.fontFlags)
		plate.castbar.name:SetShadowColor(0,0,0,0)
		--castbar shield
		plate.castbar.shield:SetTexture(O3.Media:texture('Shield'))
		plate.castbar.shield:SetTexCoord(0,1,0,1)
		plate.castbar.shield:SetDrawLayer(plate.castbar.icon.layer, plate.castbar.icon.sublevel+2)
		--new castbar icon border
		-- plate.castbar.iconBorder = plate.castbar:CreateTexture(nil, plate.castbar.icon.layer, nil, plate.castbar.icon.sublevel+1)
		-- plate.castbar.iconBorder:SetTexture("Interface\\AddOns\\rNamePlates2\\media\\castbar_icon_border")
		-- plate.castbar.iconBorder:SetPoint("TOPLEFT",plate.castbar.icon,"TOPLEFT",-2,2)
		-- plate.castbar.iconBorder:SetPoint("BOTTOMRIGHT",plate.castbar.icon,"BOTTOMRIGHT",2,-2)
		--new name
		newPlate.name = plate.healthBar:CreateFontString(nil,"BORDER")
		--newPlate.name:SetPoint("CENTER", plate.healthBar, "TOP",0,0)
		newPlate.name:SetPoint("LEFT", plate.healthBar, 'TOPLEFT', 2,0)
		newPlate.name:SetPoint("RIGHT", plate.healthBar, 'TOPRIGHT', -30,0)
		newPlate.name:SetFont(self.settings.font , self.settings.fontSize, self.settings.fontFlags)
		newPlate.name:SetTextColor(1,1,1,1)
		newPlate.name:SetShadowOffset(1,-1)
		newPlate.name:SetJustifyH('LEFT')
		plate._name = newPlate.name

		newPlate.percentage = plate.healthBar:CreateFontString(nil,"BORDER")
		--newPlate.percentage:SetPoint("CENTER", plate.healthBar, "TOP",0,0)
		newPlate.percentage:SetPoint("LEFT", plate._name, 'RIGHT', 2,0)
		newPlate.percentage:SetPoint("RIGHT", plate.healthBar, 'RIGHT', -2,0)
		newPlate.percentage:SetJustifyH('RIGHT')
		newPlate.percentage:SetFont(self.settings.font , self.settings.fontSize, self.settings.fontFlags)
		newPlate.percentage:SetTextColor(1,1,1,1)
		newPlate.percentage:SetShadowOffset(1,-1)
		plate._percentage = newPlate.percentage

		--raid icon
		plate.raid:SetParent(newPlate)
		plate.raid:ClearAllPoints()
		plate.raid:SetSize(self.settings.raidiconSize,self.settings.raidiconSize)
		plate.raid:SetPoint("BOTTOM",newPlate.name,"TOP",0,0)
		--hooks

		plate.healthBar:SetScript('OnValueChanged', function (healthBar)
			local min, max = healthBar:GetMinMaxValues()
			local val = healthBar:GetValue()
			local percent = floor(val/max*100)
			local color = self:getHealthbarColor(plate)
			healthBar._texture:SetVertexColor(color.r,color.g,color.b)

			plate._percentage:SetText(percent)
		end)


		plate:HookScript("OnShow", function (plate)
			self:onShow(plate)

		end)
		plate.castbar:HookScript("OnShow", function (castbar)
			self:onCastbarShow(newPlate, castbar)
		end)
		self:onShow(plate)

	end,
	getLevelColor = function (self, plate)
		local color = {}
		color.r, color.g, color.b = plate.level:GetTextColor()
		color.r, color.g, color.b = floor(color.r*100+.5)/100, floor(color.g*100+.5)/100, floor(color.b*100+.5)/100
		return color
	end,
	getHexColor = function (self, color)
		local r,b,g = color.r, color.b, color.g
		r = r <= 1 and r >= 0 and r or 0
		g = g <= 1 and g >= 0 and g or 0
		b = b <= 1 and b >= 0 and b or 0
		return string.format("%02x%02x%02x", r*255, g*255, b*255)
	end,
	getHealthbarColor = function (self, plate)
		local color = plate.color
		local tappedColor = self.settings.tappedColor
		if not plate.tapped then
			color.r, color.g, color.b = plate.healthBar:GetStatusBarColor()
			color.r, color.g, color.b = floor(color.r*100+.5)/100, floor(color.g*100+.5)/100, floor(color.b*100+.5)/100
		else
			color = tappedColor
		end

		if color.r == 0.53 and color.g == 0.53 and color.b == 1 then
			plate.tapped = true
			color = tappedColor
		end
		

		for class, _ in pairs(RAID_CLASS_COLORS) do
			if RAID_CLASS_COLORS[class].r == color.r and RAID_CLASS_COLORS[class].g == color.g and RAID_CLASS_COLORS[class].b == color.b then
				return color
			end
		end
		if color.g+color.b == 0 then -- hostile
			color.r,color.g,color.b = FACTION_BAR_COLORS[2].r, FACTION_BAR_COLORS[2].g, FACTION_BAR_COLORS[2].b
		elseif color.r+color.b == 0 then -- friendly npc
			color.r,color.g,color.b = FACTION_BAR_COLORS[6].r, FACTION_BAR_COLORS[6].g, FACTION_BAR_COLORS[6].b
		elseif color.r+color.g == 2 then -- neutral
			color.r,color.g,color.b = FACTION_BAR_COLORS[4].r, FACTION_BAR_COLORS[4].g, FACTION_BAR_COLORS[4].b
		elseif color.r+color.g == 0 then -- friendly player, we don't like 0,0,1 so we change it to a more likable color
			color.r,color.g,color.b = 0/255, 100/255, 255/255
		end

		return color
	end,
	getThreatColor = function (self, threat)
		local color = {}
		color.r, color.g, color.b = threat:GetVertexColor()
		color.r, color.g, color.b = floor(color.r*100+.5)/100, floor(color.g*100+.5)/100, floor(color.b*100+.5)/100
		return color

	end,
	onShow = function (self, plate)
		plate.tapped = false
		local name = plate.name:GetText() or "Unknown"
		local healthBar = plate.healthBar

		if (plate.nameFrame:GetScale() < 1 or self.smallPlates[name]) then
			plate.newPlate:SetSize(self.settings.width/2, self.settings.height+self.settings.castbarHeight+self.settings.gap)
		else
			plate.newPlate:SetSize(self.settings.width, self.settings.height+self.settings.castbarHeight+self.settings.gap)
		end
		plate.dragon:SetTexture(nil)


		--healthbar
		healthBar:ClearAllPoints()
		healthBar:SetPoint("TOP", plate.newPlate)
		healthBar:SetPoint("LEFT", plate.newPlate)
		healthBar:SetPoint("RIGHT", plate.newPlate)
		healthBar:SetHeight(self.settings.height)
		
		local min, max = healthBar:GetMinMaxValues()
		local val = healthBar:GetValue()
		local percent = floor(val/max*100)
		plate._percentage:SetText(percent)


		-- --threat glow
		plate.threat:ClearAllPoints()
		plate.threat:SetAllPoints()
		--plate.threat:SetVertexColor(self:getThreatColor(plate.threat))
		-- plate.threat:SetPoint("TOPLEFT",healthBar,-2,2)
		-- plate.threat:SetPoint("BOTTOMRIGHT",healthBar,2,-2)
		--set name and level
		local hexColor = self:getHexColor(self:getLevelColor(plate)) or "ffffff"
		
		local level = plate.level:GetText() or "-1"
		if plate.boss:IsShown() then
			level = "??"
			hexColor = "ff6600"
		elseif plate.dragon:IsShown() then
			level = level.."+"
		end
		local color = self:getHealthbarColor(plate)
		if healthBar._texture then
			healthBar._texture:SetVertexColor(color.r,color.g,color.b)
		end
		--plate._name:SetTextColor(color.r,color.g,color.b)
		plate._name:SetText("|cff"..hexColor..""..level.."|r "..name)	
	end,
	onCastbarShow = function (self, newPlate, castbar)
		--castbar
		castbar:ClearAllPoints()
		castbar:SetPoint("BOTTOM", newPlate)
		castbar:SetPoint("LEFT", newPlate)
		castbar:SetPoint("RIGHT", newPlate)
		castbar:SetHeight(self.settings.castbarHeight)
		--castbar icon
		castbar.icon:ClearAllPoints()
		castbar.icon:SetAllPoints(castbar.iconHolder)
		if castbar.shield:IsShown() then
			--castbar shield
			castbar.shield:ClearAllPoints()
			castbar.shield:SetPoint("BOTTOM",castbar.icon,0,-self.settings.shieldSize/2+2)
			castbar.shield:SetSize(self.settings.shieldSize,self.settings.shieldSize)
			castbar:SetStatusBarColor(0.8,0.8,0.8)
		end	
	end,
	reposition = function (self, plateParent, nameplates)
		plateParent:Hide()
		for blizzPlate, newPlate in pairs(nameplates) do
			newPlate:Hide()
			if blizzPlate:IsShown() then
				if (blizzPlate.threat:IsShown()) then
					blizzPlate.threatHolder:Show()
				else
					blizzPlate.threatHolder:Hide()
				end
				newPlate:SetPoint("CENTER", blizzPlate, "CENTER")
				newPlate:SetAlpha(blizzPlate:GetAlpha())
				newPlate:Show()
			end
		end
		plateParent:Show()
	end,
	setup = function (self)
		self.frame = CreateFrame("Frame", self.name, WorldFrame)

		self.bin = CreateFrame("Frame")
		self.bin:Hide()

		self:initEventHandler()
	end,
	PLAYER_ENTERING_WORLD = function (self)
		local lastUpdate = 0
		local updateInterval = self.settings.updateInterval
		local plateParent = self.frame
		local nameplates = self.nameplates

		wipe(self.smallPlates)
		self:split(self.settings.smallPlates or "", ";", self.smallPlates)

		WorldFrame:HookScript("OnUpdate", function (WorldFrame, elapsed)
			lastUpdate = lastUpdate + elapsed
			self:reposition(plateParent, nameplates)
			if lastUpdate > updateInterval then
				for _, obj in pairs({WorldFrame:GetChildren()}) do
				  if not obj._plated and self:isPlate(obj) then
					self:initPlate(obj)
				  end
				end
				lastUpdate = 0
			end
		end)
		SetCVar("bloatnameplates",0)
		SetCVar("bloatthreat",0)		
		for _, cvar in ipairs(self.cvars) do
			SetCVar(cvar, self.settings[cvar])
		end
		self:unregisterEvent('PLAYER_ENTERING_WORLD')
	end,
})
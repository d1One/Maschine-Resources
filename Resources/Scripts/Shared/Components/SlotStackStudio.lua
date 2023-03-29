------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/ScreenBase"

require "Scripts/Shared/Helpers/BrowseHelper"
require "Scripts/Shared/Helpers/ChainHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/ResourceHelper"

local ATTR_CHANNEL = NI.UTILS.Symbol("Channel")
local ATTR_EMPTY = NI.UTILS.Symbol("Empty")
local ATTR_HAS_FOCUS = NI.UTILS.Symbol("HasFocus")
local ATTR_IS_BYPASSED = NI.UTILS.Symbol("IsBypassed")
local ATTR_TYPE = NI.UTILS.Symbol("Type")

------------------------------------------------------------------------------------------------------------------------
-- Channel / Plug-in screen combo
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SlotStackStudio = class( 'SlotStackStudio' )

------------------------------------------------------------------------------------------------------------------------

function SlotStackStudio:__init(GetPictureColor)

    self.SlotMargin = 0
    self.IconWidth = 0
    self.PictureMargin = 0
    self.NameMaxWidth = 210
    self.GetPictureColor = GetPictureColor

    self.Stack = nil

end

------------------------------------------------------------------------------------------------------------------------

function SlotStackStudio:insertInto(Parent)

    if self.Stack == nil then
        self.Stack = NI.GUI.insertStack(Parent, "SlotStack")
        self.Stack:style("SlotStack")

	    -- channels

        self.ChannelScreen = NI.GUI.insertBar(self.Stack, "ChannelScreen")
        self.ChannelScreen:style(NI.GUI.ALIGN_WIDGET_RIGHT, "ChannelScreen")

	    self.Channels = {}
	    self:setupChannel("INPUT")
	    self:setupChannel("OUTPUT")
	    self:setupChannel("GROOVE")
	    self:setupChannel("MACRO")

	    -- plug-ins

        self.PluginList = NI.GUI.insertPluginItemVector(self.Stack, "PluginList")
        self.PluginList:style(true, '')
	    self.PluginList:getScrollbar():setAutohide(false)
	    self.PluginList:getScrollbar():setActive(false)

	    self.Stack:setTop(self.PluginList)

        NI.GUI.connectVector(self.PluginList,
		    function() return self:listSize() end,
		    function(Item) self:listSetup(Item) end,
		    function(Item, Index) self:listLoad(Item, Index) end)

        NI.GUI.connectVectorItemLength(self.PluginList,
            function(Index) return self:listItemLength(Index) end)

    else
	    Parent:insertChild(self.Stack, "SlotStack")
	end

end

------------------------------------------------------------------------------------------------------------------------

function SlotStackStudio:listSize()

    local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
    return Slots and Slots:size() + 1 or 0

end

------------------------------------------------------------------------------------------------------------------------

function SlotStackStudio:listSetup(Item)

	Item:getPictureFrame():setNoAlign(true)
    NI.GUI.enableCropModeForLabel(Item:getNameLabel())

end

------------------------------------------------------------------------------------------------------------------------

function SlotStackStudio:setPicture(Item, Index)

    local Picture = self:getPluginPicture(Index)
    if Picture then
        local ColorIndex = self.GetPictureColor()
        local Color = Item:getPicture():getColorFromPalette("background-color", ColorIndex, 0)

        Item:getPicture():setPicture(Picture)
		Item:getPicture():setBGColor(Color)

		Item:getPicture():setWidth(Picture:getWidth())
		Item:getPicture():setHeight(Picture:getHeight())

	    Item:getPictureFrame():setPos(0, Item:getNameLabel():getHeight())
		Item:getPictureFrame():setWidth(Picture:getWidth() + self.PictureMargin)
		Item:getPictureFrame():setHeight(Picture:getHeight() + Item:getPictureFrame():getMargin():getHeight())

		Item:setWidth(self:listItemLength(Index))

    else
        Item:getPicture():resetPicture()
    end

end

------------------------------------------------------------------------------------------------------------------------

function SlotStackStudio:listLoad(Item, Index)

    local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)

    if Slots then

        local Slot = Slots:at(Index)
        local Name = NI.DATA.SlotAlgorithms.getDisplayName(Slot)

        -- name

        Name = Index == Slots:size() and "" or ChainHelper.getShortName(Slot, Name)
        Item:getNameLabel():setText(Name)

        local Id = SlotStackStudio.getPluginInfo(Index)
        local Module = Slot and Slot:getModule()
        local Info = Module and Module:getInfo()
        local Type = Info and Info:getType()

        -- type (instrument/fx)
        if Type then
            if Type == NI.DATA.ModuleInfo.TYPE_INSTRUMENT then
                Item:getTypeLabel():setAttribute(ATTR_TYPE, Id == NI.DATA.ModuleInfo.ID_AUDIO and "audio" or "instrument")
            elseif Type == NI.DATA.ModuleInfo.TYPE_EFFECT then
                Item:getTypeLabel():setAttribute(ATTR_TYPE, "effect")
            else
                Item:getTypeLabel():setAttribute(ATTR_TYPE, "missing")
            end
        end

        Item:getTypeLabel():setVisible(Index ~= Slots:size())

        -- is active or bypassed?
        local IsBypassed = Slot and not Slot:getActiveParameter():getValue() or false;
        Item:setAttribute(ATTR_IS_BYPASSED, IsBypassed and "true" or "false")

        -- Focus state
        local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)
        Item:setAttribute(ATTR_HAS_FOCUS, (FocusSlotIndex == Index or FocusSlotIndex == -1 and Index == Slots:size()) and "true" or "false")
        Item:setAttribute(ATTR_EMPTY, Index == Slots:size() and "true" or "false")

        -- Picture
        self:setPicture(Item, Index)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SlotStackStudio:listItemLength(Index)

    local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
    local Slot = Slots:at(Index)
    local Name = Slots and NI.DATA.SlotAlgorithms.getDisplayName(Slot)

    if Name then
        Name = ChainHelper.getShortName(Slot, Name)

        local NameLength = math.min(Name and self.PluginList:getStringWidth(Name) or 0, self.NameMaxWidth)

        local HeaderWidth = self.IconWidth + NameLength
        local Picture = self:getPluginPicture(Index)
        local PictureWidth = Picture and Picture:getWidth() or 0

        return self.SlotMargin + math.max(HeaderWidth, PictureWidth + self.PictureMargin)
    else
      return 0
    end

end

------------------------------------------------------------------------------------------------------------------------

function SlotStackStudio:setupChannel(Name)

	local Channel = {}

	Channel.Name = Name
    Channel.Bar = NI.GUI.insertBar(self.ChannelScreen, "ChannelBar")
    Channel.Bar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ChannelBar")
    Channel.Icon = NI.GUI.insertLabel(Channel.Bar, "Icon")
    Channel.Icon:style(" ", "ChannelIcon")
    Channel.NameLabel = NI.GUI.insertLabel(Channel.Bar, "Name")
    Channel.NameLabel:style(Name, "ChannelName")

	Channel.Icon:setAttribute(ATTR_CHANNEL, Name)

	self.Channels[#self.Channels+1] = Channel

end

------------------------------------------------------------------------------------------------------------------------

function SlotStackStudio:getFocusChannelName()

	local PageGroupParameter = App:getWorkspace():getPageGroupParameter()
	return self.Channels[PageGroupParameter:getValue()+1].Name

end

------------------------------------------------------------------------------------------------------------------------

function SlotStackStudio.getPluginInfo(Index)

    if Index == -1 then
        return nil, "", "", false
    end

    local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
    local Slot = Slots and Slots:at(Index)
    local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)
    local Module = Slot and Slot:getModule()
    local ModuleInfo = Module and Module:getInfo()

    local Id = ModuleInfo and ModuleInfo:getId()
    local Name = NI.DATA.SlotAlgorithms.getDisplayName(Slot)
    local ResourceLocator = Slot and Slot:getBankResourceLocator(Name) or Name
    local Selected = FocusSlotIndex == Index or (FocusSlotIndex == -1 and Index == Slots:size())

    return Id, Name, ResourceLocator, Selected

end

------------------------------------------------------------------------------------------------------------------------

function SlotStackStudio:getPluginPicture(Index)

    local Id, Name, PictureChain, Selected = SlotStackStudio.getPluginInfo(Index)
    local Path = ""
    local Internal = true

    if Id then
        -- external
        if Id == NI.DATA.ModuleInfo.ID_PLUGINHOST then

            Path = ResourceHelper.getPluginIcon(PictureChain)
            Internal = false

        -- internal
        else
            Path = self.PluginList:getStringProperty("image-"..NI.UTILS.removeStringParensAndWhitespace(string.lower(Name)), "")
        end
    end

    -- "empty" or generic VST plug-in
    if Path == "" then
        local ImageEmptyString = Selected and "image-empty-selected" or "image-empty"
        Path = self.PluginList:getStringProperty(Id and "image-vst" or ImageEmptyString, "")
        Internal = true
    end

    return NI.UTILS.PictureManager.getPictureOrLoadFromDisk(Path, Internal)

end

------------------------------------------------------------------------------------------------------------------------

function SlotStackStudio:update(ForceUpdate)

	local UpdatePlugin = ForceUpdate

    if not ForceUpdate and not NI.DATA.ParameterCache.isValid(App) then
	    return false
    end

	if ForceUpdate then
		self.Stack:setActive(true)
   		self.PluginList:forceAlign() --necessary

	    self.SlotMargin = self.PluginList:getIntProperty("slot-margin", 0)
	    self.PictureMargin = self.PluginList:getIntProperty("picture-margin", 0)
	    self.IconWidth = self.PluginList:getIntProperty("icon-width", 0)
	    self.NameMaxWidth = self.PluginList:getIntProperty("name-max-width", 210)
	end

    if not NI.APP.FEATURE.EFFECTS_CHAIN then
        local Chain = App:getChain();
        if ForceUpdate or Chain:getSlots():isFocusObjectChanged()
                       or Chain:isChanged()
                       or Chain:isAnySlotChanged() then
            self.PluginList:setAlign()

            local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)
            local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)

            if FocusSlotIndex == NPOS then
                FocusSlotIndex = Slots and Slots:size() or 0
            end

            self.PluginList:setFocusItem(FocusSlotIndex, 0, 0)
            return true
        else
            return false
        end
    end

	-- update Stack
    local ModuleVisibleParam = App:getWorkspace():getModulesVisibleParameter()
	if ForceUpdate or ModuleVisibleParam:isChanged() then
		self.Stack:setTop(MaschineHelper:isShowingPlugins() and self.PluginList or self.ChannelScreen)
		UpdatePlugin = true
	end

	-- Update plug-in view
	if MaschineHelper:isShowingPlugins() then

        local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)
        local MixingLayer = NI.DATA.StateHelper.getFocusMixingLayer(App)
        local Chain = MixingLayer and MixingLayer:getChain()
        local ColorParameter = MixingLayer and MixingLayer:getColorParameter()
		local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)

	    local StateCache = App:getStateCache()
		if StateCache:isFocusSlotChanged() or
            (Chain and Chain:isChanged()) or
			(ColorParameter and ColorParameter:isChanged()) or
			UpdatePlugin then

			local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)
			if FocusSlotIndex == NPOS then
				FocusSlotIndex = Slots and Slots:size() or 0
			end

			if StateCache:isMixingLayerChanged() or UpdatePlugin then
				self.PluginList:setFocusItem(FocusSlotIndex, 0, 0) --no anim
			else
				self.PluginList:setFocusItem(FocusSlotIndex)
			end

			UpdatePlugin = true
		end

		-- check bypass state of any slot

		if not UpdatePlugin and Slots then
			for Index = 1, Slots:size() do
				local Slot = Slots:at(Index-1)
				if Slot then
					if Slot:getActiveParameter():isChanged() or
						Slot:isModuleChanged() or
						(Slot:getPluginHost() and Slot:getPluginHost():isChanged()) then
						UpdatePlugin = true
						break
					end
				end
			end
		end

		if UpdatePlugin then
			self.PluginList:setAlign()
		end

	else -- Update Channel view

	    local PageGroupParameter = App:getWorkspace():getPageGroupParameter()
	    if PageGroupParameter:isChanged() or UpdatePlugin then
			for Index = 1, 4 do
				self.Channels[Index].Bar:setAttribute(ATTR_HAS_FOCUS, Index == PageGroupParameter:getValue()+1 and "true" or "false")
			end

			UpdatePlugin = true
		end

	end

	return UpdatePlugin

end

------------------------------------------------------------------------------------------------------------------------

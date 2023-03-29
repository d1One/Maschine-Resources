------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/CapacitiveOverlayBase"
require "Scripts/Shared/Helpers/MaschineHelper"

local ATTR_SCROLLBAR_VISIBLE = NI.UTILS.Symbol("ScrollbarVisible")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
CapacitiveOverlayList = class( 'CapacitiveOverlayList', CapacitiveOverlayBase )

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:__init(Controller)

    CapacitiveOverlayBase.__init(self, Controller)
    local OverlayRoot = NHLController:getHardwareDisplay():getOverlayRoot()

    self.FrameWidget = NI.GUI.insertBar(OverlayRoot, "CapacitiveOverlayFrame")
    self.FrameWidget:setVisible(false)

    self.ArrowWidget = NI.GUI.insertLabel(OverlayRoot, "CapacitiveOverlayArrow")
    self.ArrowWidget:setVisible(false)

    self.VectorWidget = NI.GUI.insertLabelVector(self.FrameWidget, "CapacitiveListVector")
    self.VectorWidget:style(false, '')

    NI.GUI.connectVector(self.VectorWidget,
        function() return self:getListSize() end,
        function(Label) return self:ListItemSetup(Label) end,
        function(Label, Index) return self:ListItemLoad(Label, Index) end)

    self.FrameWidget:setFlex(self.VectorWidget)
    self.VectorWidget:getScrollbar():setShowIncDecButtons(false)
    self.VectorWidget:getScrollbar():setAutohide(true)

    -- Contains data that needs to be displayed, is filled when setting a param or list
    self.Data = {}

	self.CachedFocusItem = 0

    self.VectorItemMargin = 0
    self.VectorItemHeight = 0

    self.MaxItems = 5
    self.FrameTop = 0

    self.CustomShowListFunc = nil
    self.CustomCapEnabledFunc = nil

end

------------------------------------------------------------------------------------------------------------------------
-- 'Public' Interface
------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:setStyle(Style)

    self.FrameWidget:style(NI.GUI.ALIGN_WIDGET_DOWN, Style)
    self.ArrowWidget:style(" ", Style)
    self.VectorWidget:style(false, Style)

    self.VectorItemMargin = self.VectorWidget:getIntProperty("label-margin", 0)
    self.VectorItemHeight = self.VectorWidget:getIntProperty("label-height", 0)

    self.MaxItems = self.FrameWidget:getIntProperty("max-items", 5)
    self.FrameTop = self.FrameWidget:getIntProperty("top", 0)

end

------------------------------------------------------------------------------------------------------------------------
-- resets the touch mechanics AND optionally all cached data (true by default)
function CapacitiveOverlayList:reset(resetData)

	if resetData or resetData == nil then

		self.Data = {}
		self.CustomShowListFunc = nil
		self.CustomCapEnabledFunc = nil
		self:setStyle("CapacitiveOverlayDefault")
	end

	CapacitiveOverlayBase.reset(self)

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:update()

    self:updateCachedFocusItem()

    if self.FrameWidget:isVisible() then
        if self.CachedFocusItem then
            WidgetHelper.VectorCenterOnItem(self.VectorWidget, self.CachedFocusItem == NPOS and 0 or self.CachedFocusItem)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------
-- will reset "custom" list too
function CapacitiveOverlayList:assignParameterToCap(Param, Index)

    -- TAG_FORWARD is used in macros mainly
    if Param and Param:getTag() == NI.DATA.MaschineParameter.TAG_FORWARD then
        Param = Param:getParameter()
    end

    -- if param hasn't changed (except for its value) just update. otherwise reset
    if self:getFocusCap() == nil or not self:isParamStillValid(Index, Param) then

        self:resetCap(Index)

        -- assign param if handled
        if Param and self:isParamHandled(Param) then
            self.Data[Index].Param = Param
            self:cacheStringsFromParam(Index)
        end
    end

    self:update()

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:assignParametersToCaps(Params)

    for Index = 1, 8 do
        self:assignParameterToCap(Params[Index], Index)
    end

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:assignListsToCaps(Lists, FocusItems, Colors)

    for Index = 1, 8 do
        self:assignListToCap(Index, Lists[Index], Colors and Colors[Index] or nil)
        self:setListFocusItem(Index, FocusItems[Index])
    end

end

------------------------------------------------------------------------------------------------------------------------
-- will also reset parameter if there is one
function CapacitiveOverlayList:assignListToCap(Cap, List, Colors)

    List = List or {}

	local LongestStringLength = 0
	local LongestStringIndex = 0
	local IsListStillValid = self.Data[Cap] and self.Data[Cap].List and #List == #self.Data[Cap].List

    for Index = 1, #List do
        if #List[Index] >= LongestStringLength then
            LongestStringLength = #List[Index]
            LongestStringIndex = Index
        end

        if IsListStillValid and List[Index] ~= self.Data[Cap].List[Index] then
        	IsListStillValid = false
        end
    end

    if IsListStillValid then
    	return
    end

	self:resetCap(Cap)

	self.Data[Cap].List = List
    self.Data[Cap].Colors = Colors

    self.Data[Cap].CachedStrings = List
    self.Data[Cap].LongestStringIndex = LongestStringIndex

    self:update()

end

------------------------------------------------------------------------------------------------------------------------
-- Index is 0-based, string also valid
function CapacitiveOverlayList:setListFocusItem(Cap, Item)

    if self.Data[Cap] then

        local Index = Item

        if type(Item) == "string" then

            Index = 0
            for TableIndex = 1, #self.Data[Cap].CachedStrings do
                if self.Data[Cap].CachedStrings[TableIndex] == Item then
                    Index = TableIndex - 1
                    break
                end
            end
        end

        self.Data[Cap].ListFocusItem = Index
        self:update()
    end
end


------------------------------------------------------------------------------------------------------------------------
-- Custom Cap Behaviour: Page handles a custom displaying of the list
-- Func must return true/false if the custom cap must be seen as being enabled or not
function CapacitiveOverlayList:setCustomCapEnabledFunc(CustomCapEnabledFunc)

	self.CustomCapEnabledFunc = CustomCapEnabledFunc

end

------------------------------------------------------------------------------------------------------------------------
-- Custom Cap Behaviour: Page handles a custom displaying of a list
function CapacitiveOverlayList:setCustomShowListFunc(CustomShowListFunc)

	self.CustomShowListFunc = CustomShowListFunc

end

------------------------------------------------------------------------------------------------------------------------
-- LIST VECTOR
------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:getListSize()

    local FocusCap = self:getFocusCap()

    if FocusCap and self.Data[FocusCap] and self.Data[FocusCap].CachedStrings then
        return #self.Data[FocusCap].CachedStrings
    end

    return 0

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:ListItemSetup(Label)

    Label:style("","CapacitiveList")
    NI.GUI.enableCropModeForLabel(Label)

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:ListItemLoad(Label, Index)

    local FocusCap = self:getFocusCap()
    if FocusCap and self.Data[FocusCap] then

        local Text = ""

        if self.Data[FocusCap].CachedStrings then
            Text = self.Data[FocusCap].CachedStrings[Index+1]
        end

        Label:setSelected(self.CachedFocusItem == Index)
        Label:setEnabled(not self.Data[FocusCap].LastItemInvalid or Index ~= #self.Data[FocusCap].CachedStrings-1)

        Label:setText(Text)

        local Color = self.Data[FocusCap].Colors and self.Data[FocusCap].Colors[Index+1]
        Label:setPaletteColorIndex(Color and (Color + 1) or 0)

    end

end

------------------------------------------------------------------------------------------------------------------------
-- 'Pure Virtuals'
------------------------------------------------------------------------------------------------------------------------
-- is cap assigned to a valid param / List / Custom behaviour
function CapacitiveOverlayList:isCapEnabled(Cap)

    return (self.CustomCapEnabledFunc and self.CustomCapEnabledFunc(Cap)) or
    	(self.Data[Cap] and
    	(self.Data[Cap].Param or
    	(self.Data[Cap].List and #self.Data[Cap].List > 0)))
end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:isVisible()
    return self.FrameWidget:isVisible()
end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:setVisible(Show)

    local FocusCap = self:getFocusCap()
    local OverlayRoot = NHLController:getHardwareDisplay():getOverlayRoot()

    -- custom list stuff
    if self.CustomShowListFunc then
        -- show
        if Show and FocusCap and  self.CustomCapEnabledFunc(FocusCap) then
            self.CustomShowListFunc(true, FocusCap)
            self.FrameWidget:setVisible(false)
            self.ArrowWidget:setVisible(false)
            return
        -- hide
        else
            self.CustomShowListFunc(false, FocusCap)
        end
    end

    self.FrameWidget:setVisible(Show)
    self.ArrowWidget:setVisible(Show)


    if not Show or self.Data[FocusCap] == nil then
        return
    end

    -- work out best width
    local SectionWidth = OverlayRoot:getWidth() / 8 -- 8 sections per (dual) screen
    local ScrollbarWidth = self.VectorWidget:getScrollbar():getWidth()

    local LongestStringIndex = self.Data[FocusCap].LongestStringIndex
    local LongestString = self.Data[FocusCap].CachedStrings[LongestStringIndex]
    local LongestStringLength = self.VectorWidget:getStringWidth(LongestString) + self.VectorItemMargin + ScrollbarWidth
    local NumSections = math.min((math.floor(LongestStringLength / SectionWidth) + 1), 4)

    -- we want the section to start above the focus cap and expand to the right but to never be split across the screens!
    local SectionStart = math.min(((FocusCap - 1) % 4) + NumSections, 4) - NumSections + (FocusCap > 4 and 4 or 0)
    local Width = NumSections * SectionWidth

    local NumItems = math.min(self:getListSize(), self.MaxItems)
    local VectorMargins = self.VectorWidget:getOuterMargin()

    self.VectorWidget:getBar():setAttribute(ATTR_SCROLLBAR_VISIBLE,
                                            self:getListSize() > self.MaxItems and "true" or "false")

    self.FrameWidget:setPos(SectionStart * SectionWidth, self.FrameTop + (self.MaxItems - NumItems) * self.VectorItemHeight)
    self.FrameWidget:setWidth(Width)
    self.FrameWidget:setHeight(NumItems * self.VectorItemHeight + VectorMargins:getTop() + VectorMargins:getBottom())

    self.ArrowWidget:setPos((FocusCap - 1) * SectionWidth, self.ArrowWidget:getOuterMargin():getTop())

    self.FrameWidget:setVisible(true)
    self.ArrowWidget:setVisible(true)
    self.VectorWidget:forceAlign()

    self:update()

end

------------------------------------------------------------------------------------------------------------------------
-- PARAMETER HELPERS
------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:isParamHandled(Param)

    if Param then
        local IsMatchingType = MaschineHelper.isRoutingParam(Param) or
            Param:getTag() == NI.DATA.MaschineParameter.TAG_ENUM
        local IsHiddenDuringAutoWrite = MaschineHelper.isAutoWriting() and not Param:isAutomatable()

        return IsMatchingType and not IsHiddenDuringAutoWrite
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------
-- returns: size of list, and whether the last item is invalid (greyed out)
function CapacitiveOverlayList:getParamListSize(Param)

    if Param:getTag() == NI.DATA.MaschineParameter.TAG_ENUM then
        return Param:getMax() + 1, false

    elseif MaschineHelper.isRoutingParam(Param) then

        return Param:getListSize(), not Param:isCurrentValueValid()
    end

    return 0, false

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:getParamListFocusIndex(Param)

    if Param:getTag() == NI.DATA.MaschineParameter.TAG_ENUM then
        return Param:getValue()

    elseif MaschineHelper.isRoutingParam(Param) then

        return Param:getValueAsIndex()
    end

    return 0

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:getParamListItemAsString(Param, Index)

    if Param:getTag() == NI.DATA.MaschineParameter.TAG_ENUM then
        return Param:getAsString(Index)

    elseif MaschineHelper.isRoutingParam(Param) then
        return Param:getListItemAsString(Index)
    end

    return "UNSUPPORTED"

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:cacheStringsFromParam(Index)

    local Param = self.Data[Index].Param
    local Strings = {}
    local Size, LastItemInvalid = self:getParamListSize(Param)
    local LongestStringLength = 0
    local LongestStringIndex = 0

    for Index = 1, Size do
        Strings[Index] = self:getParamListItemAsString(Param, Index-1)
        if #Strings[Index] >= LongestStringLength then
            LongestStringLength = #Strings[Index]
            LongestStringIndex = Index
        end
    end

    self.Data[Index].CachedStrings = Strings
    self.Data[Index].LongestStringIndex = LongestStringIndex
    self.Data[Index].LastItemInvalid = LastItemInvalid

end

------------------------------------------------------------------------------------------------------------------------
-- checks Param at ParamIndex against NewParam - used to determine if the list must be refreshed / closed
function CapacitiveOverlayList:isParamStillValid(ParamIndex, NewParam)

    -- different param
    if  self.Data[ParamIndex] == nil or
        self.Data[ParamIndex].Param == nil or
        self.Data[ParamIndex].CachedStrings == nil or
        NewParam == nil or
        not self.Data[ParamIndex].Param:isParameterEqual(NewParam) then

        return false
    end

    -- same param, different sizes -> no, except if the only diff is the invalid entry disappearing
    local NewListSize = self:getParamListSize(NewParam)
    if #self.Data[ParamIndex].CachedStrings ~= NewListSize and
        not (self.Data[ParamIndex].LastItemInvalid and NewParam:isCurrentValueValid()) then

        return false
    end

    -- different strings -> no
    for Index = 1, NewListSize do

        if self.Data[ParamIndex].CachedStrings[Index] ~= self:getParamListItemAsString(NewParam, Index - 1) then

            return false
        end
    end

    -- validity changed (e.g. by enabling 'auto write) -> no
    if not self:isParamHandled(NewParam) then

        return false
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:updateCachedFocusItem()

    local FocusCap = self:getFocusCap()
   	self.CachedFocusItem = nil

    if not FocusCap or not self.Data[FocusCap] then
        return
    end

    -- PARAM
    if self.Data[FocusCap].Param then
        local Param = self.Data[FocusCap].Param
        self.CachedFocusItem = self:getParamListFocusIndex(Param)

    -- LIST
    elseif self.Data[FocusCap].List then
    	self.CachedFocusItem = self.Data[FocusCap].ListFocusItem
    end

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayList:resetCap(Cap)

	-- reset param data
	self.Data[Cap] = {}
	self.Data[Cap].Param = nil
	self.Data[Cap].List = nil

	if Cap == self:getFocusCap() then
        CapacitiveOverlayBase.reset(self)
	end
end


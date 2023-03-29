------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/BrowseHelper"
require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Maschine/MaschineMikro/BrowseScreenMikro"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowsePageMikro = class( 'BrowsePageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- globals
------------------------------------------------------------------------------------------------------------------------

-- browse filter categories
BrowseFilter =
{
    MIN         = 1,
    FILETYPE    = 1,
    PRODUCT     = 2,
    BANK        = 3,
    SUB_BANK    = 4,
    TYPE        = 5,
    SUB_TYPE    = 6,
    MODE        = 7,
    FAVORITES   = 8,
    MAX         = 8
}

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:__init(Controller, SamplingPage)

    -- init base class
    PageMikro.__init(self, "BrowsePage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_BROWSE }

    self.IsPinned  = true

    -- track filter/list mode
    self.ListVisible = false

    -- filter
    self.CurrentFilter = BrowseFilter.FILETYPE

    self.SamplingPage = SamplingPage

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:setupScreen()

    -- setup screen
    self.Screen = BrowseScreenMikro(self)

    -- screen buttons
    self.Screen:styleScreenButtons({"FILTER", "LIST", ""}, "HeadTabRow", "HeadTab")

    -- parameter labels
    self.Screen.ParameterLabel[1]:setText("<")
    self.Screen.ParameterLabel[3]:setText(">")

    -- screen has NavMode by default
    self.Screen:setNavMode(false)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:onShow(Show)

    if Show then
        -- we want a custom InfoBar update
        self.Screen.InfoBar.UpdateFunctor = function(ForceUpdate) self:updateInfoBar(ForceUpdate) end
    else
        self.Screen:setNavMode(false)
    end

    PageMikro.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:updateScreens(ForceUpdate)

    self.Screen.ParameterLabel[2]:setVisible(not self.ListVisible)

    if ForceUpdate then
        BrowseHelper.forceCacheRefresh()
        self.Controller:setTimer(self, 2)
    end

    -- screen buttons
    self:updateScreenButtons()

    -- title
    self.Screen.InfoBar:updateFocusMixingObjectName(self.Screen.Title[1], ForceUpdate, true)

    -- info bar
    self:updateInfoBar()

    -- update Sample Browse Mode
    if self.SamplingPage then
        self:updateSampleBrowser(ForceUpdate)
    end


    -- call base class
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:onTimer()

    if self.IsVisible then
        self.Controller:setTimer(self, 1)
    end

    BrowseHelper.updateCacheTimer()

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:updateScreenButtons()

    if self.Screen:getNavMode() > 0 then
        self.Screen.ScreenButton[3]:setSelected(true)
        self.Screen.ScreenButton[3]:setText("PLUG-IN")
        return
    end

    self.Screen:styleScreenButtons({"FILTER", "LIST", ""}, "HeadTabRow", "HeadTab")
    self.Screen.ScreenButton[3]:style("", "HeadButton")

    self.Screen.ScreenButton[1]:setSelected(not self.ListVisible)
    self.Screen.ScreenButton[2]:setSelected(self.ListVisible)

    local Text = ""
    local Selected = false

    if self.Controller:getShiftPressed() then
        Text = self.SamplingPage and "CANCEL" or "LOCATE"
    else
        local FileType = BrowseHelper:getFileType()

        if self.ListVisible then
            if FileType == NI.DB3.FILE_TYPE_GROUP then

                Text = "+ PAT"
                Selected = App:getWorkspace():getLoadGroupWithPatternParameter():getValue()

            elseif NI.DATA.SamplePrehearAccess.shouldShowPrehearWidget(App) then

                Text = "PREH."
                Selected = App:getWorkspace():getPrehearEnabledParameter():getValue()

            end
        else
            Text = "USER"
            Selected = BrowseHelper:getUserMode()
        end
    end

    self.Screen.ScreenButton[3]:setVisible(Text ~= "")
    self.Screen.ScreenButton[3]:setEnabled(Text ~= "")
    self.Screen.ScreenButton[3]:setSelected(Selected)
    self.Screen.ScreenButton[3]:setText(Text)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:updateInfoBar(ForceUpdate)

    self.Screen.InfoBar.Labels[1]:setText(BrowseHelper:getFileTypeName())
    self.Screen.InfoBar.Labels[2]:setText(tostring(BrowseHelper.getResultListSize()))

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:updateSampleBrowser(ForceUpdate)

    if ForceUpdate then
        BrowseHelper.setFileType(NI.DB3.FILE_TYPE_ONESHOT_SAMPLE)
    end

    -- Hide Browse sub page if we change sound
    if NI.DATA.StateHelper.getFocusSound(App) ~= self.FocusSound then
        self.FocusSound = NI.DATA.StateHelper.getFocusSound(App)
        self:onShow(false)
        self.SamplingPage:onShow(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:updateParameters(ForceUpdate)

    if self.ListVisible then
        self:updateResultList(self.Screen.ParameterBar[3])
    else
        self.CurrentFilter = math.bound(self.CurrentFilter, BrowseFilter.MIN, BrowseFilter.MAX)
        self:updateFilterTypes(self.Screen.ParameterLabel[2], self.Screen.ParameterLabel[4])
    end

    -- algorithm for filter type display
    local CurrentFilterIndex, NumFilterTypes = self:getCurrentFilterIndexAndNumFilterTypes()

    local HasPrev = self.CurrentFilter > BrowseFilter.MIN
    local HasNext = CurrentFilterIndex < NumFilterTypes

    self.Screen.ParameterLabel[1]:setVisible(HasPrev and not self.ListVisible)
    self.Screen.ParameterLabel[3]:setVisible(HasNext and not self.ListVisible)

    self.Screen.ParameterBar[1]:setActive(not self.ListVisible)   -- setActive because of styling issues

    self.Screen.ParameterBar[2]:setActive(not self.ListVisible)
    self.Screen.ParameterBar[3]:setActive(self.ListVisible)

    -- don't call base class (as we don't want to mess with the ParameterHandler)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:updateFilterTypes(NameLabel, ValueLabel)

    local CurrentFilterIndex, NumFilterTypes = self:getCurrentFilterIndexAndNumFilterTypes()

    NameLabel:setText(tostring(CurrentFilterIndex)
        .."/"..tostring(NumFilterTypes)..": "..self:getFilterTypeNameString(self.CurrentFilter))

    local Name, ShortName = self:getFilterTypeValueString(self.CurrentFilter)

    ValueLabel:setText(ShortName or Name)

end

------------------------------------------------------------------------------------------------------------------------

-- update result list
function BrowsePageMikro:onDB3ModelChanged(Model)

    -- if we're choosing a sample and the file type changes, leave
    if self.SamplingPage and not BrowseHelper.isSampleTab() then
        self:onShow(false)
        self.SamplingPage:onShow(true)
        return
    end

    Model = BrowseHelper.updateCachedData(Model)

    if Model == nil then
        return

    elseif Model == NI.DB3.MODEL_RESULTS and self.ListVisible then
        self:updateResultList(self.Screen.ParameterBar[3])
    else
        self:updateInfoBar()
        self:updateFilterTypes(self.Screen.ParameterLabel[2], self.Screen.ParameterLabel[4])
    end

    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:updateResultList(ValueLabel)

    BrowseHelper.loadResultItem(ValueLabel, BrowseHelper:getResultListFocusItem())

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:updateLeftRightLEDs(ForceUpdate)

    if self.Screen:getNavMode() == 1 then
        LEDHelper.setLEDState(NI.HW.LED_LEFT, LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_RIGHT, LEDHelper.LS_OFF)
        return
    end

    local CurrentFilterIndex, NumFilterTypes = self:getCurrentFilterIndexAndNumFilterTypes()

    local HasPrev = self.CurrentFilter > BrowseFilter.MIN
    local HasNext = CurrentFilterIndex < NumFilterTypes

    if self.ListVisible then

        local DatabaseFrontend = App:getDatabaseFrontend()
        local FocusIndex       = BrowseHelper:getResultListFocusItem()

        HasNext = FocusIndex < BrowseHelper.getResultListSize() - 1
        HasPrev = FocusIndex > 0

    end

    LEDStateRight = HasNext and LEDHelper.LS_DIM or LEDHelper.LS_OFF
    LEDStateLeft  = HasPrev and LEDHelper.LS_DIM or LEDHelper.LS_OFF

    -- update left/right page leds
    if not self.Controller.SwitchPressed[NI.HW.BUTTON_RIGHT] then
        LEDHelper.setLEDState(NI.HW.LED_RIGHT, LEDStateRight)
    end

    if not self.Controller.SwitchPressed[NI.HW.BUTTON_LEFT] then
        LEDHelper.setLEDState(NI.HW.LED_LEFT, LEDStateLeft)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:updatePadLEDs()

    if self.Controller:getNavPressed() then

        local MixingLayer    = NI.DATA.StateHelper.getFocusMixingLayer(App)
        local ColorParameter = MixingLayer and MixingLayer:getColorParameter() or nil

        LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS, 0,
            function(Index) return BrowseHelper.getLEDStatesSlotSelectedByIndex(Index, self.Controller:getShiftPressed()) end,
            function() return ColorParameter and ColorParameter:getValue() or 16 end)

    else

        Page.updatePadLEDs(self)

    end

end

------------------------------------------------------------------------------------------------------------------------
-- event processing
------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:onWheelButton(Pressed)

    if self.Screen:getNavMode() == 1 then
        return
    end

    if Pressed and self.ListVisible then

        if self.Controller:getShiftPressed() then
            BrowseHelper.toggleFocusItemFavoriteState()
        else
            self:loadFocusItem()
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:onWheel(Inc)

    if self.Screen:getNavMode() == 1 then

        local StateCache    = App:getStateCache()
        local FocusChain    = NI.DATA.StateHelper.getFocusChainSlots(App)

        NI.DATA.ChainAccess.shiftSlotFocus(App, FocusChain, Inc)

    else

        if self.ListVisible then
            local IncrementStep = BrowseHelper.getIncrementStep(Inc, self.Controller:getShiftPressed())
            BrowseHelper.offsetResultListFocusBy(IncrementStep, true)

        else

            if self.CurrentFilter == BrowseFilter.FILETYPE then

                local Next = Inc > 0
                local HasPrev, HasNext = BrowseHelper.hasPrevNextFileType(self.SamplingPage)
                if (Next and HasNext) or (not Next and HasPrev) then
                    BrowseHelper.selectPrevOrNextVisibleFileType(Next)
                end

            elseif self.CurrentFilter == BrowseFilter.PRODUCT then

                BrowseHelper.offsetBankChain(0, Inc)

            elseif self.CurrentFilter == BrowseFilter.BANK then

                BrowseHelper.offsetBankChain(1, Inc)

            elseif self.CurrentFilter == BrowseFilter.SUB_BANK then

                BrowseHelper.offsetBankChain(2, Inc)

            elseif self.CurrentFilter == BrowseFilter.TYPE then

                BrowseHelper.offsetAttribute(0, Inc)

            elseif self.CurrentFilter == BrowseFilter.SUB_TYPE then

                BrowseHelper.offsetAttribute(1, Inc)

            elseif self.CurrentFilter == BrowseFilter.MODE then

                BrowseHelper.offsetAttribute(2, Inc)

            elseif self.CurrentFilter == BrowseFilter.FAVORITES then

                if (Inc > 0 and not BrowseHelper.isFavoritesFilterEnabled())
                    or (Inc < 0 and BrowseHelper.isFavoritesFilterEnabled()) then

                    BrowseHelper.toggleFavoritesFilter()
                end

            end

            self:updateParameters()

        end
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:onPadEvent(PadIndex, Trigger, PadValue)

    if self.Screen:getNavMode() == 1 then

        local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)

        if Trigger and Slots then
            if self.Controller:getShiftPressed() then
                local Slot = Slots:at(PadIndex - 1)
                if Slot then
                    local ActiveParameter = Slot:getActiveParameter()
                    NI.DATA.ParameterAccess.setBoolParameter(App, ActiveParameter, not ActiveParameter:getValue())
                end
            else
                if PadIndex <= Slots:size() then
                    NI.DATA.ChainAccess.setFocusSlot(App, Slots, Slots:at(PadIndex - 1), false)

                    local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)
                    if PadIndex - 1 == FocusSlotIndex then
                        ControlHelper.togglePluginWindow()
                    end
                elseif PadIndex == Slots:size() + 1 then
                    NI.DATA.ChainAccess.setFocusSlot(App, Slots, nil, false)
                end
            end
        end
        return

    elseif self.Screen:getNavMode() == 0 then

        if Trigger then
            BrowseHelper.prehearViaPad(PadIndex)
        end

    end

    PageMikro.onPadEvent(self, PadIndex, Trigger, PadValue)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:onScreenButton(ButtonIdx, Pressed)

    if Pressed and self.Screen:getNavMode() == 0 then

        if ButtonIdx == 1 then

            self.ListVisible = false

        elseif ButtonIdx == 2 then

            self.ListVisible = true

        elseif ButtonIdx == 3 then

            if self.Controller:getShiftPressed() then

                -- Cancel
                if self.SamplingPage then
                    self:onShow(false)
                    self.SamplingPage:onShow(true)

                -- QuickBrowse
                else
                    BrowseHelper.onLocate()
                end

            else

                if self.ListVisible then

                    local FileType = BrowseHelper:getFileType()

                    if FileType == NI.DB3.FILE_TYPE_GROUP then
                        BrowseHelper.toggleLoadGroupWithPattern()
                    elseif NI.DATA.SamplePrehearAccess.shouldShowPrehearWidget(App) then
                        BrowseHelper.togglePrehear()
                    end

                else
                    BrowseHelper.toggleUserMode()
                end

            end

        end

    end

    -- call base class for update
    PageMikro.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:onLeftRightButton(Right, Pressed)

    if Pressed and self.Screen:getNavMode() == 0 then

        local Inc = Right and 1 or -1

        if self.ListVisible then

            local DatabaseFrontend = App:getDatabaseFrontend()
            local ResultListModel  = DatabaseFrontend:getBrowserModel():getResultListModel()
            local FocusIndex       = ResultListModel:getFocusItem()

            local HasNext = FocusIndex < BrowseHelper.getResultListSize() - 1
            local HasPrev = FocusIndex > 0

            if (Right and HasNext) or (not Right and HasPrev) then

                LEDHelper.setLEDState(Right and NI.HW.LED_RIGHT or NI.HW.LED_LEFT, LEDHelper.LS_BRIGHT)
                BrowseHelper.offsetResultListFocusBy(Inc)

                if BrowseHelper.canPrehear() then
                    NI.DATA.SamplePrehearAccess.playLastDatabaseBrowserSelection(App)
                else
                    self:loadFocusItem()
                end
            end

        else

            local OldFilter = self.CurrentFilter

            repeat
                self.CurrentFilter = math.bound(self.CurrentFilter + Inc, BrowseFilter.MIN, BrowseFilter.MAX)
            until self:getFilterTypeValueString(self.CurrentFilter) ~= "" or self.CurrentFilter == BrowseFilter.MAX or self.CurrentFilter == BrowseFilter.MIN

            if  self:getFilterTypeValueString(self.CurrentFilter) == "" then
                self.CurrentFilter = OldFilter
            end

            self:updateParameters()

        end

    end

end

------------------------------------------------------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:getFilterTypeNameString(FilterType)

    if FilterType == BrowseFilter.FILETYPE then
        return "FILETYPE"
    elseif FilterType == BrowseFilter.PRODUCT then
        return "PRODUCT"
    elseif FilterType == BrowseFilter.BANK then
        return "BANK"
    elseif FilterType == BrowseFilter.SUB_BANK then
        return "SUB-BANK"
    elseif FilterType == BrowseFilter.TYPE then
        return "TYPE"
    elseif FilterType == BrowseFilter.SUB_TYPE then
        return "SUB-TYPE"
    elseif FilterType == BrowseFilter.MODE then

        local DatabaseFrontend = App:getDatabaseFrontend()
        local BrowserModel = DatabaseFrontend:getBrowserModel()
        local FileType = BrowserModel:getSelectedFileType()

        if BrowseHelper.supportsModes(FileType) then
            return "CHARACTER"
        end
        return "SUB-TYPE #2"

    elseif FilterType == BrowseFilter.FAVORITES then
        return "FAVORITES"
    else
        return ""
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:getFilterTypeValueString(FilterType)

    if FilterType == BrowseFilter.FILETYPE then

        return BrowseHelper:getFileTypeName()

    elseif FilterType == BrowseFilter.PRODUCT then

        return BrowseHelper.getBankChainEntry(0)

    elseif FilterType == BrowseFilter.BANK then

        return BrowseHelper.getBankChainEntry(1)

    elseif FilterType == BrowseFilter.SUB_BANK then

        return BrowseHelper.getBankChainEntry(2)

    elseif FilterType == BrowseFilter.TYPE then

        return BrowseHelper.getAttributesEntry(0)

    elseif FilterType == BrowseFilter.SUB_TYPE then

        return BrowseHelper.getAttributesEntry(1)

    elseif FilterType == BrowseFilter.MODE then

        return BrowseHelper.getAttributesEntry(2)

    elseif FilterType == BrowseFilter.FAVORITES then

        return BrowseHelper.isFavoritesFilterEnabled() and "ON" or "OFF"

    else

        return ""

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:canFocusSoundOnPadTrigger()

    return Page.canFocusSoundOnPadTrigger(self) and not BrowseHelper.isPadPrehearEnabled()

end

------------------------------------------------------------------------------------------------------------------------
-- Helper
------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:getCurrentFilterIndexAndNumFilterTypes()

    -- algorithm for filter type display
    local NumFilterTypes = BrowseFilter.MAX
    local CurrentFilterIndex = self.CurrentFilter

    for FilterIndex = BrowseFilter.MAX, BrowseFilter.MIN, -1 do

        -- if there is a filter type with no valid options..
        if self:getFilterTypeValueString(FilterIndex) == "" then
            -- ..subtract 1 from the total number of filter types
            NumFilterTypes = NumFilterTypes - 1

            if FilterIndex == self.CurrentFilter then
                -- ..adjust the current filter type, if affected
                -- (no need to wrap, as there is always a choice of FILETYPEs)
                self.CurrentFilter = self.CurrentFilter - 1
            end

            if FilterIndex <= self.CurrentFilter then
                -- ..adjust the current index
                CurrentFilterIndex = CurrentFilterIndex - 1
            end
        end

    end

    return CurrentFilterIndex, NumFilterTypes

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMikro:loadFocusItem()

    if self.SamplingPage then

        local ResultList     = App:getDatabaseFrontend():getBrowserModel():getResultListModel()
        local FocusItemIndex = ResultList:getFocusItem()

        NI.DATA.SamplerAccess.loadIntoNewZone(App, ResultList:getItemPath(FocusItemIndex))

        self:onShow(false)
        self.SamplingPage:onShow(true)

    else

        BrowseHelper.loadFocusItem()

    end

end

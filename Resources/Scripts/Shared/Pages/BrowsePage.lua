------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/BankAttributeBar"

require "Scripts/Shared/Pages/BrowsePageBase"
require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/BrowseHelper"

local ATTR_FAVORITES_FILTER = NI.UTILS.Symbol("FavoritesFilter")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowsePage = class( 'BrowsePage', BrowsePageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function BrowsePage:__init(Controller, SamplingPage)

    BrowsePageBase.__init(self, "BrowsePage", Controller, SamplingPage)

    -- create screen
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function BrowsePage:setupScreen()

    -- setup screen
    self.Screen = ScreenMaschine(self)

    -- screen buttons
    self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"<<", ">>", "LOCATE", "USER"}, "HeadButton")

    if self.SamplingPage then
        self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "CANCEL", "+ PAT", "LOAD"}, "HeadButton")
    else
        self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"PREV", "NEXT", "<<", ">>"}, "HeadButton")
        self.Screen.ScreenButton[7]:style("+ PAT", "HeadButton")
        self.Screen.ScreenButton[8]:style("LOAD", "HeadButton")
    end

    -- insert info bar
    self.Screen.InfoBar = InfoBar(self.Controller, self.Screen.ScreenLeft, "BrowseScreenLeft")

    local BottomBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "BottomBar")
    BottomBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    -- insert bank chain and attribute bar
    self.BankAttributeBar = BankAttributeBar(self.Screen, BottomBar)
    self.BankAttributeBar:setBankChainMode()

    self.PrehearWidget = NI.GUI.insertBar( BottomBar, "PrehearBar")
    self.PrehearWidget:style(NI.GUI.ALIGN_WIDGET_DOWN, '')
    local PrehearButton = NI.GUI.insertButton(self.PrehearWidget, "PrehearButton")
    PrehearButton:style("Prehear", "")
    local PrehearSpacer = NI.GUI.insertLabel(self.PrehearWidget, "Spacer")
    PrehearSpacer:style("", "Spacer3px")
    self.PrehearLabel = NI.GUI.insertLabel(self.PrehearWidget, "PrehearVolume")
    self.PrehearLabel:style("OFF", "InfoBar")

    -- insert result list vector
    local ScreenRightSpacer = NI.GUI.insertLabel(self.Screen.ScreenRight, "Spacer")
    ScreenRightSpacer:style("", "Spacer3px")
    self.ResultList = NI.GUI.insertResultListItemVector(self.Screen.ScreenRight, "ResultList")
    self.ResultList:style(false, "")
    self.ResultList:getScrollbar():setAutohide(false)
    self.ResultList:getScrollbar():setActive(false)

    -- connect vector to functions
    NI.GUI.connectVector(self.ResultList, BrowseHelper.getResultListSize, BrowseHelper.setupResultItem,
        BrowseHelper.loadResultItem)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onTimer()

    if self.IsVisible then
        self.Controller:setTimer(self, 1)
    end

    BrowseHelper.updateCacheTimer()

    PageMaschine.onTimer(self)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onDB3ModelChanged(Model)

    -- if we're choosing a sample and the file type changes, leave
    if self.SamplingPage and not BrowseHelper.isSampleTab() then
        self:onShow(false)
        self.SamplingPage:onShow(true)
        return
    end

    Model = BrowseHelper.updateCachedData(Model)

    if Model == nil then
        return
    end

    -- refresh ALL
    if Model == NI.DB3.MODEL_RESULTS then

        self:updateResultList()

    end

    self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:updateScreens(ForceUpdate)

    if ForceUpdate then
        BrowseHelper.forceCacheRefresh()
        self.ResultList:forceAlign()
        self:updateResultList()
    end

    -- insert mode: force file type according to insert slot
    if BrowseHelper.getInsertMode() == NI.DATA.INSERT_MODE_FRESH then
        if not BrowseHelper.isCurrentFileTypeInsertModeValid() then
            BrowseHelper.closeInsertMode()
        end
    end

    -- update attributes and bank chain
    self.BankAttributeBar:update(ForceUpdate)

    -- update info bar
    self.Screen.InfoBar:update(ForceUpdate)

    -- update Sample Browse Mode
    if self.SamplingPage then
        self:updateSampleBrowser(ForceUpdate)
    end

    -- update prehear display
    self:updatePrehear(ForceUpdate)

    -- base class
    PageMaschine.updateScreens(self, ForceUpdate)

    self:updateLeftRightButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------
-- Event handling
------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onLeftRightButton(Right, Pressed)

    if Pressed then
        if self.BankAttributeBar then
            self.BankAttributeBar:toggleMode()
        end
    end

    self:updateLeftRightButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onWheel(Inc)

    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then
        local IncrementStep = BrowseHelper.getIncrementStep(Inc, self.Controller:getShiftPressed())
        BrowseHelper.offsetResultListFocusBy(IncrementStep, true)
        return true
    end

    return false
end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onWheelButton(Pressed)

    if Pressed and NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then

        if self.Controller:getShiftPressed() then
            BrowseHelper.toggleFocusItemFavoriteState()
        else
            self:loadFocusItem()
        end
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onScreenEncoder(KnobIdx, Increment)

    -- all encoders are smoothed
    if MaschineHelper.onScreenEncoderSmoother(KnobIdx, Increment, .1) == 0 then
        return
    end

    if KnobIdx <= 3 then

        self.BankAttributeBar:onKnob(KnobIdx, Increment)

    elseif KnobIdx == 4 then
        BrowseHelper.changePrehearVolume(Increment)

    elseif KnobIdx >= 5 then
        local IncrementStep = BrowseHelper.getIncrementStep(Increment, self.Controller:getShiftPressed())
        BrowseHelper.offsetResultListFocusBy(IncrementStep, true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:updateScreenButtons(ForceUpdate)

    if not self.Controller:getShiftPressed() then

        self:updateScreenButtonPrevNextFileType()
        self:updateScreenButtonPrevNextPreset()

    else

        self.Screen:unsetArrowText(1)
        self.Screen.ScreenButton[1]:setVisible(false)
        self.Screen.ScreenButton[1]:setEnabled(false)
        self.Screen.ScreenButton[2]:setVisible(false)
        self.Screen.ScreenButton[2]:setEnabled(false)

        self:updateScreenButtonRouting()
        self:updateScreenButtonPattern()

        self.Screen.ScreenButton[5]:setText("SET FAV")
        self.Screen.ScreenButton[5]:setVisible(true)
        self.Screen.ScreenButton[5]:setEnabled(BrowseHelper.getResultListSize() > 0)
        self.Screen.ScreenButton[5]:setSelected(false)

        self:updateScreenButtonPrehear(6)

        if self.SamplingPage then
            self.Screen:unsetArrowText(2)
            self.Screen.ScreenButton[7]:setText(NI.HW.FEATURE.SCREEN_TYPE_STUDIO and "" or "FAVORITES")
            self.Screen.ScreenButton[7]:setAttribute(ATTR_FAVORITES_FILTER, "true")
            self.Screen.ScreenButton[8]:setText("LOAD")
        else
            self.Screen:setArrowText(2, MaschineHelper.getFocusSlotNameWithNumber())
        end

        self.Screen.ScreenButton[7]:setVisible(true)
        self.Screen.ScreenButton[7]:setEnabled(self.SamplingPage ~= nil or BrowseHelper.hasPrevNextPluginSlot(false))
        self.Screen.ScreenButton[7]:setSelected(self.SamplingPage ~= nil and BrowseHelper.isFavoritesFilterEnabled())

        self.Screen.ScreenButton[8]:setVisible(true)
        self.Screen.ScreenButton[8]:setEnabled(
            self.SamplingPage and BrowseHelper.getResultListSize() > 0 or BrowseHelper.hasPrevNextPluginSlot(true))
        self.Screen.ScreenButton[8]:setSelected(false)

    end

    BrowsePageBase.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onScreenButton(ButtonIdx, Pressed)

    if BrowseHelper.isBusy() then
        return
    end

    if Pressed then

        if not self.Controller:getShiftPressed() then

            self:onScreenButtonPrevNextFileType(ButtonIdx)
            self:onScreenButtonPrevNextPreset(ButtonIdx)

        else

            if ButtonIdx == 3 then

                self:toggleRoutingOption()

            elseif ButtonIdx == 4 then

                self:togglePatternOption()

            elseif ButtonIdx == 5 then

                BrowseHelper.toggleFocusItemFavoriteState()

            elseif ButtonIdx == 6 then

                self:togglePrehearOption()

            elseif ButtonIdx == 7 then

                if self.SamplingPage then
                    BrowseHelper.toggleFavoritesFilter()
                else
                    BrowseHelper.onPrevNextPluginSlot(false)
                end

            elseif ButtonIdx == 8 then

                if self.SamplingPage then
                    self:loadFocusItemFromScreenButton(ButtonIdx)
                else
                    BrowseHelper.onPrevNextPluginSlot(true)
                end

            end

        end

    end

    BrowsePageBase.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onVolumeButton(Pressed)

    if Pressed then
        BrowseHelper.toggleAndStoreJogWheelMode(self, NI.HW.JOGWHEEL_MODE_VOLUME)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onTempoButton(Pressed)

    if Pressed then
        BrowseHelper.toggleAndStoreJogWheelMode(self, NI.HW.JOGWHEEL_MODE_TEMPO)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onSwingButton(Pressed)

    if Pressed then
        BrowseHelper.toggleAndStoreJogWheelMode(self, NI.HW.JOGWHEEL_MODE_SWING)
    end

end

------------------------------------------------------------------------------------------------------------------------

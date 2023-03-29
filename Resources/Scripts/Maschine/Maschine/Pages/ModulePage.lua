------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/BrowseHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/ModuleHelper"
require "Scripts/Shared/Helpers/ControlHelper"
require "Scripts/Shared/Components/ScreenMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ModulePage = class( 'ModulePage', PageMaschine )


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ModulePage:__init(Controller)

    PageMaschine.__init(self, "ModulePage", Controller)

    -- create screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_BROWSE }

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function ModulePage:setupScreen()

    -- setup screen
    self.Screen = ScreenMaschine(self)

    -- style screens
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft,
        {"MASTER", "GROUP", "SOUND", ""}, "HeadTab")
    self.Screen.InfoBar:setMode("BrowseScreenLeft")

    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"PREV", "NEXT", "CANCEL", "LOAD"}, "HeadButton")

    -- setup functions of modules vector
    local Size  = function() return ModuleHelper.getResultListSize() end
    local Setup = function(Label) Label:style("", "VectorItem") end
    local Load  = function(Label, Index) ModuleHelper.loadResultListItem(Label, Index) end

    -- spacer
    local Spacer = NI.GUI.insertLabel(self.Screen.ScreenRight, "Spacer")
    Spacer:style("", "Spacer3px")

    -- insert vector
    self.ResultList = NI.GUI.insertLabelVector(self.Screen.ScreenRight, "Vector")
    self.ResultList:style(false, '')
    self.ResultList:getScrollbar():setAutohide(false)
    self.ResultList:getScrollbar():setActive(false)

    -- connect vector to functions
    NI.GUI.connectVector(self.ResultList, Size, Setup, Load)

    self.ParameterHandler:setCustomSection(1, "Attributes")
end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function ModulePage:updateScreens(ForceUpdate)

    local StateCache = App:getStateCache()
    local IsPluginPreferencesChanged =
        NI.DATA.WORKSPACE.getPluginPreferencesChanged(App)

    if StateCache:isMixingLayerChanged() or StateCache:isFocusSlotChanged() or
        IsPluginPreferencesChanged or ForceUpdate then

        if ModuleHelper.getCurrentVendorIndex() == -1 then
            local vendors = ModuleHelper.VendorNames[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()]
            ModuleHelper.CurrentVendor = vendors[1]
        end

        ModuleHelper.refreshResultList(self.ResultList)

    end

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

    self:updateLeftRightButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:updateScreenButtons(ForceUpdate)

    local GroupFocus = NI.DATA.StateHelper.getFocusGroup(App)
    local SongFocus  = NI.DATA.StateHelper.getFocusSong(App)

    if SongFocus then
        local LevelTab = SongFocus:getLevelTab()
        local GroupFocus = NI.DATA.StateHelper.getFocusGroup(App)

        -- update level tabs
        if not GroupFocus then
            for Index = 1,3 do
                self.Screen.ScreenButton[Index]:setSelected(false)
                self.Screen.ScreenButton[Index]:setEnabled(false)
            end
        else
            self.Screen.ScreenButton[1]:setSelected(LevelTab == 0)
            self.Screen.ScreenButton[1]:setEnabled(true)
            self.Screen.ScreenButton[2]:setSelected(LevelTab == 1)
            self.Screen.ScreenButton[2]:setEnabled(true)
            self.Screen.ScreenButton[2]:setText("GROUP")

            if GroupFocus then
                self.Screen.ScreenButton[3]:setText("SOUND")
                self.Screen.ScreenButton[3]:setSelected(LevelTab == 2)
                self.Screen.ScreenButton[3]:setVisible(true)
                self.Screen.ScreenButton[3]:setEnabled(true)
            else
                self.Screen.ScreenButton[3]:setText("")
                self.Screen.ScreenButton[3]:setSelected(false)
                self.Screen.ScreenButton[3]:setVisible(false)
                self.Screen.ScreenButton[3]:setEnabled(false)
            end
        end
    end

    self.Screen.ScreenButton[5]:setVisible(BrowseHelper.getInsertMode() == NI.DATA.INSERT_MODE_OFF)
    self.Screen.ScreenButton[6]:setVisible(BrowseHelper.getInsertMode() == NI.DATA.INSERT_MODE_OFF)

    self.Screen.ScreenButton[5]:setEnabled(ModulePage:canPrevious())
    self.Screen.ScreenButton[6]:setEnabled(ModulePage:canNext())

    -- call base class
    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:canPrevious()

    return ModuleHelper.getCurrentModuleIndex() > 0
        and BrowseHelper.getInsertMode() == NI.DATA.INSERT_MODE_OFF

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:canNext()

    return ModuleHelper.getCurrentModuleIndex() < ModuleHelper.getResultListSize() - 1 and
        BrowseHelper.getInsertMode() == NI.DATA.INSERT_MODE_OFF

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:updateParameters(ForceUpdate)

    local Names = {}
    local Values = {}

    if BrowseHelper.isInstrumentSlot() then
        Names[1] = "TYPE"
        Values[1] = ModuleHelper.getCurrentType() == ModuleHelper.TYPE_INSTRUMENT and "Instr." or "Effect"
    end

    Names[2] = "format"
    Values[2] = ModuleHelper.getSelectedFormat()

    Names[3] = "VENDOR"
    Values[3] = ModuleHelper.getVendorDisplayName(ModuleHelper.getCurrentVendor())

    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomValues(Values)

    PageMaschine.updateParameters(self, ForceUpdate)
end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:updateLeftRightButtonLEDs()

    local StateCache     = App:getStateCache()
    local Slots          = NI.DATA.StateHelper.getFocusChainSlots(App)
    local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)

    local HasNext = Slots and FocusSlotIndex < Slots:size() and FocusSlotIndex >= 0 or false
    local HasPrev = Slots and (Slots:size() > 0 and FocusSlotIndex ~= 0) or false

	LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT, HasPrev)
	LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT, HasNext)

end

------------------------------------------------------------------------------------------------------------------------
-- event processing
------------------------------------------------------------------------------------------------------------------------

function ModulePage:onShow(Show)

    -- call base class
    PageMaschine.onShow(self, Show)

    if Show == true then
        -- remember old jog-wheel state
        self.OldJogWheelMode = NHLController:getJogWheelMode()
        NHLController:setJogWheelMode(NI.HW.JOGWHEEL_MODE_CUSTOM)

    elseif self.OldJogWheelMode then
        NHLController:setJogWheelMode(self.OldJogWheelMode)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:onWheel(Inc)

    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then

        self:onScreenEncoder(5, Inc)
        return true
    end

	return false

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:onWheelButton(Pressed)

    if Pressed and NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then
        ModuleHelper.loadModule()
        ModuleHelper.closeModulePage(self.Controller)
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:onPrevNextButton(Pressed, Right)

    if Pressed then
        self:onScreenEncoder(5, Right and 1 or -1)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:onLeftRightButton(Right, Pressed)

    local StateCache = App:getStateCache()
    local Slots      = NI.DATA.StateHelper.getFocusChainSlots(App)

    if Slots and Pressed then
        NI.DATA.ChainAccess.shiftSlotFocus(App, Slots, Right and 1 or -1)
    end

    self:updateLeftRightButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:onScreenButton(ButtonIdx, Pressed)

    if Pressed then

        if ButtonIdx >= 1 and ButtonIdx <= 3 then

            MaschineHelper.setFocusLevelTab(ButtonIdx - 1)

        elseif ButtonIdx == 5 or ButtonIdx == 6 then

            if BrowseHelper.getInsertMode() == NI.DATA.INSERT_MODE_OFF then

                local CanLoad = ModulePage:canNext() or ButtonIdx == 5

                self:onScreenEncoder(5, ButtonIdx == 5 and -1 or 1)

                if CanLoad then
                    ModuleHelper.loadModule()
                end

            end

        elseif ButtonIdx == 7 then

            ModuleHelper.closeModulePage(self.Controller)

        elseif ButtonIdx == 8 then

            if BrowseHelper.getInsertMode() ~= NI.DATA.INSERT_MODE_OFF then

                -- call base class here already,
                -- to properly set LED states before page change
                PageMaschine.onScreenButton(self, ButtonIdx, true)

                ModuleHelper.loadModuleInsertMode()
                ModuleHelper.closeModulePage(self.Controller)
			    self:updateScreens()
                return

            else
                ModuleHelper.loadModule()
                ModuleHelper.closeModulePage(self.Controller)
            end

        end

    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:onScreenEncoder(KnobIdx, Inc)

    if KnobIdx <= 3 and MaschineHelper.onScreenEncoderSmoother(KnobIdx, Inc, 0.1) ~= 0 then

        local Diff = Inc > 0 and 1 or -1

        if BrowseHelper.isInstrumentSlot() and KnobIdx == 1 then
            local NewType = math.bound(
                ModuleHelper.getCurrentType() + Diff, ModuleHelper.TYPE_INSTRUMENT, ModuleHelper.TYPE_EFFECT)

            if NewType ~= ModuleHelper.getCurrentType() then
                ModuleHelper.setCurrentType(NewType)
                self:updateScreens(true)
            end
        elseif KnobIdx == 2 then

            local NewFormatIndex = math.bound(
                    ModuleHelper.getCurrentFormatIndex() + Diff, 0, #ModuleHelper.getPluginFormatsForCurrentType() -1)

            if NewFormatIndex ~= ModuleHelper.getCurrentFormatIndex() then
                ModuleHelper.format = ModuleHelper.getPluginFormatsForCurrentType()[NewFormatIndex + 1]
                self:updateScreens(true)
            end

        elseif KnobIdx == 3 then

            if ModuleHelper.getCurrentVendorIndex ~= -1 then
                local VendorListSize = #ModuleHelper.VendorNames[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()]

                local NewVendor = math.bound(
                    ModuleHelper.getCurrentVendorIndex() + Diff, 1, VendorListSize)

                if NewVendor ~= ModuleHelper.getCurrentVendorIndex() then
                    ModuleHelper.CurrentVendor = ModuleHelper.VendorNames[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()][NewVendor]
                    self:updateScreens(true)
                end
            else
                ModuleHelper.format = ModuleHelper.INTERNAL
                self:updateScreens(true)
            end

        end

    elseif KnobIdx >= 5 and MaschineHelper.onScreenEncoderSmoother(KnobIdx, Inc, 0.05) ~= 0 then

        local Offset = math.floor(self.ResultList:getNumFullyVisibleItems() / 2)

        if Inc > 0 and ModuleHelper.getCurrentModuleIndex()
        < ModuleHelper.getResultListSize() - 1 then

            ModuleHelper.CurrentModuleIndex[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()][ModuleHelper.getCurrentVendor()] =
                ModuleHelper.getCurrentModuleIndex() + 1
            self.ResultList:setFocusItem(
                math.min(ModuleHelper.getCurrentModuleIndex() + Offset, ModuleHelper.getResultListSize() - 1))

        elseif Inc < 0 and ModuleHelper.getCurrentModuleIndex() > 0
        then
            ModuleHelper.CurrentModuleIndex[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()][ModuleHelper.getCurrentVendor()] =
                ModuleHelper.getCurrentModuleIndex() - 1
            self.ResultList:setFocusItem(math.max(ModuleHelper.getCurrentModuleIndex() - Offset, 0))

        end

        self:refreshAccessibleEncoderInfo()
        self:updateScreenButtons()

    end

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:onPageButton(Button, PageID, Pressed)

    if Pressed then
        BrowseHelper.setInsertMode(NI.DATA.INSERT_MODE_OFF)

        if Button == NI.HW.BUTTON_BROWSE and PageID == NI.HW.PAGE_BROWSE then
            if self.Controller:getShiftPressed() then
                NHLController:getPageStack():replacePage(NI.HW.PAGE_MODULE, NI.HW.PAGE_BROWSE)
            else
                NHLController:getPageStack():popPage()
            end
            return true
        end
    end

    return PageMaschine.onPageButton(self, Button, PageID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:onVolumeButton(Pressed)

    if Pressed then
        local NewMode = NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_VOLUME
			and NI.HW.JOGWHEEL_MODE_CUSTOM
			or  NI.HW.JOGWHEEL_MODE_VOLUME

        NHLController:setJogWheelMode(NewMode)
        self.OldJogWheelMode = NewMode
    end

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:onTempoButton(Pressed)

    if Pressed then
        local NewMode = NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_TEMPO
			and NI.HW.JOGWHEEL_MODE_CUSTOM
			or  NI.HW.JOGWHEEL_MODE_TEMPO

        NHLController:setJogWheelMode(NewMode)
        self.OldJogWheelMode = NewMode
    end

end

------------------------------------------------------------------------------------------------------------------------

function ModulePage:onSwingButton(Pressed)

    if Pressed then
        local NewMode = NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_SWING
			and NI.HW.JOGWHEEL_MODE_CUSTOM
			or  NI.HW.JOGWHEEL_MODE_SWING

        NHLController:setJogWheelMode(NewMode)
        self.OldJogWheelMode = NewMode
    end

end

----------------------------------------------------------------------------------

function ModulePage:getAccessibleParamDescriptionByIndex(EncoderIdx)

    if EncoderIdx >= 1 and EncoderIdx <= 4 then
        return PageMaschine.getAccessibleParamDescriptionByIndex(self, EncoderIdx)
    end

    local Name = ModuleHelper.moduleNameAt(ModuleHelper.getCurrentModuleIndex())
    return Name, "", "", ""

end

----------------------------------------------------------------------------------

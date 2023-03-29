require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/LedHelper"

require "Scripts/Shared/Helpers/SnapshotsHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SnapshotsPage = class( 'SnapshotsPage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:__init(Controller)

    PageMaschine.__init(self, "SnapshotsPage", Controller)

    -- setup screen
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:setupScreen()

    self.Screen = ScreenWithGrid(self)
    ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"", "", "", "EXT LOCK", "UPDATE", "DELETE", "<", ">"})

    self.Screen.ScreenButton[4]:setSelected(true)
    self.Screen.ScreenButton[4]:setEnabled(true)

    self.Screen.ScreenButton[7]:style("<", "ScreenButton")
    self.Screen.ScreenButton[8]:style(">", "ScreenButton")

    self.Screen:addParameterBar(self.Screen.ScreenLeft)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:updateScreens(ForceUpdate)

    if ForceUpdate then
        LEDHelper.setLEDState(NI.HW.LED_LEFT, LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_RIGHT, LEDHelper.LS_OFF)

        self.ParameterHandler.NumParamsPerPage = 4
    end

    self.Screen:updatePadButtonsWithFunctor(
        function(Index)
            local IsSnapshot = NI.DATA.ParameterSnapshotsAccess.isSnapshotForPad(App, Index - 1)
            local IsFocusSnapshot = NI.DATA.ParameterSnapshotsAccess.isFocusSnapshotForPad(App, Index - 1)

            local SnapshotBankIndex = NI.DATA.ParameterSnapshotsAccess.getFocusSnapshotBankIndex(App)
            local SnapshotIndex = Index + (SnapshotBankIndex * 16)

            --Functor: Visible, Enabled, Selected, Focused, Text
            return true, IsSnapshot, false, IsFocusSnapshot, IsSnapshot and tostring(SnapshotIndex) or ""
        end
    )

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:updateParameters(ForceUpdate)

    self.ParameterHandler.Parameters = {}
    self.ParameterHandler.NumParamsPerPage = 4

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local SnapshotsManager = Song and Song:getParameterSnapshotsManager()
    local MorphParam = SnapshotsManager:getSnapshotMorphParameter()
    local MorphEnabled = MorphParam:getValue()
    local MorphModeParam = SnapshotsManager:getSnapshotMorphModeParameter()
    local IsModeTarget = MorphModeParam:getValue() == 1
    local MorphTimeParam = IsModeTarget and
        SnapshotsManager:getSnapshotMorphDestTimeParameter() or
        SnapshotsManager:getSnapshotMorphTimeParameter()

    local Params = {}
    Params[1] = MorphParam
    Params[2] = MorphEnabled and MorphModeParam or nil
    Params[3] = MorphEnabled and MorphTimeParam or nil

    local CustomSections = {}
    CustomSections[1] = "Morphing"

    self.ParameterHandler:setParameters(Params, true)

    self.ParameterHandler.CustomSections = CustomSections

    -- call base class
    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:updatePadLEDs()

    for Index = 1, 16 do
        local IsSnapshot = NI.DATA.ParameterSnapshotsAccess.isSnapshotForPad(App, Index - 1)
        local IsFocusSnapshot = NI.DATA.ParameterSnapshotsAccess.isFocusSnapshotForPad(App, Index - 1)

        local LEDState = IsFocusSnapshot and LEDHelper.LS_BRIGHT or (IsSnapshot and LEDHelper.LS_DIM or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(HardwareControllerBase.PAD_LEDS[Index], LEDState, LEDColors.WHITE)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:onPadEvent(PadIndex, Trigger, PadValue)

    if not Trigger then
        return
    end

    if not self.Controller:getShiftPressed() then
        self:createOrDeleteSnapshot(PadIndex)
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:createOrDeleteSnapshot(PadIndex)

    local ErasePressed = self.Controller:getErasePressed()

    if NI.DATA.ParameterSnapshotsAccess.isSnapshotForPad(App, PadIndex - 1) then
        if ErasePressed then
            NI.DATA.ParameterSnapshotsAccess.deleteParameterSnapshotFromPad(App, PadIndex - 1)
        end
    elseif not ErasePressed then
        NI.DATA.ParameterSnapshotsAccess.createParameterSnapshotFromPad(App, PadIndex - 1);
    end

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:updateScreenButtons(ForceUpdate)

    local BankIndex = NI.DATA.ParameterSnapshotsAccess.getFocusSnapshotBankIndex(App)

    local HasFocusSnapshot = NI.DATA.ParameterSnapshotsAccess.hasFocusSnapshot(App)
    self.Screen.ScreenButton[5]:setEnabled(HasFocusSnapshot)
    self.Screen.ScreenButton[6]:setEnabled(HasFocusSnapshot)

    -- Button 7 -- PAGE BANK Left
    local HasPrev = BankIndex > 0
    self.Screen.ScreenButton[7]:setEnabled(HasPrev)

    -- Button 8 -- PAGE BANK Right
    local HasNext = BankIndex < 3
    self.Screen.ScreenButton[8]:setEnabled(HasNext)

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:onScreenButton(ButtonIndex, Pressed)

    if Pressed then

        if ButtonIndex == 4 then

            NHLController:getPageStack():popPage()

        elseif ButtonIndex == 5 then

            NI.DATA.ParameterSnapshotsAccess.applyParameterSnapshot(App)

        elseif ButtonIndex == 6 then

            NI.DATA.ParameterSnapshotsAccess.deleteFocusParameterSnapshot(App)

        elseif ButtonIndex == 7 or ButtonIndex == 8 then

            SnapshotsHelper.setPrevNextSnapshotBank(ButtonIndex == 8)

        end

    end

    PageMaschine.onScreenButton(self, ButtonIndex, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:isSoundQEAllowed()

    return false

end

------------------------------------------------------------------------------------------------------------------------

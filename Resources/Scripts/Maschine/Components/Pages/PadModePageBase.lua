------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PadModePageBase = class( 'PadModePageBase', PageMaschine )


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function PadModePageBase:__init(Controller, Page)

    PageMaschine.__init(self, Page, Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_PAD_MODE }

    self.showChordMode = function() return true end

    self.ParameterHandler.NumParamsPerPage = 4
    self.ParameterHandler.NumPages = 2

    self.setupChordModeParameter = function(ScaleEngine)
        self.ParameterHandler.Parameters[3] = ScaleEngine:getChordModeParameter()

        if ScaleEngine:getChordModeParameter():getValue() ~= 0 then
            self.ParameterHandler.Parameters[4] = ScaleEngine:getCurrentChordTypeParameter()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Setup Screen
------------------------------------------------------------------------------------------------------------------------

function PadModePageBase:setupScreen()

    self.Screen.ScreenButton[1]:style("PAD MODE", "HeadPin")

end

------------------------------------------------------------------------------------------------------------------------
-- Update
------------------------------------------------------------------------------------------------------------------------

function PadModePageBase:updateScreens(ForceUpdate)

    -- update on-screen pad grid
    local PadMode =  NHLController:getPadMode()
    self.Screen:updatePadButtonsWithFunctor(function(Index) return PadModeHelper.getScreenPadButtonState(Index, PadMode) end)

    -- screen update
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageBase:updateScreenButtons(ForceUpdate)

    -- sync pad mode with that in sw
    local VelocityMode = PadModeHelper.getPadVelocityMode()
    local KeyboardModeOn = PadModeHelper.getKeyboardMode()

    -- sticky buttons
    self.Screen.ScreenButton[2]:setSelected(KeyboardModeOn)
    self.Screen.ScreenButton[3]:setSelected(VelocityMode == NI.HW.PAD_VELOCITY_16_LEVELS)
    self.Screen.ScreenButton[4]:setSelected(VelocityMode == NI.HW.PAD_VELOCITY_FIXED)

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageBase:updateParameters(ForceUpdate)

    -- FIRST PAGE
    if self.ParameterHandler.PageIndex == 1 then

        self.ParameterHandler.Parameters = {}

        local Sections = {}
        local Values = {}
        local Names = {}

        if PadModeHelper.getKeyboardMode() then -- KB MODE ON

            local ScaleEngine = NI.DATA.getScaleEngine(App)

            if ScaleEngine then
                local bChordSetActive = self.showChordMode() and ScaleEngine:getChordModeIsChordSet()
                local ScaleLabel = bChordSetActive and "" or "Scale"
                local ChordLabel = self.showChordMode() and "Chord" or ""

                Sections = { ScaleLabel, "", ChordLabel}

                if not bChordSetActive then
                    self.ParameterHandler.Parameters[1] = ScaleEngine:getScaleBankParameter()
                    self.ParameterHandler.Parameters[2] = ScaleEngine:getScaleParameter()
                end

                if self.showChordMode() then
                    self.setupChordModeParameter(ScaleEngine)
                end

            end

        else -- KB MODE OFF

            Sections = {"Choke", "", "Link", ""}

            local Sound = NI.DATA.StateHelper.getFocusSound(App)
            if Sound then
                self.ParameterHandler.Parameters[1] = Sound:getChokeGroupParameter()
                self.ParameterHandler.Parameters[2] = Sound:getChokeModeParameter()
                self.ParameterHandler.Parameters[3] = Sound:getLinkGroupParameter()
                self.ParameterHandler.Parameters[4] = Sound:getLinkModeParameter()
            end

        end

        for i = 1, 4 do
            if PadModeHelper.multiSelectionCheckers[i](App) then
                Values[i] = "*"
            end
        end

        self.ParameterHandler:setCustomValues(Values)
        self.ParameterHandler:setCustomNames(Names)
        self.ParameterHandler:setCustomSections(Sections)

    end

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageBase:onScreenButton(Index, Pressed)

    if Pressed then
        if Index == 2 then
            -- toggle step editor/piano roll mode
            PadModeHelper.toggleKeyboardMode()

        elseif Index == 3 then
            -- toggle 16-Velocity mode
            PadModeHelper.togglePadVelocityMode(NI.HW.PAD_VELOCITY_16_LEVELS)

        elseif Index == 4 then
            -- toggle Fixed Velocity mode
            PadModeHelper.togglePadVelocityMode(NI.HW.PAD_VELOCITY_FIXED)

        elseif (Index >= 5 and Index <= 8)  then
            -- set a new base key
            local Transpose = 0

            if Index == 5 then
                Transpose = -12
            elseif Index == 6 then
                Transpose = 12
            elseif Index == 7 then
                Transpose = -1
            elseif Index == 8 then
                Transpose = 1
            end

            PadModeHelper.transposeRootNoteOrBaseKey(Transpose, self.Controller)
        end
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

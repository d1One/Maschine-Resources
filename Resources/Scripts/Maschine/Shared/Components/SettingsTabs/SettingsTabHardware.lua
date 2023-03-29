------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTab"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SettingsTabHardware = class( 'SettingsTabHardware', SettingsTab )

local VELOCITIES = {"Soft 3", "Soft 2", "Soft 1", "Linear", "Hard 1", "Hard 2", "Hard 3"}
local POSITION_TOUCHSTRIP = {"Off", "Rec. Only", "On"}
local ATTR_MIX_TO_HP = NI.UTILS.Symbol("MixToHP")

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:__init()

    SettingsTab.__init(self, NI.HW.SETTINGS_HARDWARE, "HARDWARE", SettingsTab.WITH_PARAMETER_BAR)

    self.fwSupportsHPMixing = false
    self.HWPrefs = NI.HW.getMaschinePreferences()
    self.HWJamPrefs = NI.HW.getJamPreferences()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:addContextualBar(ContextualStack)

    self.DiagramContainer = NI.GUI.insertBar(ContextualStack, "TwoColumns")
    self.DiagramContainer:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    local FirstColumn = NI.GUI.insertBar(self.DiagramContainer, "LeftContainer")
    FirstColumn:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    local BigIconHardware = NI.GUI.insertBar(FirstColumn, "BigIconHardware")
    BigIconHardware:style(NI.GUI.ALIGN_WIDGET_DOWN, "SettingsBigIcon")

    local SecondColumn = NI.GUI.insertBar(self.DiagramContainer, "RightContainer")
    SecondColumn:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.HeadphonesMirroringDiagram = NI.GUI.insertLabel(SecondColumn, "HeadphonesMirroringDiagram")
    self.HeadphonesMirroringDiagram:style("", "HeadphonesMirroringDiagram")

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:onShow(Show)

    if Show then

        self.fwSupportsHPMixing = NI.HW.HardwareAlgorithms.getFirmwareSupportsHeadphoneMixing(NHLController)
        self.HWPrefs:readHardwareSettings(NHLController, false)

    else

        NHLController:writeUserData()

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:updateScreens(ForceUpdate)

    if ForceUpdate then

        self.HWPrefs:readHardwareSettings(NHLController, false)

    end

    self.HeadphonesMirroringDiagram:setVisible(self.fwSupportsHPMixing)
    self.HeadphonesMirroringDiagram:setAttribute(ATTR_MIX_TO_HP, self.HWPrefs:isMixingMainToHeadphones() and "true" or "false")

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:updateParameters(Controller, ParameterHandler)

    local HasJamParameterPage = NI.APP.isHeadless() and App:getHardwareInterface():getFocusJamControllerModel() == NI.HW.JAM_CONTROLLER_MK1
    if HasJamParameterPage then
        ParameterHandler.NumPages = 2

    else
        ParameterHandler.NumPages = 1

        if ParameterHandler.PageIndex == 2 then
            ParameterHandler.PageIndex = 1

        end

    end

    local Sections = {}
    local Parameters = {}
    local Names = {}
    local Values = {}
    local Lists = {}

    if ParameterHandler.PageIndex == 1 then
        Sections[1] = "Pads"
        Names[1] = "SENSITIVITY"
        Values[1] = tostring(math.ceil(self.HWPrefs:getSensitivity() * 100))

        Names[2] = "SCALING"
        Lists[2] = VELOCITIES
        Values[2] = VELOCITIES[self.HWPrefs:getVeloCurve() + 1]

        Sections[3] = "LEDs"
        Names[3] = "BRIGHTNESS"
        Values[3] = tostring(self.HWPrefs:getLEDsBrightness() + 1)

        Sections[4] = "Touchstrip"
        Names[4] = "SHOW POSITION"
        Lists[4] = POSITION_TOUCHSTRIP
        Values[4] = POSITION_TOUCHSTRIP[self.HWPrefs:getShowPlayPositionOnTouchstrip() + 1]

        Sections[5] = "Display"
        Names[5] = "BRIGHTNESS"
        Values[5] = tostring(self.HWPrefs:getDisplayBrightness())

        Sections[6] = NI.APP.isHeadless() and "Outputs" or "MK3 Outputs"
        local PhonesStr = "+ Phones" .. (self.fwSupportsHPMixing and "" or " (requires firmware 1.4.1)")
        Names[6] = "MAIN"
        Lists[6] = {"Line Out", PhonesStr}
        Values[6] = self.HWPrefs:isMixingMainToHeadphones() and "+ Phones" or "Line Out"

        Sections[7] = HasJamParameterPage and "TS Knobs" or "Touch-Sensitive Knobs"
        Names[7] = "AUTO-WRITE"
        Values[7] = self.HWPrefs:getAutoWriteTouchMode() and "On" or "Off"

        Controller.CapacitiveList:assignListsToCaps(Lists, Values)

    else
        local Workspace = App:getWorkspace()
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local IsomorphicParameter = Workspace:getKeyboardLayoutParameter()

        Sections[1] = "Jam Pad Layout"
        Parameters[1] = IsomorphicParameter

        if IsomorphicParameter:getValue() == PadModeHelper.IsomorphicKeyboardLayout then
            Parameters[2] = Workspace:getIsomorphicKeyboardLayoutParameter()
            Parameters[3] = Workspace:getIsomorphicTypeParameter()
            Parameters[4] = Workspace:getIsomorphicDirectionParameter()

        end

        Sections[5] = "Jam Input Velocity"
        Names[5] = "DEFAULT"
        Parameters[5] = Song and Song:getDefaultVelocityJamParameter()

        Names[6] = "ACCENT"
        Parameters[6] = Song and Song:getAccentVelocityJamParameter()

        Sections[7] = "Jam Pad Matrix"
        Names[7] = "White Focus"
        Values[7] = self.HWJamPrefs:getBrightProjectView() and "On" or "Off"

        Controller.CapacitiveList:assignParametersToCaps(Parameters)

    end

    ParameterHandler:setParameters(Parameters)
    ParameterHandler:setCustomSections(Sections)
    ParameterHandler:setCustomNames(Names)
    ParameterHandler:setCustomValues(Values)

    if self.DiagramContainer then
        self.DiagramContainer:setVisible(ParameterHandler.PageIndex == 1)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:onScreenEncoder(Index, Value, Controller, ParameterHandler)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Page = ParameterHandler.PageIndex
    local Next = Value > 0

    if Page == 1 then

        if Index == 1 then
            self:offsetPadSensitivity(Value)

        elseif Index == 2 and EncoderSmoothed then
            self:selectPrevNextVelocityCurve(Next)

        elseif Index == 3 then
            self:offsetLEDsBrightness(Value)

        elseif Index == 4 and EncoderSmoothed then
            self:selectPrevNextMK3PlaypositionTouchstrip(Next)

        elseif Index == 5 then
            self:offsetDisplayBrightness(Value)

        elseif Index == 6 and EncoderSmoothed then
            if self.fwSupportsHPMixing then
                self:selectPrevNextMK3MainToHeadphones(Next)
            end

        elseif Index == 7 and EncoderSmoothed then
            self:selectPrevNextAutoWriteTouchMode(Next)
        end

        MaschineHelper.setHardwareSettingsChanged()

    elseif Page == 2 then

        if Index == 7 and EncoderSmoothed then
            self:selectPrevNextBrightPatternFocus(Next)
            MaschineHelper.setHardwareSettingsChanged()

        end

    end

    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:offsetPadSensitivity(Value)

    -- adjust encoder speed
    Value = Value * .75

    local Current = self.HWPrefs:getSensitivity()
    self.HWPrefs:setSensitivity(App, math.bound(Current + Value, 0, 1))
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:selectPrevNextVelocityCurve(Next)

    local Current = self.HWPrefs:getVeloCurve()
    self.HWPrefs:setVeloCurve(App, math.bound(Current + (Next and 1 or -1), 0, 6))
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:offsetLEDsBrightness(Value)

    -- adjust encoder speed, with smallest increment being 1 or -1
    Value = math.ceil(math.abs(Value) * 100) * (Value > 0 and 1 or -1)

    local Current = self.HWPrefs:getLEDsBrightness()
    self.HWPrefs:setLEDsBrightness(App, math.bound(Current + Value, 0, 99))
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:offsetDisplayBrightness(Value)

    -- adjust encoder speed, with smallest increment being 1 or -1
    Value = math.ceil(math.abs(Value) * 100) * (Value > 0 and 1 or -1)

    local Current = self.HWPrefs:getDisplayBrightness() - 1
    self.HWPrefs:setDisplayBrightness(App, math.bound(Current + Value, 0, 99))
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:selectPrevNextAutoWriteTouchMode(Next)

    local Enabled = self.HWPrefs:getAutoWriteTouchMode()
    -- Disabled <-> Enabled
    if (Enabled and not Next) or (not Enabled and Next) then
        self.HWPrefs:toggleAutoWriteTouchMode(App)
    end
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:selectPrevNextMK3MainToHeadphones(Next)

    local MainToHeadphones = self.HWPrefs:isMixingMainToHeadphones()
    -- Disabled <-> Enabled
    if (MainToHeadphones and not Next) or (not MainToHeadphones and Next) then
        self.HWPrefs:setMixMainToHeadphones(NHLController,
            MainToHeadphones and NI.DATA.MIX_TO_HEADPHONES_OFF or NI.DATA.MIX_TO_HEADPHONES_ON)
    end
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:selectPrevNextBrightPatternFocus(Next)

    local IsBright = self.HWJamPrefs:getBrightProjectView()
    -- Disabled <-> Enabled
    if (IsBright and not Next) or (not IsBright and Next) then
        self.HWJamPrefs:setBrightProjectView(not IsBright)
    end
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabHardware:selectPrevNextMK3PlaypositionTouchstrip(Next)

    local Current = self.HWPrefs:getShowPlayPositionOnTouchstrip()
    self.HWPrefs:setShowPlayPositionOnTouchstrip(math.bound(Current + (Next and 1 or -1), 0, 2))
end

------------------------------------------------------------------------------------------------------------------------

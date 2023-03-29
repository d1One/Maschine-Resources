------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Jam/LevelMeter"
require "Scripts/Maschine/Jam/LevelMeterSource"
require "Scripts/Shared/Helpers/LedHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LevelMeterControls = class( 'LevelMeterControls' )

LevelMeterControls.MODE_DEFAULT = 1
LevelMeterControls.MODE_MASTER  = 2
LevelMeterControls.MODE_CUE     = 3
LevelMeterControls.MODE_GROUP   = 4

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControls:__init(Controller, LevelMeter)

    self.Controller = Controller
    self.LevelMeter = LevelMeter

    -- level input mode
    self.Mode = nil
    self:setLevelMode(LevelMeterControls.MODE_DEFAULT)

    self.LedBlinker = LEDBlinker(JamControllerBase.DEFAULT_LED_BLINK_TIME)

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControls:modeFromButton(Button)

    if Button == NI.HW.BUTTON_CUE then
        return LevelMeterControls.MODE_CUE
    elseif Button == NI.HW.BUTTON_MST then
        return LevelMeterControls.MODE_MASTER
    elseif Button == NI.HW.BUTTON_GRP then
        return LevelMeterControls.MODE_GROUP
    end

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControls:sourceFromMode(Mode)

    if Mode == LevelMeterControls.MODE_GROUP then
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        if Group then
            return LevelMeterSource.group(Group)
        end
    elseif Mode == LevelMeterControls.MODE_CUE then
        return LevelMeterSource.cue()
    else
        return LevelMeterSource.master()
    end

    return LevelMeterSource.none()

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControls:isEncoderActive()
    return self.Mode ~= LevelMeterControls.MODE_DEFAULT
end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControls:resetMode()

    NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)
    self.Mode = LevelMeterControls.MODE_DEFAULT -- toggle off
    self.LevelMeter.Source = LevelMeterSource.master()

end

------------------------------------------------------------------------------------------------------------------------
-- Default Behaviour: IN buttons select sound input, OUT buttons select output monitoring source

function LevelMeterControls:onLevelSourceButton(Button, Pressed)

    if not Pressed then
        return
    end

    local NewMode = self:modeFromButton(Button)
    if NewMode == nil or NewMode == self.Mode then
        self:resetMode()
        return
    end

    self:setLevelMode(NewMode)

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControls:setLevelMode(NewMode)

    NHLController:setEncoderMode(NI.HW.ENC_MODE_LEVEL)

    self.Mode = NewMode

    local Workspace = App:getWorkspace()
    local SourceType = nil

    -- Set input source specific parameter
    if self.Mode == LevelMeterControls.MODE_MASTER or self.Mode == LevelMeterControls.MODE_CUE then

        SourceType = NI.DATA.LEVEL_SOURCE_MASTERCUE
        local CueVisible = Workspace:getMixerCueVisibleParameter():getValue()
        local SetCue = self.Mode == LevelMeterControls.MODE_CUE
        NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Workspace:getMixerCueVisibleParameter(), SetCue)

    elseif self.Mode == LevelMeterControls.MODE_GROUP then

        SourceType = NI.DATA.LEVEL_SOURCE_GROUP
    end

    -- Set input source
    local SourceParameter = Workspace:getHWLevelMeterSourceParameter()
    if SourceType ~= nil and SourceType ~= SourceParameter:getValue() then
        NI.DATA.ParameterAccess.setSizeTParameter(App, SourceParameter, SourceType)
    end

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControls:onTimer()

    local CueVisible = App:getWorkspace():getMixerCueVisibleParameter():getValue()
    local Source = App:getWorkspace():getHWLevelMeterSourceParameter():getValue()
    local Song = NI.DATA.StateHelper.getFocusSong(App)

    -- Update LED States
    if NI.HW.PAGE_MIXING_LAYER_SELECT == NHLController:getPageStack():getTopPage() then
        local TSMode = JamHelper.getTouchstripMode()
        local EnableMSTLed = TSMode == NI.HW.TS_MODE_CONTROL or TSMode == NI.HW.TS_MODE_MACRO
        local MSTLedState = Song and Song:getLevelTab() == NI.DATA.LEVEL_TAB_SONG and
            self.LedBlinker:getBlinkStateTick() or
            (EnableMSTLed and LEDHelper.LS_DIM or LEDHelper.LS_OFF)

        LEDHelper.setLEDState(NI.HW.LED_MST, MSTLedState)
        LEDHelper.setLEDOnOff(NI.HW.LED_GRP, false)
        LEDHelper.setLEDOnOff(NI.HW.LED_CUE, false)
    elseif JamHelper.isStepModulationModeEnabled() then
        LEDHelper.setLEDOnOff(NI.HW.LED_MST, false)
        LEDHelper.setLEDOnOff(NI.HW.LED_GRP, false)
        LEDHelper.setLEDOnOff(NI.HW.LED_CUE, false)
    else
        LEDHelper.setLEDState(NI.HW.LED_MST, self.Mode == LevelMeterControls.MODE_MASTER and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_GRP, self.Mode == LevelMeterControls.MODE_GROUP and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_CUE, self.Mode == LevelMeterControls.MODE_CUE and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
    end

    LEDHelper.setLEDOnOff(NI.HW.LED_IN1, false)

    self.LevelMeter.Source = self:sourceFromMode(self.Mode)

end

------------------------------------------------------------------------------------------------------------------------

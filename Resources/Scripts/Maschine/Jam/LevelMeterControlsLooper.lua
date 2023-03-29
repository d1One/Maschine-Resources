------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Jam/LevelMeter"
require "Scripts/Maschine/Jam/LevelMeterSource"
require "Scripts/Shared/Helpers/LedHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LevelMeterControlsLooper = class( 'LevelMeterControlsLooper' )

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControlsLooper:__init(Controller, Looper, LevelMeter)

    NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)

    self.Controller = Controller
    self.LevelMeter = LevelMeter
    self.Looper     = Looper

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControlsLooper:isEncoderActive()

    return false

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControlsLooper:isSwitchFromMasterOrGroup(Button)

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
    if not Recorder or not FocusGroup then
        return false
    end

    return (Button == NI.HW.BUTTON_MST and NI.DATA.RecorderAlgorithms.isInputMaster(Recorder))
        or (Button == NI.HW.BUTTON_GRP and NI.DATA.RecorderAlgorithms.isInputGroup(Recorder)
            and (NI.DATA.RecorderAlgorithms.getInternalInputGroup(Recorder) == FocusGroup
                or not NI.DATA.RecorderAlgorithms.isValidInternalInputGroup(Recorder, FocusGroup)))
        or (Button == NI.HW.BUTTON_IN1 and
            (NI.DATA.RecorderAlgorithms.isInputMaster(Recorder)
          or NI.DATA.RecorderAlgorithms.isInputGroup(Recorder)))

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControlsLooper:resetMode()
    -- only needed for API compatibility with LevelMeterControls
end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControlsLooper:buttonTogglesLooper(Button)

    local IsIn1 = Button == NI.HW.BUTTON_IN1
    local FromMasterGroup = self:isSwitchFromMasterOrGroup(Button)

    return (IsIn1 and not self.Controller:isShiftPressed() and not FromMasterGroup)
        or (IsIn1 and not self.Looper.Enabled)

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControlsLooper:handleOSO()

    if self.Looper.Enabled and not JamHelper.isJamOSOVisible(NI.HW.OSO_LOOP_RECORD) then
        self.Controller.ParameterHandler:showOSO(NI.HW.OSO_LOOP_RECORD)
    elseif self.Looper.Enabled then
        self.Controller.ParameterHandler:startOSOTimeout()
    else
        self.Controller.ParameterHandler:hideOSO()
    end

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControlsLooper:onLevelSourceButton(Button, Pressed)

    if not Pressed then
        if Button == NI.HW.BUTTON_IN1 and not self.Looper.isPinned() then
            self.Looper:disable()
            self:handleOSO()
        end
        return
    end

    if self:buttonTogglesLooper(Button) then
        self.Looper:toggle()
        self:handleOSO()
    end

    self:updateRecorderParameters(Button)

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControlsLooper:updateRecorderParameters(Button)

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    if not Recorder then
        return
    end

    local SourceParam = Recorder:getRecordingSourceParameter()

    if self:isSwitchFromMasterOrGroup(Button) and not self.Controller:isShiftPressed() then

        NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, SourceParam, NI.DATA.SOURCE_EXTERNAL_STEREO)
        self:handleOSO()

    elseif Button == NI.HW.BUTTON_IN1 and self.Controller:isShiftPressed() then

        local Param = Recorder:getExtStereoInputsParameter()
        NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, Param, Param:getValue() == 0 and 1 or 0)
        NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, SourceParam, NI.DATA.SOURCE_EXTERNAL_STEREO)
        self:handleOSO()

    elseif Button == NI.HW.BUTTON_MST then

        NI.DATA.RecorderAccess.setInternalInputMaster(App, Recorder)
        self:handleOSO()

    elseif Button == NI.HW.BUTTON_GRP then

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        if Group and NI.DATA.RecorderAlgorithms.isValidInternalInputGroup(Recorder, Group) then
            NI.DATA.RecorderAccess.setInternalInputGroup(App, Recorder, Group)
            self:handleOSO()
        end

    elseif Button == NI.HW.BUTTON_IN1 then

        NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, Recorder:getExtStereoInputsParameter(), 0)
        NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, SourceParam, NI.DATA.SOURCE_EXTERNAL_STEREO)
        self:handleOSO()

    end

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControlsLooper:onTimer()

    self:updateLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterControlsLooper:updateLEDs()

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    if not Recorder then
        return
    end

    local Source = Recorder:getRecordingSourceParameter():getValue()

    if NI.DATA.RecorderAlgorithms.isInputMaster(Recorder) then

        LEDHelper.setLEDState(NI.HW.LED_IN1, LEDHelper.LS_DIM)
        LEDHelper.setLEDOnOff(NI.HW.LED_MST, true)
        LEDHelper.setLEDOnOff(NI.HW.LED_GRP, false)

    elseif NI.DATA.RecorderAlgorithms.isInputGroup(Recorder) then

        local LEDState = LEDHelper.LS_BRIGHT
        if NI.DATA.RecorderAlgorithms.getInternalInputGroup(Recorder) ~= NI.DATA.StateHelper.getFocusGroup(App) then
            LEDState = LEDHelper.LS_DIM
        end

        LEDHelper.setLEDState(NI.HW.LED_IN1, LEDHelper.LS_DIM)
        LEDHelper.setLEDState(NI.HW.LED_GRP, LEDState)
        LEDHelper.setLEDOnOff(NI.HW.LED_MST, false)

    elseif Source == NI.DATA.SOURCE_EXTERNAL_STEREO then

        local Input = Recorder:getExtStereoInputsParameter():getValue()
        State = Input == 0 and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM

        LEDHelper.setLEDState(NI.HW.LED_IN1, State)
        LEDHelper.setLEDOnOff(NI.HW.LED_GRP, false)
        LEDHelper.setLEDOnOff(NI.HW.LED_MST, false)

    elseif Source == NI.DATA.SOURCE_EXTERNAL_MONO then

        LEDHelper.setLEDState(NI.HW.LED_IN1, LEDHelper.LS_DIM)
        LEDHelper.setLEDOnOff(NI.HW.LED_GRP, false)
        LEDHelper.setLEDOnOff(NI.HW.LED_MST, false)

    end

    self.LevelMeter.Source = LevelMeterSource.fromRecorderInput(Recorder)
    LEDHelper.setLEDOnOff(NI.HW.LED_CUE, false)

end

------------------------------------------------------------------------------------------------------------------------

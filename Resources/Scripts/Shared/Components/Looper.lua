------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Helper/FootSwitchMultiTrigger"
require "Scripts/Maschine/Helper/LedBlinker"
require "Scripts/Maschine/Helper/SamplingHelper"
require "Scripts/Maschine/Jam/Helper/JamHelper"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/MiscHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
Looper = class( 'Looper' )

------------------------------------------------------------------------------------------------------------------------

local function onFootswitchSingle(self)

    local RecordingHandler = App:getFinishedRecordingHandler()
    if not RecordingHandler then
        return
    end

    if SamplingHelper.isRecorderWaitingOrRecording() then

        self:endRecording()

    else

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local GroupIndex = Song and Group and Song:getGroups():calcIndex(Group)
        if GroupIndex then

            self:updateTargetAndStart(GroupIndex + 1)
            if not MaschineHelper.isPlaying() then
                NI.DATA.TransportAccess.togglePlay(App)
            end

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

local function onFootswitchDouble(self)

    self:endRecording(true)

end

------------------------------------------------------------------------------------------------------------------------

local function onFootswitchHold(self)

    NI.DATA.RecorderAccess.undoPreviousRecordingTake(App)

end

------------------------------------------------------------------------------------------------------------------------

function Looper:__init(FnOnEnabled, FnOnDisabled)

    self.FnOnEnabled = FnOnEnabled
    self.FnOnDisabled = FnOnDisabled

    self.Enabled = false

    self.PadBlinker = LEDBlinker()
    self.FootswitchTrigger = FootSwitchMultiTrigger(
        function () onFootswitchSingle(self) end,
        function () onFootswitchDouble(self) end,
        function () onFootswitchHold(self) end)

end

------------------------------------------------------------------------------------------------------------------------

function Looper:isPinned()
    return NHLController:getContext():getLooperPinnedParameter():getValue()
end

------------------------------------------------------------------------------------------------------------------------

function Looper:togglePinned()
    local PinParam = NHLController:getContext():getLooperPinnedParameter()
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, PinParam, not PinParam:getValue())
end

------------------------------------------------------------------------------------------------------------------------

function Looper:toggle()

    self.Enabled = not self.Enabled

    if self.Enabled and self.FnOnEnabled then
        self:prepareLoopRecording()
        self.FnOnEnabled()
    elseif not self.Enabled and self.FnOnDisabled then
        self.FnOnDisabled()
    end

    self.FootswitchTrigger:reset()

end


------------------------------------------------------------------------------------------------------------------------

function Looper:disable()
    if self.Enabled then
        self:toggle()
    end

end

------------------------------------------------------------------------------------------------------------------------

function Looper:prepareLoopRecording(ExtInput)

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    if not Recorder then
        return
    end

    local ModeParam = Recorder:getRecordingModeParameter()
    NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, ModeParam, NI.DATA.MODE_LOOP)

end

------------------------------------------------------------------------------------------------------------------------

function Looper:updateTargetOrStop(GroupIndex, PatternIndex, IsClear)

    if self:isTarget(GroupIndex, PatternIndex) then
        self:endRecording(IsClear)
        return true
    elseif IsClear then
        return false
    end

    if self.Enabled then
        self:updateTargetAndStart(GroupIndex, PatternIndex)
        return true
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function Looper:updateTargetLED(LEDs, GroupOffset, PatternOffset)

    if #LEDs == 0 then
        return
    end

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    if not Recorder then
        return
    end

    local GroupIndex, PatternIndex = self:targetPosition()
    if not GroupIndex or not PatternIndex then
        return
    end

    local Column = GroupIndex - GroupOffset
    local Row = PatternIndex - PatternOffset
    if not math.inRange(Column, 1, #LEDs) or not math.inRange(Row, 1, #LEDs[1]) then
        return
    end

    local Color = LEDColors.WHITE
    if not Recorder:isWaiting() then
        Color = JamHelper.getPatternLEDColorByGroupAndByIndex(GroupIndex, PatternIndex)
        if not Color then -- no pattern created so far, use group color
            Color = MaschineHelper.getGroupColorByIndex(GroupIndex, false)
        end
    end

    local State = self.PadBlinker:getBlinkStateTick()
    LEDHelper.setLEDState(LEDs[Column][Row], State, Color)

end

------------------------------------------------------------------------------------------------------------------------

function Looper:endRecording(IsClear)

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    if not Recorder then
        return
    end

    if Recorder:isWaiting() or IsClear then
        SamplingHelper.requestCancelRecording()
    elseif Recorder:isRecording() then
        SamplingHelper.toggleRecording()
    end

end

------------------------------------------------------------------------------------------------------------------------

function Looper:updateTargetAndStart(GroupIndex, PatternIndex)

    -- We're interfacing with cpp now, i.e. 0-based indexes
    GroupIndex = GroupIndex - 1

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song or GroupIndex >= Song:getGroups():size() then
        return
    end

    local Recorder = Song:getRecorder()
    if Recorder:isStopped() then
        SamplingHelper.toggleRecording()
    end

    local Group = Song:getGroups():at(GroupIndex)
    if PatternIndex then
        NI.DATA.RecorderAccess.setTargetGroupAndPattern(App, Group, PatternIndex - 1)
    else
        NI.DATA.RecorderAccess.setTargetGroup(App, Group)
    end

end

------------------------------------------------------------------------------------------------------------------------

function Looper:targetPosition()

    local Target = App:getFinishedRecordingHandler()
    if not Target then
        return nil, nil
    end

    local Group = Target:getTargetGroup()
    if not Group then
        return nil, nil
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return nil, nil
    end

    return Song:getGroups():calcIndex(Group) + 1, Target:getTargetPattern() + 1

end

------------------------------------------------------------------------------------------------------------------------

function Looper:isTarget(GroupIndex, PatternIndex)

    local TGroupIndex, TPatternIndex = self:targetPosition()
    if not TGroupIndex or not TPatternIndex then
        return false
    end

    return GroupIndex == TGroupIndex and PatternIndex == TPatternIndex

end

------------------------------------------------------------------------------------------------------------------------

function Looper:onTimer()

    self.FootswitchTrigger:tick()

end

------------------------------------------------------------------------------------------------------------------------

function Looper:onFootswitch(Pressed)

    if Pressed then
        self.FootswitchTrigger:press()
    else
        self.FootswitchTrigger:release()
    end

end


------------------------------------------------------------------------------------------------------------------------

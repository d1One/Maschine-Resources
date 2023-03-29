-----------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/NSAHelper"
require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTab"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SettingsTabAudio = class( 'SettingsTabAudio', SettingsTab )

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAudio:__init()

    SettingsTab.__init(self, NI.HW.SETTINGS_AUDIO, "AUDIO", SettingsTab.WITH_PARAMETER_BAR)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAudio:addContextualBar(ContextualStack)

    local TwoColumns = NI.GUI.insertBar(ContextualStack, "TwoColumns")
    TwoColumns:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    local FirstColumn = NI.GUI.insertBar(TwoColumns, "LeftContainer")
    FirstColumn:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    local BigIconAudio = NI.GUI.insertBar(FirstColumn, "BigIconAudio")
    BigIconAudio:style(NI.GUI.ALIGN_WIDGET_DOWN, "SettingsBigIcon")

    local SecondColumn = NI.GUI.insertBar(TwoColumns, "RightContainer")
    SecondColumn:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.AudioStatusLabel = NI.GUI.insertLabel(SecondColumn, "AudioStatusLabel")
    self.AudioStatusLabel:style("", "AudioStatusLabel")
    self.AudioLatencyLabel = NI.GUI.insertMultilineLabel(SecondColumn, "AudioLatencyLabel")
    self.AudioLatencyLabel:style("AudioLatencyLabel")
    self.AudioTotalLatencyLabel = NI.GUI.insertLabel(SecondColumn, "AudioTotalLatencyLabel")
    self.AudioTotalLatencyLabel:style("", "AudioTotalLatencyLabel")

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAudio:onShow(Show)

    if not Show then

        NSAHelper.storeSetup()

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAudio:updateParameters(Controller, ParameterHandler)

    ParameterHandler.NumPages = 6

    self.AudioStatusLabel:setText(NSAHelper.getAudioStatusCaption())
    local Latency, TotalLatency = NSAHelper.getAudioLatencyCaptions()
    self.AudioLatencyLabel:setText(Latency)
    self.AudioTotalLatencyLabel:setText(TotalLatency)

    local Sections = {}
    local Names = {}
    local Lists = {}
    local Values = {}

    if ParameterHandler.PageIndex == 1 then

        Sections = {"Interface"}
        Names = {"DRIVER", "DEVICE", "SAMPLE RATE", "BUFFER SIZE"}

        -- DRIVER
        local Drivers, FocusDriver = NSAHelper.getDriverList()
        Lists[1] = Drivers
        Values[1] = FocusDriver

        -- DEVICE
        local Devices, FocusDevice = NSAHelper.getDeviceList()
        Lists[2] = Devices
        Values[2] = FocusDevice

        -- SAMPLE RATES
        local SampleRates, FocusSampleRate = NSAHelper.getSampleRateList()
        Lists[3] = SampleRates
        Values[3] = FocusSampleRate

        -- BUFFER SIZE
        Values[4] = NSAHelper.getBufferSize()
        Lists[4] = {}

    elseif ParameterHandler.PageIndex == 2 then

        Sections = {"Input Routings"}
        Names = {"IN 1L", "IN 1R", "IN 2L", "IN 2R", "IN 3L", "IN 3R", "IN 4L", "IN 4R"}

        local AudioInputs = NSAHelper.getAudioChannelList(true)
        for Index = 1, 8 do
            local ChannelName = NSAHelper.getAudioChannel(Index, true)
            Lists[Index] = AudioInputs
            Values[Index] = ChannelName
        end


    else -- pages 3 to 6: audio outputs

        local Start = (ParameterHandler.PageIndex - 3) * 4
        Sections = {"Output Routings ("..(Start+1).."-"..(Start+4)..")"}

        local AudioOutputs = NSAHelper.getAudioChannelList(false)
        for Index = 1, 8 do
            Names[Index] = "OUT "..(Start + math.floor((Index+1)/2))..(Index%2 == 1 and "L" or "R")
            local ChannelName = NSAHelper.getAudioChannel(Start*2 + Index, false)
            Lists[Index] = AudioOutputs
            Values[Index] = ChannelName
        end

    end

    ParameterHandler:setParameters({})
    ParameterHandler:setCustomNames(Names)
    ParameterHandler:setCustomValues(Values)
    ParameterHandler:setCustomSections(Sections)
    Controller.CapacitiveList:assignListsToCaps(Lists, Values)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAudio:onCapTouched(Cap, Touched, Controller, ParameterHandler)

    if not Touched then

        if ParameterHandler.PageIndex > 1 then
            -- commit requested mappings when releasing cap touch
            NSAHelper.commitAudioChannelMappings()
            self:updateParameters(Controller, ParameterHandler)
        end

        NHLController:writeUserData()

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAudio:onScreenEncoder(Index, Value, Controller, ParameterHandler)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Page = ParameterHandler.PageIndex
    local Next = Value > 0

    if not EncoderSmoothed then
        return
    end

    if Page == 1 then

        if Index == 1  then
            NSAHelper.selectPrevNextDriver(Next)

        elseif Index == 2  then
            NSAHelper.selectPrevNextDevice(Next)

        elseif Index == 3 then
            NSAHelper.selectPrevNextSampleRate(Next)

        elseif Index == 4 then
            NSAHelper.selectPrevNextBufferSize(Next)
        end

        MaschineHelper.setAudioMIDISettingsChanged()

    elseif Page == 2 then

        NSAHelper.requestPrevNextAudioChannel(Index, Next, true)

    else -- audio outputs routings

        NSAHelper.requestPrevNextAudioChannel(Index + (Page - 3) * 8, Next, false)
    end

    self:updateParameters(Controller, ParameterHandler)

end

------------------------------------------------------------------------------------------------------------------------

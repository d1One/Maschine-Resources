-----------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/NSAHelper"
require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTab"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SettingsTabMH1071Audio = class( 'SettingsTabMH1071Audio', SettingsTab )

local MH1071_INTERNAL_DEVICE_NAME = "hw:Plus,0"
local MH1071_INTERNAL_DEVICE_ALIAS = "Internal"

local PARAMETER_PAGE_INDEX_INTERFACE = 1
local PARAMETER_PAGE_INDEX_INPUT = 2

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMH1071Audio:__init()

    SettingsTab.__init(self, NI.HW.SETTINGS_AUDIO, "AUDIO", SettingsTab.WITH_PARAMETER_BAR)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMH1071Audio:addContextualBar(ContextualStack)

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

function SettingsTabMH1071Audio:onShow(Show)

    if not Show then

        NSAHelper.storeSetup()

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMH1071Audio:updateParameters(Controller, ParameterHandler)

    ParameterHandler.NumPages = 6

    self.AudioStatusLabel:setText(NSAHelper.getAudioStatusCaption())
    local Latency, TotalLatency = NSAHelper.getAudioLatencyCaptions()
    self.AudioLatencyLabel:setText(Latency)
    self.AudioTotalLatencyLabel:setText(TotalLatency)

    local Sections = {}
    local Names = {}
    local Lists = {}
    local Values = {}

    if ParameterHandler.PageIndex == PARAMETER_PAGE_INDEX_INTERFACE then

        Sections = { "Interface" }
        Names = { "DEVICE" }

        -- DEVICE
        local Devices, FocusDevice = self:getDeviceList()
        Lists[1] = Devices
        Values[1] = FocusDevice

    elseif ParameterHandler.PageIndex == PARAMETER_PAGE_INDEX_INPUT then

        Sections = {"Input Routings"}
        Names = {"IN 1L", "IN 1R", "IN 2L", "IN 2R", "IN 3L", "IN 3R", "IN 4L", "IN 4R"}

        local AudioInputs = self:getAudioChannelList(true)
        for Index = 1, 8 do
            local ChannelName = self:getAudioChannel(Index, true)
            Lists[Index] = AudioInputs
            Values[Index] = ChannelName
        end


    else -- pages 3 to 6: audio outputs

        local Start = (ParameterHandler.PageIndex - 3) * 4
        Sections = {"Output Routings ("..(Start+1).."-"..(Start+4)..")"}

        local AudioOutputs = self:getAudioChannelList(false)
        for Index = 1, 8 do
            Names[Index] = "OUT "..(Start + math.floor((Index+1)/2))..(Index%2 == 1 and "L" or "R")
            local ChannelName = self:getAudioChannel(Start*2 + Index, false)
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

function SettingsTabMH1071Audio:onCapTouched(Cap, Touched, Controller, ParameterHandler)

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

function SettingsTabMH1071Audio:onScreenEncoder(Index, Value, Controller, ParameterHandler)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Page = ParameterHandler.PageIndex
    local Next = Value > 0

    if not EncoderSmoothed then
        return
    end

    if Page == PARAMETER_PAGE_INDEX_INTERFACE then

        if Index == 1  then
            NSAHelper.selectPrevNextDevice(Next)

        end

        MaschineHelper.setAudioMIDISettingsChanged()

    elseif Page == PARAMETER_PAGE_INDEX_INPUT then

        NSAHelper.requestPrevNextAudioChannel(Index, Next, true)

    else -- audio outputs routings

        NSAHelper.requestPrevNextAudioChannel(Index + (Page - 3) * 8, Next, false)
    end

    self:updateParameters(Controller, ParameterHandler)

end

------------------------------------------------------------------------------------------------------------------------

local function checkAndApplyAlias(String)

    return String:gsub(MH1071_INTERNAL_DEVICE_NAME, MH1071_INTERNAL_DEVICE_ALIAS)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMH1071Audio:getDeviceList()

    local Devices, FocusDevice = NSAHelper.getDeviceList()

    for Index = 1, #Devices do
        Devices[Index] = checkAndApplyAlias(Devices[Index])

    end

    FocusDevice = checkAndApplyAlias(FocusDevice)

    return Devices, FocusDevice

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMH1071Audio:getAudioChannelList(Input)

    local AudioChannels = NSAHelper.getAudioChannelList(Input)

    for Index = 1, #AudioChannels do
        AudioChannels[Index] = checkAndApplyAlias(AudioChannels[Index])

    end

    return AudioChannels

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMH1071Audio:getAudioChannel(Index, Input)

    return checkAndApplyAlias(NSAHelper.getAudioChannel(Index, Input))

end

------------------------------------------------------------------------------------------------------------------------

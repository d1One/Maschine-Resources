------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/MiscHelper"
require "Scripts/Shared/Helpers/NSAHelper"
require "Scripts/Maschine/Helper/MidiRecallHelper"
require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTab"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SettingsTabMidi = class( 'SettingsTabMidi', SettingsTab )

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMidi:__init()

    SettingsTab.__init(self, NI.HW.SETTINGS_MIDI, "MIDI", SettingsTab.WITH_PARAMETER_BAR)

    self.HWPrefs = NI.HW.getMaschinePreferences()
    self.SelectedMIDIDevice = {[true] = 1, [false] = 1}
    self.SelectedMIDIChange = NI.DATA.MIDI_RECALL_SCENE

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMidi:onShow(Show)

    if not Show then

        NSAHelper.storeSetup()

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMidi:updateParameters(Controller, ParameterHandler)

    ParameterHandler.NumPages = 2

    if ParameterHandler.PageIndex == 1 then
        local Workspace = App:getWorkspace()
        local Preferences = NI.APP.Preferences.getGeneral()

        local Lists = {}
        local Values = {}
        local Names = {"MODE", "", "", "", "SELECT", "STATUS", "SELECT", "STATUS"}
        local Params = {}

        Params[4] = Workspace:getLinkEnabledParameter()

        local MIDISyncList, MIDISyncValue, MIDISyncValueShort =
            NSAHelper.getMIDISyncList(Workspace:getLinkEnabledParameter():getValue())

        Lists[1] = MIDISyncList
        Values[1] = MIDISyncValue

        Names[3] = "DEFAULT"
        Lists[3] = { "Focus", "None" }
        Values[3] = Preferences:getDefaultMidiInput() == NI.DATA.DEFAULT_MIDI_INPUT_FOCUS and "Focus" or "None"

        Lists[5] = NSAHelper.getMIDIDevicesList(true)
        self.SelectedMIDIDevice[true] = math.bound(self.SelectedMIDIDevice[true], 1, #Lists[5] or 1)

        Values[5] = #Lists[5] == 0 and "-" or Lists[5][self.SelectedMIDIDevice[true]]
        Values[6] = NSAHelper.getMIDIDeviceState(self.SelectedMIDIDevice[true], true)

        Lists[7] = NSAHelper.getMIDIDevicesList(false)
        self.SelectedMIDIDevice[false] = math.bound(self.SelectedMIDIDevice[false], 1, #Lists[7] or 1)

        Values[7] = #Lists[7] == 0 and "-" or Lists[7][self.SelectedMIDIDevice[false]]
        Values[8] = NSAHelper.getMIDIDeviceState(self.SelectedMIDIDevice[false], false)

        ParameterHandler:setParameters(Params)
        ParameterHandler:setCustomSections({"MIDI Sync", "", "MIDI Input", "Link", "Input Devices", "", "Output Devices"})
        ParameterHandler:setCustomNames(Names)

        if Values[1] ~= "Off" then
            Names[2] = "CLOCK OFFSET"
            Values[2] = self:getMIDIClockOffset()
            local AlternativeValues = table.copy(Values)
            AlternativeValues[1] = MIDISyncValueShort
            ParameterHandler:setCustomValues(AlternativeValues)
        else
            ParameterHandler:setCustomValues(Values)
        end

        Controller.CapacitiveList:assignListsToCaps(Lists, Values)

    elseif ParameterHandler.PageIndex == 2 then
        local Lists = {}
        local Values = {}
        local Names = {}
        local Sections = {}
        local FocusedIndexes = {}
        local Params = {}

        MidiRecallHelper.populateMidiChangeParameters(self.SelectedMIDIChange, 1, Lists, Values, Names, Sections, FocusedIndexes, Params)

        ParameterHandler:setParameters(Params)
        ParameterHandler:setCustomSections(Sections)
        ParameterHandler:setCustomValues(Values)
        ParameterHandler:setCustomNames(Names)

        for Index = 1, 8 do
            if Params[Index] then
                Controller.CapacitiveList:assignParameterToCap(Params[Index], Index)

            else
                Controller.CapacitiveList:assignListToCap(Index, Lists[Index])
                Controller.CapacitiveList:setListFocusItem(Index, FocusedIndexes[Index])

            end

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMidi:addContextualBar(ContextualStack)

    local TwoColumns = NI.GUI.insertBar(ContextualStack, "TwoColumns")
    TwoColumns:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    local FirstColumn = NI.GUI.insertBar(TwoColumns, "LeftContainer")
    FirstColumn:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    local BigIconMidi = NI.GUI.insertBar(FirstColumn, "BigIconMidi")
    BigIconMidi:style(NI.GUI.ALIGN_WIDGET_DOWN, "SettingsBigIcon")

    local SecondColumn = NI.GUI.insertBar(TwoColumns, "RightContainer")
    SecondColumn:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.LinkStatus = NI.GUI.insertLinkStatus(SecondColumn, App, "LinkStatus")
    self.LinkPhaseMeter = NI.GUI.insertLinkPhaseMeter(SecondColumn, App, "LinkPhase")

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMidi:onScreenEncoder(Index, Value, Controller, ParameterHandler)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Page = ParameterHandler.PageIndex
    local Next = Value > 0

    if not EncoderSmoothed then
        return
    end

    if Page == 1 then
        if Index == 1 then
            NSAHelper.selectPrevNextMIDISync(Next, App:getWorkspace():getLinkEnabledParameter():getValue())

        elseif Index == 2 then
            self:selectPrevNextMIDIClockOffset(Next)

        elseif Index == 3 then
            self:selectPrevNextMIDIInputDefaultMode(Next)

        elseif Index == 5 or Index == 7 then
            self:selectPrevNextMIDIDevice(Next, Index == 5)

        elseif Index == 6 or Index == 8 then
            NSAHelper.selectPrevNextMIDIDeviceStatus(Next, self.SelectedMIDIDevice[Index == 6], Index == 6)
        end

    elseif Page == 2 then
        if Index == 1 then
            self.SelectedMIDIChange = MidiRecallHelper.selectPrevNextMIDIChange(Next, self.SelectedMIDIChange)

        elseif Index == 3 then
            MidiRecallHelper.selectPrevNextSource(self.SelectedMIDIChange, Next)

        elseif Index == 4 then
            NI.DATA.MidiRecallAccess.setPrevNextChannel(App, self.SelectedMIDIChange, Next)

        end

    end

    self:updateParameters(Controller, ParameterHandler)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMidi:selectPrevNextMIDIDevice(Next, Input)

    if (Next and self.SelectedMIDIDevice[Input] < NSAHelper.getMIDIDevicesListSize(Input))
        or (not Next and self.SelectedMIDIDevice[Input] > 1) then

        self.SelectedMIDIDevice[Input] = self.SelectedMIDIDevice[Input] + (Next and 1 or -1)
    end
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMidi:getMIDIClockOffset()

    if NSAHelper.getMIDISyncStatus() == NI.NSA.MIDI_SYNC_RECEIVE then
        -- from 0 -> 200 to -100 -> +100
        local Offset = self.HWPrefs:getMidiClockSyncOffset(App)
        return tostring(Offset - 100)
    end

    return NSAHelper.getMidiClockMasterSyncOffset()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMidi:selectPrevNextMIDIInputDefaultMode(Next)

    local Preferences = NI.APP.Preferences.getGeneral()
    local Value = Preferences:getDefaultMidiInput()

    if Value == NI.DATA.DEFAULT_MIDI_INPUT_FOCUS and Next then

        Preferences:setDefaultMidiInput(NI.DATA.DEFAULT_MIDI_INPUT_NONE)

    elseif Value == NI.DATA.DEFAULT_MIDI_INPUT_NONE and not Next then

        Preferences:setDefaultMidiInput(NI.DATA.DEFAULT_MIDI_INPUT_FOCUS)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMidi:selectPrevNextMIDIClockOffset(Next)

    if NSAHelper.getMIDISyncStatus() == NI.NSA.MIDI_SYNC_RECEIVE then

        local Offset = self.HWPrefs:getMidiClockSyncOffset(App)
        self.HWPrefs:setMidiClockSyncOffset(App, Offset + (Next and 1 or -1))

    elseif NSAHelper.getMIDISyncStatus() == NI.NSA.MIDI_SYNC_SEND then
        NSAHelper.selectPrevNextClockMasterOffset(Next)
    end

end

------------------------------------------------------------------------------------------------------------------------

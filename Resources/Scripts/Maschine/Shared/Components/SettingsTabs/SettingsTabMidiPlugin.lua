------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Helper/MidiRecallHelper"
require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTab"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SettingsTabMidiPlugin = class( 'SettingsTabMidiPlugin', SettingsTab )

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMidiPlugin:__init()

    SettingsTab.__init(self, NI.HW.SETTINGS_MIDI, "MIDI", SettingsTab.WITH_PARAMETER_BAR)

    self.SelectedMIDIChange = NI.DATA.MIDI_RECALL_SCENE

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMidiPlugin:updateParameters(Controller, ParameterHandler)

    ParameterHandler.NumPages = 1

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

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMidiPlugin:addContextualBar(ContextualStack)

    local TwoColumns = NI.GUI.insertBar(ContextualStack, "TwoColumns")
    TwoColumns:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    local FirstColumn = NI.GUI.insertBar(TwoColumns, "LeftContainer")
    FirstColumn:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    local BigIconMidi = NI.GUI.insertBar(FirstColumn, "BigIconMidi")
    BigIconMidi:style(NI.GUI.ALIGN_WIDGET_DOWN, "SettingsBigIcon")

    local SecondColumn = NI.GUI.insertBar(TwoColumns, "RightContainer")
    SecondColumn:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabMidiPlugin:onScreenEncoder(Index, Value, Controller, ParameterHandler)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Next = Value > 0

    if not EncoderSmoothed then
        return
    end

    if Index == 1 then
        self.SelectedMIDIChange = MidiRecallHelper.selectPrevNextMIDIChange(Next, self.SelectedMIDIChange)

    elseif Index == 3 then
        MidiRecallHelper.selectPrevNextSource(self.SelectedMIDIChange, Next)

    elseif Index == 4 then
        NI.DATA.MidiRecallAccess.setPrevNextChannel(App, self.SelectedMIDIChange, Next)

    end

    self:updateParameters(Controller, ParameterHandler)

end

------------------------------------------------------------------------------------------------------------------------

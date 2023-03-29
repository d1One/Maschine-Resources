------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MidiRecallHelper = class( 'MidiRecallHelper' )

------------------------------------------------------------------------------------------------------------------------

function MidiRecallHelper.getSources(Type)
    local Sources = {}
    local NumSources = NI.DATA.MidiRecallAccess.getNumSources(App, Type)
    local FocusedIndex = NI.DATA.MidiRecallAccess.getSelectedSourceIndex(App, Type)
    local FocusedSource = "-"

    for Index = 0, NumSources - 1 do
        local Source = NI.DATA.MidiRecallAccess.getSourceAtIndex(App, Type, Index)
        table.insert(Sources, Source)
        if Index == FocusedIndex then
            FocusedSource = Source

        end

    end

    return Sources, FocusedSource, FocusedIndex

end

------------------------------------------------------------------------------------------------------------------------

function MidiRecallHelper.selectPrevNextSource(Type, Next)
    local Sources, FocusedSource, FocusedIndex = MidiRecallHelper.getSources(Type)
    local NewFocusIndex = FocusedIndex + (Next and 1 or -1)

    if NewFocusIndex >= 0 and NewFocusIndex < #Sources then
        NI.DATA.MidiRecallAccess.setSourceFromIndex(App, Type, NewFocusIndex)

    end

end

------------------------------------------------------------------------------------------------------------------------

function MidiRecallHelper.getTypeAsString(Type)
    if Type == NI.DATA.MIDI_RECALL_SCENE then
        return "Scene"

    elseif Type == NI.DATA.MIDI_RECALL_SECTION then
        return "Section"

    elseif Type == NI.DATA.MIDI_RECALL_LOCK then
        return "Lock"

    end

    return ""

end

------------------------------------------------------------------------------------------------------------------------

function MidiRecallHelper.selectPrevNextMIDIChange(Next, MIDIChangeType)
    if (Next and MIDIChangeType ~= NI.DATA.MIDI_RECALL_LOCK)
        or (not Next and MIDIChangeType ~= NI.DATA.MIDI_RECALL_SCENE) then

        MIDIChangeType = MIDIChangeType + (Next and 1 or -1)
    end

    return MIDIChangeType

end

------------------------------------------------------------------------------------------------------------------------

function MidiRecallHelper.getMidiRecall(Type)
    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song and Type == NI.DATA.MIDI_RECALL_SCENE then
        return Song:getSceneRecall()

    elseif Song and Type == NI.DATA.MIDI_RECALL_SECTION then
        return Song:getSectionRecall()

    elseif Song and Type == NI.DATA.MIDI_RECALL_LOCK then
        return Song:getSnapshotRecall()

    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function MidiRecallHelper.populateMidiChangeParameters(Type, StartIndex, Lists, Values, Names, Sections, FocusedIndexes, Params)

    local FirstKnobIndex = StartIndex
    local SecondKnobIndex = StartIndex + 1
    local ThirdKnobIndex = StartIndex + 2
    local FourthKnobIndex = StartIndex + 3

    Sections[StartIndex] = "MIDI Change"

    Names[FirstKnobIndex] = "TYPE"
    Lists[FirstKnobIndex] = { MidiRecallHelper.getTypeAsString(NI.DATA.MIDI_RECALL_SCENE),
                 MidiRecallHelper.getTypeAsString(NI.DATA.MIDI_RECALL_SECTION),
                 MidiRecallHelper.getTypeAsString(NI.DATA.MIDI_RECALL_LOCK) }
    Values[FirstKnobIndex] = MidiRecallHelper.getTypeAsString(Type)
    FocusedIndexes[FirstKnobIndex] = Type

    local MidiRecall = MidiRecallHelper.getMidiRecall(Type)

    if MidiRecall then
        local TriggerParameter = MidiRecall:getTriggerParameter()
        local IsMidiChangeEnabled = TriggerParameter:getValue() ~= NI.DATA.MIDI_RECALL_TRIGGER_NONE
        Params[SecondKnobIndex] = MidiRecall:getTriggerParameter()

        if IsMidiChangeEnabled and NI.APP.isStandalone() then

            local Sources, FocusedSource, FocusedThirdKnobIndex = MidiRecallHelper.getSources(Type)
            Names[ThirdKnobIndex] = "SOURCE"
            Values[ThirdKnobIndex] = FocusedSource
            Lists[ThirdKnobIndex] = Sources
            FocusedIndexes[ThirdKnobIndex] = FocusedThirdKnobIndex

            Names[FourthKnobIndex] = "CHANNEL"
            Values[FourthKnobIndex] = tostring(NI.DATA.MidiRecallAccess.getSelectedChannel(App, Type))

        elseif IsMidiChangeEnabled then
            Names[ThirdKnobIndex] = "CHANNEL"
            Values[ThirdKnobIndex] = tostring(NI.DATA.MidiRecallAccess.getSelectedChannel(App, Type))

        end
    end

end

------------------------------------------------------------------------------------------------------------------------

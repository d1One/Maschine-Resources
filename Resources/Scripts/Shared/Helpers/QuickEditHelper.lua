------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/EventsHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
QuickEditHelper = class( 'QuickEditHelper' )

------------------------------------------------------------------------------------------------------------------------

function QuickEditHelper.getStepValueText()

    local WheelMode = NHLController:getJogWheelMode()

    if WheelMode == NI.HW.JOGWHEEL_MODE_VOLUME then
        return EventsHelper.getSelectedNoteEventsDisplayValue("EventVelocities")
    elseif WheelMode == NI.HW.JOGWHEEL_MODE_SWING then
        return EventsHelper.getSelectedNoteEventsDisplayValue("EventPositions")
    elseif WheelMode == NI.HW.JOGWHEEL_MODE_TEMPO then
        return EventsHelper.getSelectedNoteEventsDisplayValue("EventPitches")
    else
        return ""
    end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditHelper.getSoundTuneParam(Sound)

    if not Sound then
        return nil
    end

    local Slots = Sound:getChain():getSlots()
    local Slot = (Slots and Slots:size() > 0) and Slots:at(0)
    local Module = Slot and Slot:getModule()
    local ModuleID = Module and Module:getInfo():getId()

    if ModuleID == NI.DATA.ModuleInfo.ID_SAMPLER then
        local Sampler = Sound:getSampler()
        return Sampler and Sampler:getTuneParameter()

    elseif ModuleID == NI.DATA.ModuleInfo.ID_AUDIO then
        local AudioModule = Sound:getAudioModule()
        return AudioModule and AudioModule:getTuneParameter()

    elseif ModuleID == NI.DATA.ModuleInfo.ID_KICK then
        return Module and Module:getKickTuneParameter()

    elseif ModuleID == NI.DATA.ModuleInfo.ID_SNARE then
        return Module and Module:getSnareTuneParameter()

    elseif ModuleID == NI.DATA.ModuleInfo.ID_HIHAT then
        return Module and Module:getHihatTuneParameter()

    elseif ModuleID == NI.DATA.ModuleInfo.ID_TOM then
        return Module and Module:getTomTuneParameter()

    elseif ModuleID == NI.DATA.ModuleInfo.ID_PERC then
        return Module and Module:getPercTuneParameter()

    elseif ModuleID == NI.DATA.ModuleInfo.ID_CYMBAL then
        return Module and Module:getCymbalTuneParameter()
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditHelper.canTuneGroup(Group)

    if not Group then
        return false
    end

    local Sounds = Group:getSounds()

    for n = 0, 15 do

        local Sound = Sounds and Sounds:at(n)
        local Param = QuickEditHelper.getSoundTuneParam(Sound)

        if Param then
            return true
        end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------


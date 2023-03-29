------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/QuickEditHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Shared/Helpers/StepHelper"
require "Scripts/Shared/MikroMK3ASeries/QuickEditMikroMK3ASeries"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
QuickEditMikroMK3 = class( 'QuickEditMikroMK3' )

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:__init(Controller)

    self.Controller = Controller
    self:reset()

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:reset()

    self:resetGroupTuneOffset()

    self.NumPadsPressed = 0

    -- for step edit mode: when wheel wasn't used before releasing a held pad,
    -- remove the held step(s), otherwise the step was modified, so don't remove them
    self.RemoveStepsOnPadRelease = true

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:resetGroupTuneOffset()

    self.GroupTuneOffset = 0

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:getLevel()

    if self:inMasterLevel() then
        return NI.DATA.LEVEL_TAB_SONG
    elseif self:inGroupLevel() then
        return NI.DATA.LEVEL_TAB_GROUP
    else
        if not self:inSoundLevel() then
            print("WARNING: QuickEditMikroMK3 Mixing Level out of sync or is invalid")
        end
        return NI.DATA.LEVEL_TAB_SOUND
    end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:inStepMode()

    return PadModeHelper.isStepModeEnabled() and not self:inMasterLevel() and not self:inGroupLevel()

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:inMasterLevel()

    return self.NumPadsPressed == 0 and not self:inGroupLevel()

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:inGroupLevel()

    return NHLController:getPageStack():isTopPage(NI.HW.PAGE_QUICK_EDIT_GROUP)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:inSoundLevel()

     return self.NumPadsPressed > 0 and not self:inGroupLevel()

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:getModeString()

    if self:inStepMode() then
        return self:getStepModeString()
    end

    local WheelMode = NHLController:getJogWheelMode()
    if WheelMode == NI.HW.JOGWHEEL_MODE_VOLUME then

        return "Volume"

    elseif WheelMode == NI.HW.JOGWHEEL_MODE_TEMPO then

        return self:inMasterLevel() and "Tempo" or "Tune"

    elseif WheelMode == NI.HW.JOGWHEEL_MODE_SWING then

        return "Swing "

    end

    return ""

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:getStepModeString()

    local WheelMode = NHLController:getJogWheelMode()
    if WheelMode == NI.HW.JOGWHEEL_MODE_VOLUME then

        return "Velocity"

    elseif WheelMode == NI.HW.JOGWHEEL_MODE_TEMPO then

        return "Pitch"

    elseif WheelMode == NI.HW.JOGWHEEL_MODE_SWING then

        return "Position"

    end

    return ""

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:getValueString()

    local WheelMode = NHLController:getJogWheelMode()

    if self:inStepMode() then

        return QuickEditHelper.getStepValueText()

    elseif WheelMode == NI.HW.JOGWHEEL_MODE_VOLUME then

        return self:getValueStringVolume()

    elseif WheelMode == NI.HW.JOGWHEEL_MODE_SWING then

        return self:getValueStringSwing()

    elseif WheelMode == NI.HW.JOGWHEEL_MODE_TEMPO then

        return self:getValueStringTuneTempo()

    end

    return "-"

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:getValueStringVolume()

    local String = "N/A"
    local Object = self:getLevelObject()
    local Parameter = Object and Object:getLevelParameter()
    if Parameter then
        String = Parameter:getAsString(Parameter:getValue())
    end

    return String

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:getValueStringSwing()

    local String = "N/A"
    local Object = self:getLevelObject()
    local Parameter = Object and Object:getSwingAmountParameter()

    if Parameter then
        -- for Swing showing 100.0%; remove the decimal part and show just 100%
        local Value = Parameter:getValue()
        String = Value == 100
            and string.format("%.0f %%", Value)
            or  Parameter:getAsString(Value)
    end

    return String

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:getValueStringTuneTempo()

    local String = "N/A"
    if self:inMasterLevel() then

        String = self:getSongTempoString()

    elseif self:inGroupLevel() then

        String = self:getGroupTuneString()

    else

        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        local Parameter = QuickEditHelper.getSoundTuneParam(Sound)
        if Parameter then
            String = Parameter:getAsString(Parameter:getValue())
        end

    end

    return String

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:getSongTempoString()

    return QuickEditMikroMK3ASeries.getSongTempoString()

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:getGroupTuneString()

    local String = "N/A"
    if QuickEditHelper.canTuneGroup(NI.DATA.StateHelper.getFocusGroup(App)) then

        local GroupTuneOffset = self.GroupTuneOffset * 36
        local GroupTuneOffsetDeadBand = 0.005

        if math.abs(GroupTuneOffset) < GroupTuneOffsetDeadBand then
            GroupTuneOffset = 0.0
        end

        String = string.format("%.2f", GroupTuneOffset)

    end

    return String

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:getLevelObject()

    if self:inMasterLevel() then
        return NI.DATA.StateHelper.getFocusSong(App)
    elseif self:inGroupLevel() then
        return NI.DATA.StateHelper.getFocusGroup(App)
    elseif self:inSoundLevel() then
        return NI.DATA.StateHelper.getFocusSound(App)
    end

    print("WARNING: QuickEditMikroMK3 does not have valid mixing level")
    return nil

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:onPadEvent(PadIndex, Trigger, PadValue)

    self.NumPadsPressed = math.max(self.NumPadsPressed + (Trigger and 1 or -1), 0)

    if PadModeHelper.isStepModeEnabled() and not self:inGroupLevel() then

        if Trigger or self.RemoveStepsOnPadRelease then
            StepHelper.onPadEvent(PadIndex, Trigger, PadValue)
        else
            -- avoid removing note on release, just update HoldingPads
            StepHelper.HoldingPads[PadIndex] = nil
        end

        StepHelper.selectHoldingNotes(StepHelper.PatternSegment)

        if StepHelper.getHoldPadSize() == 0 then
            self.RemoveStepsOnPadRelease = true
        end

    else

        if self.NumPadsPressed == 0 then
            self:resetGroupTuneOffset()
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:onWheel(Inc)

    local WheelMode = NHLController:getJogWheelMode()

    if self:inStepMode() then

        self.RemoveStepsOnPadRelease = false
        NI.DATA.EventPatternAccess.modifySelectedNotesByJogWheel(App, WheelMode, Inc)

    elseif WheelMode == NI.HW.JOGWHEEL_MODE_VOLUME then

        self:onVolume(Inc)

    elseif WheelMode == NI.HW.JOGWHEEL_MODE_TEMPO then

        self:onTuneTempo(Inc)

    elseif WheelMode == NI.HW.JOGWHEEL_MODE_SWING then

        self:onSwing(Inc)

    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:isFineIncrement()

    return self.Controller:isShiftPressed()

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:onVolume(Inc)

    local Object = self:getLevelObject()
    local Parameter = Object and Object:getLevelParameter()
    if Parameter then
        NI.DATA.ParameterAccess.addParameterWheelDelta(App, Parameter, Inc, self:isFineIncrement(), true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:onSwing(Inc)

    local Object = self:getLevelObject()
    local Parameter = Object and Object:getSwingAmountParameter()
    if Parameter then
        NI.DATA.ParameterAccess.addParameterWheelDelta(App, Parameter, Inc, self:isFineIncrement(), true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:onTuneTempo(Inc)

    if self:inMasterLevel() then

        return self:onSongTempo(Inc)

    elseif self:inGroupLevel() then

        return self:onGroupTune(Inc)

    elseif self:inSoundLevel() then

        return self:onSoundTune(Inc)

    end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:onSongTempo(Inc)

    QuickEditMikroMK3ASeries.incrementSongTempo(Inc, self:isFineIncrement())

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:onGroupTune(Inc)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if not QuickEditHelper.canTuneGroup(Group) then
        return
    end

    local FineInc = self:isFineIncrement()
    local Delta = Inc * Group:getTuneOffsetIncrementScaling(FineInc)
    self.GroupTuneOffset = math.bound(self.GroupTuneOffset + Delta, -1, 1)

    NI.DATA.GroupAccess.offsetSoundsTuneParam(App, Group, Delta, FineInc)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3:onSoundTune(Inc)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Parameter = QuickEditHelper.getSoundTuneParam(Sound)
    if Parameter then
        NI.DATA.ParameterAccess.addParameterWheelDelta(App, Parameter, Inc, self:isFineIncrement(), true)
    end

end

------------------------------------------------------------------------------------------------------------------------


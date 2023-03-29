------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/QuickEditHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
QuickEditBase = class( 'QuickEditBase' )

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:__init(Controller)

    self.Controller = Controller
    self.Level = NI.DATA.LEVEL_TAB_SONG
    self.GroupTuneOffset = 0
    self.NumPadPressed = 0
    self.NumGroupPressed = 0
    self.IsChanged = false

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:getMode()

    return NHLController:getJogWheelMode()

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:setMode(Mode)

    NHLController:setTempJogWheelMode(Mode)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:setLevel(Level)

    self.Level = Level
    self.GroupTuneOffset = 0

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:isChanged()

    return self.IsChanged

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:resetChangedFlag()

    self.IsChanged = false

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:onPadEvent(PadIndex, Pressed)

    self.NumPadPressed = math.max(self.NumPadPressed + (Pressed and 1 or -1), 0)    -- should always >= 0

    if Pressed then
        self:setLevel(NI.DATA.LEVEL_TAB_SOUND)
    end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:onGroupButton(Index, Pressed)

	if Pressed and self.Controller:getShiftPressed() then
		return
	end

    self.NumGroupPressed = math.max(self.NumGroupPressed + (Pressed and 1 or -1), 0)   -- should always >= 0

    if Pressed then
        self:setLevel(NI.DATA.LEVEL_TAB_GROUP)
    end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:onWheel(Inc)

    local Mode = self:getMode()

    if Mode == NI.HW.JOGWHEEL_MODE_TEMPO then

        self:onTuneTempoChange(Inc, true)

    elseif Mode == NI.HW.JOGWHEEL_MODE_SWING then

        self:onSwingChange(Inc, true)

    elseif Mode == NI.HW.JOGWHEEL_MODE_VOLUME then

        self:onVolumeChange(Inc, true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:getLevelObject()

    if self.Level == NI.DATA.LEVEL_TAB_SONG then
        return NI.DATA.StateHelper.getFocusSong(App)

    elseif self.Level == NI.DATA.LEVEL_TAB_GROUP then
        return NI.DATA.StateHelper.getFocusGroup(App)

    elseif self.Level == NI.DATA.LEVEL_TAB_SOUND then
        return NI.DATA.StateHelper.getFocusSound(App)
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:getLevelText()

    if self.Level == NI.DATA.LEVEL_TAB_SONG then
        return "MASTER"

    elseif self.Level == NI.DATA.LEVEL_TAB_GROUP then
        return "GROUP"

    elseif self.Level == NI.DATA.LEVEL_TAB_SOUND then
        return "SOUND"
    end

    return ""

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:getModeText()

    local Mode = self:getMode()

    if Mode == NI.HW.JOGWHEEL_MODE_VOLUME then
        return "VOL"

    elseif Mode == NI.HW.JOGWHEEL_MODE_TEMPO then
        return self.Level == NI.DATA.LEVEL_TAB_SONG and "TEMPO" or "TUNE"

    elseif Mode == NI.HW.JOGWHEEL_MODE_SWING then
        return "SWING"
    end

    return ""

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:getFocusParam()

    local Mode = self:getMode()

    if Mode == NI.HW.JOGWHEEL_MODE_TEMPO then

        if self.Level == NI.DATA.LEVEL_TAB_SONG then

            local Song = NI.DATA.StateHelper.getFocusSong(App)
            return Song and Song:getTempoParameter()

        elseif self.Level == NI.DATA.LEVEL_TAB_GROUP then

            return nil --Group tune: no param

        elseif self.Level == NI.DATA.LEVEL_TAB_SOUND then

            local Sound = NI.DATA.StateHelper.getFocusSound(App)
            return QuickEditHelper.getSoundTuneParam(Sound)

        end

    elseif Mode == NI.HW.JOGWHEEL_MODE_SWING then

        local Object = self:getLevelObject()
        return Object and Object:getSwingAmountParameter()

    elseif Mode == NI.HW.JOGWHEEL_MODE_VOLUME then

        local Object = self:getLevelObject()
        return Object and Object:getLevelParameter()

    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:onTuneTempoChange(Inc, ViaWheel)

    local Param = self:getFocusParam()
    local FineInc = self.Controller:getShiftPressed() or (ViaWheel and NHLController:getWheelPressed())

    if Param then

        local SongLevel = self.Level == NI.DATA.LEVEL_TAB_SONG
        local CanControlTransport = SongLevel and NI.DATA.TransportAccess.canControlTransport(App)

        if not SongLevel or CanControlTransport then
            if ViaWheel then
                NI.DATA.ParameterAccess.addParameterWheelDelta(App, Param, Inc, FineInc, true)
            else
                NI.DATA.ParameterAccess.addParameterEncoderDelta(App, Param, Inc, FineInc, true)
            end
        end

    elseif self.Level == NI.DATA.LEVEL_TAB_GROUP then

        local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
        if FocusGroup and QuickEditHelper.canTuneGroup(FocusGroup) then

            if not ViaWheel then
                Inc = Inc > 0 and 1 or -1
            end

            Inc = Inc * FocusGroup:getTuneOffsetIncrementScaling(FineInc)
            self.GroupTuneOffset = math.bound(self.GroupTuneOffset + Inc, -1, 1)

            NI.DATA.GroupAccess.offsetSoundsTuneParam(App, FocusGroup, Inc, FineInc)

        end

    end

    self.IsChanged = true

end


------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:onSwingChange(Inc, ViaWheel)

    local Param = self:getFocusParam()
    local FineInc = self.Controller:getShiftPressed() or (ViaWheel and NHLController:getWheelPressed())

    if Param then
        if ViaWheel then
            NI.DATA.ParameterAccess.addParameterWheelDelta(App, Param, Inc, FineInc, true)
        else
            NI.DATA.ParameterAccess.addParameterEncoderDelta(App, Param, Inc, FineInc, true)
        end
    end

    self.IsChanged = true

end


------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:onVolumeChange(Inc, ViaWheel)

    local Param = self:getFocusParam()
    local FineInc = self.Controller:getShiftPressed() or (ViaWheel and NHLController:getWheelPressed())

    if Param then
        if ViaWheel then
            NI.DATA.ParameterAccess.addParameterWheelDelta(App, Param, Inc, FineInc, true)
        else
            NI.DATA.ParameterAccess.addParameterEncoderDelta(App, Param, Inc, FineInc, true)
        end

        self.IsChanged = true
    end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditBase:getValueFormatted()

    local Param = self:getFocusParam()
    local Mode = self:getMode()

    if Mode == NI.HW.JOGWHEEL_MODE_TEMPO then

        if self.Level == NI.DATA.LEVEL_TAB_SONG then

            return Param:getAsString(Param:getValue()).." BPM"

        elseif self.Level == NI.DATA.LEVEL_TAB_GROUP then

            if QuickEditHelper.canTuneGroup(NI.DATA.StateHelper.getFocusGroup(App)) then

                local GroupTuneOffset = self.GroupTuneOffset * 36
                local GroupTuneOffsetDeadBand = 0.005

                if math.abs(GroupTuneOffset) < GroupTuneOffsetDeadBand then
                    GroupTuneOffset = 0.0
                end

                return string.format("%.2f", GroupTuneOffset)
            else
                return "N/A"
            end

        end

    end

    return Param and Param:getAsString(Param:getValue()) or "N/A"

end

------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Jam/Pages/PadModePageBase"
require "Scripts/Maschine/Helper/MuteSoloHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MutePage = class( 'MutePage', PadModePageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function MutePage:__init(Controller)

    PadModePageBase.__init(self, "MutePage", Controller)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_MUTE }

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function MutePage:updateGroupLEDs()

    LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS,
        JamHelper.getGroupOffset(),
        MuteSoloHelper.getGroupMuteByIndexLEDStates,
        MaschineHelper.getGroupColorByIndex,
        MaschineHelper.getFlashStateGroupsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------

function MutePage:updatePadLEDs()

    -- turn off non pad sounds
    JamHelper.turnOffNonSoundPads(self.Controller.PAD_LEDS)

    -- update sound leds with focus state
    LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_SOUND_LEDS, 0,
		function(Index) return MuteSoloHelper.getSoundMuteByIndexLEDStates(Index, false) end,
        MaschineHelper.getSoundColorByIndex,
        MaschineHelper.getFlashStateSoundsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------

function MutePage:updateDPadLEDs()

    PadModePageBase.updateDPadLEDs(self)

    -- Disable up/down leds
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_UP, NI.HW.BUTTON_DPAD_UP, false)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_DOWN, NI.HW.BUTTON_DPAD_DOWN, false)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function MutePage:onPadButton(Column, Row, Trigger)

    if not Trigger then
        return
    end

    local SoundIndex = JamHelper.getSoundIndexByColumRow(Column, Row)
    if not SoundIndex then
        return
    end

    -- mute / unmute sound by pad index
    local MuteSoundFunction =
        function(Sounds, Sound)
            local MuteParameter = Sound:getMuteParameter()
            NI.DATA.ParameterAccess.setBoolParameter(App, MuteParameter, not MuteParameter:getValue())
        end

    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)

    if self.Controller:isClearActive() then
        MaschineHelper.removeSound(SoundIndex)
    elseif FocusGroup then
        MaschineHelper.callFunctionWithObjectVectorAndItemByIndex(FocusGroup:getSounds(), SoundIndex, MuteSoundFunction)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MutePage:onGroupButton(GroupIndex, Pressed)

    if not Pressed then
        return
    end

    -- call mute group
    local AdjustedIndex = GroupIndex + JamHelper.getGroupOffset()
    local FocusSong = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = FocusSong and FocusSong:getGroups()
    local Group = Groups and Groups:at(AdjustedIndex - 1) or nil

    if self.Controller:isClearActive() then
        MaschineHelper.removeGroup(GroupIndex)
    elseif Group then
        -- mute / unmute group by group index
        local MuteParameter = Group:getMuteParameter()
        NI.DATA.ParameterAccess.setBoolParameter(App, MuteParameter, not MuteParameter:getValue())
    end

end

------------------------------------------------------------------------------------------------------------------------


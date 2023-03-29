------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Jam/Pages/PadModePageBase"
require "Scripts/Maschine/Helper/MuteSoloHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SoloPage = class( 'SoloPage', PadModePageBase )

------------------------------------------------------------------------------------------------------------------------

function SoloPage:__init(Controller)

    -- init base class
    PadModePageBase.__init(self, "SoloPage", Controller)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SOLO }

end

------------------------------------------------------------------------------------------------------------------------

function SoloPage:updateGroupLEDs(UpdateGroupBank)

    LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS,
        JamHelper.getGroupOffset(),
        MuteSoloHelper.getGroupMuteByIndexLEDStates,
        MaschineHelper.getGroupColorByIndex,
        MaschineHelper.getFlashStateGroupsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------

function SoloPage:updatePadLEDs()

    -- turn off non-pad sounds
    JamHelper.turnOffNonSoundPads(self.Controller.PAD_LEDS)

    -- update sound leds with focus state
    LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_SOUND_LEDS, 0,
        function(Index) return MuteSoloHelper.getSoundMuteByIndexLEDStates(Index, false) end,
        MaschineHelper.getSoundColorByIndex,
        MaschineHelper.getFlashStateSoundsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------

function SoloPage:updateDPadLEDs()

    PadModePageBase.updateDPadLEDs(self)

    -- Disable up/down leds
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_UP, NI.HW.BUTTON_DPAD_UP, false)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_DOWN, NI.HW.BUTTON_DPAD_DOWN, false)

end

------------------------------------------------------------------------------------------------------------------------

function SoloPage:onGroupButton(GroupIndex, Pressed)

    if not Pressed then
        return
    end

    GroupIndex = GroupIndex + JamHelper.getGroupOffset()

    if self.Controller:isClearActive() then
        MaschineHelper.removeGroup(GroupIndex)
    else
        MuteSoloHelper.toggleGroupSoloState(GroupIndex)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SoloPage:onPadButton(Column, Row, Trigger)

    if not Trigger then
        return
    end

    local SoundIndex = JamHelper.getSoundIndexByColumRow(Column, Row)
    if SoundIndex then
        if self.Controller:isClearActive() then
            MaschineHelper.removeSound(SoundIndex)
        else
            MuteSoloHelper.toggleSoundSoloState(SoundIndex)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

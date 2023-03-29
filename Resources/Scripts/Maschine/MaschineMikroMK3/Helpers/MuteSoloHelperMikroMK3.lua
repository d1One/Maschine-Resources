------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/MuteSoloHelper"
require "Scripts/Maschine/MaschineMikroMK3/Helpers/GroupPadHelperMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MuteSoloHelperMikroMK3 = class( 'MuteSoloHelperMikroMK3' )

-- Helper for displaying pads and screen information for mute & solo MikroMK3 pages

------------------------------------------------------------------------------------------------------------------------
-- PadIndex 1-based
function MuteSoloHelperMikroMK3.setTopLineGroup(Page, GroupIndex)

    if GroupIndex and GroupIndex > 0 then

        local ZeroBasedIndex = GroupIndex - 1
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Group = Song:getGroups():at(ZeroBasedIndex)
        Page.Screen:setTopRowToGroup(Group, ZeroBasedIndex)

    else

        Page.Screen:setTopRowToFocusedGroup()

    end

end

------------------------------------------------------------------------------------------------------------------------

function MuteSoloHelperMikroMK3.setTopLineSound(Page, PadIndex)

    if PadIndex and PadIndex > 0 then

        local ZeroBasedIndex = PadIndex - 1
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local Sound = Group and Group:getSounds():at(ZeroBasedIndex)
        Page.Screen:setTopRowToSound(Sound, ZeroBasedIndex)

    else

        Page.Screen:setTopRowToFocusedSound()

    end

end

------------------------------------------------------------------------------------------------------------------------

function MuteSoloHelperMikroMK3.updateSoundPadLeds(App)

    local SelectedEnabledFunction =
    function(Index)
        local AudioMode = false
        return MuteSoloHelper.getSoundMuteByIndexLEDStates(Index, AudioMode)
    end

    -- update sound leds with focus state
    LEDHelper.updateLEDsWithFunctor(App.Controller.PAD_LEDS,
                                    0,
                                    SelectedEnabledFunction,
                                    MaschineHelper.getSoundColorByIndex,
                                    MaschineHelper.getFlashStateSoundsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------

function MuteSoloHelperMikroMK3.updateGroupPadLeds(App)

    local SelectedPadFunction =
    function (Index)
        return MuteSoloHelper.getGroupMuteByIndexLEDStates(Index)
    end

    GroupPadHelperMikroMK3.showGroupPads(App,
                                            App.Controller.PAD_LEDS,
                                            App.Controller.GROUP_LEDS,
                                            SelectedPadFunction)

end

------------------------------------------------------------------------------------------------------------------------
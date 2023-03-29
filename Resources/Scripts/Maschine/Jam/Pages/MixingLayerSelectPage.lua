------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Jam/Pages/PadModePageBase"
require "Scripts/Maschine/Helper/LedBlinker"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MixingLayerSelectPage = class( 'MixingLayerSelectPage', PadModePageBase )

------------------------------------------------------------------------------------------------------------------------

function MixingLayerSelectPage:__init(Controller)

    PadModePageBase.__init(self, "MixingLayerSelectPage", Controller)

    self.PageLEDs = {}
    self.LEDBlinker = LEDBlinker(JamControllerBase.DEFAULT_LED_BLINK_TIME)

    self.GetOSOTypeFn = function()
        local TSMode = JamHelper.getTouchstripMode()
        if JamHelper.isStepModulationModeEnabled() then
            return NI.HW.OSO_NONE
        elseif TSMode == NI.HW.TS_MODE_SWING then
            return NI.HW.OSO_SWING
        elseif TSMode == NI.HW.TS_MODE_TUNE then
            return NI.HW.OSO_TUNE
        else
            return NI.HW.OSO_NONE
        end
    end

    self.CloseOSOOnPageLeaveFn = function()
        local TSMode = JamHelper.getTouchstripMode()
        return TSMode ~= NI.HW.TS_MODE_SWING and TSMode ~= NI.HW.TS_MODE_TUNE and
            JamHelper.isJamNonStaticOSOVisible() and
            not self.Controller:isButtonPressed(NI.HW.BUTTON_SWING) and
            not self.Controller:isButtonPressed(NI.HW.BUTTON_TUNE)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixingLayerSelectPage:onPadButton(Column, Row, Pressed)

    if not NI.DATA.StateHelper.getFocusGroup(App) then
        return
    end

    if Pressed and Column >= 5 and Column <= 8 and Row >= 5 and Row <= 8 then

        if MaschineHelper.getLevelTab() ~= NI.DATA.LEVEL_TAB_SOUND then
            MaschineHelper.setFocusLevelTab(NI.DATA.LEVEL_TAB_SOUND)
        end

        local TSMode = JamHelper.getTouchstripMode()
        local ChangeSoundOffset = TouchstripControlsJam.isOutputMode(TSMode) or
            TSMode == NI.HW.TS_MODE_SWING or TSMode == NI.HW.TS_MODE_TUNE
        if ChangeSoundOffset then
            JamHelper.setSoundOffset((Row == 7 or Row == 8) and 0 or 8)
        end

        local SoundIndex = JamHelper.getSoundIndexByColumRow(Column, Row)
        JamHelper.focusSoundByIndex(SoundIndex, self.Controller)

        if not MaschineHelper.hasSoundFocus() then
            MaschineHelper.setSoundFocus()
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function MixingLayerSelectPage:onGroupButton(Index, Pressed)

    if Pressed then

        MaschineHelper.setFocusLevelTab(NI.DATA.LEVEL_TAB_GROUP)
        MaschineHelper.setGroupFocus()

        PageJam.onGroupButton(self, Index, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixingLayerSelectPage:onGroupCreate(GroupIndex, Pressed, Song)

    -- do not create new Groups when on Select Page

end

------------------------------------------------------------------------------------------------------------------------

function MixingLayerSelectPage:onLevelSourceButton(Button, Pressed)

    if Button == NI.HW.BUTTON_MST and Pressed and TouchstripControlsJam.canSongFocus() then

        MaschineHelper.setFocusLevelTab(NI.DATA.LEVEL_TAB_SONG)
        MaschineHelper.setSongFocus()

    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function MixingLayerSelectPage:updatePadLEDs()

    if not NI.DATA.StateHelper.getFocusGroup(App) then
        JamHelper.turnOffMatrixLEDs()
        return
    end

    local SoundOffset = JamHelper.getSoundOffset()
    local MixingLayerIsSound = MaschineHelper.getLevelTab() == NI.DATA.LEVEL_TAB_SOUND
    local TouchstripMode = JamHelper.getTouchstripMode()
    local IsOutputMode = TouchstripControlsJam.isOutputMode(TouchstripMode)
    local FocusSoundIndex = MixingLayerIsSound and NI.DATA.StateHelper.getFocusSoundIndex(App) + 1 or -1

    JamHelper.turnOffNonSoundPads(self.Controller.PAD_LEDS)

    local LedStateFunctor = function(Index)
        local Selected = true
        if Index == FocusSoundIndex then
            Selected = self.LEDBlinker:getBlinkStateTick() == LEDHelper.LS_BRIGHT
        elseif IsOutputMode or TouchstripMode == NI.HW.TS_MODE_SWING or TouchstripMode == NI.HW.TS_MODE_TUNE then
            if SoundOffset >= 8 then
                Selected = Index > 8
            else
                Selected = Index <= 8
            end
        end

        return MixingLayerIsSound and Selected, true
    end

    LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_SOUND_LEDS, 0,
                                    LedStateFunctor,
                                    MaschineHelper.getSoundColorByIndex)

end

------------------------------------------------------------------------------------------------------------------------

function MixingLayerSelectPage:updateGroupLEDs()

    local MixingLayerIsGroup = MaschineHelper.getLevelTab() == NI.HW.LEVEL_TAB_GROUP
    local FocusGroupIndex = MixingLayerIsGroup and NI.DATA.StateHelper.getFocusGroupIndex(App)+1 or -1

    local LedStateFunctor = function (Index)

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Groups = Song and Song:getGroups()

        if Groups and Index > 0 and Index <= Groups:size() then

            local Enabled = Groups:at(Index - 1) ~= nil
            local Selected = Enabled and MixingLayerIsGroup

            if Selected and FocusGroupIndex == Index then
                Selected = self.LEDBlinker:getBlinkStateTick() == LEDHelper.LS_BRIGHT
            end

            return Selected, Enabled

        end

        return false, false

    end

    LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS, JamHelper.getGroupOffset(), LedStateFunctor,
                                    function (Index) return MaschineHelper.getGroupColorByIndex(Index, true) end)

end

------------------------------------------------------------------------------------------------------------------------

function MixingLayerSelectPage:onPinButton(Pressed)

    -- handle event in order to prevent pinned
    return true

end

------------------------------------------------------------------------------------------------------------------------

function MixingLayerSelectPage:onDPadButton(Button, Pressed)

    if Pressed and JamHelper.getTouchstripMode() == NI.HW.TS_MODE_CONTROL then

        if Button == NI.HW.BUTTON_DPAD_UP or Button == NI.HW.BUTTON_DPAD_DOWN then
            ControlHelper.onPrevNextSlot(Button == NI.HW.BUTTON_DPAD_DOWN, false)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function MixingLayerSelectPage:updateDPadLEDs()

    LEDHelper.setLEDOnOff(NI.HW.LED_DPAD_LEFT, false)
    LEDHelper.setLEDOnOff(NI.HW.LED_DPAD_RIGHT, false)

    local TouchstripMode = JamHelper.getTouchstripMode()

    local HasPrev = TouchstripMode == NI.HW.TS_MODE_CONTROL and
        ControlHelper.hasPrevNextSlotOrPageGroup(false, false, true)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_UP, NI.HW.BUTTON_DPAD_UP, HasPrev)

    local HasNext = TouchstripMode == NI.HW.TS_MODE_CONTROL and
        ControlHelper.hasPrevNextSlotOrPageGroup(true, false, false)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_DOWN, NI.HW.BUTTON_DPAD_DOWN, HasNext)

end

------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Jam/Pages/PageJam"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PadModePageBase = class( 'PadModePageBase', PageJam )

------------------------------------------------------------------------------------------------------------------------

function PadModePageBase:__init(Name, Controller)

    PageJam.__init(self, Name, Controller)

    self.Controller = Controller

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageBase:isKeyboardModePage()

    return PadModeHelper.getKeyboardMode() and not self.Duplicate:isEnabled()

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageBase:onPageButton(Button, PageID, Pressed)

    local TopPageID = NHLController:getPageStack():getTopPage()

    if Pressed then

        if PageID == TopPageID
            and self.Controller:isShiftPressed()
            and not self:isKeyboardModePage() then

            -- Shift+Page button opens page with keyboard mode enabled
            PadModeHelper.toggleKeyboardMode()

            local OSOType = self.GetOSOTypeFn()
            if OSOType then
                self.Controller.ParameterHandler:showOSO(OSOType)
            end

            -- Ignore next release, since we handled this event
            self.Controller.CloseOnPageButtonRelease[PageID] = false
            return true
        end

    else -- button release

        if JamHelper.isJamOSOVisible() and PageID == TopPageID then
            self.Controller.ParameterHandler:startOSOTimeout()
        end

        if self.Controller.CloseOnPageButtonRelease[PageID] then
            self.Controller.CloseOnPageButtonRelease[PageID] = not self.Controller:isButtonPressed(NI.HW.BUTTON_CLEAR)
        end
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageBase:onDPadButton(Button, Pressed)

    if self:isKeyboardModePage() and Pressed then

        local Transpose = 0

        if Button == NI.HW.BUTTON_DPAD_UP then
            Transpose = self.Controller:isShiftPressed() and 1 or 12
        elseif Button == NI.HW.BUTTON_DPAD_DOWN then
            Transpose = self.Controller:isShiftPressed() and -1 or -12
        end

        PadModeHelper.transposeRootNoteOrBaseKey(Transpose)

    end

    PageJam.onDPadButton(self, Button, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageBase:updateDPadLEDs()

    PageJam.updateDPadLEDs(self)

    local UpEnabled = false
    local DownEnabled = false

    if self:isKeyboardModePage() then
        local Increment = self.Controller:isShiftPressed() and 1 or 12
        UpEnabled = PadModeHelper.canTransposeRootNote(Increment)
        DownEnabled = PadModeHelper.canTransposeRootNote(-Increment)
    end

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_UP, NI.HW.BUTTON_DPAD_UP, UpEnabled)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_DOWN, NI.HW.BUTTON_DPAD_DOWN, DownEnabled)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageBase:onPadButton(Column, Row, Pressed)

    local SoundIndex = JamHelper.getSoundIndexByColumRow(Column, Row)

    if Pressed and SoundIndex then

        if self.Duplicate:isEnabled() then
            self.Duplicate:onSoundDuplicate(SoundIndex)
        elseif not self:isKeyboardModePage() then
            JamHelper.focusSoundByIndex(SoundIndex, self.Controller)

            if self.Controller:isClearActive() then
                MaschineHelper.removeSound(SoundIndex)
            end
        end

    end

    PageJam.onPadButton(self, Column, Row, Pressed)

    -- Triggering sounds is handled on the C++ side

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageBase:updatePadLEDs()

    if self:isKeyboardModePage() then
        JamHelper.updatePadLEDsKeyboard(self.Controller)
    else
        JamHelper.updatePadLEDsSounds(self.Controller)
    end

    PageJam.updatePadLEDs(self)

end

------------------------------------------------------------------------------------------------------------------------

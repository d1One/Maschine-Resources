------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/MixerPageColorDisplayBase"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MixerPageMK3 = class( 'MixerPageMK3', MixerPageColorDisplayBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function MixerPageMK3:__init(Controller)

    MixerPageColorDisplayBase.__init(self, "MixerPageStudio", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageMK3:onShow(Show)

    MixerPageColorDisplayBase.onShow(self, Show)

    if Show then
        self.OldJogWheelMode = NHLController:getJogWheelMode()
        NHLController:setJogWheelMode(NI.HW.JOGWHEEL_MODE_CUSTOM)
    else
        local JogWheelMode = self.OldJogWheelMode == NI.HW.JOGWHEEL_MODE_CUSTOM
            and NI.HW.JOGWHEEL_MODE_DEFAULT or NI.HW.JOGWHEEL_MODE_DEFAULT
        NHLController:setJogWheelMode(JogWheelMode)
    end
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageMK3:onWheel(Inc)

    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then

        local Fine = self.Controller:getShiftPressed()
        local Index = self:isShowingSounds() and NI.DATA.StateHelper.getFocusSoundIndex(App) + 1
            or NI.DATA.StateHelper.getFocusGroupIndex(App) + 1

        self:onLevelChange(Index, Inc, Fine, true)

        return true
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageMK3:onWheelDirection(Pressed, Button)

    if Pressed then
        if Button == NI.HW.BUTTON_WHEEL_UP or Button == NI.HW.BUTTON_WHEEL_DOWN then
            self:focusGroupOrSound(Button == NI.HW.BUTTON_WHEEL_UP)
        elseif Button == NI.HW.BUTTON_WHEEL_LEFT or Button == NI.HW.BUTTON_WHEEL_RIGHT then
            self:focusPrevNextObject(Button == NI.HW.BUTTON_WHEEL_RIGHT)
            self:notifyWheelAccessibility(Button == NI.HW.BUTTON_WHEEL_RIGHT)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageMK3:notifyWheelAccessibility(Next)

    local Index = self:getFocusIndex()
    if not NHLController:isExternalAccessibilityRunning() or not Index then
        return
    end

    local SoftButtonEquivalent = Index % 8
    local SoftButtonText = nil
    if self:isShowingSounds() then
        Index = Index + (Next and 1 or -1)
        SoftButtonEquivalent = Index % 8
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local Sounds = Group and Group:getSounds()
        if Sounds ~= nil and Sounds:at(Index) ~= nil then
            SoftButtonText = Sounds:at(Index):getDisplayName()
        end
    else
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Group = Song and Song:getGroups():at(Index)
        if Group ~= nil then
            SoftButtonText = Group:getDisplayName()
        end
    end

    if SoftButtonText ~= nil then
        NHLController:addAccessibilityControlData(NI.HW.ZONE_SOFTBUTTONS, SoftButtonEquivalent, 0, 0, 0, SoftButtonText)
        NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_SOFTBUTTONS, SoftButtonEquivalent)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageMK3:updateLEDs()

    MixerPageColorDisplayBase.updateLEDs(self)

    self:updateScreenButtonLEDs()

    self:updateWheelButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageMK3:updateWheelButtonLEDs()

    local HasGroup = NI.DATA.StateHelper.getFocusGroup(App)
    local CanGroup = HasGroup and self:isShowingSounds()
    local CanSound = not self:isShowingSounds() and not self.PlusSignInFocus
    local CanLeft, CanRight = self:canFocusPrevNextObject(true)
    local Color = LEDColors.WHITE

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP, CanGroup, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN, CanSound, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanLeft, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanRight, Color)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageMK3:onPageButton(Button, PageID, Pressed)

    MixerPageColorDisplayBase.onPageButton(self, Button, PageID, Pressed)

    if Button == NI.HW.BUTTON_MUTE or Button == NI.HW.BUTTON_SOLO then
        if Pressed then
            if not (Button == NI.HW.BUTTON_MUTE and self.Controller:getShiftPressed()) then  -- not CHOKE
                NHLController:setPadMode(NI.HW.PAD_MODE_NONE)
                return true
            end
        else
            NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)
        end
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageMK3:onVolumeButton(Pressed)

    if Pressed then
        BrowseHelper.toggleAndStoreJogWheelMode(self, NI.HW.JOGWHEEL_MODE_VOLUME)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageMK3:onTempoButton(Pressed)

    if Pressed then
        BrowseHelper.toggleAndStoreJogWheelMode(self, NI.HW.JOGWHEEL_MODE_TEMPO)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageMK3:onSwingButton(Pressed)

    if Pressed then
        BrowseHelper.toggleAndStoreJogWheelMode(self, NI.HW.JOGWHEEL_MODE_SWING)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageMK3:getAccessiblePageInfo()

    return "Mixer"

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageMK3:getAccessibleLeftRightButtonText()

    return "Bank Left", "Bank Right"

end

------------------------------------------------------------------------------------------------------------------------

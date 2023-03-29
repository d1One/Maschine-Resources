------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/MixerPageColorDisplayBase"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MixerPageStudio = class( 'MixerPageStudio', MixerPageColorDisplayBase )

------------------------------------------------------------------------------------------------------------------------

function MixerPageStudio:__init(Controller)

    MixerPageColorDisplayBase.__init(self, "MixerPageStudio", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageStudio:onShow(Show)

    MixerPageColorDisplayBase.onShow(self, Show)

    if Show then
        NHLController:setJogWheelMode(NI.HW.JOGWHEEL_MODE_CUSTOM)
    else
        LEDHelper.resetButtonLEDs({NI.HW.LED_TRANSPORT_PREV, NI.HW.LED_TRANSPORT_NEXT,
                                   NI.HW.LED_ENTER, NI.HW.LED_BACK})
        NHLController:setJogWheelMode(NI.HW.JOGWHEEL_MODE_DEFAULT)
    end
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageStudio:onWheel(Inc)

    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then

        local Fine = self.Controller:getShiftPressed() or NHLController:getWheelPressed()
        local Index = self:isShowingSounds() and NI.DATA.StateHelper.getFocusSoundIndex(App) + 1
            or NI.DATA.StateHelper.getFocusGroupIndex(App) + 1

        self:onLevelChange(Index, Inc, Fine, true)

        return true
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageStudio:updateLEDs()

    MixerPageColorDisplayBase.updateLEDs(self)

    self:updateScreenButtonLEDs()

    local HasGroup = NI.DATA.StateHelper.getFocusGroup(App)
    local CanGroup = HasGroup and self:isShowingSounds()
    local CanSound = not self:isShowingSounds()

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_TRANSPORT_PREV, NI.HW.BUTTON_TRANSPORT_PREV, true)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_TRANSPORT_NEXT, NI.HW.BUTTON_TRANSPORT_NEXT, true)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_ENTER, NI.HW.BUTTON_ENTER, CanSound)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_BACK, NI.HW.BUTTON_BACK, CanGroup)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageStudio:onPageButton(Button, PageID, Pressed)

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

function MixerPageStudio:updateJogwheel()

    LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_CHANNEL, LEDHelper.LS_BRIGHT)

    local Object = self:isShowingSounds() and NI.DATA.StateHelper.getFocusSound(App) or NI.DATA.StateHelper.getFocusGroup(App)

    if Object then
        JogwheelLEDHelper.updateAllOn(MaschineStudioController.JOGWHEEL_RING_LEDS)
    else
        JogwheelLEDHelper.updateAllOff(MaschineStudioController.JOGWHEEL_RING_LEDS)
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageStudio:onWheelButton(Pressed)

    if Pressed and NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then
        MaschineHelper.setSoundFocus()
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

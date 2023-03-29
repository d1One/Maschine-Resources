------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

require "Scripts/Maschine/Helper/SelectHelper"
require "Scripts/Maschine/Helper/PatternHelper"
require "Scripts/Shared/Helpers/EventsHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SelectPageMikroMK3 = class( 'SelectPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "SelectPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)

    self.Screen.TopIcon:setActive(true)
    self.Screen.BottomIcon:setActive(false)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikroMK3:onShow(Show)

    if Show then
        NHLController:setPadMode(NI.HW.PAD_MODE_NONE)
    end

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikroMK3:updateScreen()

    self.Screen:setTopRowToFocusedSound()

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikroMK3:onPadEvent(PadIndex, Trigger, PadValue)

    if not Trigger then
        return
    end

    local EraseEvents = self.Controller:isButtonPressed(NI.HW.BUTTON_TRANSPORT_ERASE)
    EventsHelper.onPadEventQuiet(PadIndex, Trigger, EraseEvents)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikroMK3:updatePadLEDs()

    SelectHelper.updatePadLEDsSounds(self.Controller.PAD_LEDS,
                                     self.Controller:isButtonPressed(NI.HW.BUTTON_TRANSPORT_ERASE))

end

------------------------------------------------------------------------------------------------------------------------

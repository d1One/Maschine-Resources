------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Shared/Helpers/EventsHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
EventsPageMikroMK3 = class( 'EventsPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function EventsPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "EventsPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageMikroMK3:updateScreen()

    self.Screen:setTopRowToFocusedSound()
    self.Screen:setBottomRowText("")

end

---------------------------------------------------------------------------------------------------------------------

function EventsPageMikroMK3:onShow(Show)

    if Show then
        NHLController:setPadMode(NI.HW.PAD_MODE_NONE)
    end

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageMikroMK3:onPadEvent(PadIndex, Trigger, PadValue)

    if Trigger then
        EventsHelper.onPadEventEvents(PadIndex, self.Controller:isErasePressed())
    end

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageMikroMK3:updatePadLEDs()

    EventsHelper.updatePadLEDsEvents(self.Controller.PAD_LEDS, self.Controller:isErasePressed())

end

------------------------------------------------------------------------------------------------------------------------

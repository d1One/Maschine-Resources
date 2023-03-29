------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Maschine/Helper/NavigationHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NavigatePageMikroMK3 = class( 'NavigatePageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "NavigatePageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)
    self.Screen:setTopRowText("Navigate")

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMikroMK3:onShow(Show)

    if Show then
        NHLController:setPadMode(NI.HW.PAD_MODE_NONE)
        NavigationHelper.updatePadLEDsForPageView(self.Controller.PAD_LEDS);
    end

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMikroMK3:onPadEvent(PadIndex, Trigger)

    if not Trigger then
        return
    end

    NavigationHelper.triggerPad(PadIndex, self:useFineResolution())

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMikroMK3:updatePadLEDs()

    NavigationHelper.updatePadLEDsForPageView(self.Controller.PAD_LEDS);

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMikroMK3:useFineResolution()

    return self.Controller:isButtonPressed(NI.HW.BUTTON_WHEEL)

end

------------------------------------------------------------------------------------------------------------------------

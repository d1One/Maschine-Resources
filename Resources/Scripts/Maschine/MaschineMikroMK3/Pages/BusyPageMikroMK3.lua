------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BusyPageMikroMK3 = class( 'BusyPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function BusyPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "BusyPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function BusyPageMikroMK3:onShow(Show)

    if Show then
        NHLController:setPadMode(NI.HW.PAD_MODE_NONE)
    end

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function BusyPageMikroMK3:updateScreen()

    local TopMessage, BottomMessage = App:getGenericBusyMessage()

    self.Screen
        :setTopRowText(TopMessage)
        :setTopRowTextAttribute("boldCenter")
        :setBottomRowText(BottomMessage)
        :setBottomRowTextAttribute("boldCenter")

end

------------------------------------------------------------------------------------------------------------------------

function BusyPageMikroMK3:onPadEvent(PadIndex, Trigger)

    -- NOP

end

------------------------------------------------------------------------------------------------------------------------

function BusyPageMikroMK3:onWheel(Value)
end


------------------------------------------------------------------------------------------------------------------------


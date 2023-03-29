------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ArpeggiatorPageMikroMK3 = class( 'ArpeggiatorPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function ArpeggiatorPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "ArpeggiatorPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function ArpeggiatorPageMikroMK3:updateScreen()

    self.Screen
        :setTopRowText("Arp")
        :setBottomRowToFocusedPageParameter()

end

------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
KeyboardModePageMikroMK3 = class( 'KeyboardModePageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function KeyboardModePageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "KeyboardModePageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function KeyboardModePageMikroMK3:updateScreen()

    self.Screen
        :setTopRowToFocusedSound()
        :setBottomRowToFocusedPageParameter()

end

------------------------------------------------------------------------------------------------------------------------

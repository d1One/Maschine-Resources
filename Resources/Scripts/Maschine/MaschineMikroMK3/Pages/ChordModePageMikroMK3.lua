------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Maschine/MaschineMK3/Helper/MK3Helper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ChordModePageMikroMK3 = class( 'ChordModePageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function ChordModePageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "ChordModePageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function ChordModePageMikroMK3:updateScreen()

    self.Screen
        :setTopRowToFocusedSound()
        :setBottomRowToFocusedPageParameter()

end

------------------------------------------------------------------------------------------------------------------------


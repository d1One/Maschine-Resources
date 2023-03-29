------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
GridPageMikroMK3 = class( 'GridPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function GridPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "GridPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function GridPageMikroMK3:onShow(Show)

    if Show then
        NHLController:setPadMode(NI.HW.PAD_MODE_SOUND)
    end

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function GridPageMikroMK3:updateScreen()

    self.Screen
        :setTopRowText("Grid")
        :setBottomRowToFocusedPageParameter()

end

------------------------------------------------------------------------------------------------------------------------

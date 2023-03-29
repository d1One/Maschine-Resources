------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Maschine/MaschineMikroMK3/WheelButtonIcon"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
VariationPageMikroMK3 = class( 'VariationPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function VariationPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "VariationPageMikroMK3", Controller)
    self.WheelButtonIcon = WheelButtonIcon(self)

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageMikroMK3:onShow(Show)

    if Show then
        NHLController:setPadMode(NI.HW.PAD_MODE_SOUND)
    end

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageMikroMK3:updateScreen()

    self.Screen
        :setTopRowToFocusedSound()
        :setBottomRowToFocusedPageParameter()

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageMikroMK3:onControllerTimer()

    self.WheelButtonIcon:onControllerTimer()

end

------------------------------------------------------------------------------------------------------------------------

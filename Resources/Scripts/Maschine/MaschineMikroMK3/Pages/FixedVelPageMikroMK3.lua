------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
FixedVelPageMikroMK3 = class( 'FixedVelPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function FixedVelPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "FixedVelPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function FixedVelPageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)
    self.Screen:showParameterInBottomRow()

end

------------------------------------------------------------------------------------------------------------------------

function FixedVelPageMikroMK3:updateScreen()

    self.Screen:setTopRowText("Fixed Velocity")
               :setParameterName("Value")
               :setParameterValue(PadModeHelper.getFixedVelocityValue())

end


------------------------------------------------------------------------------------------------------------------------

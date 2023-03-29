------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/LoopPageColorDisplayBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LoopPageStudio = class( 'LoopPageStudio', LoopPageColorDisplayBase )

------------------------------------------------------------------------------------------------------------------------

function LoopPageStudio:__init(Controller)

    LoopPageColorDisplayBase.__init(self, "LoopPageStudio", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageStudio:updateJogwheel()

    JogwheelLEDHelper.updateAllOn(MaschineStudioController.JOGWHEEL_RING_LEDS)
    return true

end

------------------------------------------------------------------------------------------------------------------------

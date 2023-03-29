
require "Scripts/Maschine/MaschineStudio/Pages/ArrangerPageClipsStudio"

require "Scripts/Shared/Components/Clips4DWheel"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ArrangerPageClipsMK3 = class( 'ArrangerPageClipsMK3', ArrangerPageClipsStudio )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsMK3:__init(ParentPage, Controller)

    ArrangerPageClipsStudio.__init(self, "ArrangerPageClipsMK3", Controller)
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsMK3:updateWheelButtonLEDs()

    Clips4DWheel.updateLEDs(self.Controller)
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsMK3:onWheel(Inc)

    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_DEFAULT then
        return Clips4DWheel.onWheel(self.Controller, Inc)
    end
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsMK3:onWheelDirection(Pressed, DirectionButton)

    Clips4DWheel.onWheelDirection(self.Controller, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsMK3:onControllerTimer()

    Clips4DWheel.onControllerTimer(self.Controller)
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsMK3:getAccessiblePageInfo()

    return "Clips Arranger"

end

------------------------------------------------------------------------------------------------------------------------

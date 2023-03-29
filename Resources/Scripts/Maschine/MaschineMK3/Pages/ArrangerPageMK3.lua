------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/ForwardPageMaschine"
require "Scripts/Maschine/MaschineMK3/Pages/ArrangerPageClipsMK3"
require "Scripts/Maschine/MaschineStudio/Pages/ArrangerPageStudio"
require "Scripts/Maschine/MaschineStudio/Pages/ArrangerPageIdeaSpaceStudio"
require "Scripts/Maschine/MaschineStudio/Pages/ArrangerPageSectionsStudio"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ArrangerPageMK3 = class( 'ArrangerPageMK3', ArrangerPageStudio )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ArrangerPageMK3:__init(Controller)

    -- init base class (skip initialization of direct base ArrangerPageStudio as we want its logic but different subpages)
    ForwardPageMaschine.__init(self, "ArrangerPageMK3", Controller)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_ARRANGE }

    ArrangerPageStudio.addSubPage(self, ArrangerPageStudio.SECTIONS, ArrangerPageSectionsStudio(self, Controller))
    ArrangerPageStudio.addSubPage(self, ArrangerPageStudio.CLIPS, ArrangerPageClipsMK3(self, Controller))
    ArrangerPageStudio.addSubPage(self, ArrangerPageStudio.IDEAS, ArrangerPageIdeaSpaceStudio(self, Controller))
end


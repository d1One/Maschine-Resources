------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineStudio/Pages/NavigatePageStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NavigatePageMK3 = class( 'NavigatePageMK3', NavigatePageStudio )

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMK3:__init(Controller)

   -- init base class
   ForwardPageMaschine.__init(self, "NavigatePageMK3", Controller)

   -- define page LEDs
   self.PageLEDs = { NI.HW.LED_VARIATION }

   -- create the sub pages from base
   NavigatePageStudio.createSubPages(self)

end

------------------------------------------------------------------------------------------------------------------------

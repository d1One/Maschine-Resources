------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/BusyPageBase"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BusyPage = class( 'BusyPage', BusyPageBase )


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function BusyPage:__init(Controller)

    BusyPageBase.__init(self, Controller, "BusyPage")

end

------------------------------------------------------------------------------------------------------------------------
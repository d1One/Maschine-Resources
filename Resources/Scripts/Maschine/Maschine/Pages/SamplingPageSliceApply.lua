------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/SamplingPageSliceApplyBase"
require "Scripts/Maschine/Maschine/Screens/ScreenWithGrid"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SamplingPageSliceApply = class( 'SamplingPageSliceApply', SamplingPageSliceApplyBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApply:__init(Controller, Parent)

    SamplingPageSliceApplyBase.__init(self, "SamplingPageSliceApply", Controller, Parent)

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApply:setupScreen()

    -- create screen
    self.Screen = ScreenWithGrid(self)

    ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"", "", "PREV", "NEXT", "SINGLE", "", "CANCEL", "OK"})

    SamplingPageSliceApplyBase.setupScreen(self)

end



------------------------------------------------------------------------------------------------------------------------

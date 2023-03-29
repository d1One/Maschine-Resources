------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/SamplingPageSliceApplyBase"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SamplingPageSliceApplyStudio = class( 'SamplingPageSliceApplyStudio', SamplingPageSliceApplyBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyStudio:__init(Controller, Parent)

    SamplingPageSliceApplyBase.__init(self, "SamplingPageSliceApplyStudio", Controller,Parent)

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyStudio:setupScreen()

    -- create screen
    self.Screen = ScreenWithGridStudio(self, {"", "", "<<", ">>"}, {"SINGLE", "", "CANCEL", "OK"})
    self.Screen:enableLevelMeters(true)

    SamplingPageSliceApplyBase.setupScreen(self)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyStudio:onTimer()
  self.Screen:onTimer()
end


------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyStudio:updateParameters()
  self.Controller.CapacitiveList:assignParametersToCaps({})
end

------------------------------------------------------------------------------------------------------------------------

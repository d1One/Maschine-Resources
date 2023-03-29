------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/ClipPageBase"

require "Scripts/Maschine/Maschine/Screens/ScreenWithGrid"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ClipPage = class( 'ClipPage', ClipPageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ClipPage:__init(ParentPage, Controller)

    ClipPageBase.__init(self, Controller, "ClipPage")

    self.ParentPage = ParentPage

end

------------------------------------------------------------------------------------------------------------------------

function ClipPage:setupScreen()

    self.Screen = ScreenWithGrid(self)

    ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"CLIP", "", "DOUBLE", "DUPL", "", "DELETE", "PREV", "NEXT"})

    -- Parameter Bar
    self.Screen:addParameterBar(self.Screen.ScreenLeft)
    self.ParameterHandler.NumPages = 1

    -- set custom style to grid buttons
    for i, Button in ipairs(self.Screen.ButtonPad) do
        Button:style("", "SelectPad")
    end

    ClipPageBase.setupScreen(self)

end

------------------------------------------------------------------------------------------------------------------------

function ClipPage:updateParameters(ForceUpdate)

    ClipHelper.updateParameters(self.ParameterHandler)
    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ClipPage:onScreenEncoder(Idx, Inc)

    ClipHelper.onClipPageScreenEncoder(Idx, Inc, self.TransactionSequenceMarker, self.Controller:getShiftPressed())

    PageMaschine.onScreenEncoder(self, Idx, Inc)
end




------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineStudio/Pages/SnapshotsPageStudio"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SnapshotsPageMK3 = class( 'SnapshotsPageMK3', SnapshotsPageStudio )

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPageMK3:__init(Controller)

    SnapshotsPageStudio.__init(self, Controller)

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPageMK3:setPinned(Pin)

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPageMK3:setupScreen()

    self.Screen = ScreenWithGridStudio(self, {"EXT LOCK", "", "", ""}, {"UPDATE", "DELETE", "<<", ">>"},
        "HeadButton", "HeadButton")

    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPageMK3:onScreenButton(ButtonIndex, Pressed)

    if ButtonIndex == 1 then
        return -- do nothing
    elseif ButtonIndex > 4 then
        SnapshotsPage.onScreenButton(self, ButtonIndex, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPageMK3:getAccessiblePageInfo()

    return "Lock"

end

------------------------------------------------------------------------------------------------------------------------

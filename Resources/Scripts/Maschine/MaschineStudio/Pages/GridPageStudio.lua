------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/GridPageBase"

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"
require "Scripts/Maschine/Helper/GridHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
GridPageStudio = class( 'GridPageStudio', GridPageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function GridPageStudio:__init(Controller)

    GridPageBase.__init(self, "GridPageStudio", Controller)

    -- setup screen
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function GridPageStudio:setupScreen()

    self.Screen = ScreenWithGridStudio(self, {"GRID", "PERFORM", "ARRANGE", "STEP"}, {"v", "v", "v", "v"},
    	{"HeadPin", "HeadTabLeft", "HeadTabCenter", "HeadTabRight"},
        {"HeadButton", "HeadButton", "HeadButton", "HeadButton"})

    -- Parameter bar
    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)

    self.ParameterHandler.UseNoParamsCaption = false

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function GridPageStudio:updateScreens(ForceUpdate)

    for Index, Button in ipairs (self.Screen.PadButtons) do
        Button:setPaletteColorIndex(0)     -- 0 is white
        Button.Label:setPaletteColorIndex(0)
        Button:setInvalid(0)
    end

    -- call base class
    GridPageBase.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function GridPageStudio:updateParameters(ForceUpdate)

    GridPageBase.updateParameters(self, ForceUpdate)

    self.Controller.CapacitiveList:assignParametersToCaps(self.GridMode == GridHelper.STEP and self.ParameterHandler.Parameters or {})

end

------------------------------------------------------------------------------------------------------------------------

function GridPageStudio:isSoundQEAllowed()

    return false

end

------------------------------------------------------------------------------------------------------------------------


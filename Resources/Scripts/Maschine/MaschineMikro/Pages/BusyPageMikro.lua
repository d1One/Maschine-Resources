------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/MaschineMikro/ScreenMikro"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BusyPageMikro = class( 'BusyPageMikro', PageMikro )


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function BusyPageMikro:__init(Controller)

    PageMikro.__init(self, "BusyPageMikro", Controller)

    self.Labels = {}

    -- setup screen
    self:setupScreen()

end


------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function BusyPageMikro:setupScreen()

    self.Screen = ScreenMikro(self, ScreenMikro.SIMPLE_BAR)

    ScreenHelper.createBarWithLabels(self.Screen.RootBar, self.Labels, {"Busy..."}, "BusyPage", "BusyLabel")

end


------------------------------------------------------------------------------------------------------------------------

function BusyPageMikro:setMessage(LeftMessage, RightMessage)

    self.Labels[1]:setText(LeftMessage .. " " .. RightMessage)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function BusyPageMikro:onPadEvent(PadIndex, Trigger)
end


------------------------------------------------------------------------------------------------------------------------

function BusyPageMikro:onWheel(Value)
end


------------------------------------------------------------------------------------------------------------------------

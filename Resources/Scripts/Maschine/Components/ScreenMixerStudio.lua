------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/ScreenBase"
require "Scripts/Shared/Components/InfoBar"
require "Scripts/Shared/Helpers/ScreenHelper"

------------------------------------------------------------------------------------------------------------------------
-- Screen
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScreenMixerStudio = class( 'ScreenMixerStudio', ScreenBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ScreenMixerStudio:__init(Page)

    -- init base class
    ScreenBase.__init(self, Page)

end

------------------------------------------------------------------------------------------------------------------------
-- Setup Screen
------------------------------------------------------------------------------------------------------------------------

function ScreenMixerStudio:setupScreen()

    -- create root bar
    self.RootBar = NI.GUI.createBar()
    self.RootBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "Page")

    -- insert page into page stack
    local ScreenStack = NHLController:getHardwareDisplay():getPageStack()
    NI.GUI.insertPage(ScreenStack, self.RootBar, self.Page.Name)

end

------------------------------------------------------------------------------------------------------------------------

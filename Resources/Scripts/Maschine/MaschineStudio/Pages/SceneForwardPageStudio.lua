------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/ForwardPageMaschine"

require "Scripts/Maschine/MaschineStudio/Pages/ScenePageStudio"
require "Scripts/Maschine/MaschineStudio/Pages/SectionsPageStudio"

require "Scripts/Shared/Helpers/ArrangerHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SceneForwardPageStudio = class( 'SceneForwardPageStudio', ForwardPageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- const
------------------------------------------------------------------------------------------------------------------------

SceneForwardPageStudio.IDEAS = 1
SceneForwardPageStudio.SECTIONS = 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SceneForwardPageStudio:__init(Controller)

    -- init base class
    ForwardPageMaschine.__init(self, "SceneForwardPageStudio", Controller)

    ForwardPageMaschine.addSubPage(self, SceneForwardPageStudio.IDEAS, ScenePageStudio(self, Controller))
    ForwardPageMaschine.addSubPage(self, SceneForwardPageStudio.SECTIONS, SectionsPageStudio(self, Controller))

    local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()
    ForwardPageMaschine.setDefaultSubPage(self, IdeaSpaceVisible and SceneForwardPageStudio.IDEAS or SceneForwardPageStudio.SECTIONS)

    self.PageLEDs = { NI.HW.LED_SCENE }
end

------------------------------------------------------------------------------------------------------------------------

function SceneForwardPageStudio:updateScreens(ForceUpdate)

    local ActiveSubPageID  = ArrangerHelper.isIdeaSpaceFocused() and SceneForwardPageStudio.IDEAS or SceneForwardPageStudio.SECTIONS

    if ForwardPageMaschine.getCurrentPageID(self) ~= ActiveSubPageID then
        ForwardPageMaschine.switchToSubPage(self, ActiveSubPageID)
    end

    ForwardPageMaschine.updateScreens(self, ForceUpdate)
end

------------------------------------------------------------------------------------------------------------------------


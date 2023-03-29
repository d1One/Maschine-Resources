------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/ForwardPageMaschine"

require "Scripts/Maschine/MaschineStudio/Pages/PatternPageStudioPattern"
require "Scripts/Maschine/MaschineStudio/Pages/ClipPageStudio"

require "Scripts/Shared/Helpers/ArrangerHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternPageStudio = class( 'PatternPageStudio', ForwardPageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- const
------------------------------------------------------------------------------------------------------------------------

PatternPageStudio.PATTERN = 1
PatternPageStudio.CLIP = 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function PatternPageStudio:__init(Controller)

    -- init base class
    ForwardPageMaschine.__init(self, "PatternPageStudio", Controller)

    ForwardPageMaschine.addSubPage(self, PatternPageStudio.PATTERN, PatternPageStudioPattern(self, Controller))
    ForwardPageMaschine.addSubPage(self, PatternPageStudio.CLIP, ClipPageStudio(self, Controller))

    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    ForwardPageMaschine.setDefaultSubPage(self, SongClipView and PatternPageStudio.CLIP or PatternPageStudio.PATTERN)

    self.PageLEDs = { NI.HW.LED_PATTERN }
end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudio:updateScreens(ForceUpdate)

    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local ActiveSubPageID  = SongClipView and PatternPageStudio.CLIP or PatternPageStudio.PATTERN

    if ForwardPageMaschine.getCurrentPageID(self) ~= ActiveSubPageID then
        ForwardPageMaschine.switchToSubPage(self, ActiveSubPageID)
    end

    ForwardPageMaschine.updateScreens(self, ForceUpdate)
end

------------------------------------------------------------------------------------------------------------------------

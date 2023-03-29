------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/ForwardPageMaschine"

require "Scripts/Maschine/Maschine/Pages/PatternPagePattern"
require "Scripts/Maschine/Maschine/Pages/ClipPage"

require "Scripts/Shared/Helpers/ArrangerHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternPage = class( 'PatternPage', ForwardPageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- const
------------------------------------------------------------------------------------------------------------------------

PatternPage.PATTERN = 1
PatternPage.CLIP = 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function PatternPage:__init(Controller)

    -- init base class
    ForwardPageMaschine.__init(self, "PatternPage", Controller)

    ForwardPageMaschine.addSubPage(self, PatternPage.PATTERN, PatternPagePattern(self, Controller))
    ForwardPageMaschine.addSubPage(self, PatternPage.CLIP, ClipPage(self, Controller))

    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    ForwardPageMaschine.setDefaultSubPage(self, SongClipView and PatternPage.CLIP or PatternPage.PATTERN)

    self.PageLEDs = { NI.HW.LED_PATTERN }

end

------------------------------------------------------------------------------------------------------------------------

function PatternPage:onShow(Show)

    if Show then
        self:onTimer()
    end

    self.CurrentPage:onShow(Show)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPage:onTimer()

    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local ActiveSubPageID = SongClipView and PatternPage.CLIP or PatternPage.PATTERN

    if ForwardPageMaschine.getCurrentPageID(self) ~= ActiveSubPageID then
        ForwardPageMaschine.switchToSubPage(self, ActiveSubPageID)
    end

    -- re-set timer while page is shown
    local ActivePageID = self.Controller.PageManager:getPageID(self.Controller.ActivePage)
    local OwnPageID = self.Controller.PageManager:getPageID(self)

    if ActivePageID == OwnPageID then
        self.Controller:setTimer(self, 1)
    end

end

------------------------------------------------------------------------------------------------------------------------


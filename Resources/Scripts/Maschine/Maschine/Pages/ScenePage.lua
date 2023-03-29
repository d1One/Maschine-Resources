------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/ForwardPageMaschine"

require "Scripts/Maschine/Maschine/Pages/IdeasPage"
require "Scripts/Maschine/Maschine/Pages/SectionsPage"

require "Scripts/Shared/Helpers/ArrangerHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScenePage = class( 'ScenePage', ForwardPageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- const
------------------------------------------------------------------------------------------------------------------------

ScenePage.IDEAS = 1
ScenePage.SECTIONS = 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ScenePage:__init(Controller)

    -- init base class
    ForwardPageMaschine.__init(self, "ScenePage", Controller)

    ForwardPageMaschine.addSubPage(self, ScenePage.IDEAS, IdeasPage(self, Controller))
    ForwardPageMaschine.addSubPage(self, ScenePage.SECTIONS, SectionsPage(self, Controller))

    local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()
    ForwardPageMaschine.setDefaultSubPage(self, IdeaSpaceVisible and ScenePage.IDEAS or ScenePage.SECTIONS)

    self.PageLEDs = { NI.HW.LED_SCENE }

end

------------------------------------------------------------------------------------------------------------------------

function ScenePage:onShow(Show)

    if Show then
        self:onTimer()
    end

    self.CurrentPage:onShow(Show)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePage:onTimer()

    local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()
    local ActiveSubPageID = IdeaSpaceVisible and ScenePage.IDEAS or ScenePage.SECTIONS

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


------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/ForwardPageMaschine"
require "Scripts/Maschine/MaschineStudio/Pages/ArrangerPageClipsStudio"
require "Scripts/Maschine/MaschineStudio/Pages/ArrangerPageIdeaSpaceStudio"
require "Scripts/Maschine/MaschineStudio/Pages/ArrangerPageSectionsStudio"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ArrangerPageStudio = class( 'ArrangerPageStudio', ForwardPageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- CONSTS
------------------------------------------------------------------------------------------------------------------------

ArrangerPageStudio.SECTIONS = 1
ArrangerPageStudio.CLIPS = 2
ArrangerPageStudio.IDEAS = 3

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ArrangerPageStudio:__init(Controller)

    -- init base class
    ForwardPageMaschine.__init(self, "ArrangerPageStudio", Controller)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_ARRANGE }

    ForwardPageMaschine.addSubPage(self, ArrangerPageStudio.SECTIONS, ArrangerPageSectionsStudio(self, Controller))
    ForwardPageMaschine.addSubPage(self, ArrangerPageStudio.CLIPS, ArrangerPageClipsStudio(self, Controller))
    ForwardPageMaschine.addSubPage(self, ArrangerPageStudio.IDEAS, ArrangerPageIdeaSpaceStudio(self, Controller))

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageStudio:getArrangerStatePageID()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return ArrangerPageStudio.IDEAS
    elseif Song:getArrangerState():isViewInIdeaSpace() then
        return ArrangerPageStudio.IDEAS
    elseif Song:getFocusEntityParameter():getValue() == NI.DATA.FOCUS_ENTITY_CLIP then
        return ArrangerPageStudio.CLIPS
    else
        return ArrangerPageStudio.SECTIONS
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageStudio:onShow(Show)

    if Show then
        self.CurrentPage = self.SubPages[self:getArrangerStatePageID()]
    end

    ForwardPageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageStudio:updateScreens(Force)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song and NI.DATA.ParameterCache.isValid(App) then
        if Song:getArrangerState():isViewChanged() or Song:getFocusEntityParameter():isChanged() then
            self:switchToSubPage(self:getArrangerStatePageID())
        end
    end

    ForwardPageMaschine.updateScreens(self, Force)

end


------------------------------------------------------------------------------------------------------------------------

function ArrangerPageStudio:isSoundQEAllowed()

    -- let the subpages decide if they should have QE enabled
    if (self.CurrentPage.isSoundQEAllowed) then
        return self.CurrentPage:isSoundQEAllowed()
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------
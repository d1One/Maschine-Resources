------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/ForwardPageMaschine"
require "Scripts/Maschine/MaschineStudio/Pages/NavigatePageViewStudio"
require "Scripts/Maschine/MaschineStudio/Pages/NavigatePagePageNavStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NavigatePageStudio = class( 'NavigatePageStudio', ForwardPageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- CONSTS
------------------------------------------------------------------------------------------------------------------------

NavigatePageStudio.VIEW = 1
NavigatePageStudio.PAGE_NAV = 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function NavigatePageStudio:__init(Controller)

   -- init base class
   ForwardPageMaschine.__init(self, "NavigatePageStudio", Controller)

   -- define page LEDs
   self.PageLEDs = { NI.HW.LED_NAVIGATE }

   self:createSubPages()

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageStudio:createSubPages()

   ForwardPageMaschine.addSubPage(self, NavigatePageStudio.VIEW, NavigatePageViewStudio(self, self.Controller))
   ForwardPageMaschine.addSubPage(self, NavigatePageStudio.PAGE_NAV, NavigatePagePageNavStudio(self, self.Controller))

    local DefaultPage = App:getWorkspace():getPageNavModeParameter():getValue()
        and NavigatePageStudio.PAGE_NAV
        or NavigatePageStudio.VIEW

   ForwardPageMaschine.setDefaultSubPage(self, DefaultPage)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageStudio:isPageNav()

    return self.CurrentPage and self:getSubPageID(self.CurrentPage) == NavigatePageStudio.PAGE_NAV

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageStudio:onShow(Show)

    if self.Controller.QuickEdit then
        self.Controller.QuickEdit:resetMode()
    end

    ForwardPageMaschine.onShow(self, Show)

 end

-----------------------------------------------------------------------------------------------------------------------

function NavigatePageStudio:setPageNavMode(Enabled)

   local PageNavMode = App:getWorkspace():getPageNavModeParameter()
   NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, PageNavMode, Enabled)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageStudio:switchToPage(NewPage)

   self:switchToSubPage(NewPage)

   if NewPage == NavigatePageStudio.VIEW then
      self:setPageNavMode(false)
   elseif NewPage == NavigatePageStudio.PAGE_NAV then
      self:setPageNavMode(true)
   end

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageStudio:isSoundQEAllowed()

    return false

end

------------------------------------------------------------------------------------------------------------------------

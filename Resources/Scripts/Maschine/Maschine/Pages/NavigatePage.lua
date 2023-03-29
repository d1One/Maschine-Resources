------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/ForwardPageMaschine"
require "Scripts/Maschine/Maschine/Pages/NavigatePageView"
require "Scripts/Maschine/Maschine/Pages/NavigatePagePageNav"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NavigatePage = class( 'NavigatePage', ForwardPageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- CONSTS
------------------------------------------------------------------------------------------------------------------------

NavigatePage.VIEW = 1
NavigatePage.PAGE_NAV = 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function NavigatePage:__init(Controller)

    -- create page
    ForwardPageMaschine.__init(self, "NavigatePage", Controller)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_NAVIGATE }


    ForwardPageMaschine.addSubPage(self, NavigatePage.VIEW, NavigatePageView(self, Controller))
    ForwardPageMaschine.addSubPage(self, NavigatePage.PAGE_NAV, NavigatePagePageNav(self, Controller))

    local DefaultPage = NavigatePage.VIEW

    local PageNavModeParameter = App:getWorkspace():getPageNavModeParameter()
    local PageNavMode = PageNavModeParameter:getValue()

    if PageNavMode then
       DefaultPage = NavigatePage.PAGE_NAV
    end

    ForwardPageMaschine.setDefaultSubPage(self, DefaultPage)

end


------------------------------------------------------------------------------------------------------------------------

function NavigatePage:setPageNavMode(Enabled)

   local PageNavMode = App:getWorkspace():getPageNavModeParameter()
   NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, PageNavMode, Enabled)

end


------------------------------------------------------------------------------------------------------------------------

function NavigatePage:switchToPage(NewPage)

   self:switchToSubPage(NewPage)

   if NewPage == NavigatePage.VIEW then
      self:setPageNavMode(false)
   elseif NewPage == NavigatePage.PAGE_NAV then
      self:setPageNavMode(true)
   end

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePage:onWheel()

	if NHLController:getJogWheelMode() ~= NI.HW.JOGWHEEL_MODE_DEFAULT and
		self.Controller.QuickEdit.NumPadPressed > 0 then
		return true
	end

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePage:onVolumeEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePage:onTempoEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePage:onSwingEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

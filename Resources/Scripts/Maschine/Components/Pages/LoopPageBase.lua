------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

local ATTR_EMPTY = NI.UTILS.Symbol("empty")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LoopPageBase = class( 'LoopPageBase', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function LoopPageBase:__init(Page, Controller)

    -- init base class
    PageMaschine.__init(self, Page, Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = {}

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageBase:setupScreen()

    -- parameter bar
    self.ParameterHandler.SectionWidgets[1]:setText("Loop")
    self.Screen.ParameterWidgets[1]:setName("POSITION")
    self.Screen.ParameterWidgets[3]:setName("START")
    self.Screen.ParameterWidgets[4]:setName("LENGTH")

    MaschineHelper.resetScreenEncoderSmoother()

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageBase:updateScreens(ForceUpdate)

	if ForceUpdate then
		LEDHelper.setLEDState(NI.HW.LED_LEFT, LEDHelper.LS_OFF)
		LEDHelper.setLEDState(NI.HW.LED_RIGHT, LEDHelper.LS_OFF)
	end

    self.Screen.ScreenButton[5]:setSelected(NI.DATA.TransportAccess.isLoopActive(App))
    self.Screen.ScreenButton[8]:setSelected(NI.DATA.TransportAccess.isSectionLoopActive(App))

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------

function LoopPageBase:updateParameters(ForceUpdate)

    self.Screen.ParameterWidgets[1]:setValue(ArrangerHelper.getLoopPosAsString())
    self.Screen.ParameterWidgets[2]:setAttribute(ATTR_EMPTY, "true")
    self.Screen.ParameterWidgets[3]:setValue(ArrangerHelper.getLoopPosAsString())
    self.Screen.ParameterWidgets[4]:setValue(ArrangerHelper.getLoopLengthAsString())

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageBase:updatePadLEDs()

    ArrangerHelper.updatePadLEDsSections(self.Controller.PAD_LEDS)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageBase:onPadEvent(PadIndex, Trigger)

    ArrangerHelper.onPadEventSections(PadIndex, Trigger, false, false)
    return true

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageBase:onScreenButton(Idx, Pressed)

    if Pressed then

        if Idx == 4 then
            ArrangerHelper.setLoopToWholeSong()

        elseif Idx == 5 then
            NI.DATA.TransportAccess.toggleLoop(App)

        elseif Idx == 8 then
            NI.DATA.TransportAccess.toggleSceneLoop(App)

        end

    end

    PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageBase:onScreenEncoder(Idx, Inc)

    if Idx == 1 then

        if MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) ~= 0 then
            NI.DATA.TransportAccess.moveLoopFromHW(App, Inc > 0 and 1 or -1)
        end

    elseif Idx == 3 then

        if MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) ~= 0 then
            NI.DATA.TransportAccess.moveLoopBeginFromHW(App, Inc > 0 and 1 or -1)
        end

    elseif Idx == 4 then

        if MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) ~= 0 then
            NI.DATA.TransportAccess.moveLoopEndFromHW(App, Inc > 0 and 1 or -1)
        end

    elseif Idx == 5 then -- ZOOM
        self:onZoom(Inc)

    elseif Idx == 6 then -- SCROLL
    	self:onScroll(Inc)

    end

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageBase:onLoopButton(Pressed)

    if not Pressed and NHLController:getPageStack():getTopPage() == NI.HW.PAGE_LOOP then
        NHLController:getPageStack():popPage()
        return
    end

    PageMaschine.onLoopButton(self, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageBase:onPageButton(Button, PageID, Pressed)

    if Pressed then
        NHLController:getPageStack():popPage()
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageBase:onZoom(Inc)
end

------------------------------------------------------------------------------------------------------------------------

function LoopPageBase:onScroll(Inc)
end

------------------------------------------------------------------------------------------------------------------------


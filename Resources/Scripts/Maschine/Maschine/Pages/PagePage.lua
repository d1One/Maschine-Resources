------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschine"
require "Scripts/Shared/Helpers/ControlHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PagePage = class( 'PagePage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function PagePage:__init(Controller)

    PageMaschine.__init(self, "PagePage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_ALL  }

end


------------------------------------------------------------------------------------------------------------------------
-- Setup Screen
------------------------------------------------------------------------------------------------------------------------

function PagePage:setupScreen()

	-- setup screen
    self.Screen = ScreenMaschine(self)

	-- style screens
	self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadTab")
	self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"", "", "", ""}, "HeadTab")

	-- screen buttons
    ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"PAGE"})

end

------------------------------------------------------------------------------------------------------------------------

function PagePage:onShow(Show)

    PageMaschine.onShow(self, Show)

	-- set EncoderMode
	if Show == true then
		NHLController:setEncoderMode(NI.HW.ENC_MODE_CONTROL)
	else
		NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)
	end

end

------------------------------------------------------------------------------------------------------------------------
-- update screens
------------------------------------------------------------------------------------------------------------------------

function PagePage:updateScreens(ForceUpdate)

	-- screen buttons
	self:updateScreenButtons(ForceUpdate)

    -- transport bar
    self.Screen.InfoBar:update(ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PagePage:updateScreenButtons(ForceUpdate)

	local ParameterCache = App:getStateCache():getParameterCache()
	local PageParameter	 = ParameterCache:getPageParameter()
	local Update = (ForceUpdate or ParameterCache:isParameterAreaUpdateNeeded())

	if Update and PageParameter then
		for ButtonIndex = 2,8 do
			local Button = self.Screen.ScreenButton[ButtonIndex]
			local Index = ButtonIndex - 2
			local IndexValid = Index <= PageParameter:getMax()

			Button:setText(IndexValid and PageParameter:getAsString(Index) or "")
			Button:setEnabled(IndexValid)
			Button:setSelected(IndexValid and (PageParameter:getValue() == Index))
			Button:setVisible(true)
		end
	end

end

------------------------------------------------------------------------------------------------------------------------

function PagePage:onScreenButton(Idx, Pressed)

    if Pressed then
    	if Idx == 1 then
	    	self:togglePinState()

    	elseif Idx >= 2 and Idx <= 8 then
	    	ControlHelper.setPageParameter(Idx - 1)

    	end
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

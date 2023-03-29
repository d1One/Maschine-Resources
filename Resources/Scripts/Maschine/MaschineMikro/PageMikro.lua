------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/Page"
require "Scripts/Maschine/MaschineMikro/ScreenMikro"
require "Scripts/Maschine/MaschineMikro/ParameterHandlerMikro"

------------------------------------------------------------------------------------------------------------------------
-- Page Base Class for Maschine Mikro
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--[[ What to know about PageMikro:

-- The Left/Right buttons (under the screen) automatically light up and have the handler onLeftRightButton() set
to those buttons.  The base implementation of updateLeftRightButtons() does this, which bases its state on the
number of parameters that are set in self.ParameterHandler.  self.ParameterHandler is updated in
updateScreens() with updateParameters().  If you want the Left/Right buttons to light on special
conditions, then override updateLeftRightButtons() and set the appropriate GUI widgits of the screen visible.

-- Override updateParameters() to set special conditions or to set the parameters manually.

-- Other base classes to override for special showing or handling are updateGroupLEDs(), onNavButton(), onEncoder(),
onPadEvent(), etc.  See base classes before setting new functors to update and event handling procedures.
------------------------------------------------------------------------------------------------------------------------

--]]

local class = require 'Scripts/Shared/Helpers/classy'
PageMikro = class( 'PageMikro', Page )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function PageMikro:__init(Name, Controller)

    -- init base class
    Page.__init(self, Name, Controller)

    -- parameter handler that gets parameter names and values, and handles basic events
    self.ParameterHandler = ParameterHandlerMikro(nil, nil)

end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:updateScreens(ForceUpdate)

    -- parameters
    self:updateParameters(ForceUpdate)

	-- screen (needs to be called after updateParameters())
    self.Screen:update(ForceUpdate)

    -- screen button leds
    self:updateScreenButtonLEDs(ForceUpdate)

    -- left/right button leds, depend on self.Screen members
    self:updateLeftRightLEDs(ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:updateParameters(ForceUpdate)

    self.ParameterHandler:update(ForceUpdate)
    local ParamCache = App:getStateCache():getParameterCache()

    if self.Screen:getNavMode() == 0 then

        if self.Screen.ScreenMode == self.Screen.PARAMETER_MODE_MULTI then
            self.Screen.ParameterLabel[1]:setVisible(self.ParameterHandler.ParameterIndex > 1)
            self.Screen.ParameterLabel[3]:setVisible(self.ParameterHandler.ParameterIndex < #self.ParameterHandler.Parameters)
        end

    else

        if self.Screen.NavParamSelectLabels[1] and self.Screen.NavParamSelectLabels[3] then
            local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()
            self.Screen.NavParamSelectLabels[1]:setVisible(ParamCache:getValidPageParameterValue() > 0)
            self.Screen.NavParamSelectLabels[3]:setVisible(ParamCache:getValidPageParameterValue() < NumPages-1)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:updateScreenButtonLEDs(ForceUpdate)

    LEDHelper.updateScreenButtonLEDs(self.Controller, self.Screen.ScreenButton)

end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:updateLeftRightLEDs(ForceUpdate)

    -- If the left/right button is pressed, Don't mess with the left/right button LEDs
	-- because the LEDs are set in MaschineMikroController:onLeftRightButton()
	if not self.Controller.SwitchPressed[NI.HW.BUTTON_LEFT] then
		LEDHelper.setLEDState(NI.HW.LED_LEFT, self:getLeftButtonEnabled() and LEDHelper.LS_DIM or LEDHelper.LS_OFF)
    end

	if not self.Controller.SwitchPressed[NI.HW.BUTTON_RIGHT] then
		LEDHelper.setLEDState(NI.HW.LED_RIGHT, self:getRightButtonEnabled() and LEDHelper.LS_DIM or LEDHelper.LS_OFF)
	end

end

------------------------------------------------------------------------------------------------------------------------
-- getLeftButtonEnabled: Override for special use of left-arrow button
------------------------------------------------------------------------------------------------------------------------

function PageMikro:getLeftButtonEnabled()

    return self.Screen.ScreenMode == ScreenMikro.PARAMETER_MODE_MULTI and
        ((self.Screen:getNavMode() ~= 0 and self.Screen.NavParamSelectLabels[1]:isVisible()) or
         (self.Screen:getNavMode() == 0 and self.Screen.ParameterLabel[1] and self.Screen.ParameterLabel[1]:isVisible()))

end

------------------------------------------------------------------------------------------------------------------------
-- getRightButtonEnabled: Override for special use of right-arrow button
------------------------------------------------------------------------------------------------------------------------

function PageMikro:getRightButtonEnabled()

    return self.Screen.ScreenMode == ScreenMikro.PARAMETER_MODE_MULTI and
        ((self.Screen:getNavMode() ~= 0 and self.Screen.NavParamSelectLabels[3]:isVisible()) or
         (self.Screen:getNavMode() == 0 and self.Screen.ParameterLabel[3] and self.Screen.ParameterLabel[3]:isVisible()))

end

------------------------------------------------------------------------------------------------------------------------
-- updateGroupLEDs: Clear Group LEDs for MikroMK1 (independent of pad LEDs).
-- Does nothing for MikroMK2, because there are no separate Group LEDs but only pad LEDs
------------------------------------------------------------------------------------------------------------------------

function PageMikro:updateGroupLEDs()

    if self.Controller.HWModel == NI.HW.MASCHINE_CONTROLLER_MIKRO_MK1 then
        LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS, 0, function() return false, false end)
    end

    -- Here we don't call the base class because the Group leds are on the pads, and we only want those on when
    -- in a Group-related mode on specific screens. Page:updateGroupLEDs displays the Groups on the pads.

end

------------------------------------------------------------------------------------------------------------------------
-- updatePageLEDs: Override to have other related page LEDs set on/off
------------------------------------------------------------------------------------------------------------------------

function PageMikro:updatePageLEDs(LEDState)

    -- call base class
    Page.updatePageLEDs(self, LEDState)

    -- turn on/off NAV button LED depending on existance of NavGroupBar
    if self.Screen.NavGroupBar then
		LEDHelper.setLEDState(NI.HW.LED_NAV, self.Controller:getNavPressed()
			and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
    else
		LEDHelper.setLEDState(NI.HW.LED_NAV, LEDHelper.LS_OFF)
	end

end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:updateGroupPageButtonLED(LEDLevel, ForceUpdate)

	local StateCache = App:getStateCache()
	local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
	local IsColorChanged = FocusGroup and FocusGroup:getColorParameter():isChanged()

	if ForceUpdate or StateCache:isFocusGroupChanged() or IsColorChanged then
		-- update Group led level & color (if color)
		local ColorIndex = NHLController:hasRGBLEDs()
			and MaschineHelper.getGroupColorByIndex(NI.DATA.StateHelper.getFocusGroupIndex(App) + 1)

		LEDHelper.setLEDState(NI.HW.LED_GROUP, LEDLevel, ColorIndex)
	end

end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:onScreenButton(ButtonIdx, Pressed)

    if Pressed then
        -- set bright LED state and block on press, if button has been enabled but not selected
        if self.Screen.ScreenButton[ButtonIdx]:isEnabled() and not self.Screen.ScreenButton[ButtonIdx]:isSelected() then
            LEDHelper.setLEDState(self.Controller.SCREEN_BUTTON_LEDS[ButtonIdx], LEDHelper.LS_BRIGHT)
        end
    end

    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:onWheel(Value)

    return self.ParameterHandler:onWheel(Value, self.Controller:getWheelButtonPressed())

end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:onNavButton(Pressed)

    -- if page as a nav screen, sync nav mode and LED state
    -- LED state is reset in PageMikro:updatePageLEDs()
    if self.Screen and self.Screen.NavGroupBar then

        LEDHelper.setLEDState(NI.HW.LED_NAV, Pressed and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

        NHLController:setPadMode(Pressed and NI.HW.PAD_MODE_NONE or NI.HW.PAD_MODE_PAGE_DEFAULT)
        self.Screen:setNavMode(Pressed)
        self:updateScreens()

    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:onLeftRightButton(Right, Pressed)

    if Pressed then
		self.ParameterHandler:increaseParameter(Right and 1 or -1)
        self:updateParameters()
	end

end

------------------------------------------------------------------------------------------------------------------------
-- Per default the group button opens the group page, but for mute, solo, select ... the group button is a toggle
------------------------------------------------------------------------------------------------------------------------

function PageMikro:onGroupButton(Pressed)

	self.Controller:onPageButton(NI.HW.BUTTON_GROUP, NI.HW.PAGE_GROUP, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:onEnterButton(Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:onControlButton(Pressed)

	if self.Controller:isModifierPage(self)
		and Pressed
		and NHLController:getControllerModel() == NI.HW.MASCHINE_CONTROLLER_MIKRO_MK2 then

		-- Mikro2's CONTROL button is also the PIN button
		self:togglePinState()
	else
		self.Controller:onPageButton(NI.HW.BUTTON_CONTROL, NI.HW.PAGE_CONTROL, Pressed)
	end

end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:onMainButton(Pressed)

    if self.Controller:isModifierPage(self)
		and Pressed
		and NHLController:getControllerModel() == NI.HW.MASCHINE_CONTROLLER_MIKRO_MK1 then

		-- Mikro1's MAIN button is also the PIN button
		self:togglePinState()
    else
        self.Controller:onPageButton(NI.HW.BUTTON_MAIN, NI.HW.PAGE_MAIN, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:onShiftButton(Pressed)

    NI.DATA.WORKSPACE.setAutoWriteEnabled(App, false, Pressed)

    Page.onShiftButton(self, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function PageMikro:onNoteRepeatButton(Pressed)

    self.Controller:onPageButton(NI.HW.BUTTON_NOTE_REPEAT, NI.HW.PAGE_REPEAT, Pressed)

end


------------------------------------------------------------------------------------------------------------------------
-- Small Helper
------------------------------------------------------------------------------------------------------------------------

function PageMikro.getGroupIndexFromPad(PadIndex)

    if PadIndex > 12 then
   	 	return PadIndex - 12
 	elseif PadIndex > 8 then
 	 	return PadIndex - 4
 	elseif PadIndex > 4 then
 	 	return PadIndex + 4
 	elseif PadIndex > 0 then
 	 	return PadIndex + 12
    end
end

------------------------------------------------------------------------------------------------------------------------

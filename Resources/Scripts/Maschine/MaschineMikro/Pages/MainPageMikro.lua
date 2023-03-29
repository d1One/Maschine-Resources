------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Maschine/MaschineMikro/Pages/GroupPageMikro"
require "Scripts/Shared/Helpers/ControlHelper"
require "Scripts/Maschine/Components/QuickEditBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MainPageMikro = class( 'MainPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- CONSTS
------------------------------------------------------------------------------------------------------------------------

MainPageMikro.SOUND = 1
MainPageMikro.GROUP = 2

MainPageMikro.ButtonToJogWheelMode = {	NI.HW.JOGWHEEL_MODE_VOLUME,
									    NI.HW.JOGWHEEL_MODE_SWING,
									    NI.HW.JOGWHEEL_MODE_TEMPO }

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function MainPageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "MainPage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_MAIN }

    self.PageMode = MainPageMikro.SOUND

    if self.Controller:getGroupPressed() and not self.Controller:getShiftPressed() then
        self:onGroupButton(true)
    end

    -- This screen keeps its own Jog Wheel mode
    self.JogWheelMode = NI.HW.JOGWHEEL_MODE_VOLUME

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function MainPageMikro:setupScreen()

    -- setup screen
    self.Screen = ScreenMikro(self, ScreenMikro.PARAMETER_MODE_SINGLE)

    -- Info Display
    ScreenHelper.setWidgetText(self.Screen.Title, {"MAIN"})

    -- Screen Buttons
    self.Screen:styleScreenButtons({"VOLUME", "SWING", "TEMPO"}, "HeadTabRow", "HeadTab")

    -- setup parameter handler
    self.ParameterHandler:setLabels(nil, self.Screen.ParameterLabel[1])
    self.ParameterHandler.Parameters = { nil }

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        self.ParameterHandler.Parameters[1] = Song:getLevelParameter()
    end

end

------------------------------------------------------------------------------------------------------------------------

function MainPageMikro:onShow(Show)

    -- This screen stores last used jog wheel mode, independent of mode outside this screen
    NHLController:setJogWheelMode(Show and self.JogWheelMode or NI.HW.JOGWHEEL_MODE_DEFAULT)

    if not Show then
        self.Controller.QuickEdit.NumPadPressed = 0
        self.Controller.QuickEdit.NumGroupPressed = 0
        self.PageMode = MainPageMikro.SOUND
        self.Controller.QuickEdit:setLevel(NI.DATA.LEVEL_TAB_SONG)
    end

    PageMikro.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function MainPageMikro:updateScreens(ForceUpdate)

    self.JogWheelMode = NHLController:getJogWheelMode()

    for Index, Value in ipairs(MainPageMikro.ButtonToJogWheelMode) do
        self.Screen.ScreenButton[Index]:setSelected(self.JogWheelMode == Value)
    end

    -- call base
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function MainPageMikro:updateParameters(ForceUpdate)

    -- update the quick-edit parameter

	local QEObject = self.Controller.QuickEdit:getLevelObject()

	if QEObject == nil then
	   self.ParameterHandler.Parameters[1] = nil
	   return
	end

	self.Screen.Title[1]:setText(QEObject:getDisplayName())
	self.Screen.ScreenButton[3]:setText(self.Controller.QuickEdit.Level == NI.DATA.LEVEL_TAB_SONG and "TEMPO" or "TUNE")

	local Param = self.Controller.QuickEdit:getFocusParam()

	if Param then
		self.ParameterHandler.Parameters[1] = Param
		-- call base
		PageMikro.updateParameters(self, ForceUpdate)
	else
	    local QEValue = self.Controller.QuickEdit:getValueFormatted()
	    self.Screen.ParameterLabel[1]:setText(QEValue and QEValue or "")
	end

end


------------------------------------------------------------------------------------------------------------------------

function MainPageMikro:updatePadLEDs()

    if self.PageMode == MainPageMikro.GROUP then
        GroupPageMikro.updatePadLEDs(self)
    else
        PageMikro.updatePadLEDs(self)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MainPageMikro:updateGroupLEDs()

    self:updateGroupButtonLED()

    if self.PageMode == MainPageMikro.GROUP then
		Page.updateGroupLEDs(self)
    else
        -- call base
        PageMikro.updateGroupLEDs(self)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MainPageMikro:onGroupButton(Pressed)

    NHLController:setPadMode(Pressed and NI.HW.PAD_MODE_NONE or NI.HW.PAD_MODE_PAGE_DEFAULT)
	self.PageMode = Pressed and MainPageMikro.GROUP or MainPageMikro.SOUND

    self.Controller.QuickEdit:onGroupButton(0, Pressed)

    if self.Controller.QuickEdit.NumGroupPressed == 0 then
    	self.Controller.QuickEdit:setLevel(NI.DATA.LEVEL_TAB_SONG)
    end

    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function MainPageMikro:onPadEvent(PadIndex, Trigger, PadValue)

    if self.PageMode == MainPageMikro.GROUP then

        -- same behaviour as on group page
        GroupPageMikro.onPadEvent(self, PadIndex, Trigger, PadValue)

    else
    	self.Controller.QuickEdit:onPadEvent(PadIndex, Trigger)

    	if self.Controller.QuickEdit.NumPadPressed == 0 then
    		self.Controller.QuickEdit:setLevel(NI.DATA.LEVEL_TAB_SONG)
    	end

        -- call base class
        PageMikro.onPadEvent(self, PadIndex, Trigger, PadValue)
    end

    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function MainPageMikro:onScreenButton(ButtonIdx, Pressed)

    if Pressed then

		local NewMode = self.ButtonToJogWheelMode[ButtonIdx]
		NHLController:setJogWheelMode(NewMode)
		self.JogWheelMode = NHLController:getJogWheelMode()

    end

    -- call base class for update
    PageMikro.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MainPageMikro:onWheel(Inc)

	self.Controller.QuickEdit:onWheel(Inc)
	self:updateParameters(false)

	return true

end

------------------------------------------------------------------------------------------------------------------------

function MainPageMikro:updateGroupButtonLED()

    local LEDLevel = self.PageMode == MainPageMikro.GROUP and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
    PageMikro:updateGroupPageButtonLED(LEDLevel, true)

end

------------------------------------------------------------------------------------------------------------------------

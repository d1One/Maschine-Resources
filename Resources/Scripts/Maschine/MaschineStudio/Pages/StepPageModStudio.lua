------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/ControlPageStudio"
require "Scripts/Shared/Helpers/StepHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
StepPageModStudio = class( 'StepPageModStudio', ControlPageStudio )

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:__init(Controller, Name)

    -- init base class
    PageMaschine.__init(self, Name ~= nil and Name or "StepPageModStudio", Controller)

    self:setupScreen()

    -- define page leds
    self.PageLEDs = { Controller.LED_STEP }

    self.PatternSegment = -1
    self.ModTimeDeltaMap = TickFloatMap()

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:setupScreen()

    ControlPageStudio.setupScreen(self)

    self.ParameterHandler.UseNoParamsCaption = false

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:onShow(Show)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Show then
		self.SlotStack:insertInto(self.Screen.ScreenLeft.DisplayBar)
		self.Screen.ScreenLeft.DisplayBar:setFlex(self.SlotStack.Stack)
	else
        self:resetData()
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:updateParameters(ForceUpdate)

    StepHelper.setupStepModParameters(self.ParameterHandler)
    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:updateScreenButtons(ForceUpdate)

    local PluginMode = App:getWorkspace():getModulesVisibleParameter():getValue()

    if PluginMode and self.Controller:getShiftPressed() then

        ControlPageStudio.updateScreenButtonsShiftPluginMode(self, ForceUpdate)

    else

        local StateCache = App:getStateCache()
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        local LevelTab = Song and Song:getLevelTab() or -1

        ScreenHelper.setWidgetText(self.Screen.ScreenButton, self.ScreenButtonText[1])

        -- Plug-in name on arrow label
        self.Screen:setArrowText(1, MaschineHelper.getFocusChannelSlotName())

        -- Button 1,3 -- MASTER, GROUP, SOUND
        for Index = 1,3 do
            self.Screen.ScreenButton[Index]:setEnabled(Index == 1 or Group ~= nil)
            self.Screen.ScreenButton[Index]:setSelected(LevelTab == Index - 1)
        end

        self.Screen.ScreenButton[3]:style("SOUND", "HeadTabRight")

        self.Screen.ScreenButton[4]:setVisible(false)
        self.Screen.ScreenButton[4]:setEnabled(false)
        self.Screen.ScreenButton[4]:setSelected(false)

        self.Screen.ScreenButton[5]:setEnabled(ControlHelper.hasPrevNextSlotOrPageGroup(false, false))
        self.Screen.ScreenButton[6]:setEnabled(ControlHelper.hasPrevNextSlotOrPageGroup(true, false))

        self.Screen.ScreenButton[8]:setVisible(false)
        self.Screen.ScreenButton[8]:setEnabled(false)
        self.Screen.ScreenButton[8]:setSelected(false)

    end

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:updatePadLEDs()

    StepHelper.updatePadLEDs(self.PatternSegment)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:setPatternSegment(PatternSegment)

    self.PatternSegment = PatternSegment

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:resetData()

    self.PatternSegment = -1
    self.ModTimeDeltaMap:clear()

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:onNextPrev(DoNext)

    ControlPageStudio.onNextPrev(self, DoNext)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:onConfigButton()

    ControlPageStudio.onConfigButton(self)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:onPageButton(Button, PageID, Pressed)

    if Pressed and PageID ~= NI.HW.PAGE_STEP_STUDIO then
        -- remove this page before any other page is pushed
        self:resetData()
        NHLController:getPageStack():popPage()
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:onScreenEncoder(KnobIdx, EncoderInc)

	local StateCache = App:getStateCache()
	local Parameter = StateCache:getParameterCache():getGenericParameter(KnobIdx - 1, true)

	if Parameter then
        self.ModTimeDeltaMap:clear()

		for _, StepTime in pairs(StepHelper.HoldingPads) do
		    if StepTime then
                STLHelper.setKeyValue(self.ModTimeDeltaMap, StepHelper.getEventTimeFromStepTime(StepTime), EncoderInc)
			end
		end

        NI.DATA.ModulationEditingAccess.setModulationStep(App, self.ModTimeDeltaMap, Parameter, false)
	end

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:onScreenButton(ButtonIdx, Pressed)

    ControlPageStudio.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:onPadEvent(PadIndex, Trigger, PadValue)

    StepHelper.onPadEvent(PadIndex, Trigger, PadValue)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:onPrevNextButton(Pressed, Next)

	-- more of a force-set-jogwheel because the QuickEditStudio object does it under very specific conditions.
	self.Controller.QuickEdit:onPrevNextButton(Pressed, Next)

	local WheelMode = self.Controller.QuickEdit:getMode()
	NHLController:setTempJogWheelMode(WheelMode)

	return true -- handled

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModStudio:onWheel(Value, Mode)

	local QEMode = self.Controller.QuickEdit:getMode()
	if self.Controller.QuickEdit.Active ~= true and self.Controller.QuickEdit.NumPadPressed > 0 then
		self.Controller.QuickEdit:activate()
	end

	local WheelMode = NHLController:getJogWheelMode()
	if WheelMode ~= NI.HW.JOGWHEEL_MODE_DEFAULT then
		NI.DATA.EventPatternAccess.modifySelectedNotesByJogWheel(App, WheelMode, Value)
		self.Controller:getInfoBar():setTempMode("QuickEditStep")
	end

	return true -- handled

end

------------------------------------------------------------------------------------------------------------------------

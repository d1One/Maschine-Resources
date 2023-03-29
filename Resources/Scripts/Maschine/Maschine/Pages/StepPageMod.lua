------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/Pages/ControlPageControl"
require "Scripts/Shared/Helpers/ControlHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
StepPageMod = class( 'StepPageMod', ControlPageControl )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function StepPageMod:__init(Controller)

    -- init base class
    PageMaschine.__init(self, "StepPageMod", Controller)

	self:setupScreen()

    -- define page leds
    self.PageLEDs = { Controller.LED_STEP }

    self.ModTimeDeltaMap = TickFloatMap()
	self.InfoBarCounter = 0
	self.RemoveNoteFromSelectionCounter = 0

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:setupScreen()

	ControlPageControl.setupScreen(self)
    self.ParameterHandler.UseNoParamsCaption = false

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:onShow(Show)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

	if Show then
		MaschineHelper.resetScreenEncoderSmoother()
	else
		self:resetData()
	end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:updateParameters(ForceUpdate)

	StepHelper.setupStepModParameters(self.ParameterHandler)
    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:updateScreenButtons(ForceUpdate)

	-- call base class
	ControlPageControl.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:updatePadLEDs()

	StepHelper.updatePadLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:resetData()

	StepHelper.PatternSegment = -1
	self.ModTimeDeltaMap:clear()

	for PadIdx, StepTime in pairs(StepHelper.HoldingPads) do
		StepHelper.HoldingPads[PadIdx] = nil
	end

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function StepPageMod:onNextPrev(DoNext)

	ControlPageControl.onNextPrev(self, DoNext)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:onConfigButton()

	ControlPageControl.onConfigButton(self)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:onPageButton(Button, PageID, Pressed)

	if PageID == NI.HW.PAGE_STEP and Pressed then
		-- go back to Step page
		NHLController:getPageStack():popPage()
	end

	return true

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:onScreenEncoder(KnobIdx, EncoderInc)

	local StateCache = App:getStateCache()
	local Parameter = StateCache:getParameterCache():getGenericParameter(KnobIdx - 1, true)

	if Parameter then
        self.ModTimeDeltaMap:clear()

		for _, StepTime in pairs(StepHelper.HoldingPads) do
		    if StepTime ~= nil then
                STLHelper.setKeyValue(self.ModTimeDeltaMap, StepHelper.getEventTimeFromStepTime(StepTime), EncoderInc)
			end
		end

        NI.DATA.ModulationEditingAccess.setModulationStep(App, self.ModTimeDeltaMap, Parameter, false)
	end

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:onScreenButton(ButtonIdx, Pressed)

	ControlPageControl.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:onPadEvent(PadIndex, Trigger, PadValue)

	local StepTime = StepHelper.getStepTime(StepHelper.PatternSegment, PadIndex)

	StepHelper.HoldingPads[PadIndex] = Trigger and StepTime or nil

	if not Trigger then
		self.RemoveNoteFromSelectionCounter = 2
		self.Controller:setTimer(self, 1)
	end

	if StepHelper.getHoldPadSize() > 0 and Trigger then
		StepHelper.selectHoldingNotes(StepHelper.PatternSegment)

	elseif StepHelper.getHoldPadSize() <= 0 then
		NHLController:getPageStack():popPage() -- page goes back to Step page
	end

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:onTimer()

	self.RemoveNoteFromSelectionCounter = self.RemoveNoteFromSelectionCounter - 1

	if self.RemoveNoteFromSelectionCounter > 0 then
		self.Controller:setTimer(self, 1)

	elseif StepHelper.getHoldPadSize() > 0 then
		StepHelper.selectHoldingNotes(StepHelper.PatternSegment)
	end

    PageMaschine.onTimer(self)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:onWheel(Value, Mode)

	local WheelMode = Mode ~= nil and Mode or NHLController:getJogWheelMode()

	NI.DATA.EventPatternAccess.modifySelectedNotesByJogWheel(App, WheelMode, Value)

	if WheelMode ~= NI.HW.JOGWHEEL_MODE_DEFAULT then
		self.Controller:getInfoBar():setTempMode("QuickEditStep")
	end

	return true -- handled

end

------------------------------------------------------------------------------------------------------------------------
-- The next 3 functions handle the Maschine MK1 master section encoders
------------------------------------------------------------------------------------------------------------------------

function StepPageMod:onVolumeEncoder(Value)

	self.Controller.QuickEdit:setMode(NI.HW.JOGWHEEL_MODE_VOLUME)
	local Inc = MaschineHelper.onScreenEncoderSmoother(1, Value, .025)

	if Inc ~= 0 then
		self:onWheel(Inc)
	end

	return true -- handled

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:onTempoEncoder(Value)

	self.Controller.QuickEdit:setMode(NI.HW.JOGWHEEL_MODE_TEMPO)
	local Inc = MaschineHelper.onScreenEncoderSmoother(2, Value, .025)

	if Inc ~= 0 then
		self:onWheel(Inc)
	end

	return true -- handled

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMod:onSwingEncoder(Value)

	self.Controller.QuickEdit:setMode(NI.HW.JOGWHEEL_MODE_SWING)
	local Inc = MaschineHelper.onScreenEncoderSmoother(3, Value, .025)

	if Inc ~= 0 then
		self:onWheel(Inc)
	end

	return true -- handled

end

------------------------------------------------------------------------------------------------------------------------

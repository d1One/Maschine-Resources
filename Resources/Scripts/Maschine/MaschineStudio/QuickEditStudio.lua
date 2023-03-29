------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/QuickEditBase"


local class = require 'Scripts/Shared/Helpers/classy'
QuickEditStudio = class( 'QuickEditStudio', QuickEditBase )


------------------------------------------------------------------------------------------------------------------------

function QuickEditStudio:__init(Controller)

    QuickEditBase.__init(self, Controller)

    self.Active = false
    self.PendingMode = NI.HW.JOGWHEEL_MODE_TEMPO

    self.CanShiftMode = true

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditStudio:setMode(Mode)

	self.PendingMode = Mode

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditStudio:getMode()

	return self.PendingMode

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditStudio:activate()

	if not self.Active then
		self.Active = true
		NHLController:setTempJogWheelMode(self.PendingMode)
	end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditStudio:resetMode()

	if self.Active then
		NHLController:resetJogWheelMode()
		LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_PREV, LEDHelper.LS_OFF)
		LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_NEXT, LEDHelper.LS_OFF)
		self.Active = false
	end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditStudio:canQEMode()

    local SoundEditAllowed, GroupEditAllowed = true, true
    local PadPressed, GroupPressed = self.NumPadPressed > 0, self.NumGroupPressed > 0

    -- Active page is checked by MaschineStudioController
    if ControllerScriptInterface.ActivePage.isSoundQEAllowed then
        SoundEditAllowed = ControllerScriptInterface.ActivePage:isSoundQEAllowed()
    end

    if ControllerScriptInterface.ActivePage.isGroupQEAllowed then
        GroupEditAllowed = ControllerScriptInterface.ActivePage:isGroupQEAllowed()
    end

    return  self.PendingMode ~= NI.HW.JOGWHEEL_MODE_DEFAULT
        and self.PendingMode ~= NI.HW.JOGWHEEL_MODE_CUSTOM
        -- If both Group and Pad are pressed the QE will be disabled since it is not clear what should be affected.
        and math.xor(PadPressed, GroupPressed)
        and ((PadPressed and SoundEditAllowed) or (GroupPressed and GroupEditAllowed))

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditStudio:isNoteNudgeDown()

	return
		self.Controller.SwitchPressed[NI.HW.BUTTON_EDIT_NOTE] or
		self.Controller.SwitchPressed[NI.HW.BUTTON_EDIT_NUDGE]

end

------------------------------------------------------------------------------------------------------------------------
-- QE: SOUND

function QuickEditStudio:onPadEvent(PadIndex, Pressed)

    QuickEditBase.onPadEvent(self, PadIndex, Pressed)
   	self.CanShiftMode = true

    if self.NumPadPressed == 0 then
        self:resetMode()

    elseif self.PendingMode == NI.HW.JOGWHEEL_MODE_NOTENUDGE then
    	self.PendingMode = NI.HW.JOGWHEEL_MODE_TEMPO
    end

end

------------------------------------------------------------------------------------------------------------------------
-- QE: GROUP

function QuickEditStudio:onGroupButton(Index, Pressed)

    QuickEditBase.onGroupButton(self, Index, Pressed)
    self.CanShiftMode = true

    if self.NumGroupPressed == 0 then
		self:resetMode()

    elseif self.PendingMode == NI.HW.JOGWHEEL_MODE_NOTENUDGE then
    	self.PendingMode = NI.HW.JOGWHEEL_MODE_TEMPO
    end

end

------------------------------------------------------------------------------------------------------------------------
-- QE: TEMPO (MASTER) activates after 10 frames

function QuickEditStudio:onTapButton(Pressed)

    if not Pressed then
        self:resetMode()
    else
	    self:setLevel(NI.DATA.LEVEL_TAB_SONG)
		self:setMode(NI.HW.JOGWHEEL_MODE_TEMPO)
	    self.CanShiftMode = false
    	self:activate()
    end

end

------------------------------------------------------------------------------------------------------------------------
-- QE: NOTE TUNE

function QuickEditStudio:onNoteButton(Pressed)

    if not self:isNoteNudgeDown() then
        self:resetMode()
    else
	    self:setLevel(NI.DATA.LEVEL_TAB_SONG)
		self:setMode(NI.HW.JOGWHEEL_MODE_NOTENUDGE)
	    self.CanShiftMode = false
    	self:activate()
    end

end

------------------------------------------------------------------------------------------------------------------------
-- QE: NOTE NUDGE

function QuickEditStudio:onNudgeButton(Pressed)

    if not self:isNoteNudgeDown() then
        self:resetMode()
    else
	    self:setLevel(NI.DATA.LEVEL_TAB_SONG)
		self:setMode(NI.HW.JOGWHEEL_MODE_NOTENUDGE)
	    self.CanShiftMode = false
    	self:activate()
    end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditStudio:onNotePitchNudge(Inc)

	local Fine = self.Controller.SwitchPressed[NI.HW.BUTTON_SHIFT] or NHLController:getWheelPressed()

	if self.Controller.SwitchPressed[NI.HW.BUTTON_EDIT_NOTE] then

		NI.DATA.EventPatternTools.transposeNoteEvents(App, Inc * (Fine and 12 or 1))

	elseif self.Controller.SwitchPressed[NI.HW.BUTTON_EDIT_NUDGE] then

		NI.DATA.EventPatternTools.nudgeEventsInPatternRange(App, Inc, Fine, false)

	end

end


------------------------------------------------------------------------------------------------------------------------

function QuickEditStudio:onPrevNextButton(Pressed, Next)

    if not Pressed then
        return false
    end

    if self.Active then

    	if self.PendingMode == NI.HW.JOGWHEEL_MODE_NOTENUDGE then
    		self:onNotePitchNudge(Next and 1 or -1)
	    else
	        self:shiftMode(Next)
	    end

	    return true

    elseif self:canQEMode() then

    	self:activate()
    	return true

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditStudio:onWheel(Inc)

    if self.Active then

    	if self.PendingMode == NI.HW.JOGWHEEL_MODE_NOTENUDGE then
    		self:onNotePitchNudge(Inc)
	    else
	        QuickEditBase.onWheel(self, Inc)
	    end

		return true

    elseif self:canQEMode() then

    	self:activate()
		return true

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditStudio:onWheelButton(Pressed)

    if Pressed then

		if not self.Active and self:canQEMode() then
			self:activate()
			return true
		end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditStudio:update()

	-- Prev / Next Arrow update

	local Enabled = self.Active and (self.CanShiftMode or self:isNoteNudgeDown())

	LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_TRANSPORT_PREV, NI.HW.BUTTON_TRANSPORT_PREV, Enabled)
	LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_TRANSPORT_NEXT, NI.HW.BUTTON_TRANSPORT_NEXT, Enabled)


	-- JW LED Update

    LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_TUNE, LEDHelper.LS_OFF)
    LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_SWING, LEDHelper.LS_OFF)
    LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_VOLUME, LEDHelper.LS_OFF)

    if not self.Active then
        return false
    end

    local Mode = self.PendingMode
    if Mode == NI.HW.JOGWHEEL_MODE_NOTENUDGE then

        LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_EDIT, LEDHelper.LS_BRIGHT)

    elseif Mode == NI.HW.JOGWHEEL_MODE_SWING then

        LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_SWING, LEDHelper.LS_BRIGHT)

    elseif Mode == NI.HW.JOGWHEEL_MODE_TEMPO then

        if self.Level ~= NI.DATA.LEVEL_TAB_SONG then
	        LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_TUNE, LEDHelper.LS_BRIGHT)
	    end

        if self.Level == NI.DATA.LEVEL_TAB_SOUND then

        	if self:getFocusParam() == nil then
				-- no tune, no lights
				JogwheelLEDHelper.updateAllOff(MaschineStudioController.JOGWHEEL_RING_LEDS)
        		return
        	end
		end

    elseif Mode == NI.HW.JOGWHEEL_MODE_VOLUME then

        LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_VOLUME, LEDHelper.LS_BRIGHT)

    end

    JogwheelLEDHelper.updateAllOn(MaschineStudioController.JOGWHEEL_RING_LEDS)

    return true

end

------------------------------------------------------------------------------------------------------------------------
-- couldn't figure out a prettier way to do this...
function QuickEditStudio:shiftMode(Right)

	if not self.CanShiftMode then
		return
	end

    local Mode = self.PendingMode

    if Mode == NI.HW.JOGWHEEL_MODE_TEMPO then
        Mode = Right and NI.HW.JOGWHEEL_MODE_SWING or NI.HW.JOGWHEEL_MODE_VOLUME

    elseif Mode == NI.HW.JOGWHEEL_MODE_SWING then
        Mode = Right and NI.HW.JOGWHEEL_MODE_VOLUME or NI.HW.JOGWHEEL_MODE_TEMPO

    elseif Mode == NI.HW.JOGWHEEL_MODE_VOLUME then
        Mode = Right and NI.HW.JOGWHEEL_MODE_TEMPO or NI.HW.JOGWHEEL_MODE_SWING

    else
        Mode = NI.HW.JOGWHEEL_MODE_TEMPO
    end

    self:setMode(Mode)

end

------------------------------------------------------------------------------------------------------------------------

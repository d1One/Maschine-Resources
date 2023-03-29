------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/ParameterHandler"
require "Scripts/Shared/Pages/Page"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PageMaschine = class( 'PageMaschine', Page )

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:__init(Name, Controller)

    -- init base class
    Page.__init(self, Name, Controller)

    -- parameter handler that updates parameter names and values, and handles basic events
    self.ParameterHandler = ParameterHandler()

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:updateScreens(ForceUpdate)

	-- screen
	self.Screen:update(ForceUpdate)

	-- screen buttons
	self:updateScreenButtons(ForceUpdate)

    -- parameters
    self:updateParameters(ForceUpdate)

    -- Accessibility
    if NHLController:isExternalAccessibilityRunning() then
        self:refreshAccessibleButtonInfo()
        self:refreshAccessiblePadInfo()
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:updateParameters(ForceUpdate)

    self.ParameterHandler:update(ForceUpdate)

    -- accessibility
    if NHLController:isExternalAccessibilityRunning() then
        self:refreshAccessibleEncoderInfo()
        self:refreshAccessibleLeftRightButtonInfo()
    end

    if self.updateLeftRightLEDs then
        self:updateLeftRightLEDs()
    else
        -- update left/right screen buttons
    	LEDHelper.updateLeftRightLEDsWithParameters(self.Controller,
    		self.ParameterHandler.NumPages, self.ParameterHandler.PageIndex)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:updateScreenButtons(ForceUpdate)

	if self.Screen.ScreenButton == nil then
		return
	end

    -- pin button state
    if self.Screen.ScreenButton[1] and self.Controller:isModifierPage(self) then
		self.Screen.ScreenButton[1]:setSelected(self.IsPinned and self.Screen.ScreenButton[1]:isEnabled())
	end

    -- update screen button LEDs
    self.Controller:updateScreenButtonLEDs(self.Screen.ScreenButton)

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:updateGroupLEDs()

    -- set LED states
    local ShiftPressed = self.Controller:getShiftPressed() and not self.Controller:getErasePressed()
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local NumGroupPressed = self.Controller.QuickEdit and self.Controller.QuickEdit.NumGroupPressed or 0

    if ShiftPressed and Song and Song:getGroups():size() >= 8 and NumGroupPressed == 0 then

		local GroupBankFunctor =
			function(BankIndex)
				local IsFocusGroupBank = BankIndex - 1 == MaschineHelper.getFocusGroupBank()
				local IsActiveBank = BankIndex - 1 < MaschineHelper.getNumFocusSongGroupBanks(true)
				return IsFocusGroupBank, IsActiveBank
			end

		-- for now, the color index for the group banks is white
		local BankColorFunctor = function(Index) return LEDColors.WHITE end

        LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS, 0, GroupBankFunctor, BankColorFunctor)

    else
	    -- update group leds with focus & selected states.
	    -- default behaviour: shows white color on group pad after last to indicate new group can be created there.
		LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS,
        	MaschineHelper.getFocusGroupBank(self) * 8,
            function (Index) return MaschineHelper.getLEDStatesGroupSelectedByIndex(Index, true, false) end,
        	function (Index) return MaschineHelper.getGroupColorByIndex(Index, true) end,
        	MaschineHelper.getFlashStateGroupsNoteOn)

    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onShow(Show)

    Page.onShow(self, Show)


    if NHLController:isExternalAccessibilityRunning() then
        self:sendAccessibilityInfoForPage()
        if Show then
            self:refreshAccessibleButtonInfo()
            self:refreshAccessibleEncoderInfo()
            self:refreshAccessibleLeftRightButtonInfo()
        else
            self:clearAccessibleButtonInfo()
            self:clearAccessibleEncoderInfo()
            self:clearAccessibleLeftRightButtonInfo()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onScreenEncoder(KnobIdx, EncoderInc)

    self.ParameterHandler:onScreenEncoder(KnobIdx, EncoderInc, self.Controller:getShiftPressed())

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onScreenButton(ButtonIdx, Pressed)

    if Pressed then

        -- set bright LED state and block on press, if button has been enabled but not selected
        if self.Screen.ScreenButton[ButtonIdx]
			and self.Screen.ScreenButton[ButtonIdx]:isEnabled()
			and not self.Screen.ScreenButton[ButtonIdx]:isSelected() then

            LEDHelper.setLEDState(self.Controller.SCREEN_BUTTON_LEDS[ButtonIdx], LEDHelper.LS_BRIGHT)
        end

        if ButtonIdx == 1 then

            if self.Controller:isModifierPage(self) and self.Screen.ScreenButton[1]:isEnabled() then
                self:togglePinState()
            end

        end

    end

    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:refreshAccessibleButtonInfo()

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end
	for ButtonIdx = 1, 8 do
        local InformationRow = 0
        if self.Screen and self.Screen.getAccessibleArrowDirectionTextByButtonIndex then
            local ArrowText = self.Screen:getAccessibleArrowDirectionTextByButtonIndex(ButtonIdx)
            if ArrowText ~= nil then
                local ArrowDirectionRow = 0
                InformationRow = 1
                NHLController:addAccessibilityControlData(NI.HW.ZONE_SOFTBUTTONS,
                                                          ButtonIdx - 1,
                                                          self.Controller:getShiftPressed() and NI.HW.LAYER_SHIFTED or NI.HW.LAYER_UNSHIFTED,
                                                          ArrowDirectionRow,
                                                          0,
                                                          ArrowText)
            end
        end
        NHLController:addAccessibilityControlData(NI.HW.ZONE_SOFTBUTTONS,
                                                  ButtonIdx - 1,
                                                  self.Controller:getShiftPressed() and NI.HW.LAYER_SHIFTED or NI.HW.LAYER_UNSHIFTED,
                                                  InformationRow,
                                                  0,
                                                  self:getAccessibleTextByButtonIndex(ButtonIdx))

	end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:clearAccessibleButtonInfo()

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end
    for ButtonIdx = 1, 8 do
        NHLController:clearAccessibilityControlData(NI.HW.ZONE_SOFTBUTTONS, ButtonIdx - 1)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:refreshAccessibleEncoderInfo()

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end

    local SectionRow = 0
    local NameRow = 1
    local ValueRow = 2
    local UnitRow = 3
	for EncoderIdx = 1, 8 do
        local Section, Name, Value, Unit = self:getAccessibleParamDescriptionByIndex(EncoderIdx)
        local Layer = self.Controller:getShiftPressed() and NI.HW.LAYER_SHIFTED or NI.HW.LAYER_UNSHIFTED
        NHLController:clearAccessibilityControlData(NI.HW.ZONE_ERPS, EncoderIdx)
        if Section == "" and Name == "" and Value == "" and Unit == "" then
            NHLController:addAccessibilityControlData(NI.HW.ZONE_ERPS, EncoderIdx, Layer, SectionRow, 0, "")
            NHLController:setAccessibilityControlState(NI.HW.ZONE_ERPS, EncoderIdx, Layer, NI.HW.CNTRL_INACTIVE)
        else
            NHLController:addAccessibilityControlData(NI.HW.ZONE_ERPS, EncoderIdx, Layer, SectionRow, 0, Section)
            NHLController:addAccessibilityControlData(NI.HW.ZONE_ERPS, EncoderIdx, Layer, NameRow, 0, Name)
            NHLController:addAccessibilityControlData(NI.HW.ZONE_ERPS, EncoderIdx, Layer, ValueRow, 0, Value)
            NHLController:addAccessibilityControlData(NI.HW.ZONE_ERPS, EncoderIdx, Layer, UnitRow, 0, Unit)
            NHLController:setAccessibilityControlState(NI.HW.ZONE_ERPS, EncoderIdx, Layer, NI.HW.CNTRL_NO_STATE)
        end
	end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:clearAccessibleEncoderInfo()

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end

    for EncoderIdx = 1, 8 do
        NHLController:clearAccessibilityControlData(NI.HW.ZONE_ERPS, EncoderIdx)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:refreshAccessibleLeftRightButtonInfo()

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end

    local NHLButtonLeft = 59
    local NHLButtonRight = 50
    local Layer = self.Controller:getShiftPressed() and NI.HW.LAYER_SHIFTED or NI.HW.LAYER_UNSHIFTED
    local LeftMessage, RightMessage = self:getAccessibleLeftRightButtonText()

    NHLController:addAccessibilityControlData(NI.HW.ZONE_CONTROLBUTTONS, NHLButtonLeft, Layer, 0, 0, LeftMessage)
    NHLController:addAccessibilityControlData(NI.HW.ZONE_CONTROLBUTTONS, NHLButtonRight, Layer, 0, 0, RightMessage)

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:clearAccessibleLeftRightButtonInfo()

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end

    local NHLButtonLeft = 59
    local NHLButtonRight = 50

    NHLController:clearAccessibilityControlData(NI.HW.ZONE_CONTROLBUTTONS, NHLButtonLeft)
    NHLController:clearAccessibilityControlData(NI.HW.ZONE_CONTROLBUTTONS, NHLButtonRight)

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:sendAccessiblePadInfo(PadIdx)

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end
    if NI.HW.FEATURE.PADS then
        NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_PADS, PadIdx)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:refreshAccessiblePadInfo()

    if not NI.HW.FEATURE.PADS then
        return
    end
    if not NHLController:isExternalAccessibilityRunning() then
        return
    end
	for PadIdx = 1, 16 do
        NHLController:addAccessibilityControlData(NI.HW.ZONE_PADS,
                                                    PadIdx,
                                                    NI.HW.LAYER_UNSHIFTED, -- SHIFT layer is handled separately
                                                    0,
                                                    0,
                                                    self:getAccessibleTextByPadIndex(PadIdx))
	end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:refreshAccessibleWheelInfo()

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end
    local WheelParam = self.Controller.QuickEdit and self.Controller.QuickEdit:getFocusParam()
    if not WheelParam then
        NHLController:clearAccessibilityControlData(NI.HW.ZONE_JOGWHEEL, 0)
        return
    end

    local Layer = self.Controller:getShiftPressed() and NI.HW.LAYER_SHIFTED or NI.HW.LAYER_UNSHIFTED
    local Name = NI.GUI.ParameterWidgetHelper.getParameterName(WheelParam)
    local Value = WheelParam:getValueString()

    NHLController:addAccessibilityControlData(NI.HW.ZONE_JOGWHEEL, 0, Layer, 0, 0, Name)
    NHLController:addAccessibilityControlData(NI.HW.ZONE_JOGWHEEL, 0, Layer, 1, 0, Value)
    NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_JOGWHEEL, 0)

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:getAccessibleTextByButtonIndex(ButtonIdx)

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end
    if self.Screen and self.Screen.getAccessibleTextByButtonIndex then
        return self.Screen:getAccessibleTextByButtonIndex(ButtonIdx)
    end

    return ""

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:getAccessibleParamDescriptionByIndex(EncoderIdx)

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end
    if self.Screen and self.Screen.getAccessibleParamDescriptionByIndex then
        local _, Name, Value, Unit = self.Screen:getAccessibleParamDescriptionByIndex(EncoderIdx)
        local HasParameter = (Name ~= "" or Value ~= "" or Unit ~= "")
        local Section = HasParameter and self.ParameterHandler:getPreviousSectionName(EncoderIdx) or ""

        return Section, Name, Value, Unit
    end

    return "", "", "", ""

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:getAccessibleTextByPadIndex(PadIdx)

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end
    if NI.HW.FEATURE.PADS and NHLController:getPadMode() == NI.HW.PAD_MODE_STEP then
        return StepHelper.getAccessibleStepAnnouncementByPadIndex(PadIdx)
    end

    return ""

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:getAccessibleLeftRightButtonText()

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end
    local HasParameterPages = self.ParameterHandler.NumPages > 1
    local Message = HasParameterPages and "Parameter Page "..self.ParameterHandler.PageIndex or ""
    return Message, Message

end    

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onLeftRightButton(Right, Pressed)

	if Pressed then
		local NumParameters = self.ParameterHandler.NumPages
		local CurParameterIdx = self.ParameterHandler.PageIndex
		local LeftEnabled = NumParameters > 0 and CurParameterIdx > 1
		local RightEnabled = NumParameters > 0 and CurParameterIdx < NumParameters

		if (LeftEnabled and not Right) or (RightEnabled and Right) then
			self.ParameterHandler:onPrevNextParameterPage(Right and 1 or -1)
		end
	end

    self:updateParameters()

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onWheel(Inc)

	return false

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onVolumeButton(Pressed)

    if Pressed then
        local NewMode = NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_VOLUME
			and NI.HW.JOGWHEEL_MODE_DEFAULT
			or  NI.HW.JOGWHEEL_MODE_VOLUME

        NHLController:setJogWheelMode(NewMode)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onTempoButton(Pressed)

    if Pressed then
        local NewMode = NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_TEMPO
			and NI.HW.JOGWHEEL_MODE_DEFAULT
			or  NI.HW.JOGWHEEL_MODE_TEMPO

        NHLController:setJogWheelMode(NewMode)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onSwingButton(Pressed)

    if Pressed then
        local NewMode = NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_SWING
			and NI.HW.JOGWHEEL_MODE_DEFAULT
			or  NI.HW.JOGWHEEL_MODE_SWING

        NHLController:setJogWheelMode(NewMode)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onVolumeEncoder(EncoderInc)

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onTempoEncoder(EncoderInc)

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onSwingEncoder(EncoderInc)

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:getScreenEncoderInfo(EncoderIdx)

    return self.ParameterHandler:getParameterInfo(EncoderIdx)

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:getScreenButtonInfo(ButtonIdx)

    local ScreenButton = self.Screen.ScreenButton[ButtonIdx]

    if ScreenButton and ScreenButton:isVisible() then
        local Info = {}

        Info.SpeakNameInTrainingMode = true
        Info.SpeakNameInNormalMode = true
        Info.SpeakValueInTrainingMode = true
        Info.SpeakValueInNormalMode = true
        Info.SpeechName = ScreenButton:getText()
        Info.SpeechValue = ScreenButton:isSelected() and "on" or "off"

        return Info
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onGroupButtonPressed(ButtonIndex, ErasePressed, ShiftPressed, Song, Groups)

    local GroupIndex = ButtonIndex-1 + (MaschineHelper.getFocusGroupBank(self) * 8)

    if ShiftPressed and ErasePressed then

        -- define reset Group function
        local Group = Groups:at(GroupIndex) or nil
        if Group then
            NI.DATA.ObjectVectorAccess.removeGroupResetLast(App, Groups, Group)
		end

    elseif ShiftPressed and Groups:size() >= 8 then

        -- select Group bank
        MaschineHelper.setFocusGroupBankAndGroup(self, ButtonIndex - 1, true, true)

    elseif Song and GroupIndex == Groups:size() then

        NI.DATA.SongAccess.createGroup(App, Song, false)

    else

        -- focus Group
        local Group = Groups:at(GroupIndex) or nil

        if Group then
            NI.DATA.SongAccess.setFocusGroup(App, Song, Group, false)
        end

    end


end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onGroupButton(ButtonIndex, Pressed)

    local ErasePressed = self.Controller:getErasePressed()
    local ShiftPressed = self.Controller:getShiftPressed()

    -- get focused song groups
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil

    if Groups == nil then
        return
    end

    if Pressed then
        self:onGroupButtonPressed(ButtonIndex, ErasePressed, ShiftPressed, Song, Groups)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:onTimer()
end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:clearScreenButton(ButtonIdx)

    self.Screen.ScreenButton[ButtonIdx]:setEnabled(false)
    self.Screen.ScreenButton[ButtonIdx]:setSelected(false)
    self.Screen.ScreenButton[ButtonIdx]:setVisible(false)
    NHLController:clearAccessibilityControlData(NI.HW.ZONE_SOFTBUTTONS, ButtonIndex  - 1)

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:getAccessiblePageInfo()

    return self.Name

end

------------------------------------------------------------------------------------------------------------------------

function PageMaschine:sendAccessibilityInfoForPage()

    NHLController:addAccessibilityControlData(NI.HW.ZONE_SCREENINFO, 0, 0, 0, 0, self:getAccessiblePageInfo())
    NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_SCREENINFO, 0)

end

------------------------------------------------------------------------------------------------------------------------

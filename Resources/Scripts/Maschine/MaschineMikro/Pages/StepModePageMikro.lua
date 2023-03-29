------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Maschine/Helper/ClipHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Shared/Helpers/StepHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
StepModePageMikro = class( 'StepModePageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "StepPage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = self.Controller.HWModel == NI.HW.MASCHINE_CONTROLLER_MIKRO_MK1
        and { NI.HW.LED_NOTE_REPEAT }
        or  { NI.HW.LED_GROUP }

    self.PrevCurSegment = 0		-- used for "Follow" mode

    -- Used to keep track of what pad velocities were on pad-down events, because the notes
    -- are added only on pad-release, if the pad wasn't held long enough to go into the StepModPage.
	self.PadVelocities = {}

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:setupScreen()

    -- setup screen
    self.Screen = ScreenMikro(self, ScreenMikro.PARAMETER_MODE_NONE)

    -- Screen Buttons
    self.Screen:styleScreenButtons({"FOLLOW", "DOUBLE", "FIX VEL"}, "HeadButtonRow", "HeadButton")

    -- Info Display
    ScreenHelper.setWidgetText(self.Screen.Title, {"STEP MODE"})

    -- lower part of the screen where the PatternGrid + PatternGuide, as well as Fix Velocity value are
    self.StepPageStack = NI.GUI.insertStack(self.Screen.InfoGroupBar, "StepPageStack")
    self.StepPageStack:style("StepPageStack")

    -- Pattern GUI elements (grid and guide)
    self.PatternGUIBar = NI.GUI.insertBar(self.StepPageStack, "RecordBar")
    self.PatternGUIBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "PatternGUIBarStyle")

    self.PatternGrid = NI.GUI.insertHardwarePatternGrid(self.PatternGUIBar, App, "PatternGrid")
    self.PatternGuide = NI.GUI.insertHardwarePatternGuide(self.PatternGUIBar, App, "PatternGuide")

    -- Fixed Velocity value
    self.FixVelBar = NI.GUI.insertBar(self.StepPageStack, "LabelBar")
    self.FixVelBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "FixVelocityBarStyle")

    local Spacer = NI.GUI.insertLabel(self.FixVelBar, "Spacer")
    Spacer:style("", "Spacer6px")
    self.FixVelLabel = NI.GUI.insertLabel(self.FixVelBar, "LabelFixVelocityMikro")
    self.FixVelLabel:style("127", "ParameterValueSingle")
	self.FixVelBar:setVisible(false)

    -- default stack element
    self.StepPageStack:setTop(self.PatternGUIBar)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:updateScreens(ForceUpdate)

    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local SongClipViewChanged = ArrangerHelper.isSongFocusEntityChanged()

    ForceUpdate =
        ForceUpdate or
        StepHelper.getSnapParameterChanged() or
        App:getStateCache():isFocusSoundChanged() or
        SongClipViewChanged

    self.PatternGrid:update(ForceUpdate)
    self.PatternGuide:update(ForceUpdate)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local GroupValid = Group ~= nil

    self.Screen.ScreenButton[1]:setEnabled(GroupValid)
    self.Screen.ScreenButton[1]:setSelected(GroupValid and self.PatternGrid:getAutoFocusSegment())

    self.Screen.ScreenButton[2]:setEnabled(GroupValid and not SongClipView)
    self.Screen.ScreenButton[2]:setVisible(not SongClipView)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)
    self.Screen.ScreenButton[3]:setVisible(not AudioLoop)
    self.Screen.ScreenButton[3]:setEnabled(GroupValid)
    self.Screen.ScreenButton[3]:setSelected(GroupValid and StepHelper.isFixedVelocity())

    if ForceUpdate then
        self:updatePageLEDColor(LEDHelper.LS_DIM) -- set to DIM, because it is on Shift
    end

    -- call base class
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:updatePageLEDs(LEDState)

    if LEDState == LEDHelper.LS_BRIGHT then
        LEDState = LEDHelper.LS_DIM -- set to DIM, because it is on Shift
    end

    -- call base
    PageMikro.updatePageLEDs(self, LEDState)

    -- update page button led color
    self:updatePageLEDColor(LEDState)

end

------------------------------------------------------------------------------------------------------------------------
-- updatePageLEDColor: Sets the focus Sound's color to the GROUP/STEP MODE button LED
------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:updatePageLEDColor(LEDState)

	if LEDState ~= LEDHelper.LS_OFF and NHLController:hasRGBLEDs() then

		local Sound = NI.DATA.StateHelper.getFocusSound(App)
		if Sound then
			local ColorIndex = Sound:getColorParameter():getValue()
			LEDHelper.setLEDColor(self.PageLEDs[1], LEDColors[ColorIndex][LEDState])
		end

	end

end

------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:updatePadLEDs()

    StepHelper.updatePadLEDs(self.PatternGuide:getFocusedSegment())

end

------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:getLeftButtonEnabled()

    local Pattern = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) and nil or NI.DATA.StateHelper.getFocusEventPattern(App)

    return Pattern and (self.PatternGuide:getFocusedSegment() > 0) or false

end

------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:getRightButtonEnabled()

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    if Pattern then
        return self.PatternGuide:getFocusedSegment() < self.PatternGuide:getNumSegments()-1
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:startFixedVelocityTimer()

	-- update fixed velocity text
	self.FixVelLabel:setText("FIX VEL: "..tostring(StepHelper.getFixedVelocityValue()))
	self.FixVelBar:setVisible(true)
	self.StepPageStack:setTop(self.FixVelBar)

	self.FixVelTimerCount = 20
	self.Controller:setTimer(self, 1)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:onTimer()

    if self.FixVelBar:isVisible() then

        self.FixVelTimerCount = self.FixVelTimerCount - 1

        if self.FixVelTimerCount <= 0 then
            self.FixVelBar:setVisible(false)
            self.StepPageStack:setTop(self.PatternGUIBar)
        else
            self.Controller:setTimer(self, 1)
        end

    elseif self.PatternGuide:getAutoFocusSegment() and self.IsVisible then

        self.Controller:setTimer(self, 1)

        if self.PatternGuide:getFocusedSegment() ~= self.PrevCurSegment then
            -- Update screen and pad leds if following the pattern
            self.PrevCurSegment = self.PatternGuide:getFocusedSegment()
            self:updateScreens()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:onPadEvent(PadIndex, Trigger, PadValue)

    if self.Controller:getShiftPressed() then

        -- Allow shift-functions in this page
        PageMikro.onPadEvent(self, PadIndex, Trigger, PadValue)

    else

        local StepTime = StepHelper.getStepTime(self.PatternGuide:getFocusedSegment(), PadIndex)

        if not NI.DATA.StateHelper.getFocusEventPattern(App) then
            NI.DATA.WORKSPACE.createPatternIfNeeded(App)
        end

        local StepRangeWidth = StepHelper.getStepRangeWidth()

        if StepTime >= StepRangeWidth then
            return
        end

        if Trigger then
            self.PadVelocities[PadIndex] = PadValue

        -- only ok if pad was first pressed in step mode
        elseif self.PadVelocities[PadIndex] then
            -- toggle note on pad-release
            local Velocity = StepHelper.isFixedVelocity()
                and StepHelper.getFixedVelocityValue()
                or math.bound(math.floor(self.PadVelocities[PadIndex] * 128), 0, 127)

            StepHelper.toggleSoundEvent(Velocity, StepTime, Trigger)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:onScreenButton(Idx, Pressed)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)

    if Pressed then
        if Idx == 1 then

            self.PatternGuide:setAutoFocusSegment(not self.PatternGuide:getAutoFocusSegment())
            self.PatternGrid:setAutoFocusSegment(not self.PatternGrid:getAutoFocusSegment())
            self:onTimer()

        elseif Idx == 2 and NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_PATTERN) then

            local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
            if Pattern then
                NI.DATA.EventPatternAccess.doublePattern(App, Pattern)
            end

        elseif Idx == 3 and not AudioLoop then

            StepHelper.toggleFixedVelocity()
            self.StepPageStack:setTop(StepHelper.isFixedVelocity() and self.FixVelBar or self.PatternGUIBar)

            if StepHelper.isFixedVelocity() then
                self:startFixedVelocityTimer()
            end

        end
    end

    -- call base class for update
    PageMikro.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:onWheel(Inc)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)
    if AudioLoop then
        return true
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local FixVelParam = Song and Song:getFixedVelocityParameter() or nil

    if FixVelParam then
        local NewValue = math.bound(FixVelParam:getValue() + Inc, 0, 127)
        NI.DATA.ParameterAccess.setSizeTParameter(App, FixVelParam, NewValue)
    end

    self:startFixedVelocityTimer()
    return true

end

------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:onLeftRightButton(Right, Pressed)

    if not Pressed then
        return
    end

    -- turn follow off if needed
    local IsPlaying = App:getWorkspace():getPlayingParameter():getValue()
    if IsPlaying and self.PatternGuide:getAutoFocusSegment() then
        self.PatternGuide:setAutoFocusSegment(false)
        self.PatternGrid:setAutoFocusSegment(false)
    end

    StepHelper.increasePatternSegment(Right and 1 or -1, self.PatternGrid, self.Controller)
    StepHelper.increasePatternSegment(Right and 1 or -1, self.PatternGuide, self.Controller)

    self.Controller.ActivePage:updateScreens(true)

end

------------------------------------------------------------------------------------------------------------------------

function StepModePageMikro:onGroupButton(Pressed)

    if Pressed then
        NHLController:getPageStack():popPage()
    end

end

------------------------------------------------------------------------------------------------------------------------


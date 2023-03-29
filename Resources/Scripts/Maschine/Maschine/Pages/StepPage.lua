------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

require "Scripts/Maschine/Components/TransactionSequenceMarker"
require "Scripts/Shared/Components/ScreenMaschine"
require "Scripts/Shared/Components/InfoBar"
require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Maschine/Helper/GridHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/StepHelper"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
StepPage = class( 'StepPage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function StepPage:__init(Controller)

    PageMaschine.__init(self, "StepPage", Controller)

    self.IsPinned  = true

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_STEP }

    self.PrevCurSegment = 0 -- used for "Follow" mode

    self.TransactionSequenceMarker = TransactionSequenceMarker()

    -- Used to keep track of what pad velocities were on pad-down events, because the notes
    -- are added only on pad-release, if the pad wasn't held long enough to go into the StepModPage.
    self.PadVelocities = {}

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:setupScreen()

    self.Screen = ScreenMaschine(self)

    -- setup left screen
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"STEP", "", "DOUBLE", "FIXED VEL"}, "HeadButton", true)
    self.Screen.ScreenButton[1]:style("STEP", "HeadPin")

    self.Screen.ScreenButton[1]:setSelected(true)
    self.Screen.ScreenButton[2]:setVisible(false)

    -- screen buttons right
    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"FOLLOW", "", "<-", "->"}, "HeadButton")
    self.Screen.ScreenButton[6]:setVisible(false)
    self.Screen.ScreenButton[7]:style("<-", "ScreenButton")
    self.Screen.ScreenButton[8]:style("->", "ScreenButton")

    -- insert focused-sound info bar
    self.Screen.InfoBarRight = InfoBar(self.Controller, self.Screen.ScreenRight, "RightScreenDefault")

    self.PatternGrid = NI.GUI.insertHardwarePatternGrid(self.Screen.ScreenRight, App, "PatternGrid")
    self.PatternGuide = NI.GUI.insertHardwarePatternGuide(self.Screen.ScreenRight, App, "PatternGuide")

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function StepPage:updateScreens(ForceUpdate)

    ForceUpdate = ForceUpdate or StepHelper.getSnapParameterChanged()

    self.PatternGuide:update(ForceUpdate)
    self.PatternGrid:update(ForceUpdate)

    -- screen buttons
    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local HasPattern = NI.DATA.StateHelper.getFocusEventPattern(App) ~= nil
    local FollowMode = self.PatternGuide:getAutoFocusSegment()
    local CurSegment = self.PatternGuide:getFocusedSegment()
    local NumSegments = self.PatternGuide:getNumSegments()
    local IsPlaying = App:getWorkspace():getPlayingParameter():getValue()

    self.Screen.ScreenButton[3]:setVisible(not SongClipView)
    self.Screen.ScreenButton[3]:setEnabled(HasPattern and not SongClipView)


    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)
    self.Screen.ScreenButton[4]:setVisible(not AudioLoop)
    self.Screen.ScreenButton[4]:setEnabled(HasPattern)
    self.Screen.ScreenButton[4]:setSelected(HasPattern and StepHelper.isFixedVelocity())

    self.Screen.ScreenButton[5]:setEnabled(HasPattern)
    self.Screen.ScreenButton[5]:setSelected(HasPattern and FollowMode)

    self.Screen.ScreenButton[7]:setEnabled(HasPattern and CurSegment > 0)
    self.Screen.ScreenButton[8]:setEnabled(HasPattern and CurSegment < NumSegments-1)

    -- update info bars
    self.Screen.InfoBarRight:update(ForceUpdate)

    -- call base
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:updateParameters(ForceUpdate)

    local StateCache = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local Sound = NI.DATA.StateHelper.getFocusSound(App)

    local Sections = {}
    local Names = {}
    local Values = {}

    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)

    Sections = {AudioLoop and "" or "EVENTS", "", "", SongClipView and "CLIP" or "PATTERN"}

    if AudioLoop then

        self.ParameterHandler.Parameters[1] = nil
        self.ParameterHandler.Parameters[2] = nil

    else

        self.ParameterHandler.Parameters[1] = Sound and Sound:getBaseKeyParameter() or nil
        self.ParameterHandler.Parameters[2] = Song and Song:getFixedVelocityParameter() or nil

        Names[2] = "VELOCITY"

        if SongClipView then
            Names[3] = "START"
            Values[3] = ClipHelper.getFocusClipStartString()
        end

    end

    Names[4] = "LENGTH"
    if SongClipView then
        Values[4] = ClipHelper.getFocusClipLengthString()
    elseif Pattern then
        Values[4] = Song:getTickToString(Pattern:getLengthParameter():getValue())
    else
        Values[4] = "-"
    end

    self.ParameterHandler:setCustomSections(Sections)
    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomValues(Values)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- update LEDs
------------------------------------------------------------------------------------------------------------------------

function StepPage:updatePadLEDs()

    StepHelper.updatePadLEDs(self.PatternGuide:getFocusedSegment())

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onShow(Show)

    if Show then
        self:resetHoldTimer()
        StepHelper.HoldingPads = {}

        -- set page button states off
        LEDHelper.setLEDState(NI.HW.LED_LEFT, LEDHelper.LS_OFF )
        LEDHelper.setLEDState(NI.HW.LED_RIGHT, LEDHelper.LS_OFF )

        self.TransactionSequenceMarker:reset()

    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onTimer()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)

    -- If one or more pads are held down, count held time, and eventually go into event modulation page
    if not AudioLoop and StepHelper.getHoldPadSize() > 0 then

        self.PadHoldCount = self.PadHoldCount + 1

        -- roughly 1/2 second before event mod screen appears
        if self.PadHoldCount > 10 then

            local StepPageMod = self.Controller:getPage(NI.HW.PAGE_STEP_MOD)
            if StepPageMod then
                StepHelper.PatternSegment = self.PatternGuide:getFocusedSegment()
                StepHelper.selectHoldingNotes(StepHelper.PatternSegment)

                self:resetHoldTimer()
                NHLController:getPageStack():pushPage(NI.HW.PAGE_STEP_MOD)
                return
            end
        end

    end

    self.Controller:setTimer(self, 1)
    PageMaschine.onTimer(self)

    -- Update follow mode
    if self.PatternGuide:getAutoFocusSegment() and self.PatternGuide:getFocusedSegment() ~= self.PrevCurSegment then
        -- Update screen and pad leds if following the pattern
        self.PrevCurSegment = self.PatternGuide:getFocusedSegment()
        self:updateScreens()
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onPadEvent(PadIndex, Trigger, PadValue)

    if self.Controller:getShiftPressed() then

        -- Allow shift-functions in this page
        PageMaschine.onPadEvent(self, PadIndex, Trigger, PadValue)

    else

        local StepTime = StepHelper.getStepTime(self.PatternGuide:getFocusedSegment(), PadIndex)

        if not NI.DATA.StateHelper.getFocusEventPattern(App) then
            NI.DATA.WORKSPACE.createPatternIfNeeded(App)
        end

        local StepRangeWidth = StepHelper.getStepRangeWidth()

        if StepTime >= StepRangeWidth then
            return
        end

        local HoldPadSize = StepHelper.getHoldPadSize()
        local StartTimer = Trigger and HoldPadSize == 0

        if Trigger then

            StepHelper.HoldingPads[PadIndex] = StepTime
            self.PadVelocities[PadIndex] = PadValue

        else

            -- only ok if pad was first pressed in step mode
            if self.PadVelocities[PadIndex] then
                -- toggle note on pad-release
                local Velocity = StepHelper.isFixedVelocity() and StepHelper.getFixedVelocityValue()
                    or math.bound(math.floor(self.PadVelocities[PadIndex] * 128), 0, 127)

                StepHelper.toggleSoundEvent(Velocity, StepTime, Trigger)
            end

            StepHelper.HoldingPads[PadIndex] = nil
            HoldPadSize = StepHelper.getHoldPadSize()

        end

        if StartTimer then
            self.Controller:setTimer(self, 1)

        elseif HoldPadSize == 0 then
            self:resetHoldTimer()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:resetHoldTimer()

    self.PadHoldCount = 0

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onScreenEncoder(KnobIdx, EncoderInc)

    if KnobIdx == 3 or KnobIdx == 4 then

        if MaschineHelper.onScreenEncoderSmoother(KnobIdx, EncoderInc, .1) == 0 then
            return
        end

        if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then

            self.TransactionSequenceMarker:set()
            if KnobIdx == 3 then
                NI.DATA.EventPatternAccess.changeFocusClipEventStart(
                    App, EncoderInc > 0 and 1 or -1, self.Controller:getShiftPressed())
            else -- KnobIdx == 4
                NI.DATA.EventPatternAccess.changeFocusClipEventLength(
                    App, EncoderInc > 0 and 1 or -1, self.Controller:getShiftPressed())
            end

        elseif KnobIdx == 4 then

            local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
            if Pattern then
                local Quick = GridHelper.isQuickEnabled()
                NI.DATA.EventPatternAccess.incrementExplicitLength(
                    App, Pattern, EncoderInc > 0 and 1 or -1, self.Controller:getShiftPressed(), Quick)
            end

        end

        return
    end

    -- update BaseKey / FixedVelocity Parameter
    PageMaschine.onScreenEncoder(self, KnobIdx, EncoderInc)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onScreenButton(Idx, Pressed)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)

    if Pressed then
        local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

        if Idx == 3 and NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_PATTERN) then
            if Pattern then
                NI.DATA.EventPatternAccess.doublePattern(App, Pattern)
            end

        elseif Idx == 4 and not AudioLoop then
            if Pattern then
                StepHelper.toggleFixedVelocity()
            end

        elseif Idx == 5 then
            if Pattern then
                self.PatternGuide:setAutoFocusSegment(not self.PatternGuide:getAutoFocusSegment())
                self.PatternGrid:setAutoFocusSegment(not self.PatternGrid:getAutoFocusSegment())
                self:onTimer()
            end

        elseif Idx == 7 or Idx == 8 then

            local IsPlaying = App:getWorkspace():getPlayingParameter():getValue()

            -- turn follow off in this case
            if IsPlaying and self.PatternGuide:getAutoFocusSegment() then
                self.PatternGuide:setAutoFocusSegment(false)
                self.PatternGrid:setAutoFocusSegment(false)
            end

            StepHelper.increasePatternSegment(Idx == 7 and -1 or 1, self.PatternGuide, self.Controller)
            StepHelper.increasePatternSegment(Idx == 7 and -1 or 1, self.PatternGrid, self.Controller)
        end

    end

    -- call base class for update
    PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

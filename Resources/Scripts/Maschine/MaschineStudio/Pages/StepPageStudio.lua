------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/EventsPageBase"
require "Scripts/Shared/Components/ScreenMaschineStudio"
require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Helpers/StepHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
StepPageStudio = class( 'StepPageStudio', EventsPageBase )

------------------------------------------------------------------------------------------------------------------------

function StepPageStudio:__init(Controller)

    EventsPageBase.__init(self, "StepPageStudio", Controller)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_STEP }

    -- Used to keep track of what pad velocities were on pad-down events, because the notes
    -- are added only on pad-release, iff the pad wasn't held long enough to go into the StepModPage.
    self.PadVelocities = {}

end

------------------------------------------------------------------------------------------------------------------------

function StepPageStudio:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"STEP MODE", "", "DOUBLE", "FIXED VEL"},
        {"HeadPin", "HeadButton", "HeadButton", "HeadButton"}, false)

    -- right screen
    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"FOLLOW", "", "", ""}, "HeadButton", false)

    -- Main Display

    self.Encoders = CustomEncoderHandler()

    self.ParameterHandler.SectionWidgets[1]:setText("")

    self.Screen.ScreenButton[1]:setSelected(true)

    EventsPageBase.setupScreen(self, false)

end

------------------------------------------------------------------------------------------------------------------------
-- setup Custom Encoders
------------------------------------------------------------------------------------------------------------------------

function StepPageStudio:setupCustomEncoders()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Song == nil or Group == nil then
        return
    end

    EventsHelper.addEditingEncoders(self.Encoders, self.Screen.ParameterWidgets,
                                    function () return self.Controller:getShiftPressed() end)

    self.ParameterHandler.Parameters[3] = Song and Song:getFixedVelocityParameter()

end

------------------------------------------------------------------------------------------------------------------------

function StepPageStudio:onShow(Show)

    self.Arranger:setUseGlobalFollow(not Show)

    if Show then
        StepHelper.resetStepModulationHoldTime(false)
        StepHelper.resetStepModulationHoldData()

        self:setupCustomEncoders()
        self.Controller.CapacitiveList:assignParametersToCaps({})

        local SegmentSize = StepHelper.getPatternEditorSnapInTicks() * 16
        local CenterTick = StepHelper.PatternSegment * SegmentSize + SegmentSize / 2
        StepHelper.PatternSegment = math.floor(CenterTick / SegmentSize)

        self.Controller:setTimer(self, 1)

    end

    EventsPageBase.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageStudio:updateScreens(ForceUpdate)

    StepHelper.syncPatternSegmentToModel()

    local HasPattern = NI.DATA.StateHelper.getFocusEventPattern(App) ~= nil
    local KeyboardOn = PadModeHelper.getKeyboardMode()

    self.Controller.CapacitiveNavIcons:Enable(HasPattern, KeyboardOn, false)
    self.Arranger:setHWCompactVelocityLayout(not KeyboardOn)

    EventsPageBase.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageStudio:updateParameters(ForceUpdate)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    if Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound) then

        self.Encoders:resetEncoders()

    else

        self.Encoders:updateEncoder(1)
        self.Encoders:updateEncoder(2)

        if StepHelper.isFixedVelocity() then
            self.ParameterHandler:updateParamWidget(3)
        else
            self.Encoders:updateEncoder(3)
        end

        self.Encoders:updateEncoder(4)
        self.updateAccessibilityPagePosition(false)

    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPageStudio:updateScreenButtons(ForceUpdate)

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)

    self.Screen.ScreenButton[3]:setVisible(not SongClipView)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)
    self.Screen.ScreenButton[4]:setVisible(not AudioLoop)
    self.Screen.ScreenButton[4]:setSelected(StepHelper.isFixedVelocity())

    self.Screen.ScreenButton[5]:setSelected(StepHelper.FollowModeOn)

    EventsPageBase.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageStudio:onScreenEncoder(Idx, Inc)

    local StateCache = App:getStateCache()

    if NI.DATA.StateHelper.getFocusEventPattern(App) == nil then
        return
    end

    local Workspace = App:getWorkspace()

    if Idx >= 1 and Idx <= 4 then

        -- The custom Events Encoders
        if Idx == 3 and StepHelper.isFixedVelocity() then
            EventsPageBase.onScreenEncoder(self, Idx, Inc)
            self:refreshAccessibleEncoderInfo()
        else
            self.Encoders:onEncoderChanged(Idx, Inc)
        end

    elseif Idx == 6 then

        -- SCROLL (HORZ) - Jumps in whole Pages in Step Mode
        if StepHelper.FollowModeOn and self.Arranger:isPlayingFocusPattern() then
            -- turn off follow if scrolling
            StepHelper.FollowModeOn = false
        end

        if MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) ~= 0 then
            -- The last segment may start at a non-integer; we try to show a full segment *ending* at the pattern end
            local MaxSegment = NI.DATA.StateHelper.getFocusPatternLength(App) / (StepHelper.getPatternEditorSnapInTicks() * 16)
            StepHelper.setPatternSegment(math.bound(StepHelper.PatternSegment + (Inc < 0 and -1 or 1), 0, MaxSegment - 1))
            self.updateAccessibilityPagePosition(true)
        end


    elseif Idx == 8 then

        EventsPageBase.onZoomScrollEncoder(self, 8, Inc)

    end
    NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_ERPS, Idx)


end

------------------------------------------------------------------------------------------------------------------------

function StepPageStudio:onTimer()

    -- because we need to be able to move freely when the Repeat page is on top (also featuring a Pattern Editor)
    if self.IsVisible and NHLController:getPageStack():getTopPage() ~= NI.HW.PAGE_REPEAT then
        self:onTimerStepMode()
    end

    PageMaschine.onTimer(self)

    -- Count holding pad time if a pad is being held, and eventually go into step modulation page
    if StepHelper.onControllerTimer(self.Controller) then
       return
    end

    if self.IsVisible then
        self.Controller:setTimer(self, 1)
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPageStudio:onTimerStepMode()

    self.Arranger:zoomScrollOnSegment(StepHelper.PatternSegment)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageStudio:onScreenButton(Idx, Pressed)

    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)

    if Idx == 3 and Pressed and not SongClipView then

        local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
        if Pattern then
            NI.DATA.EventPatternAccess.doublePattern(App, Pattern)
        end

    elseif Idx == 4 and not AudioLoop and Pressed then
        StepHelper.toggleFixedVelocity()

    elseif Idx == 5 and Pressed then
        StepHelper.FollowModeOn = not StepHelper.FollowModeOn
    end

    -- call base class for update
    EventsPageBase.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageStudio:onPadEvent(PadIndex, Trigger, PadValue)

    StepHelper.onPadEvent(PadIndex, Trigger, PadValue)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageStudio.updateAccessibilityPagePosition(TriggerSpeech)

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end
    local HorizEncoder = 6
    NHLController:addAccessibilityControlData(NI.HW.ZONE_ERPS, HorizEncoder, 0, 0, 0, "Event page " .. math.floor(StepHelper.PatternSegment + 1))
    NHLController:setAccessibilityControlState(NI.HW.ZONE_ERPS, HorizEncoder, 0, NI.HW.CNTRL_NO_STATE)
    if TriggerSpeech then
        NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_ERPS, HorizEncoder)
    end

end

------------------------------------------------------------------------------------------------------------------------

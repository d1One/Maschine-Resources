------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/PatternHelper"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Maschine/Components/CustomEncoderHandler"
require "Scripts/Shared/Helpers/StepHelper"
require "Scripts/Shared/Helpers/EventsHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SelectPageEvents = class( 'SelectPageEvents', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SelectPageEvents:__init(ParentPage, Controller)

    PageMaschine.__init(self, "SelectPageEvents", Controller)

    -- setup screen
    self:setupScreen()

    self.ParentPage = ParentPage

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SELECT }

    -- setup Encoders
    self.Encoders = CustomEncoderHandler()

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function SelectPageEvents:setupScreen()

    -- create screen
    self.Screen = ScreenMaschine(self)

    -- insert left control bar
    self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"SELECT", "EVENTS", "", ""}, "ScreenButton", true)
    self.Screen.ScreenButton[1]:style("SELECT", "HeadPin");
    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"ALL", "NONE", "UP", "DOWN"}, "HeadButton")
    self.Screen.ScreenButton[2]:setSelected(true)

    -- insert InfoBars
    self.Screen.InfoBar = InfoBar(self.Screen.Page.Controller, self.Screen.ScreenLeft)
    self.RightInfoBar   = InfoBar(self.Screen.Page.Controller, self.Screen.ScreenRight, "EventsScreenRight")

    -- Parameters
    self.Screen:addParameterBar(self.Screen.ScreenLeft, false)
    self.Screen:addParameterBar(self.Screen.ScreenRight, false)

    MaschineHelper.resetScreenEncoderSmoother()

end

------------------------------------------------------------------------------------------------------------------------
-- setup Custom Encoders
------------------------------------------------------------------------------------------------------------------------

function SelectPageEvents:setupCustomEncoders()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Song == nil or Group == nil then
        return
    end

    local KeyboardMode = Group and Group:getKeyboardModeEnabledParameter():getValue() or false

    self.Encoders:addEncoder(
        1, "Start", self.Screen.ParameterWidgets[1], 0.05,
        function() return EventsHelper.getSelectionTimeStartDisplayValue() end,
        function(Delta) EventsHelper.onSelectionTimeChanged(Delta, true) end,
        nil
    )

    self.Encoders:addEncoder(
        2, "End", self.Screen.ParameterWidgets[2], 0.05,
        function() return EventsHelper.getSelectionTimeEndDisplayValue() end,
        function(Delta) EventsHelper.onSelectionTimeChanged(Delta, false) end,
        nil
    )

    self.Encoders:addEncoder(3, KeyboardMode and "LOW" or "", self.Screen.ParameterWidgets[3], 0.1,
        KeyboardMode
            and function() return Song:getNoteToString(EventsHelper.NoteMin) end
            or  function() return "" end,
        KeyboardMode
            and function(Delta) EventsHelper.onSelectionNotesPitchChanged(Delta, true) end
            or  function(Delta) return end,
        nil
    )

    self.Encoders:addEncoder(4, KeyboardMode and "HIGH" or "EVENT", self.Screen.ParameterWidgets[4], 0.1,
        KeyboardMode
            and function() return Song:getNoteToString(EventsHelper.NoteMax) end
            or  function() return EventsHelper.getSelectedEventIndexDisplayValue() end,
        KeyboardMode
            and function(Delta) EventsHelper.onSelectionNotesPitchChanged(Delta, false) end
            or  function(Delta) EventsHelper.selectPrevNextEvent(Delta > 0) end,
        nil
    )


    -- set Encoders for changing Event Parameters

    self.Encoders:addEncoder(
        5, "Position", self.Screen.ParameterWidgets[5], 0.05,
        function() return EventsHelper.getSelectedNoteEventsDisplayValue("EventPositions") end,
        function(Delta)
            NI.DATA.EventPatternTools.nudgeEventsInPatternRange(App, Delta > 0 and 1 or -1, self.Controller:getShiftPressed(), true)
            EventsHelper.updateSelectionRange(true)
        end,
        nil
    )

    self.Encoders:addEncoder(
        6, "Length", self.Screen.ParameterWidgets[6], 0.05,
        function() return EventsHelper.getSelectedNoteEventsDisplayValue("EventLengths") end,
        function(Delta) EventsHelper.modifySelectedNoteEvents(Delta > 0 and 1 or -1, 0, 0,
            self.Controller:getShiftPressed()) end,
        nil
    )

    self.Encoders:addEncoder(
        7, "Pitch", self.Screen.ParameterWidgets[7], 0.05,
        function() return EventsHelper.getSelectedNoteEventsDisplayValue("EventPitches") end,
        function(Delta) EventsHelper.modifySelectedNoteEvents(0, Delta > 0 and 1 or -1, 0) end,
        nil
    )

    self.Encoders:addEncoder(
        8, "Velocity", self.Screen.ParameterWidgets[8], 0.05,
        function() return EventsHelper.getSelectedNoteEventsDisplayValue("EventVelocities") end,
        function(Delta) EventsHelper.modifySelectedNoteEvents(0, 0, Delta) end,
        nil
    )

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageEvents:updateScreens(ForceUpdate)

    local StateCache = App:getStateCache()

    -- Pin Button
    self.Screen.ScreenButton[1]:setSelected(self.ParentPage.IsPinned)

    -- Right Info Bar
    self:updateRightInfoBar()

    ForceUpdate = ForceUpdate or PadModeHelper.isKeyboardModeChanged()
    if ForceUpdate then
        self:setupCustomEncoders()
    end

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageEvents:updatePadLEDs()

    EventsHelper.updatePadLEDsEvents(self.Controller.PAD_LEDS, self.Controller:getErasePressed())

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageEvents:updateRightInfoBar()

    local StateCache = App:getStateCache()
    local Sound = NI.DATA.StateHelper.getFocusSound(App)

    if Sound then

        -- Show Focus Sound Name
        self.RightInfoBar.Labels[1]:setText(Sound:getDisplayName())

        -- Show selected note events count
        local NumSelectedEvents = NI.DATA.EventPatternTools.getNumSelectedNoteEventsInPatternRange(App)

        self.RightInfoBar.Labels[2]:setText("SEL. EVENTS: " .. NumSelectedEvents)

    else

        self.RightInfoBar.Labels[1]:setText("")
        self.RightInfoBar.Labels[2]:setText("")

    end

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageEvents:updateParameters(ForceUpdate)

    local State = App:getStateCache()
    local SoundSequence = NI.DATA.StateHelper.getFocusSoundSequence(App)
    local SyncSelectionRange =
        State:isFocusSoundChanged() or
        State:isFocusPatternChanged() or
        App:getWorkspace():getSyncNoteEventsRangeParameter():isChanged()

    EventsHelper.updateSelectionRange(SyncSelectionRange) -- This needs to be called before self.Encoders:update()

    self.Encoders:update()

    EventsHelper.updateLeftRightLEDs(self.Controller)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function SelectPageEvents:onShow(Show)

    if Show then
        EventsHelper.updateSelectionRange(true)
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageEvents:onScreenEncoder(KnobIdx, EncoderInc)

    self.Encoders:onEncoderChanged(KnobIdx, EncoderInc)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageEvents:onPadEvent(PadIndex, Trigger)

    if Trigger then
        EventsHelper.onPadEventEvents(PadIndex, self.Controller:getErasePressed())
        self:updateParameters()
    end

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageEvents:onScreenButton(ButtonIdx, Pressed)

    if Pressed then

        local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
        local Group   = NI.DATA.StateHelper.getFocusGroup(App)

        if ButtonIdx == 1 then
            self.ParentPage:togglePinState()

        elseif ButtonIdx == 2 then
            self.ParentPage:switchToSubPage(SelectPage.QUIET)

        elseif ButtonIdx == 5 then

            if Pattern and Group then
                NI.DATA.EventPatternTools.selectAllEvents(App, Pattern, Group)
                EventsHelper.updateSelectionRange(true)
            end

        elseif ButtonIdx == 6 then

            if Pattern and Group then
                NI.DATA.EventPatternTools.deselectAllEvents(App, Pattern, Group)
                EventsHelper.updateSelectionRange(false)
            end

        elseif ButtonIdx == 7 then
            MaschineHelper.selectPrevNextSound(-1)

        elseif ButtonIdx == 8 then
            MaschineHelper.selectPrevNextSound(1)

        end

    end

    -- needed for button LED setting and updateScreens()
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageEvents:onLeftRightButton(Right, Pressed)

    if Pressed then
        EventsHelper.selectPrevNextEvent(Right)
    end

    self:updateParameters()

end

------------------------------------------------------------------------------------------------------------------------

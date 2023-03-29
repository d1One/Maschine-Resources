------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/EventsPageBase"
require "Scripts/Shared/Components/ScreenMaschineStudio"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
EventsPageStudio = class( 'EventsPageStudio', EventsPageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function EventsPageStudio:__init(Controller)

    EventsPageBase.__init(self, "EventsPageStudio", Controller)

    self.PageLEDs = { NI.HW.LED_TRANSPORT_EVENTS }

    self.SelectMode = false

end


------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function EventsPageStudio:setupScreen()

    -- setup screen
    self.Screen = ScreenMaschineStudio(self)
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"EVENTS", "SELECT", "", "GRID"},
        {"HeadPin", "HeadButton", "HeadButton", "HeadButton"}, false)

    -- right screen
    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"ALL", "NONE", "UP", "DOWN"}, "HeadButton", false)

    EventsPageBase.setupScreen(self, true)

    self.Encoders = CustomEncoderHandler()

    self.ParameterHandler.SectionWidgets[1]:setText("Select")

    ScreenHelper.setWidgetSpan(self.ParameterHandler.SectionWidgets, 1, 4, true)

end

------------------------------------------------------------------------------------------------------------------------
-- setup Custom Encoders
------------------------------------------------------------------------------------------------------------------------

function EventsPageStudio:setupCustomEncoders()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Song == nil or Group == nil then
        return
    end

    if self.SelectMode then

        EventsHelper.addSelectionEncoders(self.Encoders, self.Screen.ParameterWidgets)

    else

        EventsHelper.addEditingEncoders(self.Encoders, self.Screen.ParameterWidgets,
                                        function() return self.Controller:getShiftPressed() end)

    end
end

------------------------------------------------------------------------------------------------------------------------

function EventsPageStudio:onShow(Show)

    if Show then
        self:setupCustomEncoders()
        self.Arranger:setHWCompactVelocityLayout(false)
        EventsHelper.updateSelectionRange(true)

        NHLController:setPadMode(self.SelectMode and NI.HW.PAD_MODE_NONE or NI.HW.PAD_MODE_PAGE_DEFAULT)
    end

    EventsPageBase.onShow(self, Show)
end

------------------------------------------------------------------------------------------------------------------------

function EventsPageStudio:updateScreens(ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local KeyboardMode = Group and Group:getKeyboardModeEnabledParameter():getValue() or false
    local HasPattern = NI.DATA.StateHelper.getFocusEventPattern(App) ~= nil

    self.Controller.CapacitiveNavIcons:Enable(HasPattern, KeyboardMode, nil, not KeyboardMode)
    self.Arranger:setHWCompactVelocityLayout(false)

    if NI.DATA.ParameterCache.isValid(App) and PadModeHelper.isKeyboardModeChanged() then
        self:setupCustomEncoders()
    end

    self.ParameterHandler.SectionWidgets[1]:setText(self.SelectMode and "Select" or "Edit")

    self.Screen.ScreenButton[2]:setSelected(self.SelectMode)

    self.Screen.ScreenButton[3]:setVisible(false)

    local GridOn = GridHelper.getSnapEnabledParameter(GridHelper.STEP):getValue()
    self.Screen.ScreenButton[4]:setSelected(GridOn or false)

    local QuantizeText = self.Controller:getShiftPressed() and "QUANT 50%" or "QUANTIZE"
    self.Screen.ScreenButton[5]:setText(self.SelectMode and "ALL" or QuantizeText)
    self.Screen.ScreenButton[6]:setText(self.SelectMode and "NONE" or "CLEAR ALL")

    self.Screen.ScreenButton[5]:setEnabled(self.SelectMode or NI.DATA.EventPatternTools.hasNoteEditEvents(App))
    self.Screen.ScreenButton[6]:setEnabled(self.SelectMode or ActionHelper.hasEvents())

    self.Screen.ScreenButton[7]:setVisible(self.SelectMode)
    self.Screen.ScreenButton[8]:setVisible(self.SelectMode)


    -- call base
    EventsPageBase.updateScreens(self, ForceUpdate)
end

------------------------------------------------------------------------------------------------------------------------

function EventsPageStudio:onScreenButton(Idx, Pressed)

    if Pressed then

        local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
        local Group   = NI.DATA.StateHelper.getFocusGroup(App)

        if Idx == 2 then
            self.SelectMode = not self.SelectMode
            self:setupCustomEncoders()
            NHLController:setPadMode(self.SelectMode and NI.HW.PAD_MODE_NONE or NI.HW.PAD_MODE_PAGE_DEFAULT)

        elseif Idx == 4 then

            GridHelper.toggleSnapEnabled(GridHelper.STEP)

        elseif Pattern and Group then
            if self.SelectMode then
                if Idx == 5 then
                    NI.DATA.EventPatternTools.selectAllEvents(App, Pattern, Group)
                    EventsHelper.updateSelectionRange(true)
                elseif Idx == 6 then
                    NI.DATA.EventPatternTools.deselectAllEvents(App, Pattern, Group)
                    EventsHelper.updateSelectionRange(false)
                elseif Idx == 7 or Idx == 8 then
                    MaschineHelper.selectPrevNextSound(Idx == 7 and -1 or 1)
                end
            else
                if Idx == 5 and ActionHelper.hasEvents() then
                    NI.DATA.EventPatternTools.quantizeNoteEvents(App, self.Controller:getShiftPressed())
                elseif Idx == 6 and ActionHelper.hasEvents() then

                    if PadModeHelper.getKeyboardMode() then
                        NI.DATA.EventPatternTools.removeAllEventsFromFocusedSound(App)
                    else
                        NI.DATA.EventPatternTools.removeAllEventsFromGroup(App)
                    end
                end
            end
        end

    end

    -- call base class for update
    EventsPageBase.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageStudio:updateParameters(ForceUpdate)

    local State = App:getStateCache()
    local SoundSequence = NI.DATA.StateHelper.getFocusSoundSequence(App)
    local SyncSelectionRange =
        State:isFocusSoundChanged() or
        State:isFocusPatternChanged() or
        App:getWorkspace():getSyncNoteEventsRangeParameter():isChanged()

    EventsHelper.updateSelectionRange(SyncSelectionRange) -- Needs to be called before self.Encoders:update() or updateParameters()

    self.Encoders:update()

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageStudio:onScreenEncoder(Idx, Inc)

    if NI.DATA.StateHelper.getFocusEventPattern(App) == nil then
        return
    end

    if Idx >= 1 and Idx <= 4 then -- The custom Events Encoders
        self.Encoders:onEncoderChanged(Idx, Inc)
    else
        EventsPageBase.onZoomScrollEncoder(self, Idx, Inc)
    end
end

------------------------------------------------------------------------------------------------------------------------

function EventsPageStudio:onPadEvent(PadIndex, Trigger, PadValue)

    if self.SelectMode then
        if Trigger then
            EventsHelper.onPadEventEvents(PadIndex, self.Controller:getErasePressed())
        end
    else
        EventsPageBase.onPadEvent(self, PadIndex, Trigger, PadValue)
    end

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageStudio:updatePadLEDs()

    if self.SelectMode then
        EventsHelper.updatePadLEDsEvents(self.Controller.PAD_LEDS, self.Controller:getErasePressed())
    else
        EventsPageBase.updatePadLEDs(self)
    end

end

------------------------------------------------------------------------------------------------------------------------

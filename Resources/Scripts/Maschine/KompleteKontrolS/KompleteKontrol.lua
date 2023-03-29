------------------------------------------------------------------------------------------------------------------------
-- KompleteKontrol Controller Class that draws to the hardware display.
------------------------------------------------------------------------------------------------------------------------

HW = NI.HW
HELPERS = NI.HW
SCREEN = NI.HW
OSO = NI.HW.OnScreenOverlay

require "Scripts/Shared/Helpers/MiscHelper"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Components/Timer"
require "Scripts/Shared/Components/DisplayStack"

require "Scripts/Maschine/KompleteKontrolS/Pages/BrowsePage/BrowsePage"
require "Scripts/Maschine/KompleteKontrolS/Pages/ParameterPageRoot"

DISPLAY_MODE_PAGECOUNT = 1                          -- display page count info in the Page field
DISPLAY_MODE_KEYSWITCH = 2
DISPLAY_MODE_GROUPSOUND = 3                         -- display group and sound info in the Page field
DISPLAY_MODE_GROUPSOUND_NAV = 4
DISPLAY_MODE_AUTOWRITE = 5                          -- display autowrite info in the Page field
DISPLAY_MODE_VOLUME = 6                             -- display volume info in the Page field
DISPLAY_MODE_OCTAVE = 7
DISPLAY_MODE_TIMEOUT = HW.ENCODER_TOUCH_DELAY_TIMER

INVALID_NOTE = 128
INVALID_OCTAVE = 128

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
KompleteKontrol = class( 'KompleteKontrol' )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:__init()

    -- Page Display State
    self.DisplayStack = DisplayStack(DISPLAY_MODE_PAGECOUNT)
    self.DisplayStack:addMode(DISPLAY_MODE_KEYSWITCH, 1)
    self.DisplayStack:addMode(DISPLAY_MODE_GROUPSOUND, 2)
    self.DisplayStack:addMode(DISPLAY_MODE_GROUPSOUND_NAV, 2)
    self.DisplayStack:addMode(DISPLAY_MODE_AUTOWRITE, 3)
    self.DisplayStack:addMode(DISPLAY_MODE_VOLUME, 3)
    self.DisplayStack:addMode(DISPLAY_MODE_OCTAVE, 3)
    local func = function() self:onDisplayTimer() end
    self.DisplayStack:setRemoveCallback(func)
    self.KeySwitchNote = INVALID_NOTE
    self.KeySwitchName = ""

    -- table with pressed switches
    self.SwitchPressed = {}

    -- Event Handler for Switches
    self.SwitchHandler = {}

    self.SwitchHandler[HW.BUTTON_PERFORM_SHIFT]          = function(Pressed) self:onShiftButton(Pressed) end
    self.SwitchHandler[HW.BUTTON_PERFORM_SCALE]          = function(Pressed) self:onScaleButton(Pressed) end
    self.SwitchHandler[HW.BUTTON_PERFORM_ARPEGGIATOR]    = function(Pressed) self:onArpButton(Pressed) end
    self.SwitchHandler[HW.BUTTON_DISPLAY_ARROW_LEFT]     = function(Pressed) self:onPageButton(Pressed, false) end
    self.SwitchHandler[HW.BUTTON_DISPLAY_ARROW_RIGHT]    = function(Pressed) self:onPageButton(Pressed, true) end
    self.SwitchHandler[HW.BUTTON_NAVIGATE_ARROW_UP]      = function(Pressed) self:onNavUpDownButton(Pressed, true) end
    self.SwitchHandler[HW.BUTTON_NAVIGATE_ARROW_DOWN]    = function(Pressed) self:onNavUpDownButton(Pressed, false) end
    self.SwitchHandler[HW.BUTTON_NAVIGATE_ARROW_RIGHT]   = function(Pressed) self:onNavLeftRightButton(Pressed, true) end
    self.SwitchHandler[HW.BUTTON_NAVIGATE_ARROW_LEFT]    = function(Pressed) self:onNavLeftRightButton(Pressed, false) end
    self.SwitchHandler[HW.BUTTON_NAVIGATE_BACK]          = function(Pressed) self:onNavBackButton(Pressed) end
    self.SwitchHandler[HW.BUTTON_NAVIGATE_ENTER]         = function(Pressed) self:onNavEnterButton(Pressed) end
    self.SwitchHandler[HW.BUTTON_NAVIGATE_BROWSE]        = function(Pressed) self:onNavBrowseButton(Pressed) end
    self.SwitchHandler[HW.BUTTON_NAVIGATE_INSTANCE]      = function(Pressed) self:onNavInstanceButton(Pressed) end
    self.SwitchHandler[HW.BUTTON_NAVIGATE_PRESET_UP]     = function(Pressed) self:onNavPresetButton(Pressed, true) end
    self.SwitchHandler[HW.BUTTON_NAVIGATE_PRESET_DOWN]   = function(Pressed) self:onNavPresetButton(Pressed, false) end
    self.SwitchHandler[HW.BUTTON_NAVIGATE_ENCODER_PUSH]  = function(Pressed) self:onWheelButton(Pressed) end
    self.SwitchHandler[HW.BUTTON_NAVIGATE_ENCODER_CAP]   = function(Pressed) self:onWheelTouched(Pressed) end
    self.SwitchHandler[HW.BUTTON_TRANSPOSE_OCTAVE_MINUS] = function(Pressed) self:onOctaveButton(Pressed, false) end
    self.SwitchHandler[HW.BUTTON_TRANSPOSE_OCTAVE_PLUS]  = function(Pressed) self:onOctaveButton(Pressed, true) end

    self.SwitchHandler[HW.BUTTON_TRANSPORT_RECORD] = function(Pressed) self:onRecButton(Pressed) end

    self.SwitchHandler[HW.BUTTON_CAP_1] = function(Touched) self:onEncoderTouched(1, Touched) end
    self.SwitchHandler[HW.BUTTON_CAP_2] = function(Touched) self:onEncoderTouched(2, Touched) end
    self.SwitchHandler[HW.BUTTON_CAP_3] = function(Touched) self:onEncoderTouched(3, Touched) end
    self.SwitchHandler[HW.BUTTON_CAP_4] = function(Touched) self:onEncoderTouched(4, Touched) end
    self.SwitchHandler[HW.BUTTON_CAP_5] = function(Touched) self:onEncoderTouched(5, Touched) end
    self.SwitchHandler[HW.BUTTON_CAP_6] = function(Touched) self:onEncoderTouched(6, Touched) end
    self.SwitchHandler[HW.BUTTON_CAP_7] = function(Touched) self:onEncoderTouched(7, Touched) end
    self.SwitchHandler[HW.BUTTON_CAP_8] = function(Touched) self:onEncoderTouched(8, Touched) end

    -- Initialize Encoder Mode
    NHLController:setEncoderMode(NI.HW.ENC_MODE_CONTROL)

    -- Timer
    self.Timer = Timer()

    -- Initialize the display pages
    self.Pages = {}
    self:addPage(HW.PAGE_PARAMETER_OWNER, ParameterPageRoot(self))
    self:addPage(HW.PAGE_BROWSE, BrowsePage(self))

    self.BOTTOM_PAGE = HW.PAGE_PARAMETER_OWNER

    -- if stack was already initialized don't push bottom page
    if not NHLController:isPageInStack(self.BOTTOM_PAGE) then
        self:pushPage(self.Pages[self.BOTTOM_PAGE])
    end

end

------------------------------------------------------------------------------------------------------------------------
-- C++ callbacks
------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onStateFlagsChanged()

    if App:isBusy() then
        return
    end

    -- update page mode, if needed
    local OSOVisibleParameter = App:getOnScreenOverlay():getVisibleParameter()

    if OSOVisibleParameter:isChanged() then
        if OSOVisibleParameter:getValue() then
            HELPERS.acquireEncoderControl(App)
        else
            HELPERS.releaseEncoderControl(App)
        end
    end

    if OSOVisibleParameter:isChanged() and self:isShiftPressed() and self:isWheelTouched() then
        if OSOVisibleParameter:getValue() then
            self.DisplayStack:scheduleRemove(DISPLAY_MODE_VOLUME, DISPLAY_MODE_TIMEOUT)
        else
            self.DisplayStack:insert(DISPLAY_MODE_VOLUME)
        end
    end

    local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)
    local PluginHost = FocusSlot and NI.DATA.StateHelper.getFocusSlot(App):getPluginHost()

    if not PluginHost or PluginHost:isPluginChanged() or not PluginHost:isPluginLoaded() then
        self.DisplayStack:remove(DISPLAY_MODE_KEYSWITCH)
    end

    if self:getTopPage() and self:getTopPage().onStateFlagsChanged then
        self:getTopPage():onStateFlagsChanged()
    end

    self:updateScreen()

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onDB3ModelChanged(Model)

    self:updateScreen()

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onControllerTimer()

    self:updateKeySwitchDisplay()

    self.Timer:onControllerTimer()
    self.DisplayStack:onTimer()

    if self:getTopPage() and self:getTopPage().onControllerTimer then
        self:getTopPage():onControllerTimer()
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onDisplayTimer()

    if self:getTopPage() and self:getTopPage().updateScreen then
        self:getTopPage():updateScreen()
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onSwitchEvent(SwitchID, Pressed)

    if App:isBusy() then
        return
    end

    -- save pressed state
    self.SwitchPressed[SwitchID] = Pressed

    local Handler = self.SwitchHandler[SwitchID]
    if Handler then
        Handler(Pressed)
    end

    self:updateScreen()

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onEncoderEvent(EncoderID, Value)

    if App:isBusy() then
        return
    end

    if self:getTopPage() and self:getTopPage().onEncoderEvent then
        self:getTopPage():onEncoderEvent(EncoderID, Value)
    end

    self:updateScreen()

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onEncoderTouched(EncoderID, Touched)

    if App:isBusy() then
        return
    end

    if self:getTopPage() and self:getTopPage().onEncoderTouched then
        self:getTopPage():onEncoderTouched(EncoderID, Touched)
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:isEncoderTouched(EncoderID)

    return self.SwitchPressed[HW.BUTTON_CAP_1 + EncoderID - 1] or false

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onWheelEvent(WheelID, Value)

    if App:isBusy() then
        return
    end

    if self:getTopPage() and self:getTopPage().onWheelEvent then
        self:getTopPage():onWheelEvent(Value)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Switch events dispatched by class KompleteKontrol itself
------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onRecButton(Pressed)

    if Pressed then

        if MaschineHelper.isRecording() then
            NI.DATA.TransportAccess.stopEventRecording(App)
        else
            NI.DATA.TransportAccess.startEventRecording(App, false, false)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onWheelButton(Pushed)

    if App:isBusy() then
        return
    end

    if self:getTopPage() and self:getTopPage().onWheelButton then
        self:getTopPage():onWheelButton(Pushed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onWheelTouched(Touched)

    if App:isBusy() then
        return
    end

    if self:getTopPage() and self:getTopPage().onWheelTouched then
        self:getTopPage():onWheelTouched(Touched)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onNavEnterButton(Pressed)

    if self:getTopPage() and self:getTopPage().onNavEnterButton then
        self:getTopPage():onNavEnterButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onShiftButton(Pressed)

    if Pressed then
        self.DisplayStack:insert(DISPLAY_MODE_GROUPSOUND)
    else
        self.DisplayStack:remove(DISPLAY_MODE_GROUPSOUND)
    end

    if self:getTopPage() and self:getTopPage().onShiftButton then
        self:getTopPage():onShiftButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onNavPresetButton(Pressed, Up)

    self.DisplayStack:removeIfScheduled(DISPLAY_MODE_VOLUME)
    self.DisplayStack:removeIfScheduled(DISPLAY_MODE_OCTAVE)
    self.DisplayStack:removeIfScheduled(DISPLAY_MODE_AUTOWRITE)

    if self:getTopPage() and self:getTopPage().onNavPresetButton then
        self:getTopPage():onNavPresetButton(Pressed, Up)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onNavLeftRightButton(Pressed, Right)

    self.DisplayStack:removeIfScheduled(DISPLAY_MODE_VOLUME)
    self.DisplayStack:removeIfScheduled(DISPLAY_MODE_OCTAVE)
    self.DisplayStack:removeIfScheduled(DISPLAY_MODE_AUTOWRITE)

    if self:getTopPage() and self:getTopPage().onNavLeftRightButton then
        self:getTopPage():onNavLeftRightButton(Pressed, Right)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onOctaveButton(Pressed, Plus)

    if Pressed and self:isShiftPressed() then

        if Plus then
            self:toggleEditModePage(HW.PAGE_TOUCHSTRIP_MODULATION)
        else
            self:toggleEditModePage(HW.PAGE_TOUCHSTRIP_PITCH)
        end

    end

    if Pressed and not self:isShiftPressed() then

        local Octave = HELPERS.getCurrentOctave(App)

        if Octave ~= INVALID_OCTAVE then
            self.Octave = Octave
            self.DisplayStack:insert(DISPLAY_MODE_OCTAVE)
        end

    elseif not Pressed then

        self.DisplayStack:scheduleRemove(DISPLAY_MODE_OCTAVE, DISPLAY_MODE_TIMEOUT)

    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onNavBrowseButton(Pressed)

    if Pressed then

        local OnScreenOverlay = App:getOnScreenOverlay()
        local BrowseMode = App.getBrowseMode()

        if BrowseMode == NI.UTILS.BROWSE_MODE_HW then

            self:toggleBrowsePage()

            if OnScreenOverlay:isBrowserVisible() then
                OnScreenOverlay:onBrowse(NHLController:getControllerModel()) -- hide OSO Browser
            end

            if OnScreenOverlay:isInstancesVisible() then
                OnScreenOverlay:onInstance(NHLController:getControllerModel()) -- hide OSO Instance Manager
            end

        elseif BrowseMode == NI.UTILS.BROWSE_MODE_OSO then

            OnScreenOverlay:onBrowse(NHLController:getControllerModel())

            if self.Pages[self:getTopPage()] == HW.PAGE_BROWSE then
                self:toggleBrowsePage()
            end

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onScaleButton(Pressed)

    if not NI.APP.isStandalone() and not NI.APP.FEATURE.MAS_SMART_PLAY then
        return
    end

    if Pressed then

        -- SHIFT enables Perform/HW edit modes
        if self:isShiftPressed() then
            self:toggleEditModePage(HW.PAGE_SCALE)
        else
            self:toggleScaleActive()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onArpButton(Pressed)

    if not NI.APP.isStandalone() and not NI.APP.FEATURE.MAS_SMART_PLAY then
        return
    end

    if Pressed then

        -- SHIFT enables Perform/HW edit modes
        if self:isShiftPressed() then
            self:toggleEditModePage(HW.PAGE_ARP)
        else
            self:toggleArpActive()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onNavBackButton(Pressed)

    -- in case we are not on the bottom page just pop otherwise call proper handler
    if not self:isBottomPage() then
        self:popToBottomPage()
    elseif self:getTopPage() and self:getTopPage().onNavBackButton then
        self:getTopPage():onNavBackButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onNavUpDownButton(Pressed, Up)

    self.DisplayStack:removeIfScheduled(DISPLAY_MODE_VOLUME)
    self.DisplayStack:removeIfScheduled(DISPLAY_MODE_OCTAVE)
    self.DisplayStack:removeIfScheduled(DISPLAY_MODE_AUTOWRITE)

    if Pressed then
        self.DisplayStack:insert(DISPLAY_MODE_GROUPSOUND_NAV)
    else
        self.DisplayStack:scheduleRemove(DISPLAY_MODE_GROUPSOUND_NAV, DISPLAY_MODE_TIMEOUT)
    end

    if self:getTopPage() and self:getTopPage().onNavUpDownButton then
        self:getTopPage():onNavUpDownButton(Pressed, Up)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onNavInstanceButton(Pressed)

    if self.Pages[self:getTopPage()] == HW.PAGE_BROWSE then
        self:toggleBrowsePage()
    end

    if self:getTopPage() and self:getTopPage().onNavInstanceButton then
        self:getTopPage():onNavInstanceButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:onPageButton(Pressed, Next)

    if self:getTopPage() and self:getTopPage().onPageButton then
        self:getTopPage():onPageButton(Pressed, Next)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Page manager
------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:addPage(PageId, Page)

    -- self.Pages is a bidirectional map, from PageId to a reference to a Page object and back.

    self.Pages[PageId] = Page
    self.Pages[Page] = PageId

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:pushPage(Page)

    -- pushes an already added page to the top of the page stack

    local TopPage = self:getTopPage()
    if TopPage and TopPage.onDeactivate then
        TopPage:onDeactivate()
    end

    local PageId = self.Pages[Page]

    if PageId then
        NHLController:pushPage(PageId)

        if Page.onActivate then
            Page:onActivate()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:popPage()

    -- removes a page from the page stack

    local TopPage = self:getTopPage()
    if TopPage and TopPage.onDeactivate then
        TopPage:onDeactivate()
    end

    NHLController:popPage()

    TopPage = self:getTopPage()
    if TopPage and TopPage.onActivate then
        TopPage:onActivate()
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:popToBottomPage()

    local TopPage = self:getTopPage()
    if TopPage and TopPage.onDeactivate then
        TopPage:onDeactivate()
    end

    NHLController:popToBottomPage()

    TopPage = self:getTopPage()
    if TopPage and TopPage.onActivate then
        TopPage:onActivate()
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:isBottomPage()

    return NHLController:getTopPage() == self.BOTTOM_PAGE

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:getTopPage()

    return self.Pages[NHLController:getTopPage()]

end

------------------------------------------------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:isShiftPressed()

    return self.SwitchPressed[HW.BUTTON_PERFORM_SHIFT] or false

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:isWheelTouched()

    return self.SwitchPressed[HW.BUTTON_NAVIGATE_ENCODER_CAP] or false

end

------------------------------------------------------------------------------------------------------------------------
-- DisplayStack
------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:getDisplayMode()

    return self.DisplayStack:getCurrent()

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:updateKeySwitchDisplay()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)

    if Sound then

        local KeySwitchNote = Sound:getKeySwitchNote()

        if KeySwitchNote ~= self.KeySwitchNote then

            local IsValidNote = KeySwitchNote ~= INVALID_NOTE
            local KeySwitchName = Sound:getNoteName(KeySwitchNote)
            local HasKeySwitchName = KeySwitchName ~= "" and KeySwitchName ~= nil

            if HasKeySwitchName and IsValidNote then
                self.KeySwitchNote = KeySwitchNote
                self.KeySwitchName = KeySwitchName
                self.DisplayStack:insert(DISPLAY_MODE_KEYSWITCH)
                self:getTopPage():updateScreen()
            else
                self.DisplayStack:scheduleRemove(DISPLAY_MODE_KEYSWITCH, DISPLAY_MODE_TIMEOUT)
                self.KeySwitchNote = INVALID_NOTE
            end
        end

    else

        self.DisplayStack:remove(DISPLAY_MODE_KEYSWITCH)

    end

end

------------------------------------------------------------------------------------------------------------------------
-- Methods
------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:updateScreen()

    -- draw the active page
    if self:getTopPage() and self:getTopPage().updateScreen then
        self:getTopPage():updateScreen()
    end

    if self:getTopPage() and self:getTopPage().updateLEDs then
        self:getTopPage():updateLEDs()
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:toggleEditModePage(Page)

    local PageParameter = App:getWorkspace():getKKPerformPageParameter()
    local BottomPage = self:isBottomPage()

    if BottomPage then

        if  PageParameter:getValue() == Page then
            NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, PageParameter, HW.PAGE_PLUGIN)
        else
            NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, PageParameter, Page)
        end

    else

        -- in case we are on an unraleted page (e.g. BrowsePage) then do not toggle perform pages
        NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, PageParameter, Page)

    end

    if not BottomPage then
        self:popToBottomPage()
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:toggleBrowsePage()

    if  self.Pages[self:getTopPage()] == HW.PAGE_BROWSE then
        self:popPage()
    else
        self:pushPage(self.Pages[HW.PAGE_BROWSE])
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:toggleArpActive()

    local Param = NI.HW.getArpeggiatorActiveParameter(App)

    if Param then
        NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Param, not Param:getValue())
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:toggleScaleActive()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group then
        local Param = Group:getKeyboardScaleEngineActiveParameter()
        NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Param, not Param:getValue())
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:setDisplayMode(DisplayMode)

    self.DisplayMode = DisplayMode
    self.Timer:resetTimer(self)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol:toggleAutoWrite()

    NI.DATA.WORKSPACE.toggleAutoWriteEnabledKompleteKontrol(App)

end

------------------------------------------------------------------------------------------------------------------------

-- The Instance
ControllerScriptInterface = KompleteKontrol()

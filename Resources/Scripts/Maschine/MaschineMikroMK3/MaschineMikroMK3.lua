require "Scripts/Maschine/PageManager"
require "Scripts/Shared/Helpers/BrowseHelper"
require "Scripts/Maschine/MaschineMK3/TouchstripControllerMK3"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/StepHelper"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MaschineMikroMK3 = class( 'MaschineMikroMK3' )

------------------------------------------------------------------------------------------------------------------------

MaschineMikroMK3.PAD_LEDS =
{
    NI.HW.LED_PAD_1, NI.HW.LED_PAD_2, NI.HW.LED_PAD_3, NI.HW.LED_PAD_4,
    NI.HW.LED_PAD_5, NI.HW.LED_PAD_6, NI.HW.LED_PAD_7, NI.HW.LED_PAD_8,
    NI.HW.LED_PAD_9, NI.HW.LED_PAD_10, NI.HW.LED_PAD_11, NI.HW.LED_PAD_12,
    NI.HW.LED_PAD_13, NI.HW.LED_PAD_14, NI.HW.LED_PAD_15, NI.HW.LED_PAD_16
}

MaschineMikroMK3.GROUP_LEDS =
{
    NI.HW.LED_PAD_13, NI.HW.LED_PAD_14, NI.HW.LED_PAD_15, NI.HW.LED_PAD_16,
    NI.HW.LED_PAD_9, NI.HW.LED_PAD_10, NI.HW.LED_PAD_11, NI.HW.LED_PAD_12
}

------------------------------------------------------------------------------------------------------------------------

MaschineMikroMK3.PADS =
{
    NI.HW.PAD_1,
    NI.HW.PAD_2,
    NI.HW.PAD_3,
    NI.HW.PAD_4,
    NI.HW.PAD_5,
    NI.HW.PAD_6,
    NI.HW.PAD_7,
    NI.HW.PAD_8,
    NI.HW.PAD_9,
    NI.HW.PAD_10,
    NI.HW.PAD_11,
    NI.HW.PAD_12,
    NI.HW.PAD_13,
    NI.HW.PAD_14,
    NI.HW.PAD_15,
    NI.HW.PAD_16
}

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:__init()

    BrowseHelper.forceCacheRefresh()

    self.SwitchPressed = {}

    self.PageManager = PageManager(self)
    self.TouchstripController = TouchstripControllerMK3()
    self:createPages()

    self.ActivePage = nil
    self.CachedPadStates = {}
    self.QuickEdit = QuickEditMikroMK3(self)

    NI.GUI.enableAbbreviationModeUseDictionary()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:createPages()

    local Folder = "Scripts/Maschine/MaschineMikroMK3/Pages/"

    self.PageManager:register(NI.HW.PAGE_ARPEGGIATOR, Folder .. "ArpeggiatorPageMikroMK3", "ArpeggiatorPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_PAD, Folder .. "PadModePageMikroMK3", "PadModePageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_CONTROL, Folder .. "PluginPageMikroMK3", "PluginPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_KEYBOARD, Folder .. "KeyboardModePageMikroMK3", "KeyboardModePageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_CHORD, Folder .. "ChordModePageMikroMK3", "ChordModePageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_BROWSE, Folder .. "BrowserPageMikroMK3", "BrowserPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_FILE, Folder .. "FilePageMikroMK3", "FilePageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_BUSY, Folder .. "BusyPageMikroMK3", "BusyPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_FIXED_VELOCITY, Folder .. "FixedVelPageMikroMK3", "FixedVelPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_GRID, Folder .. "GridPageMikroMK3", "GridPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_REPEAT, Folder .. "NoteRepeatPageMikroMK3", "NoteRepeatPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_GROUP, Folder .. "GroupPageMikroMK3", "GroupPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_PATTERN, Folder .. "PatternPageMikroMK3",   "PatternPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_QUICK_EDIT_VOLUME, Folder .. "QuickEditPageMikroMK3", "QuickEditPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_QUICK_EDIT_SWING, Folder .. "QuickEditPageMikroMK3", "QuickEditPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_QUICK_EDIT_TEMPO, Folder .. "QuickEditPageMikroMK3", "QuickEditPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_QUICK_EDIT_GROUP, Folder .. "QuickEditGroupPageMikroMK3", "QuickEditGroupPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_SAMPLING, Folder .. "SamplingPageMikroMK3", "SamplingPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_SCENE, Folder .. "ScenePageMikroMK3", "ScenePageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_SECTION, Folder .. "SectionPageMikroMK3", "SectionPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_SELECT, Folder .. "SelectPageMikroMK3", "SelectPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_STEP, Folder .. "StepPageMikroMK3", "StepPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_NAVIGATE, Folder .. "NavigatePageMikroMK3", "NavigatePageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_VARIATION, Folder .. "VariationPageMikroMK3", "VariationPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_TAP_TEMPO, Folder .. "TapTempoPageMikroMK3", "TapTempoPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_SOLO, Folder .. "SoloPageMikroMK3", "SoloPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_MUTE, Folder .. "MutePageMikroMK3", "MutePageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_SOLO_GROUP, Folder .. "SoloGroupPageMikroMK3", "SoloGroupPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_MUTE_GROUP, Folder .. "MuteGroupPageMikroMK3", "MuteGroupPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_DUPLICATE, Folder .. "DuplicateSoundPageMikroMK3", "DuplicateSoundPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_DUPLICATE_GROUP, Folder .. "DuplicateGroupPageMikroMK3", "DuplicateGroupPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_DUPLICATE_SCENE, Folder .. "DuplicateScenePageMikroMK3", "DuplicateScenePageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_DUPLICATE_SECTION, Folder .. "DuplicateSectionPageMikroMK3", "DuplicateSectionPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_DUPLICATE_PATTERN, Folder .. "DuplicatePatternPageMikroMK3", "DuplicatePatternPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_EVENTS, Folder .. "EventsPageMikroMK3", "EventsPageMikroMK3", true)
    self.PageManager:register(NI.HW.PAGE_MACRO, Folder .. "MacroPageMikroMK3", "MacroPageMikroMK3", true)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:getPage(PageID)

    return self.PageManager:getPage(PageID)

end

------------------------------------------------------------------------------------------------------------------------

local function isQuickEditPage(PageID)

    return PageID == NI.HW.PAGE_QUICK_EDIT_VOLUME
        or PageID == NI.HW.PAGE_QUICK_EDIT_SWING
        or PageID == NI.HW.PAGE_QUICK_EDIT_TEMPO
        or PageID == NI.HW.PAGE_QUICK_EDIT_GROUP

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:updatePageSync(ForceUpdate)

    local TopPageID = NHLController:getPageStack():getTopPage()
    if ForceUpdate or NHLController:getPageStack():isPageStackChanged() or self.ActivePage == nil then

        local CurrentPageID = self.PageManager:getPageID(self.ActivePage)

        if ForceUpdate or TopPageID ~= CurrentPageID then

            if self.ActivePage then
                self.ActivePage:onShow(false)
            end

            self.ActivePage = self.PageManager:getPage(TopPageID)

            if self.ActivePage then
                self.ActivePage:onShow(true)
            end

            if isQuickEditPage(CurrentPageID) and not isQuickEditPage(TopPageID) then
                self.QuickEdit:reset()
            end

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:onStateFlagsChanged()

    -- update focus sound index
    PadModeHelper.FocusedSoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App)+1

    -- update active page
    self:updatePageSync()

    if self.ActivePage then
        self.ActivePage:onStateFlagsChanged()
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:onDB3ModelChanged(Model)

    BrowseHelper.updateCachedData(Model)

    if self.ActivePage and self.ActivePage.onDB3ModelChanged then
        self.ActivePage:onDB3ModelChanged(Model)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:onControllerTimer()

    if self.ActivePage and self.ActivePage.onControllerTimer then
        self.ActivePage:onControllerTimer()
    end

    if PadModeHelper.isStepModeEnabled() then

        StepHelper.FollowModeOn = NHLController:getContext():getStepPageFollowParameter():getValue()

        StepHelper.updateFollowOffset()

        if StepHelper.isPadHoldTimerActive() then

            -- Allows users to select a pad without toggling its state on and off
            StepHelper.incrementPadHoldTime()

        end
    end

    self:updateLEDs()

end

------------------------------------------------------------------------------------------------------------------------

local function shouldPadModeHelperUpdateLEDs()

    local padMode = NHLController:getPadMode()

    return padMode ~= NI.HW.PAD_MODE_NONE
        and padMode ~= NI.HW.PAD_MODE_SECTION
        and padMode ~= NI.HW.PAD_MODE_SCENE

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:updateLEDs()

    if self.ActivePage and self.ActivePage.updatePadLEDs then

        self.ActivePage:updatePadLEDs()

    end

    if shouldPadModeHelperUpdateLEDs() then

        PadModeHelper.updatePadLEDs(self)

    end

    self.TouchstripController:updateLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:onTouchEvent(TouchID, TouchType, Value)

    self.TouchstripController:onTouchEvent(TouchID, TouchType, Value)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:onSwitchEvent(SwitchId, Pressed)

    self.SwitchPressed[SwitchId] = Pressed

    if SwitchId == NI.HW.BUTTON_SHIFT then
        LEDHelper.setLEDState(NI.HW.LED_SHIFT, Pressed and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
    end

    if self.ActivePage and self.ActivePage.onSwitchEvent then
        self.ActivePage:onSwitchEvent(SwitchId, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:onPadEvent(PadIndex, Trigger, PadValue)

    local ShiftErasePressed = self:isShiftPressed() and self:isErasePressed()

    -- only execute onPadEventShift, if no other button is pressed along shift (except erase)
    if Trigger and (ShiftErasePressed or self:isOnlyShiftPressed())
               and MaschineHelper.onPadEventShift(PadIndex, Trigger, self:isErasePressed()) then

        return

    elseif self.ActivePage and self.ActivePage.onPadEvent then

        self.ActivePage:onPadEvent(PadIndex, Trigger, PadValue)

    elseif PadModeHelper.isStepModeEnabled() and not self:isShiftPressed() then

        StepHelper.onPadEvent(PadIndex, Trigger, PadValue)

    else

        PadModeHelper.onPadEvent(PadIndex, Trigger, PadValue)

    end

    if PadModeHelper.isChordModeChordSet() then

        self.CachedPadStates[PadIndex] = Trigger

    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:onWheelEvent(EncoderID, Value)

    if self.ActivePage and self.ActivePage.onWheelEvent then
        self.ActivePage:onWheelEvent(Value)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:isButtonPressed(Button)

    return Button and self.SwitchPressed[Button] == true

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:isShiftPressed()

    return self.SwitchPressed[NI.HW.BUTTON_SHIFT] == true

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:isOnlyShiftPressed()

    if not self:isShiftPressed() then
        return false
    end

    for Switch, IsPressed in pairs(self.SwitchPressed) do

        if Switch ~= NI.HW.BUTTON_SHIFT and IsPressed then
            return false
        end

    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:isErasePressed()

    return self.SwitchPressed[NI.HW.BUTTON_TRANSPORT_ERASE] == true

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:printPageStack()

    print("-----top------")
    local NumPages = NHLController:getPageStack():getNumPages()
    for i = NumPages - 1, 0, -1  do
        local id = NHLController:getPageStack():getPageAt(i)
        local Page = self.PageManager:getPage(id)
        print (tostring(Page and Page.Name or "no registered page with id")..": "..tostring(id))
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:resetCachedPadStates()

    for PadIndex, _ in ipairs(self.PADS) do
        self.CachedPadStates[PadIndex] = false;
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:getAndResetCachedPadState(Index)

    local State = self.CachedPadStates[Index] == true
    self.CachedPadStates[Index] = false
    return State

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:openBusyDialog()

    NHLController:getPageStack():pushPage(NI.HW.PAGE_BUSY)
    self:updatePageSync(true)       -- The timer can be disabled while busy loading - make sure the page is displayed
    NHLController:updateLEDs(true)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:closeBusyDialog()

    if  NHLController:getPageStack():getTopPage() == NI.HW.PAGE_BUSY or
        NHLController:getPageStack():getTopPage() == NI.HW.PAGE_MODAL_DIALOG
    then
        NHLController:getPageStack():popPage()
        NHLController:updateLEDs(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:openDialogAudioExport()

    self:openBusyDialog()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:openDialogMessage()

    self:openBusyDialog()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:openDialogTextInput()

    self:openBusyDialog()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroMK3:openDialogUSBStorageMode()

    self:openBusyDialog()

end

------------------------------------------------------------------------------------------------------------------------

ControllerScriptInterface = MaschineMikroMK3()

------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- Maschine Mikro
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/HardwareControllerBase"
require "Scripts/Shared/Helpers/EventsHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Components/QuickEditBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MaschineMikroController = class( 'MaschineMikroController', HardwareControllerBase )

------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------

MaschineMikroController.SCREEN_BUTTONS =
{
    NI.HW.BUTTON_F1,
    NI.HW.BUTTON_F2,
    NI.HW.BUTTON_F3
}

MaschineMikroController.SCREEN_BUTTON_LEDS =
{
    NI.HW.LED_F1,
    NI.HW.LED_F2,
    NI.HW.LED_F3
}

MaschineMikroController.SCREEN_ENCODERS = {}

MaschineMikroController.GROUP_LEDS =
{
    NI.HW.LED_GROUP_A,
    NI.HW.LED_GROUP_B,
    NI.HW.LED_GROUP_C,
    NI.HW.LED_GROUP_D,
    NI.HW.LED_GROUP_E,
    NI.HW.LED_GROUP_F,
    NI.HW.LED_GROUP_G,
    NI.HW.LED_GROUP_H
}

------------------------------------------------------------------------------------------------------------------------
-- Pad to group map
------------------------------------------------------------------------------------------------------------------------

MaschineMikroController.PAD_TO_GROUP =
{
    [NI.HW.PAD_9]  = 5,
    [NI.HW.PAD_10] = 6,
    [NI.HW.PAD_11] = 7,
    [NI.HW.PAD_12] = 8,
    [NI.HW.PAD_13] = 1,
    [NI.HW.PAD_14] = 2,
    [NI.HW.PAD_15] = 3,
    [NI.HW.PAD_16] = 4
}

MaschineMikroController.MODIFIER_PAGES =
{
    NI.HW.PAGE_SCENE,
    NI.HW.PAGE_DUPLICATE,
    NI.HW.PAGE_GRID,
    NI.HW.PAGE_GROUP,
    NI.HW.PAGE_MUTE,
    NI.HW.PAGE_VIEW,
    NI.HW.PAGE_PAD,
    NI.HW.PAGE_PAGE,
    NI.HW.PAGE_PATTERN,
    NI.HW.PAGE_REPEAT,
    NI.HW.PAGE_SELECT,
    NI.HW.PAGE_SOLO,
    NI.HW.PAGE_VARIATION
}

MaschineMikroController.BUTTON_TO_PAGE =
{
    [NI.HW.BUTTON_CONTROL]      = NI.HW.PAGE_CONTROL,
    [NI.HW.BUTTON_STEP]         = NI.HW.PAGE_STEP,
    [NI.HW.BUTTON_BROWSE]       = NI.HW.PAGE_BROWSE,
    [NI.HW.BUTTON_SAMPLE]       = NI.HW.PAGE_SAMPLING,

    [NI.HW.BUTTON_SCENE]        = NI.HW.PAGE_SCENE,
    [NI.HW.BUTTON_PATTERN]      = NI.HW.PAGE_PATTERN,
    [NI.HW.BUTTON_PAD_MODE]     = NI.HW.PAGE_PAD,
    [NI.HW.BUTTON_NAVIGATE]     = NI.HW.PAGE_VIEW,
    [NI.HW.BUTTON_DUPLICATE]    = NI.HW.PAGE_DUPLICATE,
    [NI.HW.BUTTON_SELECT]       = NI.HW.PAGE_SELECT,
    [NI.HW.BUTTON_SOLO]         = NI.HW.PAGE_SOLO,
    [NI.HW.BUTTON_MUTE]         = NI.HW.PAGE_MUTE,

    [NI.HW.BUTTON_NOTE_REPEAT]      = NI.HW.PAGE_REPEAT,
    [NI.HW.BUTTON_TRANSPORT_GRID]   = NI.HW.PAGE_GRID
}

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:__init()

    -- contruct base class
    HardwareControllerBase.__init(self)

    -- create all MaschineMikroController pages
    self:createPages()

    self.QuickEdit = QuickEditBase(self)

    NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:createPages()

    -- register pages
    local Folder = "Scripts/Maschine/MaschineMikro/Pages/"

    local Pages = self.PageManager

    -- main pages
    Pages:register(NI.HW.PAGE_CONTROL,    Folder .. "ControlPageMikro",   "ControlPageMikro")
    Pages:register(NI.HW.PAGE_BROWSE,     Folder .. "BrowsePageMikro",    "BrowsePageMikro")
    Pages:register(NI.HW.PAGE_MODULE,     Folder .. "ModulesPageMikro",   "ModulesPageMikro")
    Pages:register(NI.HW.PAGE_SAMPLING,   Folder .. "SamplingPageMikro",  "SamplingPageMikro")

    -- modifier pages
    Pages:register(NI.HW.PAGE_SCENE,      Folder .. "ScenePageMikro",     "ScenePageMikro")
    Pages:register(NI.HW.PAGE_PATTERN,    Folder .. "PatternPageMikro",   "PatternPageMikro")
    Pages:register(NI.HW.PAGE_VIEW,       Folder .. "ViewPageMikro",      "ViewPageMikro")
    Pages:register(NI.HW.PAGE_DUPLICATE,  Folder .. "DuplicatePageMikro", "DuplicatePageMikro")
    Pages:register(NI.HW.PAGE_SELECT,     Folder .. "SelectPageMikro",    "SelectPageMikro")
    Pages:register(NI.HW.PAGE_PAD,        Folder .. "PadModePageMikro",   "PadModePageMikro")
    Pages:register(NI.HW.PAGE_SOLO,       Folder .. "SoloPageMikro",      "SoloPageMikro")
    Pages:register(NI.HW.PAGE_MUTE,       Folder .. "MutePageMikro",      "MutePageMikro")

    Pages:register(NI.HW.PAGE_GROUP,      Folder .. "GroupPageMikro",     "GroupPageMikro")
    Pages:register(NI.HW.PAGE_REPEAT,     Folder .. "RepeatPageMikro",    "RepeatPageMikro")
    Pages:register(NI.HW.PAGE_GRID,       Folder .. "GridPageMikro",      "GridPageMikro")
    Pages:register(NI.HW.PAGE_VARIATION,  Folder .. "VariationPageMikro", "VariationPageMikro")

    -- other pages
    Pages:register(NI.HW.PAGE_STEP,       Folder .. "StepModePageMikro",  "StepModePageMikro")
    Pages:register(NI.HW.PAGE_MAIN,       Folder .. "MainPageMikro",      "MainPageMikro")
    Pages:register(NI.HW.PAGE_REC_MODE,   Folder .. "RecModePageMikro",   "RecModePageMikro")
    Pages:register(NI.HW.PAGE_PATTERN_LENGTH, Folder .. "PatternLengthPageMikro",  "PatternLengthPageMikro")
    Pages:register(NI.HW.PAGE_LOOP,       Folder .. "LoopPageMikro",      "LoopPageMikro")
    Pages:register(NI.HW.PAGE_BUSY,       Folder .. "BusyPageMikro",      "BusyPageMikro")
    Pages:register(NI.HW.PAGE_SAVE_DIALOG, Folder .. "SaveDialogPageMikro",  "SaveDialogPageMikro")

    -- instantiate these pages before they are shown (avoid lazy loading) because their page button leds all light at
    -- the same time, and the pages need to be loaded in the page manager for that to work correctly.
    self:getPage(NI.HW.PAGE_SCENE)
    self:getPage(NI.HW.PAGE_PATTERN)
    self:getPage(NI.HW.PAGE_DUPLICATE)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:openDialogAudioExport()

    self:openBusyDialog()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:openDialogMessage()

    self:openBusyDialog()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:openDialogTextInput()

    self:openBusyDialog()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:openDialogUSBStorageMode()

    self:openBusyDialog()

end

------------------------------------------------------------------------------------------------------------------------
-- Pad Handler
------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:onPadEvent(PadIndex, Trigger, PadValue)

    local Handled = false

    if self.ActivePage and self:getShiftPressed() then

        local TopPageIsGroup = NHLController:getPageStack():getTopPage() == NI.HW.PAGE_GROUP
        local TopPageIsMain = NHLController:getPageStack():getTopPage() == NI.HW.PAGE_MAIN

        Handled = MaschineHelper.onPadEventShift(PadIndex, Trigger,
            self:getErasePressed() and not TopPageIsGroup and not TopPageIsMain,
            self:getNavPressed() or (self:getErasePressed() and (TopPageIsGroup or TopPageIsMain)))

    end

    if not Handled then
        HardwareControllerBase.onPadEvent(self, PadIndex, Trigger, PadValue)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Button Handlers
------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:setupButtonHandler()

    -- setup common handlers in base class
    HardwareControllerBase.setupButtonHandler(self)

    -- mikro only
    self.SwitchHandler[NI.HW.BUTTON_MAIN]           =  function(On) self:onMainButton(On) end
    self.SwitchHandler[NI.HW.BUTTON_CONTROL]        =  function(On) self:onControlButton(On) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP]          =  function(On) self:onGroupButton(On) end
    self.SwitchHandler[NI.HW.BUTTON_NAV]            =  function(On) self:onNavButton(On) end
    self.SwitchHandler[NI.HW.BUTTON_NOTE_REPEAT]    =  function(On) self:onNoteRepeatButton(On) end

    --  mikro screen buttons
    self.SwitchHandler[NI.HW.BUTTON_F1] = function(Pressed) self:onScreenButton(1, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_F2] = function(Pressed) self:onScreenButton(2, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_F3] = function(Pressed) self:onScreenButton(3, Pressed) end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:getShiftPageID(Button, CurPageID, Pressed)

    if (self.HWModel == NI.HW.MASCHINE_CONTROLLER_MIKRO_MK1 and Button == NI.HW.BUTTON_NOTE_REPEAT) then

        return NHLController:getPageStack():isPageInStack(NI.HW.PAGE_STEP) and NI.HW.PAGE_REPEAT or NI.HW.PAGE_STEP

    elseif (self.HWModel == NI.HW.MASCHINE_CONTROLLER_MIKRO_MK2 and Button == NI.HW.BUTTON_GROUP
        and not self:getErasePressed()) then

        return NHLController:getPageStack():isPageInStack(NI.HW.PAGE_STEP) and NI.HW.PAGE_GROUP or NI.HW.PAGE_STEP

    end

    return HardwareControllerBase.getShiftPageID(self, Button, CurPageID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:onPageButtonShift(Button, Pressed)

    -- [SHIFT] + [SCENE] = Toggle Ideas View
    if Pressed and Button == NI.HW.BUTTON_SCENE then
        ArrangerHelper.toggleIdeasView()
        LEDHelper.setLEDState(NI.HW.LED_SCENE, LEDHelper.LS_BRIGHT)
        return true
    end

    -- [SHIFT] + [SAMPLE] = Save Project
    if Pressed and Button == NI.HW.BUTTON_SAMPLE then
        MaschineHelper.saveProject(self:getInfoBar())
        LEDHelper.setLEDState(NI.HW.LED_SAMPLE, LEDHelper.LS_BRIGHT)
        return true
    end

    -- [SHIFT] + [NOTE_REPEAT] = Tap Tempo
    if Pressed and Button == NI.HW.BUTTON_NOTE_REPEAT and self.HWModel ~= NI.HW.MASCHINE_CONTROLLER_MIKRO_MK1 then
        NHLController:onTapTempo()
        LEDHelper.setLEDState(NI.HW.LED_NOTE_REPEAT, LEDHelper.LS_BRIGHT)
        return true
    end

    return HardwareControllerBase.onPageButtonShift(self, Button, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:onPageButton(Button, PageID, Pressed)

    if self.ActivePage and self.ActivePage.Name == "StepPage" then

        if (self.HWModel == NI.HW.MASCHINE_CONTROLLER_MIKRO_MK1 and Button == NI.HW.BUTTON_NOTE_REPEAT) then

            PageID = self:getShiftPressed() and NI.HW.PAGE_REPEAT or NI.HW.PAGE_STEP

        elseif (self.HWModel == NI.HW.MASCHINE_CONTROLLER_MIKRO_MK2 and Button == NI.HW.BUTTON_GROUP) then

            PageID = self:getShiftPressed() and NI.HW.PAGE_GROUP or NI.HW.PAGE_STEP

        end

    end

    HardwareControllerBase.onPageButton(self, Button, PageID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:onGroupButton(Pressed)

    if self.ActivePage then
        local PageID = self:getShiftPressed() and self:getShiftPageID(NI.HW.BUTTON_GROUP, nil, Pressed) or nil

        if PageID then
            self:onPageButton(NI.HW.BUTTON_GROUP, PageID, Pressed)
        else
            self.ActivePage:onGroupButton(Pressed)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:onMainButton(Pressed)

    if self.ActivePage then
        self.ActivePage:onMainButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:onControlButton(Pressed)

    if Pressed and self:getShiftPressed() and self.HWModel == NI.HW.MASCHINE_CONTROLLER_MIKRO_MK1 then
        -- [SHIFT] + [ENTER] = Tap Tampo on Mikro Mk1
        NHLController:onTapTempo()
    elseif self.ActivePage then
        self.ActivePage:onControlButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:onLeftRightButton(Right, Pressed)

    if self.ActivePage then

        if Pressed and not Right and self.ActivePage:getLeftButtonEnabled() then
            LEDHelper.setLEDState(NI.HW.LED_LEFT, LEDHelper.LS_BRIGHT) -- left button led
        elseif Pressed and Right and self.ActivePage:getRightButtonEnabled() then
            LEDHelper.setLEDState(NI.HW.LED_RIGHT, LEDHelper.LS_BRIGHT) -- right button led
        elseif not Pressed then
            self.ActivePage:updateLeftRightLEDs()
        end

        self.ActivePage:onLeftRightButton(Right, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:onNoteRepeatButton(Pressed)

    if self.ActivePage then
        self.ActivePage:onNoteRepeatButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:getInfoBar()

    return self.ActivePage and self.ActivePage.Screen and self.ActivePage.Screen.InfoBar

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:getNavPressed()

    return self.SwitchPressed[NI.HW.BUTTON_NAV] == true

end

------------------------------------------------------------------------------------------------------------------------

function MaschineMikroController:getGroupPressed()

    return self.SwitchPressed[NI.HW.BUTTON_GROUP] == true

end

------------------------------------------------------------------------------------------------------------------------
-- Create Instance
------------------------------------------------------------------------------------------------------------------------

ControllerScriptInterface = MaschineMikroController()

------------------------------------------------------------------------------------------------------------------------

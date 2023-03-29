------------------------------------------------------------------------------------------------------------------------
-- Maschine Controller
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/HardwareControllerBase"
require "Scripts/Shared/Helpers/EventsHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Maschine/QuickEdit"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MaschineController = class( 'MaschineController', HardwareControllerBase )

------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------

MaschineController.SCREEN_BUTTONS =
{
    NI.HW.BUTTON_SCREEN_1,
    NI.HW.BUTTON_SCREEN_2,
    NI.HW.BUTTON_SCREEN_3,
    NI.HW.BUTTON_SCREEN_4,
    NI.HW.BUTTON_SCREEN_5,
    NI.HW.BUTTON_SCREEN_6,
    NI.HW.BUTTON_SCREEN_7,
    NI.HW.BUTTON_SCREEN_8
}

MaschineController.SCREEN_BUTTON_LEDS =
{
    NI.HW.LED_SCREEN_BUTTON_1,
    NI.HW.LED_SCREEN_BUTTON_2,
    NI.HW.LED_SCREEN_BUTTON_3,
    NI.HW.LED_SCREEN_BUTTON_4,
    NI.HW.LED_SCREEN_BUTTON_5,
    NI.HW.LED_SCREEN_BUTTON_6,
    NI.HW.LED_SCREEN_BUTTON_7,
    NI.HW.LED_SCREEN_BUTTON_8
}

MaschineController.GROUP_LEDS =
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

MaschineController.GROUP_BUTTONS =
{
    NI.HW.BUTTON_GROUP_A,
    NI.HW.BUTTON_GROUP_B,
    NI.HW.BUTTON_GROUP_C,
    NI.HW.BUTTON_GROUP_D,
    NI.HW.BUTTON_GROUP_E,
    NI.HW.BUTTON_GROUP_F,
    NI.HW.BUTTON_GROUP_G,
    NI.HW.BUTTON_GROUP_H
}

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function MaschineController:__init()

    -- contruct base class
    HardwareControllerBase.__init(self)

    -- create all Maschine pages
    self:createPages()

    NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)
    self.QuickEdit = QuickEdit(self)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:createPages()

	-- register pages
    local Folder = "Scripts/Maschine/Maschine/Pages/"
    local SharedFolder = "Scripts/Shared/Pages/"

    local Pages = self.PageManager

    -- main pages
    Pages:register(NI.HW.PAGE_CONTROL,   Folder .. "ControlPage",    "ControlPage")
    Pages:register(NI.HW.PAGE_BROWSE,    SharedFolder .. "BrowsePage",     "BrowsePage")
    Pages:register(NI.HW.PAGE_MODULE,    Folder .. "ModulePage",     "ModulePage")
    Pages:register(NI.HW.PAGE_SAMPLING,  Folder .. "SamplingPage",   "SamplingPage")
    Pages:register(NI.HW.PAGE_MIXER,     Folder .. "MixerPage",     "MixerPage")

    -- modifier pages
    Pages:register(NI.HW.PAGE_SCENE,     Folder .. "ScenePage",      "ScenePage")
    Pages:register(NI.HW.PAGE_PATTERN,   Folder .. "PatternPage",    "PatternPage")
    Pages:register(NI.HW.PAGE_PAD,       Folder .. "PadModePage",    "PadModePage")
    Pages:register(NI.HW.PAGE_NAVIGATE,  Folder .. "NavigatePage",   "NavigatePage")
    Pages:register(NI.HW.PAGE_DUPLICATE, Folder .. "DuplicatePage",  "DuplicatePage")
    Pages:register(NI.HW.PAGE_SELECT,    Folder .. "SelectPage",     "SelectPage")
    Pages:register(NI.HW.PAGE_SOLO,      Folder .. "SoloPage",       "SoloPage")
    Pages:register(NI.HW.PAGE_MUTE,      Folder .. "MutePage",       "MutePage")
    Pages:register(NI.HW.PAGE_REPEAT,    Folder .. "RepeatPage",     "RepeatPage")
    Pages:register(NI.HW.PAGE_GRID,      Folder .. "GridPage",       "GridPage")
    Pages:register(NI.HW.PAGE_VARIATION, Folder .. "VariationPage",  "VariationPage")

    -- other pages
    Pages:register(NI.HW.PAGE_STEP,             Folder .. "StepPage",           "StepPage")
    Pages:register(NI.HW.PAGE_STEP_MOD,         Folder .. "StepPageMod",        "StepPageMod")
    Pages:register(NI.HW.PAGE_PAGE,             Folder .. "PagePage",           "PagePage")
    Pages:register(NI.HW.PAGE_REC_MODE,         Folder .. "RecModePage",        "RecModePage")
    Pages:register(NI.HW.PAGE_PATTERN_LENGTH,   Folder .. "PatternLengthPage",  "PatternLengthPage")
    Pages:register(NI.HW.PAGE_LOOP,             Folder .. "LoopPage",           "LoopPage")
    Pages:register(NI.HW.PAGE_BUSY,             Folder .. "BusyPage",           "BusyPage")
    Pages:register(NI.HW.PAGE_SNAPSHOTS,        Folder .. "SnapshotsPage",      "SnapshotsPage")
    Pages:register(NI.HW.PAGE_SAVE_DIALOG,      Folder .. "SaveDialogPage",     "SaveDialogPage")

	-- instantiate these pages before they are shown (avoid lazy loading) because their page button leds all light at
	-- the same time, and the pages need to be loaded in the page manager for that to work correctly.
	self:getPage(NI.HW.PAGE_SCENE)
	self:getPage(NI.HW.PAGE_PATTERN)
	self:getPage(NI.HW.PAGE_DUPLICATE)

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen button handler
------------------------------------------------------------------------------------------------------------------------

function MaschineController:setupButtonHandler()

	-- setup common handlers in base class
	HardwareControllerBase.setupButtonHandler(self)

    --  MaschineMK1 and MaschineMK2 buttons
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_1] = function(Pressed) self:onScreenButton(1, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_2] = function(Pressed) self:onScreenButton(2, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_3] = function(Pressed) self:onScreenButton(3, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_4] = function(Pressed) self:onScreenButton(4, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_5] = function(Pressed) self:onScreenButton(5, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_6] = function(Pressed) self:onScreenButton(6, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_7] = function(Pressed) self:onScreenButton(7, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_8] = function(Pressed) self:onScreenButton(8, Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_GROUP_A] = function(Pressed) self:onGroupButton(1, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_B] = function(Pressed) self:onGroupButton(2, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_C] = function(Pressed) self:onGroupButton(3, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_D] = function(Pressed) self:onGroupButton(4, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_E] = function(Pressed) self:onGroupButton(5, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_F] = function(Pressed) self:onGroupButton(6, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_G] = function(Pressed) self:onGroupButton(7, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GROUP_H] = function(Pressed) self:onGroupButton(8, Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_AUTO_WRITE] = function(Pressed) self:onAutoWriteButton(Pressed) end

    if self.HWModel == NI.HW.MASCHINE_CONTROLLER_MK2 then
		self.SwitchHandler[NI.HW.BUTTON_VOLUME] =  function(On) self:onVolumeButton(On) end
		self.SwitchHandler[NI.HW.BUTTON_SWING]  =  function(On) self:onSwingButton(On) end
		self.SwitchHandler[NI.HW.BUTTON_TEMPO]  =  function(On) self:onTempoButton(On) end
		self.SwitchHandler[NI.HW.BUTTON_ENTER]  =  function(On) self:onEnterButton(On) end

		-- Left/Right master button handlers

		self.SwitchHandler[NI.HW.BUTTON_MASTER_RIGHT] = function(Pressed) self:onLeftRightMasterButton(Pressed, true) end
		self.SwitchHandler[NI.HW.BUTTON_MASTER_LEFT] = function(Pressed) self:onLeftRightMasterButton(Pressed, false) end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:updateSwitchLEDs()

    self:updateVolumeTempoSwingButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:getShiftPageID(Button, CurPageID, Pressed)

    -- [SHIFT] + [SAMPLE] = [MIXER] (but only on MK1/MK2, *not* Mikro)
    if Button == NI.HW.BUTTON_SAMPLE then
        return NI.HW.PAGE_MIXER
    end

    return HardwareControllerBase.getShiftPageID(self, Button, CurPageID, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:onPageButtonShift(Button, Pressed)

    -- [SHIFT] + [SCENE] = Toggle Ideas View
    if Pressed and Button == NI.HW.BUTTON_SCENE then
        ArrangerHelper.toggleIdeasView()
        LEDHelper.setLEDState(NI.HW.LED_SCENE, LEDHelper.LS_BRIGHT)
        return true
    end

    -- [SHIFT] + [NOTE_REPEAT] = Tap Tempo
    if Pressed and Button == NI.HW.BUTTON_NOTE_REPEAT then
        NHLController:onTapTempo()
        LEDHelper.setLEDState(NI.HW.LED_NOTE_REPEAT, LEDHelper.LS_BRIGHT)
        return true
    end

    return HardwareControllerBase.onPageButtonShift(self, Button, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
-- Pad Handler
------------------------------------------------------------------------------------------------------------------------

function MaschineController:onPadEvent(PadIndex, Trigger, PadValue)

    if self.ActivePage then
		self.QuickEdit:onPadEvent(PadIndex, Trigger)
	end

    local Handled = false

    if self.ActivePage and self:getShiftPressed() then
        Handled = MaschineHelper.onPadEventShift(PadIndex, Trigger, self:getErasePressed())
    end

    if not Handled then
        -- call base
        HardwareControllerBase.onPadEvent(self, PadIndex, Trigger, PadValue)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- QuickEdit
------------------------------------------------------------------------------------------------------------------------

function MaschineController:onWheelEvent(Index, Inc)

	-- Current page gets 1st priority
	if self.ActivePage and self.ActivePage:onWheel(Inc) then
		return
	end

	-- then QuickEdit
	if self.QuickEdit:onWheel(Inc) then
		self:showQuickEdit()
		return
	end

	-- then Transport
	self.TransportSection:onWheel(Inc)

end

------------------------------------------------------------------------------------------------------------------------
-- Button Handlers
------------------------------------------------------------------------------------------------------------------------

function MaschineController:onGroupButton(Index, Pressed)

    if not self.ActivePage then
    	return
    end

	-- PRIO 1: Page
    if self.ActivePage:onGroupButton(Index, Pressed) then
		return
	end

	-- QuickEdit: always checked
	self.QuickEdit:onGroupButton(Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:onLeftRightMasterButton(Pressed, Right)

    --forward button event as wheel event

    if self.ActivePage then
		self:updateMasterLeftRightLEDs()
    end

    if Pressed then
        self:onWheelEvent(0, Right and 1 or -1)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:updateMasterLeftRightLEDs()

    if self.SwitchPressed[NI.HW.BUTTON_MASTER_RIGHT] then
        LEDHelper.setLEDState(NI.HW.LED_MASTER_RIGHT, LEDHelper.LS_BRIGHT)
    else
        LEDHelper.setLEDState(NI.HW.LED_MASTER_RIGHT, LEDHelper.LS_OFF)
    end

    if self.SwitchPressed[NI.HW.BUTTON_MASTER_LEFT] then
        LEDHelper.setLEDState(NI.HW.LED_MASTER_LEFT, LEDHelper.LS_BRIGHT)
    else
        LEDHelper.setLEDState(NI.HW.LED_MASTER_LEFT, LEDHelper.LS_OFF)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:onVolumeEncoder(EncoderInc)

	if self.ActivePage then
		local Handled = self.ActivePage:onVolumeEncoder(EncoderInc)

		if not Handled then
			self.QuickEdit:onVolumeEncoder(EncoderInc)
			self:showQuickEdit()
		end
	end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:onTempoEncoder(EncoderInc)

	if self.ActivePage then
		local Handled = self.ActivePage:onTempoEncoder(EncoderInc)

		if not Handled then
			self.QuickEdit:onTempoEncoder(EncoderInc)
			self:showQuickEdit()
		end
	end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:onSwingEncoder(EncoderInc)

	if self.ActivePage then

		local Handled = self.ActivePage:onSwingEncoder(EncoderInc)

		if not Handled then
			self.QuickEdit:onSwingEncoder(EncoderInc)
			self:showQuickEdit()
		end

	end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:getInfoBar()

    if self.ActivePage then
        local Page = self.ActivePage.CurrentPage or self.ActivePage
        return Page and Page.Screen and Page.Screen.InfoBar
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:updatePageSync(ForceUpdate)

    -- call base
    HardwareControllerBase.updatePageSync(self, ForceUpdate)

    -- update NOTE_REPEAT button
    if  NHLController:getPageStack():getTopPage() ~= NI.HW.PAGE_REPEAT then
        LEDHelper.setLEDState(NI.HW.LED_NOTE_REPEAT, MaschineHelper.isArpRepeatActive()
            and LEDHelper.LS_DIM or LEDHelper.LS_OFF)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:openDialogAudioExport()

    self:openBusyDialog()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:openDialogMessage()

    self:openBusyDialog()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:openDialogTextInput()

    self:openBusyDialog()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineController:openDialogUSBStorageMode()

    self:openBusyDialog()

end

------------------------------------------------------------------------------------------------------------------------
-- Create Instance
------------------------------------------------------------------------------------------------------------------------

ControllerScriptInterface = MaschineController()

------------------------------------------------------------------------------------------------------------------------

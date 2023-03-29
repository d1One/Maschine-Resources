
require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/DuplicateHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
DuplicatePageMikro = class( 'DuplicatePageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function DuplicatePageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "DuplicatePage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_DUPLICATE }

    -- Because this needs to save the SOUND or GROUP mode that it's in, it is saved in BaseMode, and when it needs
    -- to go to PATTERN or SCENE mode, the SOUND/GROUP mode is perserved in BaseMode
    self.BaseMode = DuplicateHelper.SOUND
    self.Mode = NI.DATA.StateHelper.getFocusGroup(App) and self.BaseMode or DuplicateHelper.GROUP

    -- index of object to duplicate (e.g. sound, group, scene, pattern).
    -- when this is >0, the next pad event down will duplicate object from this index.
    self.SourceIndex = -1
    self.SourceGroupIndex = -1

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function DuplicatePageMikro:setupScreen()

    -- setup screen
    self.Screen = ScreenMikro(self)

    -- Info Display
    ScreenHelper.setWidgetText(self.Screen.Title, {"DUPLICATE"})

    -- Screen Buttons
    self.Screen:styleScreenButtons({"+EVENT", "", ""}, "HeadButtonRow", "HeadButton")

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageMikro:onShow(Show)

    if Show then
        -- sync group bank with that in SW
        self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()
    else
        self.Mode = NI.DATA.StateHelper.getFocusGroup(App) and self.BaseMode or DuplicateHelper.GROUP
        self.SourceIndex = -1
        self.SourceGroupIndex = -1
    end

    PageMikro.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function DuplicatePageMikro:updateScreens(ForceUpdate)

    DuplicateHelper.updateSceneSectionMode(self, ForceUpdate)

    -- exit Sound duplication mode if focus is on Audio Group
    if (self.Mode == DuplicateHelper.SOUND and not NI.DATA.StateHelper.getFocusGroup(App)) then
        DuplicateHelper.setMode(self, DuplicateHelper.GROUP)
        self.SourceIndex = -1
        self.SourceGroupIndex = -1
    end

    -- make sure GroupBank is not pointing to some outdated value after groups updates
    self.Screen:updateGroupBank(self)

    -- Check Source Validity! (group or pattern could be deleted before pasting)
    if not DuplicateHelper.isSourceValid(self.Mode, self.SourceIndex, self.SourceGroupIndex) then
        self.SourceIndex = -1
        self.SourceGroupIndex = -1
    end

    local ShiftPressed = self.Controller:getShiftPressed()
    local F1Enabled = not (ShiftPressed or self.Mode == DuplicateHelper.SCENE
        or self.Mode == DuplicateHelper.PATTERN or self.Mode == DuplicateHelper.CLIP)
    self.Screen.ScreenButton[1]:setEnabled(F1Enabled)
    self.Screen.ScreenButton[1]:setVisible(F1Enabled)
    self.Screen.ScreenButton[2]:setVisible(false)
    self.Screen.ScreenButton[3]:setVisible(false)

    local Title, Bank, NumBanks = nil, nil, nil
    local ButtonSelected, ButtonText = false, ""

    if self.Mode == DuplicateHelper.SOUND then
        Title = "DUPLICATE SOUND"
        ButtonSelected = F1Enabled and App:getWorkspace():getDuplicateSoundWithEventsParameter():getValue()
        ButtonText = "+EVENT"

    elseif self.Mode == DuplicateHelper.GROUP_SELECT then
        Title = "SELECT GROUP"
        Bank = self.Screen.GroupBank + 1
        NumBanks = MaschineHelper.getNumFocusSongGroupBanks(true)
        ButtonSelected = F1Enabled and App:getWorkspace():getDuplicateSoundWithEventsParameter():getValue()
        ButtonText = "+EVENT"

    elseif self.Mode == DuplicateHelper.GROUP then
        Title = "DUPLICATE GROUP"
        Bank = self.Screen.GroupBank + 1
        NumBanks = MaschineHelper.getNumFocusSongGroupBanks(true)
        ButtonSelected = F1Enabled and DuplicateHelper.getDuplicateWithOption(self.Mode)
        ButtonText = "+PAT"

    elseif self.Mode == DuplicateHelper.SCENE then
        Title = "DUPLICATE SCENE"
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        Bank = Song and (Song:getFocusSceneBankIndexParameter():getValue() + 1)
        NumBanks = Song and (math.floor(Song:getScenes():size() / 16) + 1)

    elseif self.Mode == DuplicateHelper.SECTION then
        Title = "DUPLICATE SECTION"
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        Bank = Song and (Song:getFocusSectionBankIndexParameter():getValue() + 1)
        NumBanks = Song and (Song:getNumSectionBanksParameter():getValue())
        ButtonSelected = F1Enabled and DuplicateHelper.getDuplicateWithOption(self.Mode)
        ButtonText = "LINK"

    elseif self.Mode == DuplicateHelper.PATTERN then
        Title = "DUPLICATE PATTERN"
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        Bank = Group and (Group:getFocusPatternBankIndexParameter():getValue() + 1)
        NumBanks = Song and (Song:getNumPatternBanksParameter():getValue())

    elseif self.Mode == DuplicateHelper.CLIP then
        Title = "DUPLICATE CLIP"
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        Bank = Group and (Group:getClipEventBankParameter():getValue() + 1)
        NumBanks = Group and (Group:getClipEventBankParameter():getMax() + 1)

    else
        Title = "DUPLICATE"
        error("Duplicate Page mode not set")
    end

    self.Screen.Title[1]:setText(Title)
    self.Screen.ScreenButton[1]:setText(ButtonText)
    self.Screen.ScreenButton[1]:setSelected(ButtonSelected)
    if ShiftPressed then
        self.Screen.ParameterLabel[2]:setText((Bank and NumBanks) and "BANK: "..tostring(Bank).."/"..tostring(NumBanks) or "")
        self.Screen.ParameterLabel[4]:setText("")
    else
        self.Screen.ParameterLabel[2]:setText("")
        self.Screen.ParameterLabel[4]:setText("")
    end

    -- call base class
    PageMikro.updateScreens(self, ForceUpdate)

    self:updatePageLEDs(LEDHelper.LS_BRIGHT)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageMikro:updatePageLEDs(LEDState)

    DuplicateHelper.updatePageLEDs(LEDState, self.Mode, self.Controller)
    PageMikro.updatePageLEDs(self, LEDState)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageMikro:updateGroupLEDs()

	if self.Mode == DuplicateHelper.GROUP or self.Mode == DuplicateHelper.GROUP_SELECT then
        LEDHelper.turnOffLEDs(self.Controller.PAD_LEDS)

	   	local CanPasteGroup = self.Mode ~= DuplicateHelper.GROUP_SELECT and self.SourceIndex >= 0
		local CanPasteSound = self.Mode == DuplicateHelper.GROUP_SELECT

        DuplicateHelper.updateGroupLEDs(self, CanPasteGroup, CanPasteSound)
    else
		PageMikro.updateGroupLEDs(self)
	end

	local GroupState = (self.Mode == DuplicateHelper.GROUP or self.Mode == DuplicateHelper.GROUP_SELECT)
		and LEDHelper.LS_BRIGHT
		or  LEDHelper.LS_DIM
	PageMikro:updateGroupPageButtonLED(GroupState, true)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageMikro:updatePadLEDs()

    if self.Mode ~= DuplicateHelper.GROUP_SELECT and self.Mode ~= DuplicateHelper.GROUP then
	    local CanPaste = (self.SourceIndex >= 0) and (self.Mode ~= DuplicateHelper.GROUP_SELECT)
	    DuplicateHelper.updatePadLEDs(self, self.Controller.PAD_LEDS, CanPaste)
	end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageMikro:updateLeftRightLEDs(ForceUpdate)

	-- once these labels' visibility are set correctly, the base implementation will do the rest
    local LeftVisible = false
    local RightVisible = false
    if self.Controller:getShiftPressed() then
        LeftVisible, RightVisible = DuplicateHelper.getLeftRightButtonsEnabled(self)
    end

	self.Screen.ParameterLabel[1]:setVisible(LeftVisible)
	self.Screen.ParameterLabel[3]:setVisible(RightVisible)

	PageMikro.updateLeftRightLEDs(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function DuplicatePageMikro:onPageButton(Button, PageID, Pressed)

    if self.Controller:getShiftPressed() then
        return false
    end

    return DuplicateHelper.onPageButton(Button, Pressed, self)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageMikro:onScreenButton(Idx, Pressed)

    if Idx == 1 and Pressed and self.Screen.ScreenButton[1]:isEnabled() then
        if (self.Mode == DuplicateHelper.GROUP or self.Mode == DuplicateHelper.SECTION) then
            DuplicateHelper.setDuplicateWithOption(self.Mode, not DuplicateHelper.getDuplicateWithOption(self.Mode))
        else
            local Param = App:getWorkspace():getDuplicateSoundWithEventsParameter()
            NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Param, not Param:getValue())
        end
    end

    PageMikro.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageMikro:onLeftRightButton(Right, Pressed)

	if self.Controller:getShiftPressed() and Pressed then
		DuplicateHelper.onLeftRightButton(self, Right)
	end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageMikro:onGroupButton(Pressed)

    if not Pressed then
        return
    end

    local NewMode
    if self.Mode == DuplicateHelper.SOUND then
        NewMode = self.SourceIndex < 0 and DuplicateHelper.GROUP or DuplicateHelper.GROUP_SELECT
    elseif self.Mode == DuplicateHelper.PATTERN or self.Mode == DuplicateHelper.CLIP
        or self.Mode == DuplicateHelper.SCENE or self.Mode == DuplicateHelper.SECTION then
        NewMode = DuplicateHelper.GROUP
    else
        NewMode = NI.DATA.StateHelper.getFocusGroup(App) and DuplicateHelper.SOUND or DuplicateHelper.GROUP
    end

    DuplicateHelper.setMode(self, NewMode)

    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageMikro:onPadEvent(PadIndex, Trigger)

	if not Trigger then
		return
	end

	if self.Mode == DuplicateHelper.GROUP or self.Mode == DuplicateHelper.GROUP_SELECT then

		if PadIndex >= 9 then
			local GroupIdx = self.Controller.PAD_TO_GROUP[PadIndex] - 1 + (self.Screen.GroupBank * 8)
			DuplicateHelper.onGroupButton(self, GroupIdx)
		end

		self:updateScreens()

	else
		DuplicateHelper.onPadEvent(self, PadIndex)
		self:updateScreens()
	end

end

------------------------------------------------------------------------------------------------------------------------

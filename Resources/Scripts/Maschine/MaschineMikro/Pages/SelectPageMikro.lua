------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Maschine/MaschineMikro/ScreenMikro"
require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Maschine/Helper/ClipHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/SelectHelper"
require "Scripts/Shared/Helpers/EventsHelper"
require "Scripts/Shared/Helpers/PadModeHelper"

local ATTR_ALIGN = NI.UTILS.Symbol("align")
local ATTR_GROUP = NI.UTILS.Symbol("Group")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SelectPageMikro = class( 'SelectPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- globals
------------------------------------------------------------------------------------------------------------------------

-- Page Modes
SelectModes =
{
    SOUND  = 1,
    GROUP  = 2,
    EVENTS = 3
}

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:__init(Controller)

	-- init base class
	PageMikro.__init(self, "SelectPage", Controller)

	-- setup screen
	self:setupScreen()

	-- define page leds
	self.PageLEDs = { NI.HW.LED_SELECT }

	-- set page mode
	self.PageMode = SelectModes.SOUND
	self.PageModeBeforeGroup = SelectModes.SOUND -- for saving the mode (SOUND or EVENTS) before going into GROUP

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:setupScreen()

    -- setup screen
    self.Screen = ScreenMikro(self)

    -- Info Display
    ScreenHelper.setWidgetText(self.Screen.Title, {"SELECT"})

    -- Screen Buttons
    self.Screen:styleScreenButtons({"QUIET", "EVENTS", "MULTI"}, "HeadTabRow", "HeadTab")
    self.Screen.ScreenButton[3]:style("MULTI", "HeadButton")

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:onShow(Show)

	if Show then
		-- sync group bank with that in SW
		self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()

		-- setup Infobar
		self.Screen.InfoBar.Labels[1]:setAttribute(ATTR_ALIGN, "center")
		self.Screen.InfoBar.Labels[2]:setActive(false)

		-- set mode to group if the group button is held down while opening this page; otherwise reset to sound mode
		if self.Controller:getGroupPressed() then
			self:setPageMode(SelectModes.GROUP)
		else
		    self:setPageMode(SelectModes.SOUND)
		end
	end

	PageMikro.onShow(self, Show)
	PageMikro:updateGroupPageButtonLED(self:getGroupButtonLEDState(), true)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:setPageMode(Mode)

	self.PageModeBeforeGroup = self.PageMode ~= SelectModes.GROUP and self.PageMode or SelectModes.SOUND
    self.PageMode = Mode

    self.Screen.InfoBar:setMode(self.PageMode == SelectModes.GROUP and "FocusedGroup" or "FocusedSound")

    self:updateScreens(true)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:updateScreens(ForceUpdate)

    -- make sure GroupBank is not pointing to some outdated value after groups updates
    self.Screen:updateGroupBank(self)

    local InEventsMode = self.PageMode == SelectModes.EVENTS
    local InGroupMode = self.PageMode == SelectModes.GROUP
    -- update screen buttons
    self.Screen.ScreenButton[1]:setAttribute(ATTR_GROUP, InGroupMode and "true" or "false")
    self.Screen.ScreenButton[1]:setEnabled(not InGroupMode)
    self.Screen.ScreenButton[1]:style(InGroupMode and "" or "QUIET", InGroupMode and "HeadButton" or "HeadTab")
    self.Screen.ScreenButton[1]:setSelected(self.PageMode == SelectModes.SOUND)

    self.Screen.ScreenButton[2]:setEnabled(not InGroupMode)
    self.Screen.ScreenButton[2]:style(InGroupMode and "" or "EVENTS", InGroupMode and "HeadButton" or "HeadTab")
    self.Screen.ScreenButton[2]:setSelected(InEventsMode)

    self.Screen.ScreenButton[3]:style(InEventsMode and "" or "MULTI", InEventsMode and "HeadTab" or "HeadButton")
    self.Screen.ScreenButton[3]:setEnabled(not InEventsMode)
    self.Screen.ScreenButton[3]:setSelected(not InEventsMode and App:getWorkspace():getSelectMultiParameter():getValue())


    -- update lower parameter area
    if self.PageMode == SelectModes.GROUP then
		self.Screen.ParameterLabel[2]:setText("BANK:"..tostring(self.Screen.GroupBank+1).."/"
		                                                ..tostring(MaschineHelper.getNumFocusSongGroupBanks(false)))
	else
		self.Screen.ParameterLabel[2]:setText("")
		self.Screen.ParameterLabel[4]:setText("")
    end

    -- call base class
	PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:getGroupButtonLEDState()

	if self.PageMode == SelectModes.EVENTS or not self.IsVisible then
		return LEDHelper.LS_OFF
	end

	return self.PageMode == SelectModes.GROUP and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:updatePadLEDs()

	if self.PageMode == SelectModes.GROUP then

            LEDHelper.turnOffLEDs(self.Controller.PAD_LEDS)

	elseif self.PageMode == SelectModes.SOUND then

            SelectHelper.updatePadLEDsSounds(self.Controller.PAD_LEDS, self.Controller:getErasePressed())

	elseif self.PageMode == SelectModes.EVENTS then

            EventsHelper.updatePadLEDsEvents(self.Controller.PAD_LEDS, self.Controller:getErasePressed())

	end

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:updateGroupLEDs()

    -- update group led state and color
    PageMikro:updateGroupPageButtonLED(self:getGroupButtonLEDState(), true)

    -- update group pad LEDs
	if self.PageMode == SelectModes.GROUP then
		SelectHelper.updateGroupLEDs(self.Controller.GROUP_LEDS, self.Screen.GroupBank)
	else
        PageMikro.updateGroupLEDs(self)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:updateLeftRightLEDs(ForceUpdate)

	local LeftOn = false
	local RightOn = false

	if self.PageMode == SelectModes.GROUP then
		local GroupBank = MaschineHelper.getFocusGroupBank(self)
		local MaxBanks = MaschineHelper.getNumFocusSongGroupBanks(false)

		LeftOn = GroupBank > 0
		RightOn = (GroupBank < MaxBanks-1) or MaschineHelper.getFocusSongGroupCount() % 8 == 0
	end

	self.Screen.ParameterLabel[1]:setVisible(LeftOn)
	self.Screen.ParameterLabel[3]:setVisible(RightOn)

	-- call base class
	PageMikro.updateLeftRightLEDs(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:onScreenButton(ButtonIdx, Pressed)

    if Pressed then
        if ButtonIdx == 1 then
            self:setPageMode(SelectModes.SOUND)
        elseif ButtonIdx == 2 then
            self:setPageMode(SelectModes.EVENTS)
        elseif ButtonIdx == 3 and self.PageMode ~= SelectModes.EVENTS then
			MaschineHelper.toggleMultiSelectParameter()
        end
    end

    -- call base class for update
    PageMikro.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:onGroupButton(Pressed)

	if Pressed then
		if self.PageMode == SelectModes.EVENTS then
			PageMikro.onGroupButton(self, Pressed)
		else
			self:setPageMode(self.PageMode == SelectModes.GROUP and self.PageModeBeforeGroup or SelectModes.GROUP)
		end
	end

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:onPadEvent(PadIndex, Trigger)

	if not Trigger then
            return
	end

	if self.PageMode == SelectModes.GROUP then

	    if PadIndex < 9 then
                return
            end

		local GroupIndex = self.Controller.PAD_TO_GROUP[PadIndex] + (self.Screen.GroupBank * 8) - 1
		MaschineHelper.selectGroupByIndex(GroupIndex)

	elseif self.PageMode == SelectModes.SOUND then

            EventsHelper.onPadEventQuiet(PadIndex, Trigger, self.Controller:getErasePressed())

	elseif self.PageMode == SelectModes.EVENTS then

            EventsHelper.onPadEventEvents(PadIndex, self.Controller:getErasePressed())
            self:updateParameters()

	end

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:onLeftRightButton(Right, Pressed)

	if self.PageMode == SelectModes.GROUP and Pressed then

		local NewGroupBank = self.Screen.GroupBank + (Right and 1 or -1)

		if NewGroupBank >= 0 and NewGroupBank < MaschineHelper.getNumFocusSongGroupBanks(true) then
			self.Screen.GroupBank = NewGroupBank
		end

		self:updateScreens()

	end

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageMikro:onWheel(Inc)

    if self.PageMode == SelectModes.EVENTS and NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then
        return true -- Handled
    else
        return PageMikro.onWheel(self, Inc)
    end

end

------------------------------------------------------------------------------------------------------------------------


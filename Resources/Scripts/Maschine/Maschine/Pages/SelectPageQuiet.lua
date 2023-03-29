------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/PatternHelper"
require "Scripts/Maschine/Helper/SelectHelper"
require "Scripts/Shared/Helpers/EventsHelper"
require "Scripts/Maschine/Maschine/Screens/ScreenWithGrid"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SelectPageQuiet = class( 'SelectPageQuiet', PageMaschine )


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SelectPageQuiet:__init(ParentPage, Controller)

    PageMaschine.__init(self, "SelectPageQuiet", Controller)

    -- setup screen
    self:setupScreen()

	self.ParentPage = ParentPage

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SELECT }

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function SelectPageQuiet:setupScreen()

	-- create screen
	self.Screen = ScreenWithGrid(self)

    -- screen buttons
    ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"SELECT", "EVENTS", "PREV", "NEXT", "ALL", "NONE", "", "MULTI"})
    self.Screen.ScreenButton[1]:style("SELECT", "HeadPin");
	self.Screen.ScreenButton[2]:setSelected(false)

    -- Group buttons in left screen
	self.Screen:insertGroupButtons(true)

	-- set custom style to grid buttons
	for i, Button in ipairs(self.Screen.ButtonPad) do
		Button:style("", "SelectPad")
	end

	for i, Button in ipairs(self.Screen.GroupButtons) do
		Button:style("", "SelectPad")
	end

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageQuiet:onShow(Show)

	PageMaschine.onShow(self, Show)

	if Show then
		-- synchronize local group bank with that in SW
		self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()
	end

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageQuiet:updateScreens(ForceUpdate)

    -- make sure GroupBank is not pointing to some outdated value after groups updates
    self.Screen:updateGroupBank(self)

    local StateCache = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds() or nil

    local BaseGroupIndex = MaschineHelper.getFocusGroupBank(self) * 8

    self.Screen:updateGroupButtonsWithFunctor(
		function(Index) return SelectHelper.getSelectButtonStatesGroups(Index + BaseGroupIndex) end)

    ScreenHelper.updateButtonsWithFunctor(self.Screen.ButtonPad,
		function(Index) return SelectHelper.getSelectButtonStatesSounds(Index) end)

	-- Pin Button
	self.Screen.ScreenButton[1]:setSelected(self.ParentPage.IsPinned)

    -- multi button
    self.Screen.ScreenButton[8]:setSelected(App:getWorkspace():getSelectMultiParameter():getValue())

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageQuiet:updatePadLEDs()

	SelectHelper.updatePadLEDsSounds(self.Controller.PAD_LEDS, self.Controller:getErasePressed())

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageQuiet:updateGroupLEDs()

    if self.Controller:getErasePressed() and self.Controller:getShiftPressed() then
        PageMaschine.updateGroupLEDs(self)
    end

	SelectHelper.updateGroupLEDs(self.Controller.GROUP_LEDS, self.Screen.GroupBank)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function SelectPageQuiet:onGroupButton(ButtonIndex, Pressed)

    if self.Controller:getErasePressed() and self.Controller:getShiftPressed() then
        PageMaschine.onGroupButton(self, ButtonIndex, Pressed)
	elseif not Pressed then
		return
	end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil
	local GroupIndex = ButtonIndex + (self.Screen.GroupBank * 8) - 1

    MaschineHelper.selectGroupByIndex(GroupIndex)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageQuiet:onPadEvent(PadIndex, Trigger)

	if Trigger then
		local Erase = self.Controller.SwitchPressed[NI.HW.BUTTON_TRANSPORT_ERASE] == true
		EventsHelper.onPadEventQuiet(PadIndex, Trigger, Erase)
	end

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageQuiet:onScreenButton(ButtonIdx, Pressed)

    if Pressed then

		if ButtonIdx == 1 then
			self.ParentPage:togglePinState()

		elseif ButtonIdx == 2 then
			self.ParentPage:switchToSubPage(SelectPage.EVENTS)
			return true

		elseif ButtonIdx == 3 or ButtonIdx == 4 then

			local NewGroupBank = self.Screen.GroupBank + (ButtonIdx == 3 and -1 or 1)
			local MaxPageIndex = MaschineHelper.getNumFocusSongGroupBanks(true)

			if NewGroupBank >= 0 and NewGroupBank < MaxPageIndex then
				self.Screen.GroupBank = NewGroupBank
				self:updateScreens(true)
			end

		elseif ButtonIdx == 5 or ButtonIdx == 6 then
			MaschineHelper.setAllSoundsSelected(ButtonIdx == 5, ButtonIdx == 6)

		elseif ButtonIdx == 8 then
			MaschineHelper.toggleMultiSelectParameter()

		end

	end

    -- needed for button LED setting and updateScreens()
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/PatternHelper"
require "Scripts/Maschine/Helper/SelectHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SelectPageStudio = class( 'SelectPageStudio', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SelectPageStudio:__init(Controller)

    PageMaschine.__init(self, "SelectPageStudio", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SELECT }

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function SelectPageStudio:setupScreen()

    -- create screen
    self.Screen = ScreenWithGridStudio(self, {"SELECT", "", "<<", ">>"}, {"ALL", "NONE", "", "MULTI"})
    self.Screen.ScreenButton[1]:style("SELECT", "HeadPin");
    self.Screen:enableLevelMeters(true)

    -- own GroupBank Management to not change the FocusGroup on switching Banks
    self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()

    -- group buttons in left screen
    self.Screen:insertGroupButtons(true)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageStudio:onShow(Show)

	if Show then
		-- synchronize own GroupBank with focused group in SW
		self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()
	end

	PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageStudio:updateScreens(ForceUpdate)

    -- make sure GroupBank is not pointing to some outdated value after groups updates
    self.Screen:updateGroupBank(self)

    local BaseGroupIndex = MaschineHelper.getFocusGroupBank(self) * 8

    self.Screen:updateGroupButtonsWithFunctor(
		function(Index) return SelectHelper.getSelectButtonStatesGroups(Index + BaseGroupIndex) end)

    self.Screen:updatePadButtonsWithFunctor(
		function(Index) return SelectHelper.getSelectButtonStatesSounds(Index) end)

    -- multi button
    self.Screen.ScreenButton[8]:setSelected(App:getWorkspace():getSelectMultiParameter():getValue())

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageStudio:updatePadLEDs()

    SelectHelper.updatePadLEDsSounds(self.Controller.PAD_LEDS, self.Controller:getErasePressed())

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageStudio:updateGroupLEDs()

	SelectHelper.updateGroupLEDs(self.Controller.GROUP_LEDS, self.Screen.GroupBank)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function SelectPageStudio:onGroupButton(ButtonIndex, Pressed)

    if not Pressed then
        return
    end

    if self.Controller:getErasePressed() and self.Controller:getShiftPressed() then
    	PageMaschine.onGroupButton(self, ButtonIndex, Pressed)
    else

        local Song = NI.DATA.StateHelper.getFocusSong(App)
		local GroupIndex = ButtonIndex + (self.Screen.GroupBank * 8) - 1

		MaschineHelper.selectGroupByIndex(GroupIndex)
	end
end

------------------------------------------------------------------------------------------------------------------------

function SelectPageStudio:onPadEvent(PadIndex, Trigger)

    MaschineHelper.selectSoundByPadIndex(PadIndex, Trigger)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageStudio:onScreenButton(ButtonIdx, Pressed)

    if Pressed then
        if ButtonIdx == 3 or ButtonIdx == 4 then

            local NewGroupBank = self.Screen.GroupBank + (ButtonIdx == 3 and -1 or 1)
            local MaxPageIndex = MaschineHelper.getNumFocusSongGroupBanks(true)

            if NewGroupBank >= 0 and NewGroupBank < MaxPageIndex then
                self.Screen.GroupBank = NewGroupBank
            end

        elseif ButtonIdx == 5 or ButtonIdx == 6 then
            MaschineHelper.setAllSoundsSelected(ButtonIdx == 5, ButtonIdx == 6)

        elseif ButtonIdx == 8 then
            MaschineHelper.toggleMultiSelectParameter()

        end
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageStudio:getAccessiblePageInfo()

    return "Select"

end

------------------------------------------------------------------------------------------------------------------------

function SelectPageStudio:getAccessibleTextByPadIndex(PadIdx)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sound = Group and Group:getSounds():at(PadIdx - 1) or nil
    return Sound and Sound:getDisplayName() or ""

end

------------------------------------------------------------------------------------------------------------------------

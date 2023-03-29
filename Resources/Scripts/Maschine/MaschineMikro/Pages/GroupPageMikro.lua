------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
GroupPageMikro = class( 'GroupPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function GroupPageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "GroupPage", Controller)

	-- define page leds
    self.PageLEDs = { NI.HW.LED_GROUP }

    -- setup screen
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function GroupPageMikro:setupScreen()

    -- setup screen
    self.Screen = ScreenMikro(self)

    -- Info Display
    self.Screen.InfoBar:setMode("FocusedGroup")

    self.Screen.Title[1]:setText("GROUP")
    self.Screen:styleScreenButtons({"", "", ""}, "HeadButtonRow", "HeadButton")

    self.Screen.ParameterLabel[2]:setText("BANK")

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikro:updateScreens(ForceUpdate)

    self.Screen.ParameterLabel[2]:setText("BANK: "..tostring(MaschineHelper.getFocusGroupBank() + 1).."/"
                                                  ..tostring(MaschineHelper.getNumFocusSongGroupBanks(false)))

    self.Screen.InfoBar:update(true)

    PageMikro:updateGroupPageButtonLED(LEDHelper.LS_BRIGHT, ForceUpdate)

	-- call base class
	PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikro:updatePageLEDs(LEDLevel)

    PageMikro.updatePageLEDs(self, LEDLevel)

    self:updateGroupPageButtonLED(LEDLevel, true)

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikro:updateGroupLEDs()

	Page.updateGroupLEDs(self)

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikro:updatePadLEDs()

    LEDHelper.turnOffLEDs(self.Controller.PAD_LEDS)

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikro:updateLeftRightLEDs(ForceUpdate)

	local GroupBank = MaschineHelper.getFocusGroupBank() + 1
	local MaxBanks = MaschineHelper.getNumFocusSongGroupBanks(true)

	self.Screen.ParameterLabel[1]:setVisible(GroupBank > 1)
	self.Screen.ParameterLabel[3]:setVisible(GroupBank < MaxBanks)

	-- call base class
	PageMikro.updateLeftRightLEDs(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikro:onPadEvent(PadIndex, Trigger)

    if PadIndex < 9 or not Trigger then
        return
    end

    local GroupIndex = self.Controller.PAD_TO_GROUP[PadIndex] + (MaschineHelper.getFocusGroupBank() * 8)
    local ErasePressed = self.Controller:getErasePressed()
    local ShiftPressed = self.Controller:getShiftPressed()

    if ErasePressed and ShiftPressed then

        local Song      = NI.DATA.StateHelper.getFocusSong(App)
        local Groups    = Song and Song:getGroups() or nil
        MaschineHelper.callFunctionWithObjectVectorAndItemByIndex(Groups, GroupIndex,
            function(Groups, Group) NI.DATA.ObjectVectorAccess.removeGroupResetLast(App, Groups, Group) end
        )

    else

        -- focus group
        MaschineHelper.setFocusGroup(GroupIndex, true)

	end

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikro:onPageButton(Button, Page, Pressed)

    if Pressed and (Page == NI.HW.PAGE_SOLO or Page == NI.HW.PAGE_MUTE) then

        local NewPage = self.Controller:getPage(Page)

        -- if we go to mute/solo from group page, switch to group mode
        if NewPage then
            NewPage:setMode(2)
        end

    end
    return false

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikro:onLeftRightButton(Right, Pressed)

	if Pressed then
        MaschineHelper.incrementFocusGroupBank(self, Right and 1 or -1, true, true)
	end

end

------------------------------------------------------------------------------------------------------------------------

function GroupPageMikro:onGroupButton(Pressed)

    if Pressed then
        NHLController:getPageStack():popPage()

        if NHLController:getPageStack():getTopPage() == NI.HW.PAGE_STEP then
            NHLController:getPageStack():popPage()
        end
    else
        PageMikro.onGroupButton(self, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- when F1 or F2 is pressed we briefly show a message in the parameter area showing the selected group type
------------------------------------------------------------------------------------------------------------------------

function GroupPageMikro:onTimer()

    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Maschine/MaschineMikro/ScreenMikro"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LoopPageMikro = class( 'LoopPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------

function LoopPageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "LoopPage", Controller)

    -- setup screen
    self:setupScreen()

    self.ParameterIndex = 1

    -- define page leds
    self.PageLEDs = {}

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMikro:setupScreen()

    self.Screen = ScreenMikro(self)

    -- tabs
    self.Screen:styleScreenButtons({"", "", "LOOP"}, "HeadButtonRow", "HeadButton")

    -- title
    ScreenHelper.setWidgetText(self.Screen.Title, {"LOOP"})

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMikro:updateScreens(ForceUpdate)

    if ForceUpdate then
        self.Screen.ScreenButton[1]:setVisible(false)
        self.Screen.ScreenButton[2]:setVisible(false)
    end

    self.Screen.ScreenButton[3]:setSelected(NI.DATA.TransportAccess.isLoopActive(App))

    -- call base class
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMikro:updateParameters(ForceUpdate)

    local NameLabel = self.Screen.ParameterLabel[2]
    local ValueLabel = self.Screen.ParameterLabel[4]

    local ParameterNames
    ParameterNames = {"POSITION", "START", "LENGTH", "SECTION LOOP" }

    local Name = self.ParameterIndex .. "/" .. #ParameterNames .. ": " .. ParameterNames[self.ParameterIndex]
    local Value = "-"

    if self.ParameterIndex == 1 then

        Value = ArrangerHelper.getLoopPosAsString()

    elseif self.ParameterIndex == 2 then

        Value = ArrangerHelper.getLoopPosAsString()

    elseif self.ParameterIndex == 3 then

        Value = ArrangerHelper.getLoopLengthAsString()

    elseif self.ParameterIndex == 4 then

        Value = ArrangerHelper.getSceneLoopActiveAsString()

    end

    NameLabel:setText(Name)
    ValueLabel:setText(Value)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMikro:updateLeftRightLEDs(ForceUpdate)

    self.Screen.ParameterLabel[1]:setVisible(self.ParameterIndex > 1)
    self.Screen.ParameterLabel[3]:setVisible(self.ParameterIndex < 4)

    PageMikro.updateLeftRightLEDs(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMikro:onShow(Show)

    if Show then
        NHLController:setPadMode(NI.HW.PAD_MODE_SECTION)
    else
        NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)
    end

    PageMikro.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMikro:onWheel(Inc)

    if self.ParameterIndex == 1 then

        NI.DATA.TransportAccess.moveLoopFromHW(App, Inc)

    elseif self.ParameterIndex == 2 then

        NI.DATA.TransportAccess.moveLoopBeginFromHW(App, Inc)

    elseif self.ParameterIndex == 3 then

        NI.DATA.TransportAccess.moveLoopEndFromHW(App, Inc)

    elseif self.ParameterIndex == 4 then

        NI.DATA.TransportAccess.setSceneLoopActive(App, Inc > 0)

    end

	return true

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMikro:onScreenButton(Idx, Pressed)

    if Pressed then
        if Idx == 3 then
            NI.DATA.TransportAccess.toggleLoop(App)
        end
    end

    -- call base class
    PageMikro.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMikro:onLeftRightButton(Right, Pressed)

	if not Pressed then
		return
	end

    local Inc = Right and 1 or -1

    self.ParameterIndex = math.bound(self.ParameterIndex + Inc, 1, 4)

    self:updateParameters()

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMikro:onLoopButton(Pressed)

    if not Pressed then
        NHLController:getPageStack():popPage()
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMikro:onPageButton(Button, PageID, Pressed)

    if Pressed then
        NHLController:getPageStack():popPage()
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMikro:updatePadLEDs()

    ArrangerHelper.updatePadLEDsSections(self.Controller.PAD_LEDS)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMikro:onPadEvent(PadIndex, Pressed, PadValue)

    ArrangerHelper.onPadEventSections(PadIndex, Pressed, false, false)

end

------------------------------------------------------------------------------------------------------------------------


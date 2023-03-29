require "Scripts/Shared/KH1062/Pages/KH1062Page"

local CreateGroupUtil = require("Scripts/Maschine/KH1062/CreateGroupUtil")
require "Scripts/Maschine/KH1062/DataController"
require "Scripts/Maschine/KH1062/DataModel"
local MuteSoloLedButtons = require("Scripts/Maschine/KH1062/MuteSoloLedButtons")

require "Scripts/Shared/Components/ScreenMikroASeriesBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
GroupNavigatorPage = class( 'GroupNavigatorPage', KH1062Page )

------------------------------------------------------------------------------------------------------------------------

function GroupNavigatorPage:__init(PageName, Environment, SwitchHandler, ConfirmActionFunc)

    KH1062Page.__init(self, ScreenMikroASeriesBase(PageName, Environment.ScreenStack), SwitchHandler)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_LEFT, Shift = false, Pressed = true },
                                        function() self:onWheelLeft() end)
    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_RIGHT, Shift = false, Pressed = true },
                                        function () self:onWheelRight() end)
    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_UP, Shift = false, Pressed = true },
                                        function() self:onWheelUp() end)
    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_DOWN, Shift = false, Pressed = true },
                                        function() self:onWheelDown() end)

    self.DataController = Environment.DataController
    self.DataModel = Environment.DataModel
    self.LedController = Environment.LedController
    self.ConfirmActionFunc = ConfirmActionFunc

    self.MuteLedButton, self.SoloLedButton =
        MuteSoloLedButtons.createMuteSoloSoundLedButtons(Environment, self.SwitchEventTable)

end

------------------------------------------------------------------------------------------------------------------------

function GroupNavigatorPage:setupScreen()

    KH1062Page.setupScreen(self)
    self.Screen:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function GroupNavigatorPage:onWheelLeft()

    if self.DataModel:isFocusGroupIndexValid() then
        self.DataController:setFocusGroup(self.DataModel:getOneBasedFocusGroupIndex() - 1)
    end

end

------------------------------------------------------------------------------------------------------------------------

function GroupNavigatorPage:onWheelRight()

    CreateGroupUtil.selectOrCreateNextGroup(
        self.ConfirmActionFunc,
        self.DataModel,
        self.DataController)

end

------------------------------------------------------------------------------------------------------------------------

function GroupNavigatorPage:onWheelUp()

    self.DataController:selectPrevNextSound(-1)

end

------------------------------------------------------------------------------------------------------------------------

function GroupNavigatorPage:onWheelDown()

    self.DataController:selectPrevNextSound(1)

end

------------------------------------------------------------------------------------------------------------------------

function GroupNavigatorPage:updateScreen()

    KH1062Page:updateScreen()
    local FocusGroupData = self.DataModel:getFocusGroupData()
    local FocusSoundData = self.DataModel:getFocusSoundData()

    self.Screen:showTextInBottomRow()

    self.Screen:setTopRowTextAttribute("bold")
    self.Screen:setTopRowText(FocusGroupData.DisplayName)
    self.Screen:setTopRowIcon(FocusGroupData.IsMuted and "muted" or "object", FocusGroupData.GroupLabel)

    self.Screen:setBottomRowTextAttribute("bold")
    self.Screen:setBottomRowText(FocusSoundData.DisplayName)
    self.Screen:setBottomRowIcon(FocusSoundData.IsMuted and "muted" or "object", "" .. FocusSoundData.OneBasedIndex)

end

------------------------------------------------------------------------------------------------------------------------

function GroupNavigatorPage:updateLEDs()

    if self:isShowing() then
        if self.isShiftPressed() then
            self.MuteLedButton:updateLed()
            self.SoloLedButton:updateLed()
        else
            self.LedController:turnOffLEDs({ NI.HW.LED_LEFT, NI.HW.LED_RIGHT})
        end
    end

end


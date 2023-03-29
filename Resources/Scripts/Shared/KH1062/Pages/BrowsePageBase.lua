require "Scripts/Shared/Components/ScreenMikroASeriesBase"

local AccessibilityHelper = require("Scripts/Shared/KH1062/AccessibilityHelper")
require "Scripts/Shared/KH1062/BrowserController"

require "Scripts/Shared/KH1062/Pages/KH1062Page"

local ButtonHelper = require("Scripts/Shared/KH1062/ButtonHelper")
local FunctionChecker = require("Scripts/Shared/Components/FunctionChecker")
local ActionLedButtonHelper = require("Scripts/Shared/Helpers/ActionLedButtonHelper")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowsePageBase = class( 'BrowsePageBase', KH1062Page )

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:__init(PageName, Environment, Controller, Callbacks, ShiftStateCallbacks)

    if not Controller then
        error("Null controller supplied")
    end

    self.Controller = Controller

    if not Controller.PageManager then
        error("Null page manager supplied")
    end

    FunctionChecker.checkFunctionsExist(Callbacks, {"openLibrarySwitchOverlay"})
    self.Callbacks = Callbacks

    self.PageManager = Controller.PageManager
    self.BrowserModel = Environment.BrowserModel
    self.ResultListModel = Environment.BrowserModel:getResultListModel()
    self.BrowserController = Environment.BrowserController
    self.LedController = Environment.LedController
    self.AccessibilityController = Environment.AccessibilityController
    self.AccessibilityModel = Environment.AccessibilityModel
    self.AppModel = Environment.AppModel

    local ScreenStack = Environment.ScreenStack
    KH1062Page.__init(self, ScreenMikroASeriesBase(PageName, ScreenStack), Controller.SwitchHandler)

    self:setupLibraryLedButtons()

    self.ShiftStateCallbacks = KH1062Page.defaultMissingCallbacks(ShiftStateCallbacks, {"createShiftStateButtons", "updateShiftStateLEDs"})
    self.ShiftStateCallbacks.createShiftStateButtons(self)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:setupLibraryLedButtons()

    local NilReleaseActionFunc = nil
    local FactoryLibraryText = "Factory Library"
    local UserLibraryText = "User Library"
    local SayIfTrainingModeElseFunc =
        function(TrainingModeText, ElseFunc)
            AccessibilityHelper.sayIfTrainingModeElse(
                self.AccessibilityModel,
                self.AccessibilityController,
                TrainingModeText,
                ElseFunc
            )
        end

    self.FactoryLedButton = ActionLedButtonHelper.createButton(
        function ()
            return self.BrowserModel:isUserMode()
        end,

        function (ActiveState)
            self.LedController:setLEDState(NI.HW.LED_LEFT, ButtonHelper.getLedStateFromActiveState(ActiveState))
        end,

        function ()
            SayIfTrainingModeElseFunc(
                FactoryLibraryText,
                function()
                    self.BrowserController:setUserMode(false)
                    self.Callbacks.openLibrarySwitchOverlay("Factory", "Library")
                end
            )
        end,

        NilReleaseActionFunc,

        function ()
            if self.AccessibilityModel:isTrainingMode() then
                self.AccessibilityController.say(FactoryLibraryText)
            end
        end
    )

    self.UserLedButton = ActionLedButtonHelper.createButton(
        function ()
            return not self.BrowserModel:isUserMode()
        end,

        function (ActiveState)
            self.LedController:setLEDState(NI.HW.LED_RIGHT, ButtonHelper.getLedStateFromActiveState(ActiveState))
        end,

        function ()
            SayIfTrainingModeElseFunc(
                UserLibraryText,
                function()
                    self.BrowserController:setUserMode(true)
                    self.Callbacks.openLibrarySwitchOverlay("User", "Library")
                end
            )
        end,

        NilReleaseActionFunc,

        function ()
            if self.AccessibilityModel:isTrainingMode() then
                self.AccessibilityController.say(UserLibraryText)
            end
        end
    )

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_LEFT, Shift = false },
        function(Pressed)
            self.FactoryLedButton:onPressed(Pressed)
            return true
        end
    )

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_RIGHT, Shift = false },
        function(Pressed)
            self.UserLedButton:onPressed(Pressed)
            return true
        end
    )

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:setupScreen()

    KH1062Page.setupScreen(self)

    self.Screen:setupScreen()
    self.Screen:showTextInBottomRow(true)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:onWheel(Delta)

    if self.AccessibilityModel:isTrainingMode() then
        return
    end
    local Increment = BrowseHelper.getIncrementStepMikroMK3(Delta, self.isShiftPressed())
    self:changeListFocus(Increment)
    self:sayBrowserListChange()

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:updateLEDs()

    if self:isShowing() then

        if self.isShiftPressed() then
            self.ShiftStateCallbacks.updateShiftStateLEDs(self)
        else
            self.FactoryLedButton:updateLed()
            self.UserLedButton:updateLed()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:updateScreen()

    self:updateLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:setIconToCurrentFileType()

    self.Screen:setTopRowIcon(string.lower(self.BrowserModel:getFileTypeName()), "")

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:onShow(Show)

    if Show then
        self.BrowserController:forceCacheRefresh()
    end

    KH1062Page.onShow(self, Show)

    if Show then
        self:updateFocusedItem()
        self.FactoryLedButton:onPressed(false)
        self.UserLedButton:onPressed(false)
        self:updateLEDs()
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase.toModelString(Model)

    local Names = {
        [NI.DB3.MODEL_BROWSER] = "MODEL_BROWSER",
        [NI.DB3.MODEL_BANKCHAIN] = "MODEL_BANKCHAIN",
        [NI.DB3.MODEL_ATTRIBUTES] = "MODEL_ATTRIBUTES",
        [NI.DB3.MODEL_RESULTS] = "MODEL_RESULTS",
        [NI.DB3.MODEL_PRODUCTS] = "MODEL_PRODUCTS"
    }

    return Names[Model]

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:onDB3ModelChanged(Model)

    Model = self.BrowserController:updateCachedData(Model)

    if Model == NI.DB3.MODEL_BANKCHAIN then
        self:updateLEDs()
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:updateScrollbar(ListSize, CurrentIndex)

    self.Screen.Scrollbar:setRange(ListSize, 1)
    self.Screen.Scrollbar:setValue(CurrentIndex, true)
    self.Screen.Scrollbar:setVisible(ListSize > 1)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:onNavPresetButton(Previous)

    if self.Callbacks.changeToResultPage then
        self.Callbacks:changeToResultPage()
    end
    self.BrowserController:changeResultListFocus(Previous and -1 or 1)
    self.BrowserController:loadSelectedResultListItem(false)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:getAccessibleItemLine()

    return self.Screen.BottomCaption:getText()

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:getAccessibilityData()

    local IsTrainingMode = self.AccessibilityModel:isTrainingMode()
    local MsgText = IsTrainingMode and "" or self:getAccessibleItemLine()
    if self.AppModel.getDatabaseScanInProgressParameter():getValue() then
        MsgText = MsgText .. ". Scan in progress"
    end

    return
    {
        Page = "Browser",
        Subtitle = self.Screen.TopCaption:getText(),
        Text = MsgText
    }

end

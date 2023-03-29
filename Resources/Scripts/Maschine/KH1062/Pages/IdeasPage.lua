local ButtonHelper = require("Scripts/Shared/KH1062/ButtonHelper")
require "Scripts/Shared/KH1062/Pages/KH1062Page"

require "Scripts/Maschine/Helper/PatternHelper"
local CreateGroupUtil = require("Scripts/Maschine/KH1062/CreateGroupUtil")
require "Scripts/Maschine/KH1062/DataController"
require "Scripts/Maschine/KH1062/DataModel"
local MuteSoloLedButtons = require("Scripts/Maschine/KH1062/MuteSoloLedButtons")

local FunctionChecker = require("Scripts/Shared/Components/FunctionChecker")
require "Scripts/Shared/Components/ScreenMikroASeriesBase"

local ActionLedButtonHelper = require("Scripts/Shared/Helpers/ActionLedButtonHelper")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
IdeasPage = class( 'IdeasPage', KH1062Page )

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:__init(PageName, ScreenStack, Environment, SwitchHandler, Callbacks)

    FunctionChecker.checkFunctionsExist(
        Callbacks,
        {"changeToGroupPage", "openConfirmActionOverlay", "openPatternLengthEditor"})

    KH1062Page.__init(self, ScreenMikroASeriesBase(PageName, ScreenStack), SwitchHandler)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_LEFT, Shift = false, Pressed = true },
                                        function()
                                            self:focusPreviousGroup()
                                        end)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_RIGHT, Shift = false, Pressed = true },
                                        function()
                                            self:focusNextGroup()
                                        end)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_UP, Shift = false, Pressed = true },
                                        function()
                                            self:focusPreviousPattern()
                                        end)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_DOWN, Shift = false, Pressed = true },
                                        function()
                                            self:focusNextPattern()
                                        end)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_LEFT, Shift = true, Pressed = true },
                                        function()
                                            self:focusPreviousScene()
                                        end)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_RIGHT, Shift = true, Pressed = true },
                                        function()
                                            self:focusNextScene()
                                        end)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL, Shift = false, Pressed = true },
                                        function()
                                            Callbacks.openPatternLengthEditor()
                                        end)

    self.Callbacks = Callbacks
    self.DataController = Environment.DataController
    self.ArrangerController = Environment.DataController.ArrangerController
    self.IdeaSpaceController = Environment.DataController.IdeaSpaceController
    self.DataModel = Environment.DataModel
    self.ArrangerModel = Environment.DataModel.ArrangerModel
    self.IdeaSpaceModel = Environment.DataModel.IdeaSpaceModel
    self.LedController = Environment.LedController

    self.MuteLedButton, self.SoloLedButton =
        MuteSoloLedButtons.createMuteSoloGroupLedButtons(Environment, self.SwitchEventTable)

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:setupScreen()

    KH1062Page.setupScreen(self)

    self.Screen:showTextInBottomRow()
               :setTopRowTextAttribute("bold")
               :setBottomRowTextAttribute("bold")

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:onShow(Show)

    KH1062Page.onShow(self, Show)

    if Show then

        if not self.ArrangerModel:isIdeaSpaceFocused() then
            self.ArrangerController:jumpToIdeaSpace()
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:focusPreviousGroup()

    if self.DataModel:isFocusGroupIndexValid() then
        self.DataController:setFocusGroup(self.DataModel:getOneBasedFocusGroupIndex() - 1)
    end

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:focusNextGroup()

    CreateGroupUtil.selectOrCreateNextGroup(
        self.Callbacks.openConfirmActionOverlay,
        self.DataModel,
        self.DataController)

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:focusPreviousScene()

    local SelectNext = false
    self.IdeaSpaceController:selectPrevNextScene(SelectNext)

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:focusNextScene()

    if self.IdeaSpaceModel:isOnLastScene() then
        self.Callbacks.openConfirmActionOverlay(
            "New Scene",
            NI.HW.BUTTON_WHEEL_LEFT,
            function() self.IdeaSpaceController:createScene() end
        )
    else
        local SelectNext = true
        self.IdeaSpaceController:selectPrevNextScene(SelectNext)
    end

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:focusPreviousPattern()

    local SelectNext = false
    self.IdeaSpaceController:focusPrevNextPattern(SelectNext)

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:focusNextPattern()

    if not self.ArrangerModel:isIdeaSpaceFocused() then return end

    if self.IdeaSpaceModel:isOnLastPattern() then
        self.Callbacks.openConfirmActionOverlay(
            "New Pattern",
            NI.HW.BUTTON_WHEEL_UP,
            function() self.IdeaSpaceController:createPattern() end
        )
    else
        local SelectNext = true
        self.IdeaSpaceController:focusPrevNextPattern(SelectNext)
    end

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:onStateFlagsChanged()

    if self.ArrangerModel:isIdeaSpaceFocusChanged() and not self.ArrangerModel:isIdeaSpaceFocused() then

        self.Callbacks.changeToGroupPage()
    end

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:updateScreen()

    if self.ArrangerModel:isIdeaSpaceFocused() then
        local FocusSceneName = self.IdeaSpaceModel:getFocusSceneName()
        local FocusGroupData = self.DataModel:getFocusGroupData()
        self.Screen
            :setTopRowText(FocusSceneName)
            :showTextInBottomRow()
            :setBottomRowIcon(FocusGroupData.IsMuted and "muted" or "object", FocusGroupData.GroupLabel)
            :setBottomRowText(self.IdeaSpaceModel:getFocusPatternName())
    end

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:updateLEDs()

    if self:isShowing() then
        if self.isShiftPressed() then
            self.MuteLedButton:updateLed()
            self.SoloLedButton:updateLed()
        else
            self.LedController:turnOffLEDs({ NI.HW.LED_LEFT, NI.HW.LED_RIGHT })
        end
    end

end

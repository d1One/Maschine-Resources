require "Scripts/Shared/KH1062/Pages/TwoLineMessagePage"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PageSwitchMessagePage = class( 'PageSwitchMessagePage', TwoLineMessagePage )

------------------------------------------------------------------------------------------------------------------------

function PageSwitchMessagePage:__init(PageName, Environment, SwitchHandler)

    TwoLineMessagePage.__init(self, PageName, Environment.ScreenStack, SwitchHandler)

    self.ParameterCacheModel = Environment.DataModel.ParameterCacheModel
    self.AccessibilityController = Environment.AccessibilityController

end

------------------------------------------------------------------------------------------------------------------------

function PageSwitchMessagePage:setupScreen()

    TwoLineMessagePage.setupScreen(self)
    NI.GUI.enableCropModeForLabel(self.LabelTop)

end

------------------------------------------------------------------------------------------------------------------------

function PageSwitchMessagePage:onShow(Show)

    TwoLineMessagePage.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function PageSwitchMessagePage:updateScreen()

    local PageName = self.ParameterCacheModel:getFocusedParameterPageName()
    local PageOfMessage = "Page " ..
        self.ParameterCacheModel:getFocusedParameterPageNumber() ..
        "/" ..
        self.ParameterCacheModel:getFocusedParameterPageCount()

    self:setMessage(PageName, PageOfMessage)
    self.AccessibilityController.say(PageName)

end
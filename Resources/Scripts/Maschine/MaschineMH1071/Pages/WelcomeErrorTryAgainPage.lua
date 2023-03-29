------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
WelcomeErrorTryAgainPage = class( 'WelcomeErrorTryAgainPage', PageMaschine )

local BUTTON_INDEX_TRY_AGAIN = 8

------------------------------------------------------------------------------------------------------------------------

function WelcomeErrorTryAgainPage:__init(Controller)

    PageMaschine.__init(self, "WelcomeErrorTryAgainPage", Controller)

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeErrorTryAgainPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeErrorTryAgainPage:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, { "", "", "", "" }, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, { "", "", "", "" }, "HeadButton")

    self.Screen.ScreenLeft.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "StudioDisplayBar")
    self.Screen.ScreenRight.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenRight, "StudioDisplayBar")

    self.Screen.ScreenLeft.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.Screen.ScreenRight.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    self.Icon = NI.GUI.insertBar(self.Screen.ScreenLeft.DisplayBar, "Icon")
    self.Icon:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.LeftLabel = NI.GUI.insertMultilineLabel(self.Screen.ScreenLeft.DisplayBar, "LabelLeft")
    self.LeftLabel:style("")
    self.LeftLabel:setText("Registration Failed")
    self.Screen.ScreenLeft.DisplayBar:setFlex(self.LeftLabel)

    self.Screen.ScreenLeft:setFlex(self.Screen.ScreenLeft.DisplayBar)
    self.Screen.ScreenRight:setFlex(self.Screen.ScreenRight.DisplayBar)

    self.ButtonBarLeft:setActive(false)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeErrorTryAgainPage:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[BUTTON_INDEX_TRY_AGAIN]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_TRY_AGAIN]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_TRY_AGAIN]:setSelected(false)
    self.Screen.ScreenButton[BUTTON_INDEX_TRY_AGAIN]:setText("TRY AGAIN")

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeErrorTryAgainPage:onScreenButton(Index, Pressed)

    local ShouldHandle = Pressed and self.Screen.ScreenButton[Index]:isEnabled()

    if ShouldHandle and Index == BUTTON_INDEX_TRY_AGAIN then

        NHLController:getPageStack():popPage()

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

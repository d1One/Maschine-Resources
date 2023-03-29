------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
WelcomeConfirmActivationPage = class( 'WelcomeConfirmActivationPage', PageMaschine )

local BUTTON_INDEX_CHANGE_LOGIN = 5
local BUTTON_INDEX_OK = 8

------------------------------------------------------------------------------------------------------------------------

function WelcomeConfirmActivationPage:__init(Controller)

    PageMaschine.__init(self, "WelcomeConfirmActivationPage", Controller)

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConfirmActivationPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConfirmActivationPage:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton")

    self.Screen.ScreenLeft.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "StudioDisplayBar")
    self.Screen.ScreenLeft.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.Screen.ScreenLeft:setFlex(self.Screen.ScreenLeft.DisplayBar)

    self.Icon = NI.GUI.insertBar(self.Screen.ScreenRight, "Icon")
    self.Icon:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.Label = NI.GUI.insertMultilineLabel(self.Screen.ScreenRight, "Label")
    self.Label:style("")
    self.Screen.ScreenRight:setFlex(self.Label)

    self.ButtonBarLeft:setActive(false)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConfirmActivationPage:updateScreens(ForceUpdate)

    if ForceUpdate then

        local Username = App:getActivationManager():getLoggedUsername()
        if Username ~= "" then

            self.Label:setText("Register to Native ID\n"..Username.."?")

        else

            self.Label:setText("Register MASCHINE+?")

        end

    end

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConfirmActivationPage:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[BUTTON_INDEX_CHANGE_LOGIN]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_CHANGE_LOGIN]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_CHANGE_LOGIN]:setSelected(false)
    self.Screen.ScreenButton[BUTTON_INDEX_CHANGE_LOGIN]:setText("CHANGE")

    self.Screen.ScreenButton[BUTTON_INDEX_OK]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_OK]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_OK]:setSelected(false)
    self.Screen.ScreenButton[BUTTON_INDEX_OK]:setText("OK")

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConfirmActivationPage:onScreenButton(Index, Pressed)

    local PageStack = NHLController:getPageStack()
    local ShouldHandle = Pressed and self.Screen.ScreenButton[Index]:isEnabled()

    if ShouldHandle and Index == BUTTON_INDEX_CHANGE_LOGIN then

        App:getActivationManager():logout()
        PageStack:replaceBottomPage(NI.HW.PAGE_LOGIN)

    elseif ShouldHandle and Index == BUTTON_INDEX_OK then

        PageStack:replaceBottomPage(NI.HW.PAGE_WELCOME_ACTIVATING)

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

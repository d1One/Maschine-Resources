------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
WelcomeActivatingPage = class( 'WelcomeActivatingPage', PageMaschine )

local RETRY_WAIT_TIME = 150
local RETRY_REMAINING_ATTEMPTS = 10

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function WelcomeActivatingPage:__init(Controller)

    PageMaschine.__init(self, "WelcomeActivatingPage", Controller)

    self.RetryRemainingAttemptsCountdown = 0
    self.RetryWaitTimeCountdown = 0

    self.onActivationSuccessfulFunction =
        function()
            NHLController:getPageStack():replaceBottomPage(NI.HW.PAGE_WELCOME_ACTIVATION_SUCCESSFUL)
        end

    self.onActivationCanceledFunction =
        function()
            local PageStack = NHLController:getPageStack()
            PageStack:pushPage(NI.HW.PAGE_WELCOME_ERROR_TRY_AGAIN)
            PageStack:replaceBottomPage(NI.HW.PAGE_WELCOME_CONFIRM_ACTIVATION)
        end

    self.onProductIsMissing =
        function()
            -- There is a very high chance that products will take a few seconds/minutes to show up in a user's list of
            -- owned products after being successfuly registered to an account. So we have a retry mechanism here that
            -- will wait a few frames and then try again. After too many unsuccessful tries, an error message is shown
            -- and the user is taken back to the previous page
            if self.RetryRemainingAttemptsCountdown > 0 then
                self.RetryRemainingAttemptsCountdown = self.RetryRemainingAttemptsCountdown - 1
                print("Trying again in a moment... #"..tostring(self.RetryRemainingAttemptsCountdown))
                self.RetryWaitTimeCountdown = RETRY_WAIT_TIME
            else
                local PageStack = NHLController:getPageStack()
                PageStack:pushPage(NI.HW.PAGE_WELCOME_ERROR_TRY_AGAIN)
                PageStack:replaceBottomPage(NI.HW.PAGE_WELCOME_CONFIRM_ACTIVATION)
            end
        end

    App:getActivationManager():setActivationSuccessfulCallback(self.onActivationSuccessfulFunction)
    App:getActivationManager():setActivationCanceledCallback(self.onActivationCanceledFunction)
    App:getActivationManager():setProductIsMissingCallback(self.onProductIsMissing)

    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeActivatingPage:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.Screen.ScreenLeft.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "StudioDisplayBar")
    self.Screen.ScreenRight.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenRight, "StudioDisplayBar")

    self.Screen.ScreenLeft.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.Screen.ScreenRight.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    self.Screen.ScreenLeft:setFlex(self.Screen.ScreenLeft.DisplayBar)
    self.Screen.ScreenRight:setFlex(self.Screen.ScreenRight.DisplayBar)

    self.LeftPicture = NI.GUI.insertBar(self.Screen.ScreenLeft.DisplayBar, "LeftPicture")
    self.LeftPicture:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.Screen.ScreenLeft.DisplayBar:setFlex(self.LeftPicture)

    self.ActivationLoop = NI.GUI.insertAnimation(self.Screen.ScreenRight.DisplayBar, "ActivationLoop")
    self.ActivationLoop:style("")
    self.RightTitle = NI.GUI.insertLabel(self.Screen.ScreenRight.DisplayBar, "RightTitle")
    self.RightTitle:style("", "")
    self.RightTitle:setText("Registering your MASCHINE+")

    self.RightSubtitle = NI.GUI.insertLabel(self.Screen.ScreenRight.DisplayBar, "RightSubtitle")
    self.RightSubtitle:style("", "")
    self.RightSubtitle:setText("This may take a few moments.")

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeActivatingPage:onShow(Show)

    if Show then

        if self.Controller.turnOffAllPageLEDs then
            self.Controller:turnOffAllPageLEDs()
            LEDHelper.turnOffLEDs(HardwareControllerBase.SCREEN_BUTTON_LEDS)
        else
            NHLController:resetAllLEDs()
        end
        App:getActivationManager():activateWithHardwareSerial(NHLController:getControllerModel())
        self.RetryRemainingAttemptsCountdown = RETRY_REMAINING_ATTEMPTS
        self.RetryWaitTimeCountdown = 0

    else

        self.RetryRemainingAttemptsCountdown = 0
        self.RetryWaitTimeCountdown = 0

    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeActivatingPage:onControllerTimer()

    if self.RetryWaitTimeCountdown > 0 then

        self.RetryWaitTimeCountdown = self.RetryWaitTimeCountdown - 1

        if self.RetryWaitTimeCountdown == 0 then

            App:getActivationManager():retrieveOwnedProductsAndActivate()

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

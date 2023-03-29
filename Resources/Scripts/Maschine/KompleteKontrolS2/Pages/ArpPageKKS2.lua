------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/ArpPage"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ArpPageKKS2 = class( 'ArpPageKKS2', ArpPage )

------------------------------------------------------------------------------------------------------------------------

function ArpPageKKS2:__init(Controller)

    ArpPage.__init(self, Controller)

end

------------------------------------------------------------------------------------------------------------------------

function ArpPageKKS2:setupScreen()

    ArpPage.setupScreen(self)

    self.Screen.ScreenButton[2]:setVisible(true)
    self.Screen.ScreenButton[2]:setEnabled(true)
    self.Screen.ScreenButton[2]:setText("LOCK")

    self.ParameterHandler.UseCache = false

end

------------------------------------------------------------------------------------------------------------------------

function ArpPageKKS2:updateScreens()

    ArpPage.updateScreens(self)

    self.Screen.ScreenButton[1]:setText(MaschineHelper.isDrumkitMode() and "NOTE RPT" or "ARP")
    self.Screen.ScreenButton[2]:setSelected(MaschineHelper.isArpRepeatLocked())

end

------------------------------------------------------------------------------------------------------------------------

function ArpPageKKS2:updateLEDs()

    LEDHelper.setLEDState(NI.HW.LED_CLEAR, LEDHelper.LS_OFF)
end

------------------------------------------------------------------------------------------------------------------------

function ArpPageKKS2:onScreenButton(ButtonIdx, Pressed)

    if Pressed and ButtonIdx == 2 then
        MaschineHelper.toggleArpRepeatLockState()
    end

    ArpPage.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------


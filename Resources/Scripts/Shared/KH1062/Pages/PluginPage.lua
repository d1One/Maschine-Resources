require "Scripts/Shared/Components/ScreenMikroASeriesBase"
require "Scripts/Shared/KH1062/Pages/KH1062Page"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PluginPage = class( 'PluginPage', KH1062Page )

------------------------------------------------------------------------------------------------------------------------

function PluginPage:__init(PageName, ScreenStack, SwitchHandler, getFocusedPluginInfo, updateScreenFromPluginInfo,
                            ChainCallbacks, ShiftStateCallbacks)

    self.getFocusedPluginInfo = getFocusedPluginInfo
    self.updateScreenFromPluginInfo = updateScreenFromPluginInfo

    KH1062Page.__init(self, ScreenMikroASeriesBase(PageName, ScreenStack), SwitchHandler)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_LEFT, Shift = false, Pressed = true },
                                       function() ChainCallbacks.onShiftSlotFocus(-1) end)
    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_RIGHT, Shift = false, Pressed = true },
                                       function() ChainCallbacks.onShiftSlotFocus(1) end)
    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_LEFT, Shift = true, Pressed = true },
                                       function() ChainCallbacks.onMoveFocusSlot(-1) end)
    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_RIGHT, Shift = true, Pressed = true },
                                       function() ChainCallbacks.onMoveFocusSlot(1) end)
    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_UP, Shift = true, Pressed = true },
                                       function () ChainCallbacks.onRemoveFocusSlot() end)
    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL, Shift = true, Pressed = true },
                                       function () ChainCallbacks.onToggleFocusSlotActive() end)

    self.ShiftStateCallbacks = KH1062Page.defaultMissingCallbacks(ShiftStateCallbacks,
                                                                    {"createShiftStateButtons", "updateShiftStateLEDs"})
    self.ShiftStateCallbacks.createShiftStateButtons(self)

end

------------------------------------------------------------------------------------------------------------------------

function PluginPage:updateScreen(ForceUpdate)

    self.updateScreenFromPluginInfo(self.getFocusedPluginInfo(), self.Screen)

end

------------------------------------------------------------------------------------------------------------------------

function PluginPage:updateLEDs()

    if self:isShowing() then
        if self.isShiftPressed() then
            self.ShiftStateCallbacks.updateShiftStateLEDs(self)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function PluginPage.renderPressBrowserMessage(Screen)

    Screen:setTopRowText("Press")
          :setTopRowTextAttribute("boldCenter")
          :setTopRowIcon()
          :setBottomRowText("BROWSER")
          :setBottomRowTextAttribute("boldCenter")
          :setBottomRowIcon()

end
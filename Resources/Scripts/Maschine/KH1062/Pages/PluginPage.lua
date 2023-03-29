local MuteSoloLedButtons = require("Scripts/Maschine/KH1062/MuteSoloLedButtons")
require "Scripts/Shared/KH1062/Pages/PluginPage"

------------------------------------------------------------------------------------------------------------------------

local StyleMap = {
    [true] = {
        [NI.DATA.ModuleInfo.TYPE_INSTRUMENT] = "instrument",
        [NI.DATA.ModuleInfo.TYPE_EFFECT] = "effect"
    },
    [false] = {
        [NI.DATA.ModuleInfo.TYPE_INSTRUMENT] = "instrument_Bypassed",
        [NI.DATA.ModuleInfo.TYPE_EFFECT] = "effect_Bypassed"
    }
}

------------------------------------------------------------------------------------------------------------------------

local function getStyle(FocusSlot)

    if not FocusSlot.ModuleType then
        return "missing"
    end

    local Style = StyleMap[FocusSlot.IsActive][FocusSlot.ModuleType]
    return Style and Style or ""

end

------------------------------------------------------------------------------------------------------------------------

local function updateScreen(ChainInfo, Screen)

    if not (ChainInfo and ChainInfo.FocusSound) then
        return
    end

    if ChainInfo.ChainSize == 0 then
        PluginPage.renderPressBrowserMessage(Screen)
    else
        local FocusSound = ChainInfo.FocusSound
        local FocusSlot = ChainInfo.FocusSlot
        local SlotDisplayName = FocusSlot and FocusSlot.DisplayName or ""
        Screen:setTopRowText(FocusSound.DisplayName)
              :setTopRowTextAttribute("bold")
              :setTopRowIcon(FocusSound.IsMuted and "muted" or "labelCenter", tostring(FocusSound.OneBasedIndex))
              :setBottomRowText(#SlotDisplayName > 0 and SlotDisplayName or "Empty Slot")
              :setBottomRowTextAttribute("")
              :setBottomRowIcon(FocusSlot and getStyle(FocusSlot) or "")
    end

end

------------------------------------------------------------------------------------------------------------------------

local function createPluginPage(PageName, Environment, SwitchHandler, getFocusedChainInfo, ChainCallbacks)

    local ScreenStack = Environment.ScreenStack
    local LedController = Environment.LedController

    local MuteSoloCallbacks = {

        createShiftStateButtons = function (Page)
            Page.MuteLedButton, Page.SoloLedButton =
                MuteSoloLedButtons.createMuteSoloSoundLedButtons(Environment, Page.SwitchEventTable)
        end,

        updateShiftStateLEDs = function (Page)
            Page.MuteLedButton:updateLed()
            Page.SoloLedButton:updateLed()
        end

    }

    return PluginPage(PageName, ScreenStack, SwitchHandler, getFocusedChainInfo, updateScreen,
                      ChainCallbacks, MuteSoloCallbacks)

end

------------------------------------------------------------------------------------------------------------------------

return createPluginPage
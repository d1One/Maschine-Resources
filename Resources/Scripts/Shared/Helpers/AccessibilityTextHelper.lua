------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
AccessibilityTextHelper = class( 'AccessibilityTextHelper' )

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.getPageEntireText(PageData)

    return PageData and PageData.Page .. " " .. PageData.Subtitle .. " " .. PageData.Text or ""

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.getPageSubtitleAndText(PageData)

    if not PageData then
        return ""
    end
    local Text = PageData.Subtitle or ""
    local function hasPageDataText()
        return PageData.Text and #PageData.Text > 0
    end
    if hasPageDataText() then
        Text = Text .. " " .. PageData.Text
    end
    return  Text

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.getPageTextOnly(PageData)

    return PageData and PageData.Text or ""

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.getOnOffFieldText(Name, IsOn)

    local SpeechString = Name and Name or ""
    return SpeechString .. ", " .. (IsOn and "ON" or "OFF")

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.getFocusPluginText(PluginName, SlotIndex, NumSlotsFunc)

    local PluginNameOrEmptySlot = (SlotIndex == NPOS or SlotIndex > NumSlotsFunc()) and "Empty Slot" or PluginName
    local SlotIndexOrNumSlots = (SlotIndex == NPOS and NumSlotsFunc() + 1 or SlotIndex)

    return "Slot " .. SlotIndexOrNumSlots .. ", " .. PluginNameOrEmptySlot

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.getFocusPluginMessage()

    local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
    if not Slots then
        return ""
    end

    local SlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)
    local PluginName = NI.DATA.SlotAlgorithms.getDisplayName(Slots:at(SlotIndex))

    PluginName = SlotIndex == -1 and "Empty Slot" or PluginName
    SlotIndex = (SlotIndex == -1 and Slots:size() or SlotIndex) + 1

    return "Slot " .. SlotIndex .. ", " .. PluginName

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.getMovedPluginMessage()

    local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
    local SlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)
    if not Slots or SlotIndex == NPOS then
        return ""
    end

    local PluginName = NI.DATA.SlotAlgorithms.getDisplayName(Slots:at(SlotIndex))

    return "Moved " .. PluginName .. " to Slot " .. SlotIndex + 1

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.getMovedPluginText(PluginName, SlotIndexOneBased)

    return "Moved " .. PluginName .. " to Slot " .. SlotIndexOneBased

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.getGroupName(Name)
    return AccessibilityTextHelper.prefixString(Name, "group")
end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.getPatternName(Name)
    return AccessibilityTextHelper.prefixString(Name, "pattern")
end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.getSoundName(Name)
    return AccessibilityTextHelper.prefixString(Name, "sound")
end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.getSceneName(Name)
    return AccessibilityTextHelper.prefixString(Name, "scene")
end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.prefixString(String, Prefix)
    Prefix = Prefix:lower()
    if string.sub(String, 1, string.len(Prefix)):lower() ~= Prefix then
        String = Prefix .. " " .. String
    end
    return String
end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityTextHelper.replaceWord(String, Find, Replace)
    String = String:lower():gsub(
        "%f[%a]" .. Find:lower() .. "%f[%A]",
        Replace
    )

    return String
end

------------------------------------------------------------------------------------------------------------------------

return AccessibilityTextHelper

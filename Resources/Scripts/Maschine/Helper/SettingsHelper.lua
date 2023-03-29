------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SettingsHelper = class( 'SettingsHelper' )

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getPaletteIndexes()

    local Colors = {}

    for Index = 0, NI.DATA.COLOR_PALETTE_MAX do

        table.insert(Colors, Index)

    end

    return Colors

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getColorsAsStrings(List)

    local Values = {}

    for Index = 1, #List do

        table.insert(Values, NI.DATA.DefaultColorInfo.getColorName(List[Index]))

    end

    return Values

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getSceneColorsList()

    local Values = SettingsHelper.getPaletteIndexes()

    -- White
    table.insert(Values, NI.DATA.COLOR_WHITE)

    -- Auto
    table.insert(Values, NI.DATA.COLOR_AUTO)

    return Values

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getGroupColorsList()

    local Values = SettingsHelper.getPaletteIndexes()

    -- Auto
    table.insert(Values, NI.DATA.COLOR_AUTO)

    return Values

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getSoundColorsList()

    local Values = SettingsHelper.getPaletteIndexes()

    -- Use Group Color
    table.insert(Values, NI.DATA.COLOR_USE_GROUPCOLOR)

    -- Auto
    table.insert(Values, NI.DATA.COLOR_AUTO)

    return Values

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getSceneColorsAsStrings()

    return SettingsHelper.getColorsAsStrings(SettingsHelper.getSceneColorsList())

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getGroupColorsAsStrings()

    return SettingsHelper.getColorsAsStrings(SettingsHelper.getGroupColorsList())

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getSoundColorsAsStrings()

    return SettingsHelper.getColorsAsStrings(SettingsHelper.getSoundColorsList())

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getCurrentSceneColorName()

    local Preferences = NI.APP.Preferences.getColors()
    local Color = Preferences:getSceneColorSetting()
    return NI.DATA.DefaultColorInfo.getColorName(Color)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getCurrentGroupColorName()

    local Preferences = NI.APP.Preferences.getColors()
    local Color = Preferences:getGroupColorSetting()
    return NI.DATA.DefaultColorInfo.getColorName(Color)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getCurrentSoundColorName()

    local Preferences = NI.APP.Preferences.getColors()
    local Color = Preferences:getSoundColorSetting()
    return NI.DATA.DefaultColorInfo.getColorName(Color)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.selectPrevNextSceneColor(Next)

    local Preferences = NI.APP.Preferences.getColors()
    local SceneColors = SettingsHelper.getSceneColorsList()
    local Current = Preferences:getSceneColorSetting()
    local Index = table.findKey(SceneColors, Current)

    Index = math.bound(Index + (Next and 1 or -1), 1, #SceneColors)

    local Preferences = NI.APP.Preferences.getColors()
    Preferences:setSceneColorSetting(SceneColors[Index])
    Preferences:write()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.selectPrevNextGroupColor(Next)

    local Preferences = NI.APP.Preferences.getColors()
    local GroupColors = SettingsHelper.getGroupColorsList()
    local Current = Preferences:getGroupColorSetting()
    local Index = table.findKey(GroupColors, Current)

    Index = math.bound(Index + (Next and 1 or -1), 1, #GroupColors)

    local Preferences = NI.APP.Preferences.getColors()
    Preferences:setGroupColorSetting(GroupColors[Index])
    Preferences:write()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.selectPrevNextSoundColor(Next)

    local Preferences = NI.APP.Preferences.getColors()
    local SoundColors = SettingsHelper.getSoundColorsList()
    local Current = Preferences:getSoundColorSetting()
    local Index = table.findKey(SoundColors, Current)

    Index = math.bound(Index + (Next and 1 or -1), 1, #SoundColors)

    local Preferences = NI.APP.Preferences.getColors()
    Preferences:setSoundColorSetting(SoundColors[Index])
    Preferences:write()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.isLoadWithColors()

    local Preferences = NI.APP.Preferences.getColors()
    return Preferences:isLoadWithColors()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.setLoadWithColors(Enabled)

    local Preferences = NI.APP.Preferences.getColors()
    Preferences:setLoadWithColors(Enabled)
    Preferences:write()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getLoadLastProjectAtStartup()

    local Preferences = NI.APP.Preferences.getGeneral()
    return Preferences:getLoadLastProjectAtStartup()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.setLoadLastProjectAtStartup(Enabled)

    local Preferences = NI.APP.Preferences.getGeneral()
    Preferences:setLoadLastProjectAtStartup(Enabled)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getPatternAutoGrow()

    local Preferences = NI.APP.Preferences.getGeneral()
    return Preferences:getPatternAutoGrow()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.setPatternAutoGrow(Enabled)

    local Preferences = NI.APP.Preferences.getGeneral()
    Preferences:setPatternAutoGrow(Enabled)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.getPatternDefaultLength()

    local Preferences = NI.APP.Preferences.getGeneral()
    local Bar = Preferences:getPatternLengthBars()
    local Beat = Preferences:getPatternLengthBeats()
    local Sixteenths = Preferences:getPatternLengthSixteenths()

    return tostring(Bar)..":"..tostring(Beat)..":"..tostring(Sixteenths)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsHelper.isOverConnectedWiFi(WiFiList)

    local Workspace = App:getWorkspace()
    local WiFiStatusParameter = Workspace and Workspace:getWiFiStatusParameter() or nil
    local IsConnected = WiFiStatusParameter and WiFiStatusParameter:getValue() == NI.DATA.WIFI_STATUS_CONNECTED or false
    local WiFiSSIDParameter = Workspace and Workspace:getWiFiSSIDParameter() or nil
    local WiFiSSID = WiFiSSIDParameter and WiFiSSIDParameter:getValue() or ""

    return IsConnected and WiFiSSID == WiFiList:getSelectedItem() or false

end

------------------------------------------------------------------------------------------------------------------------

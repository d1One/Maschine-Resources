------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/InfoBarBase"

require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/ScreenHelper"

local ATTR_ICON = NI.UTILS.Symbol("icon")
local ATTR_ONE = NI.UTILS.Symbol("one")
local ATTR_STYLE = NI.UTILS.Symbol("style")
local ATTR_WITH_ICON = NI.UTILS.Symbol("with-icon")

------------------------------------------------------------------------------------------------------------------------
-- Generic Mikro MK3 screen

local class = require 'Scripts/Shared/Helpers/classy'
ScreenMikroMK3 = class( 'ScreenMikroMK3' )

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:__init(Page)

    self:setupScreen(Page)

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:onPageShow()

    NHLController:getHardwareDisplay():getPageStack():setTop(self.RootBar)

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setupScreen(Page)

    self.RootBar = NI.GUI.createBar()
    self.RootBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    local ScreenStack = NHLController:getHardwareDisplay():getPageStack()
    NI.GUI.insertPage(ScreenStack, self.RootBar, Page.Name)

    self.RootBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "bar")

    -- Container for Top+Bottom Lines
    self.Main = NI.GUI.insertBar(self.RootBar, "Main")
    self.Main:style(NI.GUI.ALIGN_WIDGET_DOWN, "bar")
    self.RootBar:setFlex(self.Main)

    -- Top Line
    self.TopBar = NI.GUI.insertBar(self.Main, "TopBar")
    self.TopBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "bar")
    self.TopIcon = NI.GUI.insertLabel(self.TopBar, "TopIcon")
    self.TopIcon:style("", "label")
    self.TopCaption = NI.GUI.insertLabel(self.TopBar, "TopCaption")
    self.TopCaption:style("", "label")

    self.TopBar:setFlex(self.TopCaption)
    NI.GUI.enableCropModeForLabel(self.TopCaption)

    -- Bottom Line with Icon and Text
    self.BottomBar = NI.GUI.insertBar(self.Main, "BottomBar")
    self.BottomBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "bar")
    self.BottomIcon = NI.GUI.insertLabel(self.BottomBar, "BottomIcon")
    self.BottomIcon:style("", "label")
    self.BottomCaption = NI.GUI.insertLabel(self.BottomBar, "BottomCaption")
    self.BottomCaption:style("", "label")

    self.BottomBar:setFlex(self.BottomCaption)
    NI.GUI.enableCropModeForLabel(self.BottomCaption)

    -- Bottom Line with Parameter
    self.ParameterBar = NI.GUI.insertBar(self.BottomBar, "ParameterBar")
    self.ParameterBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "bar")
    self.ParameterName = NI.GUI.insertLabel(self.ParameterBar, "ParameterName")
    self.ParameterName:style("", "label")
    self.ParameterValue = NI.GUI.insertLabel(self.ParameterBar, "ParameterValue")
    self.ParameterValue:style("", "label")

    self.ParameterBar:setFlex(self.ParameterName)
    self.ParameterValue:setAutoResize(true)
    NI.GUI.enableAbbreviationModeForLabel(self.ParameterName)
    NI.GUI.enableAbbreviationModeForLabel(self.ParameterValue)

    -- Scrollbar
    self.Scrollbar = NI.GUI.insertScrollbar(self.RootBar, "Scrollbar")
    self.Scrollbar:setAutohide(true)
    self.Scrollbar:setShowIncDecButtons(false)
    self.Scrollbar:style(false, 0, 0, "Scrollbar")

    -- Setup initial state
    self:setTopRowIcon()
    self:setBottomRowIcon()
    self:showTextInBottomRow()

end

------------------------------------------------------------------------------------------------------------------------

local function setIcon(Icon, Attribute, Text)

    Icon:setActive(Attribute and Attribute ~= "" or false)
    if Attribute then
        Icon:setAttribute(ATTR_ICON, Attribute)
    end

    Icon:setText(Text or "")

end

------------------------------------------------------------------------------------------------------------------------
-- If Attribute evaluates to false or empty string, the icon is hidden. Text is optional
------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setTopRowIcon(Attribute, Text)

    setIcon(self.TopIcon, Attribute, Text)
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setTopRowText(Text)

    self.TopCaption:setText(Text or "")
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setTopRowTextAttribute(Attribute)

    self.TopCaption:setAttribute(ATTR_STYLE, Attribute or "")
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setTopRowToSound(Sound, Index)

    if Sound then
        -- this is needed in order to display the "1" and "11" centered
        self.TopIcon:setAttribute(ATTR_ONE, (Index == 0 or Index == 10) and "true" or "false")

        if NI.DATA.SoundAlgorithms.hasLocationIssues(Sound) then
            self:setTopRowIcon("missing", "")
        else
            self:setTopRowIcon(Sound:getMuteParameter():getValue() and "muted" or "object", tostring(Index + 1))
        end

        self:setTopRowText(Sound:getDisplayName())
    else
        self:setTopRowIcon("", "")
        self:setTopRowText("No Selection")
    end

    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setTopRowToFocusedSound()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    self:setTopRowToSound(Sound, NI.DATA.StateHelper.getFocusSoundIndex(App))
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setTopRowToGroup(Group, Index)

    if Group then
        if NI.DATA.GroupAlgorithms.hasLocationIssues(Group) then
            self:setTopRowIcon("missing", "")
        else
            self:setTopRowIcon(Group:getMuteParameter():getValue() and "muted" or "object", NI.DATA.Group.getLabel(Index))
        end

        self:setTopRowText(Group:getDisplayName())
    else
        self:setTopRowIcon("", "")
        self:setTopRowText("No Selection")
    end

    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setTopRowToFocusedGroup()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Index = NI.DATA.StateHelper.getFocusGroupIndex(App)
    self:setTopRowToGroup(Group, Index)

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setTopRowToMaster()

    self:setTopRowIcon("labelBoldCenter", "M")
    self:setTopRowText(App:getProject():getCurrentProjectDisplayName())

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setTopRowToFocusedObject()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local LevelTab = Song and Song:getLevelTab() or NI.DATA.LEVEL_TAB_SONG

    if LevelTab == NI.DATA.LEVEL_TAB_SONG then
        self:setTopRowToMaster()

    elseif LevelTab == NI.DATA.LEVEL_TAB_GROUP then
        self:setTopRowToFocusedGroup()

    elseif LevelTab == NI.DATA.LEVEL_TAB_SOUND then
        self:setTopRowToFocusedSound()
    end

    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:showTextInBottomRow()

    self.ParameterBar:setActive(false)
    self.BottomCaption:setActive(true)
    self.BottomBar:setFlex(self.BottomCaption)
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:showParameterInBottomRow()

    self.ParameterBar:setActive(true)
    self.BottomCaption:setActive(false)
    self.BottomBar:setFlex(self.ParameterBar)
    return self

end

------------------------------------------------------------------------------------------------------------------------
-- If Attribute evaluates to false or empty string, the icon is hidden. Text is optional
------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setBottomRowIcon(Attribute, Text)

    setIcon(self.BottomIcon, Attribute, Text)
    self.BottomBar:setAttribute(ATTR_WITH_ICON, tostring(self.BottomIcon:isActive()))
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setBottomRowText(Text)

    self.BottomCaption:setText(Text or "")
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setBottomRowTextAttribute(Attribute)

    self.BottomCaption:setAttribute(ATTR_STYLE, Attribute or "")
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setBottomRowToParameter(Parameter)

    self:showParameterInBottomRow()

    if not Parameter then
        self:setParameterName("")
        self:setParameterValue("")
    elseif Parameter.name and Parameter.maschineParameter then
        -- new-style InputHandler parameters
        self:setParameterName(Parameter:name())
        self:setParameterValue(Parameter:valueStringShort())
    else
        -- "classic" parameter
        self:setParameterName(Parameter:getName())
        self:setParameterValue(Parameter:getValueString())
    end

    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setBottomRowToFocusedPageParameter()

    return self:setBottomRowToParameter(NHLController:focusedParameter())

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setParameterName(Name)

    self.ParameterName:setText(Name or "")
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:cropParameterName()

    NI.GUI.enableCropModeForLabel(self.ParameterName)
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setParameterValue(Value)

    if Value and type(Value) ~= "string" then
        Value = tostring(Value)
    end

    self.ParameterValue:setText(Value or "")
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setSceneBankParameter()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local NumScenes = Song:getScenes():size()
    local BankIndex = Song:getFocusSceneBankIndexParameter():getValue() + 1

    local NumBanks = math.ceil(NumScenes / NI.UTILS.CONST_SCENES_PER_BANK)
    local BankFull = (NumScenes % NI.UTILS.CONST_SCENES_PER_BANK) == 0

    self:setParameterName("Bank")
        :setParameterValue(tostring(BankIndex) .. "/" .. tostring(BankFull and NumBanks + 1 or NumBanks))
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setSectionBankParameter()

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if not Song then
        return ""
    end

    local BankIndex = Song:getFocusSectionBankIndexParameter():getValue() + 1 or 0 -- 0 indexed
    local NumBanks =  Song:getNumSectionBanksParameter():getValue() or 0
    local NumBanksShow = ArrangerHelper.canAddSectionBank() and NumBanks + 1 or NumBanks

    self:setParameterName("Bank")
        :setParameterValue(tostring(BankIndex) .. "/" .. tostring(NumBanksShow))

    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:updateScrollbar(Total, Value)

    self.Scrollbar:setRange(Total, 1)
    self.Scrollbar:setValue(Value, true)
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroMK3:setPatternBankParameter(CurrentPosition, NumPatterns) -- CurrentPosition 0 indexed

    self:setParameterName("Bank")
        :setParameterValue((CurrentPosition + 1) .. "/" .. NumPatterns)
    return self

end

------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschine"
require "Scripts/Shared/Helpers/ControlHelper"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MixerPage = class( 'MixerPage', PageMaschine )

MixerPage.MixParamNames = {"LEVEL", "PAN"} -- It's possible to extend this list

MixerPage.ParamLevel = 1
MixerPage.ParamPan   = 2

------------------------------------------------------------------------------------------------------------------------

function MixerPage:__init(Controller)

    -- init base class
    PageMaschine.__init(self, "MixerPage", Controller)

    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SAMPLE }

end

------------------------------------------------------------------------------------------------------------------------

function MixerPage:setupScreen()

    -- setup screen
    self.Screen = ScreenMaschine(self)

    -- Left screen
    self.Screen:addScreenButtonBar(self.Screen.ScreenLeft,
        {" ", "GROUP", "SOUND", " "}, "HeadTab")
    self.Screen.ScreenButton[1]:setEnabled(false)
    self.Screen.ScreenButton[4]:setEnabled(false)
    self.Screen.InfoBar = InfoBar(self.Controller, self.Screen.ScreenLeft)
    self.Screen:addParameterBar(self.Screen.ScreenLeft)

    -- Right screen
    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"<<", ">>", "", ""}, "HeadButton")
    self.Screen.InfoBarRight = InfoBar(self.Controller, self.Screen.ScreenRight, "RightScreenDefault")
    self.Screen:addParameterBar(self.Screen.ScreenRight)

    self.MixParamIndex = 1
    self.SoundGroupIndex = 0 -- 0: Sounds 1-8, 1: Sounds 9-16 are active

end

------------------------------------------------------------------------------------------------------------------------

function MixerPage:onPageButton(Button, PageID, Pressed)

    -- Ensure that we get back to control, if sampling is pressed
    if (Pressed and Button == NI.HW.BUTTON_SAMPLE) then
        if self.Controller:getShiftPressed() then
            NHLController:getPageStack():replacePage(NI.HW.PAGE_MIXER, NI.HW.PAGE_SAMPLING)
        else
            PageMaschine.onControlButton(self, Pressed)
        end
        return true
    end

    -- call base class otherwise
    return PageMaschine.onPageButton(self, Button, PageID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPage:onScreenButton(ButtonIdx, Pressed)

    local Button = self.Screen.ScreenButton[ButtonIdx]

    if Pressed and Button and Button:isEnabled() then

        if (ButtonIdx == 2 or ButtonIdx == 3) then

            MaschineHelper.setFocusLevelTab(ButtonIdx - 1)

        elseif (ButtonIdx == 5 or ButtonIdx == 6) then

            local Delta = ButtonIdx == 5 and -1 or 1
            self.MixParamIndex = math.wrap(self.MixParamIndex + Delta, 1, #MixerPage.MixParamNames)

        end

    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPage:onPadEvent(PadIndex, Pressed, PadValue)

    self.SoundGroupIndex = NI.DATA.StateHelper.getFocusSoundIndex(App) < 8 and 0 or 1

    self:updateScreens(false)

    PageMaschine.onPadEvent(self, PadIndex, Pressed, PadValue)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPage:updateScreenButtons(ForceUpdate)

    local Level = MaschineHelper.getLevelTab()

    self.Screen.ScreenButton[2]:setSelected(Level == NI.DATA.LEVEL_TAB_GROUP or Level == NI.DATA.LEVEL_TAB_SONG)
    self.Screen.ScreenButton[2]:setText("GROUP")

    if NI.DATA.StateHelper.getFocusGroup(App) then
        self.Screen.ScreenButton[3]:setText("SOUND")
        self.Screen.ScreenButton[3]:setEnabled(true)
        self.Screen.ScreenButton[3]:setSelected(Level == NI.DATA.LEVEL_TAB_SOUND)
    end

    -- Call base
    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPage:updateScreens(ForceUpdate)

    local StateCache = App:getStateCache()
    if NI.DATA.StateHelper.getFocusSong(App) then

        self.Screen:setArrowText(1, MixerPage.MixParamNames[self.MixParamIndex])

        if ForceUpdate or StateCache:isFocusGroupChanged()
            or StateCache:isGroupsChanged()
            or StateCache:isFocusSoundChanged()
            or StateCache:isMixingLayerChanged() then

            self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()
            self.SoundGroupIndex = NI.DATA.StateHelper.getFocusSoundIndex(App) < 8 and 0 or 1
        end

    end

    -- call base class updateScreens
    PageMaschine.updateScreens(self, ForceUpdate)

    self:updateLeftRightLeds()

end

------------------------------------------------------------------------------------------------------------------------

function MixerPage:setParametersFromObjects(Objects)

    local Parameters = {}
    local Sections = {}
    local Names = {}
    local Values = {}

    for i = 1, 8 do

        local Object = Objects[i]
        if Object then

            local Param

            Sections[i] = Object[2]

            Object = Object[1] -- Other part is not needed anymore

            -- Either LEVEL or PAN (may be extended -> no short if)
            if self.MixParamIndex == MixerPage.ParamLevel then
                Param = Object:getLevelParameter()

            elseif self.MixParamIndex == MixerPage.ParamPan then
                Param = Object:getPanParameter()
            end

            Parameters[i] = Param

            Names[i]  = Object:getDisplayName()
            Values[i] = Param and Param:getAsString(Param:getValue()) or ""
        end

        self.ParameterHandler:enableCropModeForName(i)


    end

    self.ParameterHandler:setParameters(Parameters, true)
    self.ParameterHandler:setCustomSections(Sections)
    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomValues(Values)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPage:updateParameters(ForceUpdate)

    if not NI.DATA.StateHelper.getFocusGroup(App) then
        return
    end

    local Level = MaschineHelper.getLevelTab()

    local Objects = {}

    local Index

    if Level == NI.DATA.LEVEL_TAB_GROUP or Level == NI.DATA.LEVEL_TAB_SONG then

        local Song   = NI.DATA.StateHelper.getFocusSong(App)
        local Groups = Song and Song:getGroups() or nil

        local GroupStart   = self.Screen.GroupBank * 8
        local GroupEnd     = (GroupStart + 8 < Groups:size() and GroupStart + 8 or Groups:size()) - 1

        for i=GroupStart,GroupEnd do

            Index = i - GroupStart + 1
            Objects[Index] = {}

            Objects[Index][1] = Groups:at(i)
            Objects[Index][2] = NI.DATA.Group.getLabel(i)

        end

    elseif Level == NI.DATA.LEVEL_TAB_SOUND then

        local Group  = NI.DATA.StateHelper.getFocusGroup(App)
        if Group then
            local Sounds = Group:getSounds()

            for i=1,8 do
                Index = i + self.SoundGroupIndex * 8
                Objects[i] = {}

                Objects[i][1] = Sounds:at(Index - 1)
                Objects[i][2] = string.format("%d", Index)
            end
        end

    end

    self:setParametersFromObjects(Objects)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPage:onLeftRightButton(Right, Pressed)

    local Level = MaschineHelper.getLevelTab()

	if Pressed then

        if Level == NI.DATA.LEVEL_TAB_SOUND then
            self.SoundGroupIndex = Right and 1 or 0 -- can only be 1 or 0 depending on L/R button

        elseif Level == NI.DATA.LEVEL_TAB_GROUP or Level == NI.DATA.LEVEL_TAB_SONG then
            local NumBankGroups = MaschineHelper.getNumFocusSongGroupBanks() - 1
            self.Screen.GroupBank = math.bound(Right and self.Screen.GroupBank + 1 or self.Screen.GroupBank - 1, 0, NumBankGroups)
        end

        self:updateParameters()

    end

    self:updateLeftRightLeds() -- Always update

end

------------------------------------------------------------------------------------------------------------------------

function MixerPage:updateLeftRightLeds()

    local Level = MaschineHelper.getLevelTab()

    if Level == NI.DATA.LEVEL_TAB_SOUND then
        LEDHelper.updateLeftRightLEDsWithParameters(self.Controller, 2, self.SoundGroupIndex + 1)

    elseif Level == NI.DATA.LEVEL_TAB_GROUP or Level == NI.DATA.LEVEL_TAB_SONG then
        LEDHelper.updateLeftRightLEDsWithParameters(self.Controller, MaschineHelper.getNumFocusSongGroupBanks(false), self.Screen.GroupBank + 1)
    end

end

------------------------------------------------------------------------------------------------------------------------


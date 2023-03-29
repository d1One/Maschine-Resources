------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/TransactionSequenceMarker"
require "Scripts/Shared/Components/InfoBarStudio"
require "Scripts/Shared/Components/ScreenMaschineStudio"
require "Scripts/Shared/Helpers/ColorPaletteHelper"
require "Scripts/Maschine/Helper/ClipHelper"
require "Scripts/Maschine/Helper/PatternHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ArrangerPageSectionsStudio = class( 'ArrangerPageSectionsStudio', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

local function getGroupListCount()

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    local BankCount = Song and math.floor((Song:getGroups():size() + 7) / 8) or 0

    return BankCount * 8

end

------------------------------------------------------------------------------------------------------------------------

local function setupGroupLabel(Label)

    Label:style("","GroupListItem")

end

------------------------------------------------------------------------------------------------------------------------

local function loadGroupLabel(Label, Index)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups()

    if Groups and Groups:at(Index) then
        Label:setVisible(true)
        Label:setText( NI.DATA.Group.getLabel(Index) )
        ColorPaletteHelper.setGroupColor(Label, Index+1)
        Label:setSelected(Index == NI.DATA.StateHelper.getFocusGroupIndex(App))
    else
        Label:setVisible(false)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:__init(ParentPage, Controller)

    PageMaschine.__init(self, "ArrangerPageSectionsStudio", Controller)

    self.ParentPage = ParentPage
    self.TransactionSequenceMarker = TransactionSequenceMarker()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_ARRANGE }

    -- This is used to make the encoder use for Scene Clip changing less hyper-sensitive
    self.SceneClipEncoderCounter = 0

    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"SECTION", "CLIP", "", ""},
        {"HeadTabLeft", "HeadTabRight", "HeadButton", "HeadButton"}, false)

    self.Screen:styleScreen(self.Screen.ScreenRight, {"CREATE", "DELETE", "<<", ">>"}, "HeadButton", false, false)

    self.GroupList = NI.GUI.insertLabelVector(self.Screen.ScreenRight.DisplayBar,"GroupList")
    self.GroupList:style(false, '')
    self.GroupList:getScrollbar():setVisible(false)
    NI.GUI.connectVector(self.GroupList, getGroupListCount, setupGroupLabel, loadGroupLabel)

    self.Arranger = self.Controller.SharedObjects.Arranger
    self.ArrangerOV = self.Controller.SharedObjects.ArrangerOverview

    MaschineHelper.resetScreenEncoderSmoother()

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:updateScreens(ForceUpdate)

    -- update info bars
    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)

    -- update arrangers
    self.Arranger:update(ForceUpdate)
    self.ArrangerOV:update(ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        -- scroll GroupList
        if App:getStateCache():isGroupsChanged() or ForceUpdate then
            local GroupBank = math.floor(NI.DATA.StateHelper.getFocusGroupIndex(App) / 8)
            self.GroupList:setItemOffset(GroupBank * 8)
        end
    end

    -- call base
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:updateScreenButtons(ForceUpdate)

    if self.Controller:getShiftPressed() then

        self.Screen.ScreenButton[1]:setText("IDEAS")
        self.Screen.ScreenButton[1]:setVisible(true)
        self.Screen.ScreenButton[1]:setSelected(false)
        self.Screen.ScreenButton[2]:setText("SONG")
        self.Screen.ScreenButton[2]:setVisible(true)
        self.Screen.ScreenButton[2]:setSelected(true)

        for Index = 3, 8 do
            self.Screen.ScreenButton[Index]:setVisible(false)
        end

        self.Screen:unsetArrowText(1)

    else

        local Section = NI.DATA.StateHelper.getFocusSection(App)

        self.Screen.ScreenButton[1]:setText("SECTION")
        self.Screen.ScreenButton[1]:setSelected(true)
        self.Screen.ScreenButton[2]:setText("CLIP")
        self.Screen.ScreenButton[2]:setSelected(false)

        local CanConvertSectionToClips = ArrangerHelper.canConvertFocusSectionToClips()
        self.Screen.ScreenButton[3]:setVisible(true)
        self.Screen.ScreenButton[3]:setText("CONVERT")
        self.Screen.ScreenButton[3]:setEnabled(CanConvertSectionToClips)

        self.Screen.ScreenButton[4]:setVisible(true)
        self.Screen.ScreenButton[4]:setText("DUPLICATE")
        self.Screen.ScreenButton[4]:setEnabled(Section ~= nil)

        -- CREATE button
        self.Screen.ScreenButton[5]:setVisible(true)

        self.Screen.ScreenButton[6]:setVisible(true)
        self.Screen.ScreenButton[6]:setText(ArrangerHelper.deleteSectionButtonText())
        self.Screen.ScreenButton[6]:setEnabled(Section ~= nil)

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local BankIndex = Song and Song:getFocusSectionBankIndexParameter():getValue() or 0
        local HasPrev, HasNext = ArrangerHelper.hasPrevNextSectionBanks()
        if Song then
            self.Screen:setArrowText(1, "BANK "..tostring(BankIndex + 1))
        else
            self.Screen:unsetArrowText(1)
        end
        self.Screen.ScreenButton[7]:setVisible(true)
        self.Screen.ScreenButton[7]:setEnabled(HasPrev)

        self.Screen.ScreenButton[8]:setVisible(true)
        self.Screen.ScreenButton[8]:setEnabled(HasNext or ArrangerHelper.canAddSectionBank())

    end

    -- call base
    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:updateParameters(ForceUpdate)

    self.ParameterHandler:setCustomSection(1, "Section")
    self.ParameterHandler:setCustomNames({"POSITION", "SCENE", "", "LENGTH"})
    local Values = { ArrangerHelper.getFocusedSectionSongPosAsString(),
                     ArrangerHelper.getSceneReferenceParameterValue(),
                     nil,
                     ArrangerHelper.getFocusSectionLengthString() }
    self.ParameterHandler:setCustomValues(Values)

    ArrangerHelper.updateSceneReferenceCapacitiveListAndFocus(self.Controller, 2)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:updateLeftRightLEDs()

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT, ArrangerHelper.hasPrevNextSection(false))
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT, ArrangerHelper.hasPrevNextSection(true))

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_ENTER, NI.HW.BUTTON_ENTER, false)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_BACK, NI.HW.BUTTON_BACK, false)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:updateWheelButtonLEDs()

    LEDHelper.setLEDState(NI.HW.LED_WHEEL_BUTTON_UP, LEDHelper.LS_OFF)
    LEDHelper.setLEDState(NI.HW.LED_WHEEL_BUTTON_DOWN, LEDHelper.LS_OFF)
    LEDHelper.setLEDState(NI.HW.LED_WHEEL_BUTTON_LEFT, LEDHelper.LS_OFF)
    LEDHelper.setLEDState(NI.HW.LED_WHEEL_BUTTON_RIGHT, LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:onShow(Show)

    if Show then
        self.TransactionSequenceMarker:reset()

        self.ArrangerOV:insertInto(self.Screen.ScreenLeft.DisplayBar, true)
        self.Arranger:insertInto(self.Screen.ScreenRight.DisplayBar, true)
        self.ArrangerOV:setVisible(true)
        self.ArrangerOV.Arranger:setArrangerViewport(self.Arranger.Arranger)

        NHLController:setPadMode(NI.HW.PAD_MODE_SECTION)
        self.Controller.CapacitiveNavIcons:Enable(true)
    else
        NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)
        LEDHelper.resetButtonLEDs({NI.HW.LED_ENTER, NI.HW.LED_BACK})
        ArrangerHelper.resetHoldingPads()

        self.Controller.CapacitiveList:reset()
        self.Controller.CapacitiveNavIcons:Enable(false)
    end

    -- call base class
    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:onScreenButton(Idx, Pressed)

    if Pressed then
        if self.Controller:getShiftPressed() then
            local Song = NI.DATA.StateHelper.getFocusSong(App)

            if Idx == 1 then
                NI.DATA.SongAccess.focusIdeas(App, Song)

            elseif Idx == 2 then
                NI.DATA.SongAccess.focusSongTimeline(App, Song)

            end
        else
            if Idx == 2 then
                NI.DATA.ArrangerAccess.toggleSongFocusEntity(App)

            elseif Idx == 3 then
                ArrangerHelper.convertFocusSectionToClips()
            elseif Idx == 4 then
                ArrangerHelper.duplicateSection()

            elseif Idx == 5 then
                ArrangerHelper.insertSectionAfterFocused()

            elseif Idx == 6 then
                ArrangerHelper.removeFocusedSectionOrBank(false)

            elseif Idx == 7 or Idx == 8 then
                ArrangerHelper.setPrevNextSectionBank(Idx == 8)

            end
        end
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:onWheelButton(Pressed)

    -- handled: no QE
    return true

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:onScreenEncoder(Idx, Inc)

    if Idx == 5 then -- ZOOM
        self.Arranger:zoom(Inc)

    elseif Idx == 6 then -- SCROLL
        self.Arranger:scroll(Inc)

    else
        if MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) == 0 then
            return
        end

        if Idx == 1 then        -- POSITION
            self.TransactionSequenceMarker:set()
            NI.DATA.SongAccess.swapFocusedSection(App, Inc > 0)

        elseif Idx == 2 then    -- SCENE
            ArrangerHelper.shiftSceneOfFocusSection(Inc)

        elseif Idx == 4 then    -- LENGTH
            ArrangerHelper.incrementFocusSectionLength(Inc, self.Controller:getShiftPressed())

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:onLeftRightButton(Right, Pressed)

    if Pressed then
        ArrangerHelper.focusPrevNextSection(Right)
    end

    self:updateLeftRightLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:updatePadLEDs()

    ArrangerHelper.updatePadLEDsSections(self.Controller.PAD_LEDS)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:onPadEvent(PadIndex, Trigger)

    ArrangerHelper.onPadEventSections(PadIndex, Trigger, self.Controller:getErasePressed(), true)
    return true

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:isSoundQEAllowed()

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:getAccessiblePageInfo()

    return "Sections Arranger"

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:getAccessibleTextByPadIndex(PadIdx)

    local AllowCreatingSections = true
    return ArrangerHelper.getAccessibleSectionNameByPadIndex(PadIdx, AllowCreatingSections)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageSectionsStudio:getAccessibleLeftRightButtonText()

    return "Scene Left", "Scene Right"

end

------------------------------------------------------------------------------------------------------------------------

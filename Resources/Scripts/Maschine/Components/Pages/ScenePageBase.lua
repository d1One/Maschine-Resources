------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScenePageBase = class( 'ScenePageBase', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function ScenePageBase:__init(ParentPage, Controller, Page)

    PageMaschine.__init(self, Page, Controller)

    self:setupScreen()

    self.ParentPage = ParentPage
    self.AppendMode = false

    self.PageLEDs = { NI.HW.LED_SCENE }

    -- Showing rename as shift functionality is only available to non-desktop MASCHINE
    self.ShowRename = NI.APP.isHeadless()

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageBase:updateScreenButtons(ForceUpdate)

    -- Pin Button
    self.Screen.ScreenButton[1]:setSelected(self.ParentPage.IsPinned)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Scene = NI.DATA.StateHelper.getFocusScene(App)
    local HasScene = Scene ~= nil
    local HasSong = Song ~= nil
    local ShiftPressed = self.Controller:getShiftPressed()

    -- Button 2 -- Remove
    self.Screen.ScreenButton[2]:setEnabled(HasScene and not NI.DATA.IdeaSpaceAlgorithms.isSceneUnique(Song, Scene))
    self.Screen.ScreenButton[2]:setVisible(not ShiftPressed and not self.AppendMode)

    -- Button 3 -- Append
    self.Screen.ScreenButton[3]:setVisible(not ShiftPressed)
    self.Screen.ScreenButton[3]:setSelected(self.AppendMode)

    -- Button 4 -- Duplicate
    self.Screen.ScreenButton[4]:setEnabled(HasScene)
    self.Screen.ScreenButton[4]:setVisible(not ShiftPressed and not self.AppendMode and HasSong)

    -- Button 5 -- Create / Rename
    if ShiftPressed and self.ShowRename then

        self.Screen.ScreenButton[5]:setText("RENAME")
        self.Screen.ScreenButton[5]:setEnabled(HasScene)
        self.Screen.ScreenButton[5]:setVisible(true)

    elseif ShiftPressed then

        self.Screen.ScreenButton[5]:setText("")
        self.Screen.ScreenButton[5]:setEnabled(false)
        self.Screen.ScreenButton[5]:setVisible(false)

    else

        self.Screen.ScreenButton[5]:setText("CREATE")
        self.Screen.ScreenButton[5]:setEnabled(not self.AppendMode and HasSong)
        self.Screen.ScreenButton[5]:setVisible(true)

    end

    -- Button 6 -- Delete
    if ShiftPressed then

        self.Screen.ScreenButton[6]:setText("DEL BANK")

    else

        self.Screen.ScreenButton[6]:setText("DELETE")

    end

    self.Screen.ScreenButton[6]:setEnabled(HasScene)
    self.Screen.ScreenButton[6]:setVisible(not self.AppendMode)

    local HasPrev, HasNext = ArrangerHelper.hasPrevNextSceneBanks()
    self.Screen.ScreenButton[7]:setEnabled(HasPrev)
    self.Screen.ScreenButton[8]:setEnabled(HasNext)

    -- call base
    PageMaschine.updateScreenButtons(self, ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------

function ScenePageBase:updatePadLEDs()

    ArrangerHelper.updatePadLEDsIdeaSpace(self.Controller, self.AppendMode)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageBase:onShow(Show)

    -- call base
    PageMaschine.onShow(self, Show)

    ArrangerHelper.setAppendMode(self, false)

    if Show then
        NHLController:setPadMode(NI.HW.PAD_MODE_SCENE)
    else
        NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageBase:onScreenButton(Idx, Pressed)

    if Pressed then

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Scene = NI.DATA.StateHelper.getFocusScene(App)
        local ShiftPressed = self.Controller:getShiftPressed()

        if Idx == 1 then

            self.ParentPage:togglePinState()

        elseif Idx == 2 and not ShiftPressed and Song and Scene and not self.AppendMode then

            NI.DATA.IdeaSpaceAccess.makeSceneUnique(App, Song, Scene)

        elseif Idx == 3 and not ShiftPressed then

            ArrangerHelper.setAppendMode(self, not self.AppendMode)

        elseif Idx == 4 and not ShiftPressed and Song and Scene and not self.AppendMode then

            NI.DATA.IdeaSpaceAccess.duplicateScene(App, Song, Scene)

        elseif Idx == 5 and Song and not self.AppendMode then

            if ShiftPressed and self.ShowRename and Scene then

                local NameParam = Scene:getNameParameter()
                MaschineHelper.openRenameDialog(NameParam:getValue(), NameParam)

            elseif not ShiftPressed then

                NI.DATA.IdeaSpaceAccess.insertSceneAfterFocusScene(App, Song)

            end

        elseif Idx == 6 and not self.AppendMode then

            ArrangerHelper.removeFocusedSceneOrBank(ShiftPressed)

        elseif Idx == 7 or Idx == 8 then

            ArrangerHelper.setPrevNextSceneBank(Idx == 8)

        end

    end

    -- call base class for update
    PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageBase:onPadEvent(PadIndex, Pressed, PadValue)

    ArrangerHelper.onPadEventIdeas(
        PadIndex, Pressed, self.Controller:getErasePressed(), not self.AppendMode, self.AppendMode)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageBase:onVolumeEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageBase:onTempoEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageBase:onSwingEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageBase:onWheel()

    if NHLController:getJogWheelMode() ~= NI.HW.JOGWHEEL_MODE_DEFAULT and
        self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------
-- Formats and updates the text for the level buttons (MASTER, GROUP, SOUND)
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LevelButtonsHelper = class( 'LevelButtonsHelper' )

------------------------------------------------------------------------------------------------------------------------
-- Call this after having initially created the buttons in your PageABC:__init() method.
--
-- Params:
-- ScreenButtons: list of the 3 buttons MASTER - GROUP - SOUND
------------------------------------------------------------------------------------------------------------------------

function LevelButtonsHelper:__init(ScreenButtons)

    self.ScreenButton = ScreenButtons

    self.Styles = { ScreenButtons[1]:getStyle(),
                    ScreenButtons[2]:getStyle(),
                    ScreenButtons[3]:getStyle()}

end


------------------------------------------------------------------------------------------------------------------------

function LevelButtonsHelper:updateButtons()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local LevelTab = Song and Song:getLevelTab() or -1      -- note: getLevelTab is 0-based

    self.ScreenButton[1]:setSelected(LevelTab == NI.DATA.LEVEL_TAB_SONG)
    self.ScreenButton[1]:setVisible(true)
    self.ScreenButton[1]:setEnabled(true)
    self.ScreenButton[1]:style("MASTER", self.Styles[1])

    self.ScreenButton[2]:setSelected(LevelTab == NI.DATA.LEVEL_TAB_GROUP)
    self.ScreenButton[2]:setVisible(true)
    self.ScreenButton[2]:setEnabled(true)
    self.ScreenButton[2]:style("GROUP", self.Styles[2])

    self.ScreenButton[3]:setSelected(LevelTab == NI.DATA.LEVEL_TAB_SOUND)
    self.ScreenButton[3]:setVisible(true)
    self.ScreenButton[3]:setEnabled(true)
    self.ScreenButton[3]:style("SOUND", self.Styles[3])

end

------------------------------------------------------------------------------------------------------------------------

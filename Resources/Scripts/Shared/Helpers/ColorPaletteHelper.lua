require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ColorPaletteHelper = class( 'ColorPaletteHelper' )

------------------------------------------------------------------------------------------------------------------------

function ColorPaletteHelper.setPatternColor(Widget, PatternID)

    local ColorIndex = MaschineHelper.getPatternColorByIndex(PatternID)

    if ColorIndex == nil then
        ColorIndex = -1
    end

    Widget:setPaletteColorIndex(ColorIndex+1)

end

------------------------------------------------------------------------------------------------------------------------

function ColorPaletteHelper.setClipColor(Widget, ClipIndex, CanAdd)

    local ColorIndex = MaschineHelper.getClipColorByIndex(ClipIndex + 1, CanAdd)
    Widget:setPaletteColorIndex(ColorIndex and ColorIndex + 1 or 0)

end

------------------------------------------------------------------------------------------------------------------------

-- Gets the color from the Scene with SceneID and sets it on Widget
function ColorPaletteHelper.setSceneColor(Widget, SceneID, CanAdd)

    local ColorIndex = MaschineHelper.getIdeaSpaceSceneColorByIndex(SceneID, CanAdd)

    if ColorIndex == nil then
        ColorIndex = -1
    end

    Widget:setPaletteColorIndex(ColorIndex + 1)

end

------------------------------------------------------------------------------------------------------------------------

-- Gets the color from the Section with SceneID and sets it on Widget
function ColorPaletteHelper.setSectionColor(Widget, SceneID)

    local ColorIndex = MaschineHelper.getSectionSceneColorByIndex(SceneID)

    if ColorIndex == nil then
        ColorIndex = -1
    end

    Widget:setPaletteColorIndex(ColorIndex+1)

end

------------------------------------------------------------------------------------------------------------------------

function ColorPaletteHelper.setGroupColor(Widget, GroupID)

    local ColorIndex = MaschineHelper.getGroupColorByIndex(GroupID)

    Widget:setPaletteColorIndex(ColorIndex ~= nil and ColorIndex+1 or 0)

	return ColorIndex

end

------------------------------------------------------------------------------------------------------------------------

function ColorPaletteHelper.setSoundColor(Widget, SoundID, GroupID)

    local ColorIndex = MaschineHelper.getSoundColorByIndex(SoundID, GroupID)

    Widget:setPaletteColorIndex(ColorIndex ~= nil and ColorIndex+1 or 0)

	return ColorIndex

end

------------------------------------------------------------------------------------------------------------------------


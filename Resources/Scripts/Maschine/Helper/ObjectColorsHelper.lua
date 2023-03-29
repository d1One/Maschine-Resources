------------------------------------------------------------------------------------------------------------------------

ObjectColorsHelper = {}

------------------------------------------------------------------------------------------------------------------------

function ObjectColorsHelper.paletteIndexes()

    local Colors = {}

    for Index = 0, NI.DATA.COLOR_PALETTE_MAX do

        table.insert(Colors, Index)

    end

    return Colors

end

------------------------------------------------------------------------------------------------------------------------

function ObjectColorsHelper.colorsAsStrings(List)

    local Values = {}

    for Index = 1, #List do

        table.insert(Values, NI.DATA.DefaultColorInfo.getColorName(List[Index]))

    end

    return Values

end

------------------------------------------------------------------------------------------------------------------------

function ObjectColorsHelper.objectColorsList()

    local Values = ObjectColorsHelper.paletteIndexes()

    table.insert(Values, 1, NI.DATA.COLOR_DEFAULT)

    return Values

end

------------------------------------------------------------------------------------------------------------------------

function ObjectColorsHelper.objectColorsAsStrings()

    return ObjectColorsHelper.colorsAsStrings(ObjectColorsHelper.objectColorsList())

end

------------------------------------------------------------------------------------------------------------------------

function ObjectColorsHelper.currentObjectColorValue(Parameter)

    return Parameter:isUseDefaultColor() and NI.DATA.COLOR_DEFAULT or Parameter:getValue()

end

------------------------------------------------------------------------------------------------------------------------

function ObjectColorsHelper.setupObjectColorParameter(Object, Index, Values, ListValues, ListColors)

    if Object then

        local ColorParameter = Object:getColorParameter()

        if ColorParameter then

            local CurrentColor = ObjectColorsHelper.currentObjectColorValue(ColorParameter)

            Values[Index] = NI.DATA.DefaultColorInfo.getColorName(CurrentColor)
            ListValues[Index] = ObjectColorsHelper:objectColorsAsStrings()
            ListColors[Index] = ObjectColorsHelper.paletteIndexes()
            table.insert(ListColors[Index], 1, nil)

        end

    else

        Values[Index] = "-"

    end

end

------------------------------------------------------------------------------------------------------------------------

function ObjectColorsHelper.selectPrevNextObjectColor(Object, Next, SetObjectColorFunction)

    if Object then

        local ColorParameter = Object:getColorParameter()

        if ColorParameter then

            local ObjectColors = ObjectColorsHelper.objectColorsList()
            local Index = table.findKey(ObjectColors, ObjectColorsHelper.currentObjectColorValue(ColorParameter))
            Index = math.bound(Index + (Next and 1 or -1), 1, #ObjectColors)

            local Color = ObjectColors[Index]
            local UseDefaultColor = Color == NI.DATA.COLOR_DEFAULT
            SetObjectColorFunction(App, Object, Color, UseDefaultColor)

        end

    end

end

------------------------------------------------------------------------------------------------------------------------


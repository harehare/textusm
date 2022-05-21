module Models.Color exposing
    ( Color
    , background1Defalut
    , background2Defalut
    , backgroundDarkDefalut
    , backgroundDefalut
    , black
    , blue
    , colors
    , darkIconColor
    , decoder
    , disabledIconColor
    , fromString
    , gray
    , green
    , iconColor
    , labelDefalut
    , lightGray
    , lime
    , lineDefalut
    , name
    , navy
    , olive
    , orange
    , pink
    , purple
    , red
    , teal
    , textDefalut
    , toString
    , transparent
    , white
    , white2
    , yellow
    )

import Json.Decode as D
import Regex


type Color
    = Color Name Rgb


background1Defalut : Color
background1Defalut =
    Color "Background1 Defalut" "#266B9A"


background2Defalut : Color
background2Defalut =
    Color "Background2 Defalut" "#3E9BCD"


backgroundDarkDefalut : Color
backgroundDarkDefalut =
    Color "Background Dark Defalut" "#323d46"


backgroundDefalut : Color
backgroundDefalut =
    Color "Background Defalut" "#F4F4F5"


black : Color
black =
    Color "Black" "#000000"


blue : Color
blue =
    Color "Blue" "#CEE5F2"


colors : List Color
colors =
    [ white
    , black
    , gray
    , lightGray
    , yellow
    , green
    , blue
    , orange
    , pink
    , red
    , purple
    , background1Defalut
    , background2Defalut
    , lineDefalut
    , labelDefalut
    , backgroundDefalut
    , backgroundDarkDefalut
    , teal
    , olive
    , lime
    , green2
    , transparent
    , purple2
    , yellow2
    ]


darkIconColor : Color
darkIconColor =
    Color "Icon color" "#b9b9b9"


decoder : D.Decoder Color
decoder =
    D.map fromString D.string


disabledIconColor : Color
disabledIconColor =
    Color "Disabled icon color" "#848A90"


fromString : String -> Color
fromString rgb =
    case String.toUpper rgb of
        "#000000" ->
            black

        "#008080" ->
            teal

        "#00FF00" ->
            lime

        "#258F9B" ->
            green2

        "#266B9A" ->
            background1Defalut

        "#323D46" ->
            backgroundDarkDefalut

        "#333333" ->
            gray

        "#3E9BCD" ->
            background2Defalut

        "#434343" ->
            lineDefalut

        "#7C48A5" ->
            purple2

        "#808000" ->
            olive

        "#8C9FAE" ->
            labelDefalut

        "#CD89F7" ->
            purple

        "#CEE5F2" ->
            blue

        "#D3D3D3" ->
            lightGray

        "#D3F8E2" ->
            green

        "#EE8A8B" ->
            red

        "#F4F4F5" ->
            backgroundDefalut

        "#F6CFE6" ->
            pink

        "#F7CAB2" ->
            orange

        "#F9D188" ->
            yellow2

        "#FEFEFE" ->
            white

        "#FFF9B2" ->
            yellow

        "transparent" ->
            transparent

        _ ->
            case
                Regex.find
                    (Maybe.withDefault Regex.never <|
                        Regex.fromString "^#[a-fA-F0-9]{6}$"
                    )
                    rgb
                    |> List.head
            of
                Just c ->
                    if c.match == rgb then
                        Color "custom" rgb

                    else
                        background1Defalut

                Nothing ->
                    background1Defalut


gray : Color
gray =
    Color "Gray" "#333333"


green : Color
green =
    Color "Green" "#D3F8E2"


iconColor : Color
iconColor =
    Color "Icon color" "#F5F5F6"


labelDefalut : Color
labelDefalut =
    Color "Label Defalut" "#8C9FAE"


lightGray : Color
lightGray =
    Color "Light Gray" "#D3D3D3"


lime : Color
lime =
    Color "Lime" "#00ff00"


lineDefalut : Color
lineDefalut =
    Color "Line Defalut" "#434343"


name : Color -> String
name (Color n _) =
    n


navy : Color
navy =
    Color "Navy" "#273037"


olive : Color
olive =
    Color "Olive" "#808000"


orange : Color
orange =
    Color "Orange" "#F7CAB2"


pink : Color
pink =
    Color "Pink" "#F6CFE6"


purple : Color
purple =
    Color "Purple" "#CD89F7"


red : Color
red =
    Color "Red" "#EE8A8B"


teal : Color
teal =
    Color "Teal" "#008080"


textDefalut : Color
textDefalut =
    Color "Text Defalut" "#111111"


toString : Color -> String
toString (Color _ rgb) =
    rgb


transparent : Color
transparent =
    Color "transparent" "transparent"


white : Color
white =
    Color "White" "#FEFEFE"


white2 : Color
white2 =
    Color "White" "#F4F4F4"


yellow : Color
yellow =
    Color "Yellow" "#FFF9B2"


green2 : Color
green2 =
    Color "Green2" "#258F9B"


type alias Name =
    String


purple2 : Color
purple2 =
    Color "Purple2" "#7C48A5"


type alias Rgb =
    String


yellow2 : Color
yellow2 =
    Color "Yellow2" "#F9D188"

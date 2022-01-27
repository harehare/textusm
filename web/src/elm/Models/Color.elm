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
    , green2
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
    , purple2
    , red
    , teal
    , textDefalut
    , toString
    , transparent
    , white
    , white2
    , yellow
    , yellow2
    )

import Json.Decode as D
import Regex


type alias Name =
    String


type alias Rgb =
    String


type Color
    = Color Name Rgb


white : Color
white =
    Color "White" "#FEFEFE"


white2 : Color
white2 =
    Color "White" "#F4F4F4"


black : Color
black =
    Color "Black" "#000000"


gray : Color
gray =
    Color "Gray" "#333333"


lightGray : Color
lightGray =
    Color "Light Gray" "#D3D3D3"


yellow : Color
yellow =
    Color "Yellow" "#FFF9B2"


yellow2 : Color
yellow2 =
    Color "Yellow2" "#F9D188"


green : Color
green =
    Color "Green" "#D3F8E2"


green2 : Color
green2 =
    Color "Green2" "#258F9B"


blue : Color
blue =
    Color "Blue" "#CEE5F2"


orange : Color
orange =
    Color "Orange" "#F7CAB2"


pink : Color
pink =
    Color "Pink" "#F6CFE6"


red : Color
red =
    Color "Red" "#EE8A8B"


purple : Color
purple =
    Color "Purple" "#CD89F7"


purple2 : Color
purple2 =
    Color "Purple2" "#7C48A5"


navy : Color
navy =
    Color "Navy" "#273037"


teal : Color
teal =
    Color "Teal" "#008080"


olive : Color
olive =
    Color "Olive" "#808000"


lime : Color
lime =
    Color "Lime" "#00ff00"


background1Defalut : Color
background1Defalut =
    Color "Background1 Defalut" "#266B9A"


background2Defalut : Color
background2Defalut =
    Color "Background2 Defalut" "#3E9BCD"


lineDefalut : Color
lineDefalut =
    Color "Line Defalut" "#434343"


labelDefalut : Color
labelDefalut =
    Color "Label Defalut" "#8C9FAE"


backgroundDefalut : Color
backgroundDefalut =
    Color "Background Defalut" "#F4F4F5"


backgroundDarkDefalut : Color
backgroundDarkDefalut =
    Color "Background Dark Defalut" "#323d46"


textDefalut : Color
textDefalut =
    Color "Text Defalut" "#111111"


iconColor : Color
iconColor =
    Color "Icon color" "#F5F5F6"


disabledIconColor : Color
disabledIconColor =
    Color "Disabled icon color" "#848A90"


darkIconColor : Color
darkIconColor =
    Color "Icon color" "#b9b9b9"


transparent : Color
transparent =
    Color "transparent" "transparent"


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


toString : Color -> String
toString (Color _ rgb) =
    rgb


name : Color -> String
name (Color n _) =
    n


fromString : String -> Color
fromString rgb =
    case String.toUpper rgb of
        "#FEFEFE" ->
            white

        "#000000" ->
            black

        "#333333" ->
            gray

        "#D3D3D3" ->
            lightGray

        "#FFF9B2" ->
            yellow

        "#D3F8E2" ->
            green

        "#258F9B" ->
            green2

        "#CEE5F2" ->
            blue

        "#F7CAB2" ->
            orange

        "#F6CFE6" ->
            pink

        "#EE8A8B" ->
            red

        "#CD89F7" ->
            purple

        "#266B9A" ->
            background1Defalut

        "#3E9BCD" ->
            background2Defalut

        "#434343" ->
            lineDefalut

        "#8C9FAE" ->
            labelDefalut

        "#F4F4F5" ->
            backgroundDefalut

        "#008080" ->
            teal

        "#00FF00" ->
            lime

        "#808000" ->
            olive

        "#323D46" ->
            backgroundDarkDefalut

        "#7C48A5" ->
            purple2

        "#F9D188" ->
            yellow2

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


decoder : D.Decoder Color
decoder =
    D.map fromString D.string

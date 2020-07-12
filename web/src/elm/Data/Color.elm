module Data.Color exposing (Color, background1Defalut, background2Defalut, backgroundDefalut, black, blue, colors, fromString, gray, green, labelDefalut, lightGray, lineDefalut, name, orange, pink, purple, red, textDefalut, toString, white, yellow)


type alias Name =
    String


type alias Rgb =
    String


type Color
    = Color Name Rgb


white : Color
white =
    Color "WHITE" "#FFFFFF"


black : Color
black =
    Color "BLACK" "#000000"


gray : Color
gray =
    Color "GRAY" "#333333"


lightGray : Color
lightGray =
    Color "LIGHT GRAY" "#D3D3D3"


yellow : Color
yellow =
    Color "YELLOW" "#FFF9B2"


green : Color
green =
    Color "GREEN" "#D3F8E2"


blue : Color
blue =
    Color "BLUE" "#CEE5F2"


orange : Color
orange =
    Color "ORANGE" "#F7CAB2"


pink : Color
pink =
    Color "PINK" "#F6CFE6"


red : Color
red =
    Color "RED" "#EE8A8B"


purple : Color
purple =
    Color "PURPLE" "#CD89F7"


background1Defalut : Color
background1Defalut =
    Color "BACKGROUND1 DEFALUT" "#266B9A"


background2Defalut : Color
background2Defalut =
    Color "BACKGROUND2 DEFALUT" "#3E9BCD"


lineDefalut : Color
lineDefalut =
    Color "LINE DEFALUT" "#434343"


labelDefalut : Color
labelDefalut =
    Color "LABEL DEFALUT" "#8C9FAE"


backgroundDefalut : Color
backgroundDefalut =
    Color "BACKGROUND DEFALUT" "#F4F4F5"


textDefalut : Color
textDefalut =
    Color "TEXT DEFALUT" "#111111"


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
    ]


toString : Color -> String
toString (Color _ rgb) =
    rgb


name : Color -> String
name (Color n _) =
    n


fromString : String -> Color
fromString rgb =
    case rgb of
        "#FFFFFF" ->
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

        _ ->
            background1Defalut

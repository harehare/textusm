module Views.Diagram.Toolbar exposing
    ( ClickEvent
    , ToolbarButton
    , viewColorOnly
    , viewForFreeForm
    )

import Css
    exposing
        ( absolute
        , backgroundColor
        , bold
        , border3
        , borderRadius
        , borderRight3
        , center
        , cursor
        , displayFlex
        , fontSize
        , fontWeight
        , hex
        , margin
        , pointer
        , position
        , px
        , rem
        , rgba
        , right
        , solid
        , textAlign
        , top
        )
import Events
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Models.Color as Color exposing (Color)
import Models.Item as Item exposing (Item)
import Models.ItemSettings as ItemSettings
import Style.Style as Style
import Svg.Styled as Svg exposing (Svg, svg)
import Svg.Styled.Attributes as SvgAttr exposing (stroke, strokeWidth, x1, x2, y1, y2)


type alias ClickEvent msg =
    Item -> msg


type ToolbarButton msg
    = Button (Html msg)
    | Separator (Html msg)


viewColorOnly : ClickEvent msg -> Html msg
viewColorOnly e =
    view <| userStoryMap e


viewForFreeForm : ClickEvent msg -> Html msg
viewForFreeForm e =
    view <| freeForm e


canvasView : Item -> ClickEvent msg -> Html msg
canvasView item event =
    Html.div
        [ css
            [ Css.width <| px 20
            , Css.height <| px 20
            , Style.roundedSm
            , border3 (px 4) solid (hex <| Color.toString Color.lineDefalut)
            , cursor pointer
            , margin <| px 2
            ]
        , Events.onClickStopPropagation <| event item
        ]
        []


cardView : Color -> Item -> ClickEvent msg -> Html msg
cardView color item event =
    Html.div
        [ css
            [ Css.width <| px 24
            , Css.height <| px 24
            , Style.roundedSm
            , backgroundColor <| hex <| Color.toString color
            , border3 (px 1) solid (rgba 0 0 0 0.1)
            , cursor pointer
            , margin <| px 2
            ]
        , Events.onClickStopPropagation <| event item
        ]
        []


createCanvas : Item
createCanvas =
    Item.new
        |> Item.withTextOnly "Click to edit # canvas"


createColorItem : Color -> Item
createColorItem color =
    Item.new
        |> Item.withItemSettings
            (ItemSettings.new
                |> ItemSettings.withBackgroundColor (Just color)
                |> ItemSettings.withForegroundColor (Just Color.black)
                |> Just
            )
        |> Item.withTextOnly "Click to edit"


createHorizontalLineItem : Item
createHorizontalLineItem =
    Item.new
        |> Item.withTextOnly "---"


createTextItem : Item
createTextItem =
    Item.new
        |> Item.withTextOnly "Click to edit # text"


createVerticalLineItem : Item
createVerticalLineItem =
    Item.new
        |> Item.withTextOnly "/"


freeForm : ClickEvent msg -> List (ToolbarButton msg)
freeForm e =
    [ Button <| cardView Color.white (createColorItem Color.white) e
    , Button <| cardView Color.yellow (createColorItem Color.yellow) e
    , Button <| cardView Color.green (createColorItem Color.green) e
    , Button <| cardView Color.blue (createColorItem Color.blue) e
    , Button <| cardView Color.orange (createColorItem Color.orange) e
    , Button <| cardView Color.pink (createColorItem Color.pink) e
    , Button <| cardView Color.red (createColorItem Color.red) e
    , Button <| cardView Color.purple (createColorItem Color.purple) e
    , Separator <| separator
    , Button <| canvasView createCanvas e
    , Separator <| separator
    , Button <|
        iconView
            (Svg.g []
                [ Svg.line [ x1 "4", y1 "4", x2 "26", y2 "4", stroke <| Color.toString Color.lineDefalut, strokeWidth "4" ] []
                , Svg.line [ x1 "14", y1 "2", x2 "14", y2 "22", stroke <| Color.toString Color.lineDefalut, strokeWidth "4" ] []
                ]
            )
            createTextItem
            e
    , Button <| iconView (Svg.line [ x1 "14", y1 "2", x2 "14", y2 "22", stroke <| Color.toString Color.lineDefalut, strokeWidth "4" ] []) createVerticalLineItem e
    , Button <| iconView (Svg.line [ x1 "0", y1 "12", x2 "24", y2 "12", stroke <| Color.toString Color.lineDefalut, strokeWidth "3" ] []) createHorizontalLineItem e
    ]


iconView : Svg msg -> Item -> ClickEvent msg -> Html msg
iconView icon item event =
    Html.div
        [ css
            [ Css.height <| px 24
            , Style.roundedSm
            , cursor pointer
            , margin <| px 2
            , fontWeight bold
            , textAlign center
            ]
        , Events.onClickStopPropagation <| event item
        ]
        [ svg [ SvgAttr.width "24" ] [ icon ] ]


separator : Html msg
separator =
    Html.div
        [ css
            [ borderRight3 (px 1) solid (rgba 0 0 0 0.1)
            , Css.width <| px 1
            , Css.height <| px 40
            ]
        ]
        []


userStoryMap : ClickEvent msg -> List (ToolbarButton msg)
userStoryMap e =
    [ Button <| cardView Color.white (createColorItem Color.white) e
    , Button <| cardView Color.yellow (createColorItem Color.yellow) e
    , Button <| cardView Color.green (createColorItem Color.green) e
    , Button <| cardView Color.blue (createColorItem Color.blue) e
    , Button <| cardView Color.orange (createColorItem Color.orange) e
    , Button <| cardView Color.pink (createColorItem Color.pink) e
    , Button <| cardView Color.red (createColorItem Color.red) e
    , Button <| cardView Color.purple (createColorItem Color.purple) e
    ]


view : List (ToolbarButton msg) -> Html msg
view items =
    Html.div
        [ css
            [ backgroundColor <| hex <| Color.toString Color.white2
            , borderRadius <| px 4
            , border3 (px 1) solid (rgba 0 0 0 0.1)
            , displayFlex
            , position absolute
            , top <| px 66
            , right <| px 32
            , Style.shadowSm
            , Style.roundedSm
            ]
        ]
    <|
        List.map
            (\item ->
                case item of
                    Button view_ ->
                        Html.div
                            [ css
                                [ Css.width <| px 40
                                , Css.height <| px 40
                                , fontSize <| rem 1.2
                                , Style.flexCenter
                                , cursor pointer
                                ]
                            ]
                            [ view_ ]

                    Separator view_ ->
                        Html.div
                            [ css
                                [ Css.width <| px 8
                                , Css.height <| px 40
                                , fontSize <| rem 1.2
                                , Style.flexCenter
                                , cursor pointer
                                ]
                            ]
                            [ view_ ]
            )
            items

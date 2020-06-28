module Views.Diagram.CardMenu exposing (view)

import Data.Color as Color exposing (Color)
import Data.Item exposing (Item)
import Html exposing (Html, div, text)
import Html.Attributes exposing (style)
import Html.Events as E
import Models.Diagram exposing (CardMenu(..))
import Views.Empty as Empty


view :
    { state : CardMenu
    , item : Item
    , onMenuSelect : CardMenu -> msg
    , onColorChanged : Color -> msg
    , onBackgroundColorChanged : Color -> msg
    }
    -> Html msg
view props =
    div
        [ style "width" "102px"
        , style "height" "50px"
        , style "background-color" "#F2F2F2"
        , style "box-shadow" "0 8px 16px 0 rgba(0, 0, 0, 0.12)"
        , style "border-radius" "2px"
        , style "position" "absolute"
        , style "bottom" "8px"
        , style "left" "8px"
        , style "z-index" "100"
        , style "display" "flex"
        ]
        [ div
            [ style "width" "50px"
            , style "height" "50px"
            , style "font-size" "1.2rem"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "border-right" "1px solid #CCC"
            , style "cursor" "pointer"
            ]
            [ div [ style "color" <| Color.toString <| Maybe.withDefault Color.black <| props.item.color, style "padding" "8px", E.onClick <| props.onMenuSelect ColorSelectMenu ] [ text "Aa" ]
            ]
        , div
            [ style "width" "50px"
            , style "height" "50px"
            , style "font-size" "1.4rem"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "border-right" "1px solid #CCC"
            ]
            [ colorCircle (props.item.backgroundColor |> Maybe.withDefault Color.black) <| props.onMenuSelect BackgroundColorSelectMenu
            ]
        , case props.state of
            ColorSelectMenu ->
                colorPicker Color.colors props.onColorChanged

            BackgroundColorSelectMenu ->
                colorPicker Color.colors props.onBackgroundColorChanged

            CloseMenu ->
                Empty.view
        ]


colorCircle : Color -> msg -> Html msg
colorCircle color msg =
    div
        [ style "width" "24px"
        , style "height" "24px"
        , style "border-radius" "100%"
        , style "background-color" <| Color.toString color
        , style "border" "1px solid rgba(0, 0, 0, 0.1)"
        , style "cursor" "pointer"
        , style "margin" "2px"
        , E.onClick msg
        ]
        []


colorPicker : List Color -> (Color -> msg) -> Html msg
colorPicker colors onColorChanged =
    div
        [ style "width" "140px"
        , style "height" "140px"
        , style "background-color" "#F2F2F2"
        , style "box-shadow" "0 8px 16px 0 rgba(0, 0, 0, 0.12)"
        , style "border-radius" "2px"
        , style "position" "absolute"
        , style "top" "-158px"
        , style "left" "0"
        , style "z-index" "100"
        , style "display" "flex"
        , style "flex-wrap" "wrap"
        , style "justify-content" "space-between"
        , style "padding" "8px"
        ]
    <|
        List.map (\color -> colorCircle color <| onColorChanged color) colors

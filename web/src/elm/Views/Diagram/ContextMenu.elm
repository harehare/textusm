module Views.Diagram.ContextMenu exposing (view)

import Data.Color as Color exposing (Color)
import Data.Item exposing (Item)
import Data.Position as Position exposing (Position)
import Events exposing (onClickStopPropagation)
import Html exposing (Html, div, text)
import Html.Attributes as Attr
import Models.Diagram exposing (ContextMenu(..))
import Svg exposing (Svg, foreignObject)
import Svg.Attributes exposing (height, style, width, x, y)
import Views.Empty as Empty
import Views.Icon as Icon


view :
    { state : ContextMenu
    , item : Item
    , position : Position
    , onMenuSelect : ContextMenu -> msg
    , onColorChanged : Color -> msg
    , onBackgroundColorChanged : Color -> msg
    , onEditMarkdown : msg
    }
    -> Svg msg
view props =
    foreignObject
        [ x <| String.fromInt <| Position.getX props.position
        , y <| String.fromInt <| Position.getY props.position
        , width "152"
        , height "205"
        ]
        [ div
            [ Attr.style "background-color" "#FEFEFE"
            , Attr.style "box-shadow" "0 8px 16px 0 rgba(0, 0, 0, 0.12)"
            , Attr.style "border-radius" "2px"
            , Attr.style "display" "flex"
            ]
            [ div
                [ Attr.style "width" "50px"
                , Attr.style "height" "50px"
                , Attr.style "font-size" "1.2rem"
                , Attr.style "display" "flex"
                , Attr.style "align-items" "center"
                , Attr.style "justify-content" "center"
                , Attr.style "border-right" "1px solid #CCC"
                , Attr.style "cursor" "pointer"
                ]
                [ div
                    [ Attr.style "color" <| Color.toString <| Maybe.withDefault Color.black <| props.item.color
                    , Attr.style "text-shadow" "1px 1px 1px #555555"
                    , Attr.style "padding" "8px"
                    , onClickStopPropagation <| props.onMenuSelect ColorSelectMenu
                    ]
                    [ text "Aa" ]
                ]
            , div
                [ Attr.style "width" "50px"
                , Attr.style "height" "50px"
                , Attr.style "font-size" "1.4rem"
                , Attr.style "display" "flex"
                , Attr.style "align-items" "center"
                , Attr.style "justify-content" "center"
                , Attr.style "border-right" "1px solid #CCC"
                ]
                [ colorCircle (props.item.backgroundColor |> Maybe.withDefault Color.black) <| props.onMenuSelect BackgroundColorSelectMenu
                ]
            , div
                [ Attr.style "width" "50px"
                , Attr.style "height" "50px"
                , Attr.style "font-size" "1.2rem"
                , Attr.style "display" "flex"
                , Attr.style "align-items" "center"
                , Attr.style "justify-content" "center"
                , Attr.style "border-right" "1px solid #CCC"
                , Attr.style "cursor" "pointer"
                ]
                [ div
                    [ Attr.style "color" <| Color.toString <| Maybe.withDefault Color.black <| props.item.color
                    , Attr.style "text-shadow" "1px 1px 1px #555555"
                    , Attr.style "padding" "8px"
                    , onClickStopPropagation props.onEditMarkdown
                    ]
                    [ Icon.markdown "#273037" 32 ]
                ]
            , case props.state of
                ColorSelectMenu ->
                    colorPicker Color.colors props.onColorChanged

                BackgroundColorSelectMenu ->
                    colorPicker Color.colors props.onBackgroundColorChanged

                _ ->
                    Empty.view
            ]
        ]


colorCircle : Color -> msg -> Html msg
colorCircle color msg =
    div
        [ Attr.style "width" "24px"
        , Attr.style "height" "24px"
        , Attr.style "border-radius" "100%"
        , Attr.style "background-color" <| Color.toString color
        , Attr.style "border" "1px solid rgba(0, 0, 0, 0.1)"
        , Attr.style "cursor" "pointer"
        , Attr.style "margin" "2px"
        , onClickStopPropagation msg
        ]
        []


colorPicker : List Color -> (Color -> msg) -> Html msg
colorPicker colors onColorChanged =
    div
        [ Attr.style "width" "140px"
        , Attr.style "height" "140px"
        , Attr.style "background-color" "#FEFEFE"
        , Attr.style "box-shadow" "0 8px 16px 0 rgba(0, 0, 0, 0.12)"
        , Attr.style "border-radius" "2px"
        , Attr.style "position" "absolute"
        , Attr.style "bottom" "0"
        , Attr.style "left" "0"
        , Attr.style "z-index" "100"
        , Attr.style "display" "flex"
        , Attr.style "flex-wrap" "wrap"
        , Attr.style "justify-content" "space-between"
        , Attr.style "padding" "8px"
        ]
    <|
        List.map (\color -> colorCircle color <| onColorChanged color) colors

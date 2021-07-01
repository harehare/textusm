module Views.Diagram.ContextMenu exposing (view)

import Events exposing (onClickStopPropagation)
import Html exposing (Html)
import Html.Attributes as Attr
import Models.Diagram exposing (ContextMenu(..))
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Types.Color as Color exposing (Color)
import Types.FontSize as FontSize exposing (FontSize)
import Types.FontStyle as FontStyle exposing (FontStyle)
import Types.Item as Item exposing (Item)
import Types.Position as Position exposing (Position)
import Views.DropDownList as DropDownList exposing (DropDownValue)
import Views.Empty as Empty
import Views.Icon as Icon


fontSizeItems : List { name : String, value : DropDownValue }
fontSizeItems =
    List.map
        (\f ->
            let
                size =
                    FontSize.unwrap f
            in
            { name = String.fromInt size, value = DropDownList.stringValue <| String.fromInt size }
        )
        FontSize.list


view :
    { state : ContextMenu
    , item : Item
    , position : Position
    , dropDownIndex : Maybe String
    , onMenuSelect : ContextMenu -> msg
    , onColorChanged : Color -> msg
    , onBackgroundColorChanged : Color -> msg
    , onFontStyleChanged : FontStyle -> msg
    , onFontSizeChanged : FontSize -> msg
    , onToggleDropDownList : String -> msg
    }
    -> Svg msg
view props =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt <| Position.getX props.position
        , SvgAttr.y <| String.fromInt <| (Position.getY props.position + 8)
        , SvgAttr.width "320"
        , SvgAttr.height "205"
        ]
        [ Html.div
            [ Attr.style "background-color" "#fefefe"
            , Attr.style "border-radius" "4px"
            , Attr.style "border" "1px solid rgba(0, 0, 0, 0.1)"
            , Attr.style "display" "flex"
            , Attr.style "width" "320px"
            ]
            [ Html.div
                [ Attr.style "width" "50px"
                , Attr.style "height" "48px"
                , Attr.style "font-size" "1.2rem"
                , Attr.style "display" "flex"
                , Attr.style "align-items" "center"
                , Attr.style "justify-content" "center"
                , Attr.style "border-right" "1px solid rgba(0, 0, 0, 0.1)"
                , Attr.style "cursor" "pointer"
                , onClickStopPropagation <| props.onMenuSelect ColorSelectMenu
                ]
                [ Html.div []
                    [ Icon.font
                        (Item.getForegroundColor props.item
                            |> Maybe.withDefault Color.black
                            |> Color.toString
                        )
                        16
                    ]
                ]
            , Html.div
                [ Attr.style "width" "50px"
                , Attr.style "height" "48px"
                , Attr.style "font-size" "1.4rem"
                , Attr.style "display" "flex"
                , Attr.style "align-items" "center"
                , Attr.style "justify-content" "center"
                , Attr.style "border-right" "1px solid rgba(0, 0, 0, 0.1)"
                ]
                [ colorCircle
                    (Item.getBackgroundColor props.item
                        |> Maybe.withDefault Color.black
                    )
                    (props.onMenuSelect BackgroundColorSelectMenu)
                ]
            , Html.div
                [ Attr.style "width" "72px"
                , Attr.style "height" "48px"
                , Attr.style "font-size" "1.2rem"
                , Attr.style "display" "flex"
                , Attr.style "align-items" "center"
                , Attr.style "justify-content" "center"
                , Attr.style "cursor" "pointer"
                , Attr.style "border-right" "1px solid rgba(0, 0, 0, 0.1)"
                , onClickStopPropagation <| props.onMenuSelect CloseMenu
                ]
                [ DropDownList.view props.onToggleDropDownList
                    "fontSize"
                    props.dropDownIndex
                    (\s -> props.onFontSizeChanged <| FontSize.fromInt (String.toInt s |> Maybe.withDefault (FontSize.unwrap FontSize.default)))
                    fontSizeItems
                    (Item.getFontSize props.item |> FontSize.unwrap |> String.fromInt)
                ]
            , Html.div
                [ Attr.style "width" "50px"
                , Attr.style "height" "48px"
                , Attr.style "font-size" "1.2rem"
                , Attr.style "display" "flex"
                , Attr.style "align-items" "center"
                , Attr.style "justify-content" "center"
                , Attr.style "cursor" "pointer"
                , onClickStopPropagation <| props.onFontStyleChanged FontStyle.Bold
                ]
                [ Html.div
                    [ Attr.style "color"
                        (Item.getForegroundColor props.item
                            |> Maybe.withDefault Color.black
                            |> Color.toString
                        )
                    ]
                    [ Icon.bold "#273037" 16 ]
                ]
            , Html.div
                [ Attr.style "width" "50px"
                , Attr.style "height" "48px"
                , Attr.style "font-size" "1.2rem"
                , Attr.style "display" "flex"
                , Attr.style "align-items" "center"
                , Attr.style "justify-content" "center"
                , Attr.style "cursor" "pointer"
                , onClickStopPropagation <| props.onFontStyleChanged FontStyle.Italic
                ]
                [ Html.div
                    [ Attr.style "color" <|
                        (Item.getForegroundColor props.item
                            |> Maybe.withDefault Color.black
                            |> Color.toString
                        )
                    ]
                    [ Icon.italic "#273037" 16 ]
                ]
            , Html.div
                [ Attr.style "width" "50px"
                , Attr.style "height" "48px"
                , Attr.style "font-size" "1.2rem"
                , Attr.style "display" "flex"
                , Attr.style "align-items" "center"
                , Attr.style "justify-content" "center"
                , Attr.style "cursor" "pointer"
                , onClickStopPropagation <| props.onFontStyleChanged FontStyle.Strikethrough
                ]
                [ Html.div
                    [ Attr.style "color" <|
                        (Item.getBackgroundColor props.item
                            |> Maybe.withDefault Color.black
                            |> Color.toString
                        )
                    ]
                    [ Icon.strikethrough "#273037" 16 ]
                ]
            , case props.state of
                ColorSelectMenu ->
                    colorPicker 0 Color.colors props.onColorChanged

                BackgroundColorSelectMenu ->
                    colorPicker 10 Color.colors props.onBackgroundColorChanged

                _ ->
                    Empty.view
            ]
        ]


colorCircle : Color -> msg -> Html msg
colorCircle color msg =
    Html.div
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


colorPicker : Int -> List Color -> (Color -> msg) -> Html msg
colorPicker x colors onColorChanged =
    Html.div
        [ Attr.style "width" "140px"
        , Attr.style "height" "140px"
        , Attr.style "background-color" "#FEFEFE"
        , Attr.style "box-shadow" "0 8px 16px 0 rgba(0, 0, 0, 0.12)"
        , Attr.style "border-radius" "2px"
        , Attr.style "position" "absolute"
        , Attr.style "bottom" "0"
        , Attr.style "left" <| String.fromInt x ++ "px"
        , Attr.style "z-index" "100"
        , Attr.style "display" "flex"
        , Attr.style "flex-wrap" "wrap"
        , Attr.style "justify-content" "space-between"
        , Attr.style "padding" "8px"
        ]
    <|
        List.map (\color -> colorCircle color <| onColorChanged color) colors

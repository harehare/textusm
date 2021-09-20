module Views.Diagram.ContextMenu exposing (view, viewAllMenu, viewColorMenuOnly)

import Events
import Html exposing (Html)
import Html.Attributes as Attr
import Models.Color as Color exposing (Color)
import Models.Diagram exposing (ContextMenu(..), Data(..), Msg(..))
import Models.Dialog exposing (display)
import Models.FontSize as FontSize exposing (FontSize)
import Models.FontStyle as FontStyle exposing (FontStyle)
import Models.Item as Item exposing (Item)
import Models.Position as Position exposing (Position)
import Models.Size exposing (Width)
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Views.DropDownList as DropDownList exposing (DropDownValue)
import Views.Empty as Empty
import Views.Icon as Icon


type alias Props msg =
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


type alias MenuDisplay =
    { color : Bool
    , backgroundColor : Bool
    , fontStyleBold : Bool
    , fontStyleItalic : Bool
    , fontStyleStrikethrough : Bool
    , fontSize : Bool
    }


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


viewAllMenu : Props msg -> Svg msg
viewAllMenu props =
    view
        320
        { color = True
        , backgroundColor = True
        , fontStyleBold = True
        , fontStyleItalic = True
        , fontStyleStrikethrough = True
        , fontSize = True
        }
        props


viewColorMenuOnly : Props msg -> Svg msg
viewColorMenuOnly props =
    view
        50
        { color = False
        , backgroundColor = True
        , fontStyleBold = False
        , fontStyleItalic = False
        , fontStyleStrikethrough = False
        , fontSize = False
        }
        props


view : Width -> MenuDisplay -> Props msg -> Svg msg
view width display props =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt <| Position.getX props.position
        , SvgAttr.y <| String.fromInt <| (Position.getY props.position + 8)
        , SvgAttr.width "320"
        , SvgAttr.height "205"
        ]
        [ Html.div
            [ Attr.style "background-color" (Color.toString Color.white)
            , Attr.style "border-radius" "4px"
            , Attr.style "border" "1px solid rgba(0, 0, 0, 0.1)"
            , Attr.style "display" "flex"
            , Attr.style "width" <| String.fromInt width ++ "px"
            ]
            [ if display.color then
                Html.div
                    [ Attr.style "width" "50px"
                    , Attr.style "height" "48px"
                    , Attr.style "font-size" "1.2rem"
                    , Attr.style "display" "flex"
                    , Attr.style "align-items" "center"
                    , Attr.style "justify-content" "center"
                    , Attr.style "border-right" "1px solid rgba(0, 0, 0, 0.1)"
                    , Attr.style "cursor" "pointer"
                    , Events.onMouseDown <| \_ -> props.onMenuSelect ColorSelectMenu
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

              else
                Empty.view
            , if display.backgroundColor then
                Html.div
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

              else
                Empty.view
            , if display.fontSize then
                Html.div
                    [ Attr.style "width" "72px"
                    , Attr.style "height" "48px"
                    , Attr.style "font-size" "1.2rem"
                    , Attr.style "display" "flex"
                    , Attr.style "align-items" "center"
                    , Attr.style "justify-content" "center"
                    , Attr.style "cursor" "pointer"
                    , Attr.style "border-right" "1px solid rgba(0, 0, 0, 0.1)"
                    , Events.onMouseDown <| \_ -> props.onMenuSelect CloseMenu
                    ]
                    [ DropDownList.view props.onToggleDropDownList
                        "fontSize"
                        props.dropDownIndex
                        (\s -> props.onFontSizeChanged <| FontSize.fromInt (String.toInt s |> Maybe.withDefault (FontSize.unwrap FontSize.default)))
                        fontSizeItems
                        (Item.getFontSize props.item |> FontSize.unwrap |> String.fromInt)
                    ]

              else
                Empty.view
            , if display.fontStyleBold then
                Html.div
                    [ Attr.style "width" "50px"
                    , Attr.style "height" "48px"
                    , Attr.style "font-size" "1.2rem"
                    , Attr.style "display" "flex"
                    , Attr.style "align-items" "center"
                    , Attr.style "justify-content" "center"
                    , Attr.style "cursor" "pointer"
                    , Events.onMouseDown <| \_ -> props.onFontStyleChanged FontStyle.Bold
                    ]
                    [ Html.div
                        [ Attr.style "color"
                            (Item.getForegroundColor props.item
                                |> Maybe.withDefault Color.black
                                |> Color.toString
                            )
                        ]
                        [ Icon.bold Color.navy 16 ]
                    ]

              else
                Empty.view
            , if display.fontStyleItalic then
                Html.div
                    [ Attr.style "width" "50px"
                    , Attr.style "height" "48px"
                    , Attr.style "font-size" "1.2rem"
                    , Attr.style "display" "flex"
                    , Attr.style "align-items" "center"
                    , Attr.style "justify-content" "center"
                    , Attr.style "cursor" "pointer"
                    , Events.onMouseDown <| \_ -> props.onFontStyleChanged FontStyle.Italic
                    ]
                    [ Html.div
                        [ Attr.style "color" <|
                            (Item.getForegroundColor props.item
                                |> Maybe.withDefault Color.black
                                |> Color.toString
                            )
                        ]
                        [ Icon.italic Color.navy 16 ]
                    ]

              else
                Empty.view
            , if display.fontStyleStrikethrough then
                Html.div
                    [ Attr.style "width" "50px"
                    , Attr.style "height" "48px"
                    , Attr.style "font-size" "1.2rem"
                    , Attr.style "display" "flex"
                    , Attr.style "align-items" "center"
                    , Attr.style "justify-content" "center"
                    , Attr.style "cursor" "pointer"
                    , Events.onMouseDown <| \_ -> props.onFontStyleChanged FontStyle.Strikethrough
                    ]
                    [ Html.div
                        [ Attr.style "color" <|
                            (Item.getBackgroundColor props.item
                                |> Maybe.withDefault Color.black
                                |> Color.toString
                            )
                        ]
                        [ Icon.strikethrough Color.navy 16 ]
                    ]

              else
                Empty.view
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
        , Events.onMouseDown <| \_ -> msg
        ]
        []


colorPicker : Int -> List Color -> (Color -> msg) -> Html msg
colorPicker x colors onColorChanged =
    Html.div
        [ Attr.style "width" "140px"
        , Attr.style "height" "150px"
        , Attr.style "background-color" <| Color.toString Color.white
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

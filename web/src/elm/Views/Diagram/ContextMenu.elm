module Views.Diagram.ContextMenu exposing (Props, viewAllMenu, viewColorMenuOnly)

import Css
    exposing
        ( absolute
        , backgroundColor
        , border3
        , borderRadius
        , borderRight3
        , bottom
        , cursor
        , displayFlex
        , flexWrap
        , fontSize
        , hex
        , int
        , justifyContent
        , left
        , margin
        , padding
        , pointer
        , position
        , px
        , rem
        , rgba
        , solid
        , spaceBetween
        , wrap
        , zIndex
        , zero
        )
import Events
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Models.Color as Color exposing (Color)
import Models.Diagram exposing (ContextMenu(..), Settings)
import Models.Dialog exposing (display)
import Models.FontSize as FontSize exposing (FontSize)
import Models.FontStyle as FontStyle exposing (FontStyle)
import Models.Item as Item exposing (Item)
import Models.Position as Position exposing (Position)
import Models.Property as Property
import Models.Size exposing (Width)
import Style.Style as Style
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Diagram.Views as Views
import Views.DropDownList as DropDownList exposing (DropDownValue)
import Views.Empty as Empty
import Views.Icon as Icon


type alias Props msg =
    { state : ContextMenu
    , item : Item
    , settings : Settings
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
        [ SvgAttr.class "context-menu"
        , SvgAttr.x <| String.fromInt <| Position.getX props.position
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
                    [ css
                        [ Css.width <| px 50
                        , Css.height <| px 48
                        , fontSize <| rem 1.2
                        , Style.flexCenter
                        , borderRight3 (px 1) solid (rgba 0 0 0 0.1)
                        , cursor pointer
                        ]
                    , Events.onMouseDown <| \_ -> props.onMenuSelect ColorSelectMenu
                    ]
                    [ Html.div []
                        [ Icon.font
                            (Item.getForegroundColor props.item
                                |> Maybe.withDefault (Views.getItemColor props.settings Property.empty props.item |> Tuple.first)
                                |> Color.toString
                            )
                            16
                        ]
                    ]

              else
                Empty.view
            , if display.backgroundColor then
                Html.div
                    [ Attr.class "background-color-menu"
                    , css
                        [ Css.width <| px 50
                        , Css.height <| px 48
                        , fontSize <| rem 1.4
                        , Style.flexCenter
                        , borderRight3 (px 1) solid (rgba 0 0 0 0.1)
                        ]
                    ]
                    [ colorCircle
                        (Item.getBackgroundColor props.item
                            |> Maybe.withDefault (Views.getItemColor props.settings Property.empty props.item |> Tuple.second)
                        )
                        (props.onMenuSelect BackgroundColorSelectMenu)
                    ]

              else
                Empty.view
            , if display.fontSize then
                Html.div
                    [ css
                        [ Css.width <| px 64
                        , Css.height <| px 48
                        , fontSize <| rem 1.2
                        , Style.flexCenter
                        , cursor pointer
                        , borderRight3 (px 1) solid (rgba 0 0 0 0.1)
                        ]
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
                    [ css
                        [ Css.width <| px 50
                        , Css.height <| px 48
                        , fontSize <| rem 1.2
                        , Style.flexCenter
                        , cursor pointer
                        ]
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
                    [ css
                        [ Css.width <| px 50
                        , Css.height <| px 48
                        , fontSize <| rem 1.2
                        , Style.flexCenter
                        , cursor pointer
                        ]
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
                    [ css
                        [ Css.width <| px 50
                        , Css.height <| px 48
                        , fontSize <| rem 1.2
                        , Style.flexCenter
                        , cursor pointer
                        ]
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
        [ css
            [ Css.width <| px 24
            , Css.height <| px 24
            , Style.roundedFull
            , backgroundColor <| hex <| Color.toString color
            , border3 (px 1) solid (rgba 0 0 0 0.1)
            , cursor pointer
            , margin <| px 2
            ]
        , Attr.class <| String.toLower <| Color.name color
        , Events.onMouseDown <| \_ -> msg
        ]
        []


colorPicker : Int -> List Color -> (Color -> msg) -> Html msg
colorPicker x colors onColorChanged =
    Html.div
        [ css
            [ Css.width <| px 140
            , Css.height <| px 150
            , backgroundColor <| hex <| Color.toString Color.white
            , Style.shadowSm
            , borderRadius <| px 2
            , position absolute
            , bottom zero
            , left <| px <| toFloat x
            , zIndex <| int 100
            , displayFlex
            , flexWrap wrap
            , justifyContent spaceBetween
            , padding <| px 8
            ]
        ]
    <|
        List.map (\color -> colorCircle color <| onColorChanged color) colors

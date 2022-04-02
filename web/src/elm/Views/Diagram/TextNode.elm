module Views.Diagram.TextNode exposing (root, view)

import Css
    exposing
        ( backgroundColor
        , borderStyle
        , color
        , focus
        , hex
        , marginLeft
        , marginTop
        , none
        , outline
        , padding4
        , property
        , px
        , transparent
        , zero
        )
import Events
import Html.Styled as Html
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events exposing (onBlur, onInput)
import Models.Color as Color exposing (Color)
import Models.Diagram as Diagram exposing (Msg(..), SelectedItem)
import Models.DiagramSettings as DiagramSettings
import Models.FontSize as FontSize
import Models.Item as Item exposing (Item)
import Models.Position exposing (Position)
import Models.Property exposing (Property)
import Models.Size exposing (Size)
import String
import Style.Style as Style
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Diagram.Views as Views


view : DiagramSettings.Settings -> Property -> Position -> SelectedItem -> Item -> Svg Msg
view settings property ( posX, posY ) selectedItem item =
    let
        ( color, _ ) =
            Views.getItemColor settings property item

        nodeWidth : Int
        nodeWidth =
            settings.size.width

        view_ : Svg Msg
        view_ =
            Svg.g
                [ Events.onClickStopPropagation <| Select <| Just { item = item, position = ( posX, posY + settings.size.height ), displayAllMenu = True }
                , Diagram.dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False
                ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt nodeWidth
                    , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                    , SvgAttr.x <| String.fromInt posX
                    , SvgAttr.y <| String.fromInt posY
                    , SvgAttr.fill settings.backgroundColor
                    ]
                    []
                , textNode settings property ( posX, posY ) ( nodeWidth, settings.size.height ) color item
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.getLineNo item_ == Item.getLineNo item then
                Svg.g []
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt nodeWidth
                        , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                        , SvgAttr.x <| String.fromInt posX
                        , SvgAttr.y <| String.fromInt posY
                        , SvgAttr.strokeWidth "1"
                        , SvgAttr.stroke "transparent"
                        , SvgAttr.fill settings.backgroundColor
                        , SvgAttr.class "ts-node"
                        ]
                        []
                    , textNodeInput settings ( posX, posY ) ( nodeWidth, settings.size.height ) item_
                    ]

            else
                view_

        Nothing ->
            view_


textNode : DiagramSettings.Settings -> Property -> Position -> Size -> Color -> Item -> Svg Msg
textNode settings property ( posX, posY ) ( svgWidth, svgHeight ) colour item =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        , SvgAttr.width <| String.fromInt svgWidth
        , SvgAttr.height <| String.fromInt svgHeight
        , SvgAttr.fill <| Color.toString colour
        , SvgAttr.color
            (Item.getForegroundColor item
                |> Maybe.withDefault Color.black
                |> Color.toString
            )
        , FontSize.svgStyledFontSize FontSize.default
        ]
        [ Html.div
            [ css
                [ Css.width <| px <| toFloat <| svgWidth
                , Css.height <| px <| toFloat <| svgHeight
                , DiagramSettings.fontFamiliy settings
                , Style.breakWord
                , Style.flexCenter
                ]
            , Attr.class "ts-node"
            ]
            [ Html.div [ css [ FontSize.cssFontSize <| Item.getFontSizeWithProperty item property ] ] [ Html.text <| Item.getText item ] ]
        ]


textNodeInput : DiagramSettings.Settings -> Position -> Size -> Item -> Svg Msg
textNodeInput settings ( posX, posY ) ( svgWidth, svgHeight ) item =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        , SvgAttr.width <| String.fromInt svgWidth
        , SvgAttr.height <| String.fromInt svgHeight
        ]
        [ Html.div
            [ css
                [ backgroundColor transparent
                , Css.width <| px <| toFloat <| svgWidth
                , Css.height <| px <| toFloat <| svgHeight
                , Style.flexCenter
                ]
            ]
            [ Html.input
                [ Attr.id "edit-item"
                , Attr.type_ "text"
                , Attr.autofocus True
                , Attr.autocomplete False
                , Attr.style "padding" "8px 8px 8px 0"
                , css
                    [ DiagramSettings.fontFamiliy settings
                    , padding4 (px 8) (px 8) (px 8) zero
                    , borderStyle none
                    , backgroundColor transparent
                    , outline none
                    , FontSize.cssFontSize <| Item.getFontSize item
                    , Css.width <| px <| toFloat <| svgWidth - 20
                    , marginTop <| px 2
                    , marginLeft <| px 2
                    , color <|
                        hex
                            (Item.getForegroundColor item
                                |> Maybe.withDefault Color.black
                                |> Color.toString
                            )
                    , focus
                        [ outline none
                        ]
                    ]
                , Attr.value <| " " ++ String.trimLeft (Item.getText item)
                , onInput EditSelectedItem
                , Events.onEnter <| EndEditSelectedItem item
                , onBlur <| Select Nothing
                ]
                []
            ]
        ]


root : { settings : DiagramSettings.Settings, property : Property, position : Position, selectedItem : SelectedItem, item : Item } -> Svg Msg
root { settings, property, position, selectedItem, item } =
    let
        ( posX, posY ) =
            position

        borderColor : String
        borderColor =
            Item.getBackgroundColor item
                |> Maybe.andThen (\c -> Just <| Color.toString c)
                |> Maybe.withDefault settings.color.activity.backgroundColor

        textColor : Color
        textColor =
            Item.getForegroundColor item
                |> Maybe.andThen (\c -> Just <| Color.toString c)
                |> Maybe.withDefault settings.color.activity.color
                |> Color.fromString

        view_ : Svg Msg
        view_ =
            Svg.g
                [ Events.onClickStopPropagation <| Select <| Just { item = item, position = ( posX, posY + settings.size.height ), displayAllMenu = True }
                , Diagram.dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False
                ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt settings.size.width
                    , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                    , SvgAttr.x <| String.fromInt posX
                    , SvgAttr.y <| String.fromInt posY
                    , SvgAttr.strokeWidth "3"
                    , SvgAttr.stroke borderColor
                    , SvgAttr.rx "32"
                    , SvgAttr.ry "32"
                    , SvgAttr.fill settings.backgroundColor
                    , SvgAttr.class "ts-node"
                    ]
                    []
                , textNode settings property ( posX, posY ) ( settings.size.width, settings.size.height ) textColor item
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.getLineNo item_ == Item.getLineNo item then
                Svg.g []
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt settings.size.width
                        , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                        , SvgAttr.x <| String.fromInt posX
                        , SvgAttr.y <| String.fromInt posY
                        , SvgAttr.strokeWidth "3"
                        , SvgAttr.stroke borderColor
                        , SvgAttr.rx "32"
                        , SvgAttr.ry "32"
                        , SvgAttr.fill settings.backgroundColor
                        , SvgAttr.class "ts-node"
                        ]
                        []
                    , textNodeInput settings ( posX, posY ) ( settings.size.width, settings.size.height ) item_
                    ]

            else
                view_

        Nothing ->
            view_

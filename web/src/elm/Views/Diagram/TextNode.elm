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
import Models.Diagram as Diagram exposing (Msg(..), ResizeDirection(..), SelectedItem)
import Models.DiagramSettings as DiagramSettings
import Models.FontSize as FontSize
import Models.Item as Item exposing (Item)
import Models.Position as Position exposing (Position)
import Models.Property as Property exposing (Property)
import Models.Size as Size exposing (Size)
import String
import Style.Style as Style
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Diagram.Views as Views


view : DiagramSettings.Settings -> Property -> Position -> SelectedItem -> Item -> Svg Msg
view settings property position selectedItem item =
    let
        view_ : Svg Msg
        view_ =
            let
                ( color, _ ) =
                    Views.getItemColor settings property item

                ( posX, posY ) =
                    Item.getPosition item position

                ( offsetWidth, offsetHeight ) =
                    Item.getOffsetSize item

                ( width, height ) =
                    ( Property.getCardWidth property, Property.getCardHeight property )
                        |> Tuple.mapBoth
                            (\w -> Maybe.withDefault settings.size.width w)
                            (\h -> Maybe.withDefault (settings.size.height - 1) h)
                        |> Tuple.mapBoth
                            (\w -> w + offsetWidth)
                            (\h -> h + offsetHeight)
            in
            Svg.g
                [ Events.onClickStopPropagation <| Select <| Just { item = item, position = position, displayAllMenu = True } ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt width
                    , SvgAttr.height <| String.fromInt <| height - 1
                    , SvgAttr.x <| String.fromInt posX
                    , SvgAttr.y <| String.fromInt posY
                    , SvgAttr.fill settings.backgroundColor
                    ]
                    []
                , textNode settings property ( posX, posY ) ( width, height ) color item
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.getLineNo item_ == Item.getLineNo item then
                let
                    selectedItemOffsetSize : Size
                    selectedItemOffsetSize =
                        Item.getOffsetSize item_

                    selectedItemOffsetPosition : Position
                    selectedItemOffsetPosition =
                        Item.getOffset item_

                    selectedItemPosition : Position
                    selectedItemPosition =
                        position
                            |> Tuple.mapBoth
                                (\x -> x + Position.getX selectedItemOffsetPosition)
                                (\y -> y + Position.getY selectedItemOffsetPosition)

                    selectedItemSize : Size
                    selectedItemSize =
                        ( settings.size.width, settings.size.height - 1 )
                            |> Tuple.mapBoth
                                (\w -> max 0 (w + Size.getWidth selectedItemOffsetSize))
                                (\h -> max 0 (h + Size.getHeight selectedItemOffsetSize))

                    ( x_, y_ ) =
                        selectedItemPosition

                    ( width_, height_ ) =
                        selectedItemSize
                in
                Svg.g
                    [ Diagram.dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False ]
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt width_
                        , SvgAttr.height <| String.fromInt <| height_ - 1
                        , SvgAttr.x <| String.fromInt x_
                        , SvgAttr.y <| String.fromInt y_
                        , SvgAttr.strokeWidth "1"
                        , SvgAttr.stroke "transparent"
                        , SvgAttr.fill settings.backgroundColor
                        , SvgAttr.class "ts-node"
                        ]
                        []
                    , Views.resizeCircle item TopLeft ( x_ - 8, y_ - 8 )
                    , Views.resizeCircle item TopRight ( x_ + width_ + 8, y_ - 8 )
                    , Views.resizeCircle item BottomRight ( x_ + width_ + 8, y_ + height_ + 8 )
                    , Views.resizeCircle item BottomLeft ( x_ - 8, y_ + height_ + 8 )
                    , textNodeInput settings ( x_, y_ ) ( width_, height_ ) item_
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
                , FontSize.cssFontSize <| Item.getFontSizeWithProperty item property
                ]
            , Attr.class "ts-node"
            ]
            [ Html.text <| Item.getText item ]
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
                    , FontSize.cssFontSize <| Maybe.withDefault FontSize.default <| Item.getFontSize item
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
                [ Events.onClickStopPropagation <| Select <| Just { item = item, position = ( posX, posY + settings.size.height ), displayAllMenu = True } ]
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

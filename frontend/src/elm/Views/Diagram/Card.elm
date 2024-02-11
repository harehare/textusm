module Views.Diagram.Card exposing (docs, text, viewWithDefaultColor)

import Attributes
import Css exposing (backgroundColor, property)
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Settings as DiagramSettings
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Events
import Html.Attributes as Attr
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Markdown
import Models.Color as Color exposing (Color)
import Models.Diagram as Diagram exposing (ResizeDirection(..), SelectedItem, SelectedItemInfo)
import Models.FontSize as FontSize exposing (FontSize)
import Models.Item as Item exposing (Item)
import Models.Position as Position exposing (Position)
import Models.Property as Property exposing (Property)
import Models.Size as Size exposing (Size)
import String
import Style.Style as Style
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Diagram.Views as Views


viewWithDefaultColor :
    { settings : DiagramSettings.Settings
    , property : Property
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , canMove : Bool
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
viewWithDefaultColor { settings, property, position, selectedItem, item, canMove, dragStart, onEditSelectedItem, onEndEditSelectedItem, onSelect } =
    let
        ( foreColor, backColor ) =
            Views.getItemColor settings property item
    in
    view
        { settings = settings
        , property = property
        , position = position
        , selectedItem = selectedItem
        , item = item
        , canMove = canMove
        , defaultColor =
            { defaultForeColor = foreColor
            , defaultBackColor = backColor
            }
        , onEditSelectedItem = onEditSelectedItem
        , onEndEditSelectedItem = onEndEditSelectedItem
        , onSelect = onSelect
        , dragStart = dragStart
        }


view :
    { settings : DiagramSettings.Settings
    , property : Property
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , canMove : Bool
    , defaultColor :
        { defaultForeColor : Color
        , defaultBackColor : Color
        }
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
view { settings, property, position, selectedItem, item, canMove, defaultColor, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        ( foreColor, backColor ) =
            ( Item.getForegroundColor item, Item.getBackgroundColor item )
                |> Tuple.mapBoth
                    (\c -> c |> Maybe.withDefault defaultColor.defaultForeColor)
                    (\c -> c |> Maybe.withDefault defaultColor.defaultBackColor)

        lockEditing : Bool
        lockEditing =
            settings.lockEditing |> Maybe.withDefault False

        view_ : Svg msg
        view_ =
            let
                ( posX, posY ) =
                    Item.getPosition item position

                ( offsetWidth, offsetHeight ) =
                    Item.getOffsetSize item

                ( width, height ) =
                    ( Property.getCardWidth property, Property.getCardHeight property )
                        |> Tuple.mapBoth
                            (\w -> Maybe.withDefault (CardSize.toInt settings.size.width) w)
                            (\h -> Maybe.withDefault (CardSize.toInt settings.size.height - 1) h)
                        |> Tuple.mapBoth
                            (\w -> w + offsetWidth)
                            (\h -> h + offsetHeight)
            in
            Svg.g
                [ SvgAttr.class "card"
                , Attributes.dataTest <| "card-" ++ (String.fromInt <| Item.getLineNo item)
                , if lockEditing then
                    SvgAttr.style ""

                  else
                    Events.onClickStopPropagation <|
                        onSelect <|
                            Just { item = item, position = position, displayAllMenu = True }
                ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt width
                    , SvgAttr.height <| String.fromInt height
                    , SvgAttr.x <| String.fromInt posX
                    , SvgAttr.y <| String.fromInt posY
                    , SvgAttr.fill <| Color.toString backColor
                    , SvgAttr.rx "1"
                    , SvgAttr.ry "1"
                    , SvgAttr.style "filter:url(#shadow)"
                    , SvgAttr.class "ts-card"
                    , SvgAttr.stroke "rgba(0, 0, 0, 0.05)"
                    , css [ Css.hover [ Css.cursor Css.pointer ] ]
                    ]
                    []
                , text
                    { settings = settings
                    , position = ( posX, posY )
                    , size = ( width, height )
                    , color = foreColor
                    , fontSize = Item.getFontSizeWithProperty item property
                    , item = item
                    }
                ]
    in
    if lockEditing then
        view_

    else
        case selectedItem of
            Just item_ ->
                if Item.eq item_ item then
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
                            ( CardSize.toInt settings.size.width, CardSize.toInt settings.size.height - 1 )
                                |> Tuple.mapBoth
                                    (\w -> max 0 (w + Size.getWidth selectedItemOffsetSize))
                                    (\h -> max 0 (h + Size.getHeight selectedItemOffsetSize))

                        ( x_, y_ ) =
                            selectedItemPosition
                    in
                    Svg.g
                        [ if canMove then
                            dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False

                          else
                            SvgAttr.style ""
                        ]
                        [ Svg.rect
                            [ SvgAttr.width <| String.fromInt <| Size.getWidth selectedItemSize + 16
                            , SvgAttr.height <| String.fromInt <| Size.getHeight selectedItemSize + 16
                            , SvgAttr.x (String.fromInt <| x_ - 8)
                            , SvgAttr.y (String.fromInt <| y_ - 8)
                            , SvgAttr.rx "1"
                            , SvgAttr.ry "1"
                            , SvgAttr.fill "transparent"
                            , SvgAttr.stroke "rgba(38, 107, 154, 0.6)"
                            , SvgAttr.strokeWidth "2"
                            ]
                            []
                        , Svg.rect
                            [ SvgAttr.width <| String.fromInt <| Size.getWidth selectedItemSize + 4
                            , SvgAttr.height <| String.fromInt <| Size.getHeight selectedItemSize + 4
                            , SvgAttr.x (String.fromInt <| x_ - 2)
                            , SvgAttr.y (String.fromInt <| y_ - 2)
                            , SvgAttr.rx "1"
                            , SvgAttr.ry "1"
                            , SvgAttr.fill <| Color.toString backColor
                            , SvgAttr.style "filter:url(#shadow)"
                            ]
                            []
                        , Views.resizeCircle { item = item, direction = TopLeft, position = ( x_ - 8, y_ - 8 ), dragStart = dragStart }
                        , Views.resizeCircle { item = item, direction = TopRight, position = ( x_ + Size.getWidth selectedItemSize + 8, y_ - 8 ), dragStart = dragStart }
                        , Views.resizeCircle { item = item, direction = BottomRight, position = ( x_ + Size.getWidth selectedItemSize + 8, y_ + Size.getHeight selectedItemSize + 8 ), dragStart = dragStart }
                        , Views.resizeCircle { item = item, direction = BottomLeft, position = ( x_ - 8, y_ + Size.getHeight selectedItemSize + 8 ), dragStart = dragStart }
                        , Views.inputView
                            { settings = settings
                            , fontSize = Item.getFontSizeWithProperty item property
                            , position = selectedItemPosition
                            , size = selectedItemSize
                            , color = foreColor
                            , item = item_
                            , onEditSelectedItem = onEditSelectedItem
                            , onEndEditSelectedItem = onEndEditSelectedItem
                            , onSelect = onSelect
                            }
                        ]

                else
                    view_

            Nothing ->
                view_


text :
    { settings : DiagramSettings.Settings
    , position : Position
    , size : Size
    , color : Color
    , fontSize : FontSize
    , item : Item
    }
    -> Svg msg
text props =
    if Item.isMarkdown props.item then
        Svg.foreignObject
            [ SvgAttr.x <| String.fromInt <| Position.getX props.position
            , SvgAttr.y <| String.fromInt <| Position.getY props.position
            , SvgAttr.width <| String.fromInt <| Size.getWidth props.size
            , SvgAttr.height <| String.fromInt <| Size.getHeight props.size
            , SvgAttr.fill <| Color.toString <| props.color
            , SvgAttr.color <| Color.toString <| props.color
            , FontSize.svgStyledFontSize <| props.fontSize
            , SvgAttr.class "ts-text"
            , SvgAttr.cursor "pointer"
            ]
            [ markdown props.settings
                ( props.color
                , if Item.isHighlight props.item then
                    Color.yellow

                  else
                    Color.transparent
                )
                (Item.getText props.item)
            ]

    else if Item.isImage props.item then
        Views.image { size = props.size, position = props.position, item = props.item }

    else if String.length (Item.getText props.item) > 13 then
        Svg.foreignObject
            [ SvgAttr.x <| String.fromInt <| Position.getX props.position
            , SvgAttr.y <| String.fromInt <| Position.getY props.position
            , SvgAttr.width <| String.fromInt <| Size.getWidth props.size
            , SvgAttr.height <| String.fromInt <| Size.getHeight props.size
            , SvgAttr.fill <| Color.toString <| props.color
            , SvgAttr.color <| Color.toString <| props.color
            , FontSize.svgStyledFontSize <| props.fontSize
            , SvgAttr.class "ts-text"
            ]
            [ Html.div
                [ css
                    [ Style.paddingSm
                    , DiagramSettings.fontFamiliy props.settings
                    , property "word-wrap" "break-word"
                    , Css.cursor Css.pointer
                    ]
                ]
                [ Html.span
                    [ css
                        [ backgroundColor <|
                            if Item.isHighlight props.item then
                                Css.hex <| Color.toString Color.yellow

                            else
                                Css.hex <| Color.toString Color.transparent
                        ]
                    ]
                    [ Html.text <| Item.getText props.item ]
                ]
            ]

    else
        Views.plainText
            { settings = props.settings
            , position = props.position
            , size = props.size
            , foreColor = props.color
            , fontSize = props.fontSize
            , text = Item.getText <| props.item
            , isHighlight = Item.isHighlight props.item
            }


markdown : DiagramSettings.Settings -> ( Color, Color ) -> String -> Html msg
markdown settings ( foreColor, backColor ) t =
    Html.fromUnstyled <|
        Markdown.toHtml
            [ Attr.class "md-content"
            , Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
            , Attr.style "color" <| Color.toString foreColor
            , Attr.style "backgroundColor" <| Color.toString backColor
            , Attr.style "cursor" "pointer"
            ]
            t


docs : Chapter x
docs =
    Chapter.chapter "Card"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ viewWithDefaultColor
                    { settings = DiagramSettings.default
                    , property = Property.empty
                    , position = Position.zero
                    , selectedItem = Nothing
                    , item = Item.new |> Item.withText "test"
                    , canMove = True
                    , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                    , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , dragStart = \_ _ -> SvgAttr.style ""
                    }
                ]
                |> Svg.toUnstyled
            )

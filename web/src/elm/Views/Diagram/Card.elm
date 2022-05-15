module Views.Diagram.Card exposing (text, view, viewWithDefaultColor)

import Css exposing (backgroundColor, property)
import Events
import Html.Attributes as Attr
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Markdown
import Models.Color as Color exposing (Color)
import Models.Diagram as Diagram exposing (Msg(..), ResizeDirection(..), SelectedItem)
import Models.DiagramSettings as DiagramSettings
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
    }
    -> Svg Msg
viewWithDefaultColor { settings, property, position, selectedItem, item, canMove } =
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
        , defaultForeColor = foreColor
        , defaultBackColor = backColor
        }


view :
    { settings : DiagramSettings.Settings
    , property : Property
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , canMove : Bool
    , defaultForeColor : Color
    , defaultBackColor : Color
    }
    -> Svg Msg
view { settings, property, position, selectedItem, item, canMove, defaultForeColor, defaultBackColor } =
    let
        ( foreColor, backColor ) =
            ( Item.getForegroundColor item, Item.getBackgroundColor item )
                |> Tuple.mapBoth
                    (\c -> c |> Maybe.withDefault defaultForeColor)
                    (\c -> c |> Maybe.withDefault defaultBackColor)

        view_ : Svg Msg
        view_ =
            let
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
                [ SvgAttr.class "card"
                , if Item.isImage item then
                    SvgAttr.class ""

                  else
                    Events.onClickStopPropagation <|
                        Select <|
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
                    ]
                    []
                , text settings
                    ( posX, posY )
                    ( width, height )
                    foreColor
                    (Item.getFontSizeWithProperty item property)
                    item
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
                in
                Svg.g
                    [ if canMove then
                        Diagram.dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False

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
                    , Views.resizeCircle item TopLeft ( x_ - 8, y_ - 8 )
                    , Views.resizeCircle item TopRight ( x_ + Size.getWidth selectedItemSize + 8, y_ - 8 )
                    , Views.resizeCircle item BottomRight ( x_ + Size.getWidth selectedItemSize + 8, y_ + Size.getHeight selectedItemSize + 8 )
                    , Views.resizeCircle item BottomLeft ( x_ - 8, y_ + Size.getHeight selectedItemSize + 8 )
                    , Views.inputView
                        { settings = settings
                        , fontSize = Item.getFontSizeWithProperty item property
                        , position = selectedItemPosition
                        , size = selectedItemSize
                        , color = foreColor
                        , item = item_
                        }
                    ]

            else
                view_

        Nothing ->
            view_


text : DiagramSettings.Settings -> Position -> Size -> Color -> FontSize -> Item -> Svg Msg
text settings ( posX, posY ) ( svgWidth, svgHeight ) colour fs item =
    if Item.isMarkdown item then
        Svg.foreignObject
            [ SvgAttr.x <| String.fromInt posX
            , SvgAttr.y <| String.fromInt posY
            , SvgAttr.width <| String.fromInt svgWidth
            , SvgAttr.height <| String.fromInt svgHeight
            , SvgAttr.fill <| Color.toString colour
            , SvgAttr.color <| Color.toString colour
            , FontSize.svgStyledFontSize fs
            , SvgAttr.class "ts-text"
            ]
            [ markdown settings
                ( colour
                , if Item.isHighlight item then
                    Color.yellow

                  else
                    Color.transparent
                )
                (Item.getText item
                    |> String.trim
                    |> String.dropLeft 3
                    |> String.trim
                )
            ]

    else if Item.isImage item then
        Views.image ( svgWidth, svgHeight ) ( posX, posY ) <| String.trim <| Item.getText item

    else if String.length (Item.getText item) > 15 then
        Svg.foreignObject
            [ SvgAttr.x <| String.fromInt posX
            , SvgAttr.y <| String.fromInt posY
            , SvgAttr.width <| String.fromInt svgWidth
            , SvgAttr.height <| String.fromInt svgHeight
            , SvgAttr.fill <| Color.toString colour
            , SvgAttr.color <| Color.toString colour
            , FontSize.svgStyledFontSize fs
            , SvgAttr.class "ts-text"
            ]
            [ Html.div
                [ css
                    [ Style.paddingSm
                    , DiagramSettings.fontFamiliy settings
                    , property "word-wrap" "break-word"
                    ]
                ]
                [ Html.span
                    [ css
                        [ backgroundColor <|
                            if Item.isHighlight item then
                                Css.hex <| Color.toString Color.yellow

                            else
                                Css.hex <| Color.toString Color.transparent
                        ]
                    ]
                    [ Html.text <| Item.getText item ]
                ]
            ]

    else
        Views.plainText
            { settings = settings
            , position = ( posX, posY )
            , size = ( svgWidth, svgHeight )
            , foreColor = colour
            , fontSize = fs
            , text = Item.getText item
            , isHighlight = Item.isHighlight item
            }


markdown : DiagramSettings.Settings -> ( Color, Color ) -> String -> Html Msg
markdown settings ( foreColor, backColor ) t =
    Html.fromUnstyled <|
        Markdown.toHtml
            [ Attr.class "md-content"
            , Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
            , Attr.style "color" <| Color.toString foreColor
            , Attr.style "backgroundColor" <| Color.toString backColor
            ]
            t

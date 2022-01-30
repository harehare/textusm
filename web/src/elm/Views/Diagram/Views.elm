module Views.Diagram.Views exposing
    ( canvas
    , canvasBottom
    , canvasImage
    , card
    , getItemColor
    , grid
    , horizontalLine
    , node
    , plainText
    , rootTextNode
    , verticalLine
    )

import Constants
import Css
    exposing
        ( backgroundColor
        , borderStyle
        , breakWord
        , color
        , focus
        , hex
        , marginLeft
        , marginTop
        , none
        , outline
        , overflowWrap
        , padding4
        , property
        , px
        , transparent
        , zero
        )
import Events
import Html.Attributes as LegacyAttr
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events exposing (onBlur, onInput)
import Markdown
import Models.Color as Color exposing (Color)
import Models.Diagram as Diagram exposing (MoveState(..), Msg(..), ResizeDirection(..), SelectedItem)
import Models.DiagramSettings as DiagramSettings
import Models.FontSize as FontSize exposing (FontSize)
import Models.Item as Item exposing (Item, ItemType(..), Items)
import Models.ItemSettings as ItemSettings
import Models.Position as Position exposing (Position)
import Models.Property as Property exposing (Property)
import Models.Size as Size exposing (Size)
import String
import Style.Style as Style
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr


getItemColor : DiagramSettings.Settings -> Property -> Item -> ( Color, Color )
getItemColor settings property item =
    case
        ( Item.getItemType item
        , Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getForegroundColor
        , Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getBackgroundColor
        )
    of
        ( _, Just c, Just b ) ->
            ( c, b )

        ( Activities, Just c, Nothing ) ->
            ( c
            , Property.getCardBackgroundColor1 property
                |> Maybe.withDefault (Color.fromString settings.color.activity.backgroundColor)
            )

        ( Activities, Nothing, Just b ) ->
            ( Property.getCardForegroundColor1 property
                |> Maybe.withDefault (Color.fromString settings.color.activity.color)
            , b
            )

        ( Activities, Nothing, Nothing ) ->
            ( Property.getCardForegroundColor1 property
                |> Maybe.withDefault (Color.fromString settings.color.activity.color)
            , Property.getCardBackgroundColor1 property
                |> Maybe.withDefault (Color.fromString settings.color.activity.backgroundColor)
            )

        ( Tasks, Just c, Nothing ) ->
            ( c
            , Property.getCardBackgroundColor2 property
                |> Maybe.withDefault (Color.fromString settings.color.task.backgroundColor)
            )

        ( Tasks, Nothing, Just b ) ->
            ( Property.getCardForegroundColor2 property
                |> Maybe.withDefault (Color.fromString settings.color.task.color)
            , b
            )

        ( Tasks, Nothing, Nothing ) ->
            ( Property.getCardForegroundColor2 property
                |> Maybe.withDefault (Color.fromString settings.color.task.color)
            , Property.getCardBackgroundColor2 property
                |> Maybe.withDefault (Color.fromString settings.color.task.backgroundColor)
            )

        ( _, Just c, Nothing ) ->
            ( c
            , Property.getCardBackgroundColor3 property
                |> Maybe.withDefault (Color.fromString settings.color.story.backgroundColor)
            )

        ( _, Nothing, Just b ) ->
            ( Property.getCardForegroundColor3 property
                |> Maybe.withDefault (Color.fromString settings.color.story.color)
            , b
            )

        _ ->
            ( Property.getCardForegroundColor3 property
                |> Maybe.withDefault (Color.fromString settings.color.story.color)
            , Property.getCardBackgroundColor3 property
                |> Maybe.withDefault (Color.fromString settings.color.story.backgroundColor)
            )


getCanvasColor : DiagramSettings.Settings -> Property -> Item -> ( Color, Color )
getCanvasColor settings property item =
    case
        ( Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getForegroundColor
        , Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getBackgroundColor
        )
    of
        ( Just f, Just b ) ->
            ( f, b )

        ( Just f, Nothing ) ->
            ( f
            , Property.getCanvasBackgroundColor property
                |> Maybe.withDefault Color.transparent
            )

        ( Nothing, Just b ) ->
            ( Property.getLineColor property
                |> Maybe.withDefault (Color.fromString settings.color.line)
            , b
            )

        _ ->
            ( Property.getLineColor property
                |> Maybe.withDefault (Color.fromString settings.color.line)
            , Property.getCanvasBackgroundColor property
                |> Maybe.withDefault Color.transparent
            )


getLineColor : DiagramSettings.Settings -> Item -> Color
getLineColor settings item =
    Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getBackgroundColor |> Maybe.withDefault (Color.fromString settings.color.line)


card :
    { settings : DiagramSettings.Settings
    , property : Property
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , canMove : Bool
    }
    -> Svg Msg
card { settings, property, position, selectedItem, item, canMove } =
    let
        ( color, backgroundColor ) =
            getItemColor settings property item

        ( offsetX, offsetY ) =
            Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getOffset

        ( offsetWidth, offsetHeight ) =
            Item.getOffsetSize item

        ( posX, posY ) =
            if ( offsetX, offsetY ) == Position.zero then
                position

            else
                position |> Tuple.mapBoth (\x -> x + offsetX) (\y -> y + offsetY)

        ( width, height ) =
            ( settings.size.width, settings.size.height - 1 ) |> Tuple.mapBoth (\w -> w + offsetWidth) (\h -> h + offsetHeight)

        view_ : Svg Msg
        view_ =
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
                    , SvgAttr.fill <| Color.toString backgroundColor
                    , SvgAttr.rx "1"
                    , SvgAttr.ry "1"
                    , SvgAttr.style "filter:url(#shadow)"
                    , SvgAttr.class "ts-card"
                    ]
                    []
                , text settings
                    ( posX, posY )
                    ( width, height )
                    color
                    (Item.getFontSize item)
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
                        ( Position.getX selectedItemPosition, Position.getY selectedItemPosition )
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
                        , SvgAttr.fill <| Color.toString backgroundColor
                        , SvgAttr.style "filter:url(#shadow)"
                        ]
                        []
                    , resizeCircle item TopLeft ( x_ - 8, y_ - 8 )
                    , resizeCircle item TopRight ( x_ + Size.getWidth selectedItemSize + 8, y_ - 8 )
                    , resizeCircle item BottomRight ( x_ + Size.getWidth selectedItemSize + 8, y_ + Size.getHeight selectedItemSize + 8 )
                    , resizeCircle item BottomLeft ( x_ - 8, y_ + Size.getHeight selectedItemSize + 8 )
                    , inputView
                        { settings = settings
                        , fontSize = Item.getFontSize item
                        , position = ( x_, y_ )
                        , size = selectedItemSize
                        , color = color
                        , item = item_
                        }
                    , comments settings ( x_ + Size.getWidth selectedItemSize + 24, y_ + 2 ) (Item.getComments item)
                    ]

            else
                view_

        Nothing ->
            view_


comments : DiagramSettings.Settings -> Position -> Maybe String -> Svg Msg
comments settings ( posX, posY ) comments_ =
    case comments_ of
        Just c ->
            Svg.g []
                [ Svg.rect
                    [ SvgAttr.width "125"
                    , SvgAttr.height "60"
                    , SvgAttr.x <| String.fromInt posX
                    , SvgAttr.y <| String.fromInt posY
                    , SvgAttr.fill "#3D3D3D"
                    , SvgAttr.rx "6"
                    , SvgAttr.ry "6"
                    , SvgAttr.class "ts-card"
                    ]
                    []
                , Svg.path
                    [ SvgAttr.d
                        (String.join " "
                            [ "M"
                            , String.fromInt <| posX - 8
                            , String.fromInt <| posY + 20
                            , "L"
                            , String.fromInt <| posX + 2
                            , String.fromInt <| posY + 10
                            , "L"
                            , String.fromInt <| posX + 2
                            , String.fromInt <| posY + 30
                            , "Z"
                            ]
                        )
                    , SvgAttr.fill "#3D3D3D"
                    ]
                    []
                , Svg.foreignObject
                    [ SvgAttr.x <| String.fromInt <| posX - 1
                    , SvgAttr.y <| String.fromInt <| posY - 2
                    , SvgAttr.width "125"
                    , SvgAttr.height "60"
                    , SvgAttr.color "#f5f5f6"
                    , FontSize.svgStyledFontSize <| FontSize.fromInt 11
                    , SvgAttr.class "ts-text"
                    ]
                    [ Html.div
                        [ css
                            [ DiagramSettings.fontFamiliy settings
                            , property "word-wrap" "break-word"
                            , overflowWrap breakWord
                            , Style.paddingSm
                            ]
                        ]
                        [ Html.text <| String.dropLeft 1 c ]
                    ]
                ]

        Nothing ->
            Svg.g [] []


horizontalLine :
    { settings : DiagramSettings.Settings
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    }
    -> Svg Msg
horizontalLine { settings, position, selectedItem, item } =
    let
        color : Color
        color =
            getLineColor settings item

        ( offsetX, offsetY ) =
            Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getOffset

        ( offsetWidth, offsetHeight ) =
            Item.getOffsetSize item

        ( posX, posY ) =
            if ( offsetX, offsetY ) == Position.zero then
                position

            else
                position |> Tuple.mapBoth (\x -> x + offsetX) (\y -> y + offsetY)

        width : Int
        width =
            settings.size.width + offsetWidth

        view_ : Svg Msg
        view_ =
            Svg.g
                [ Events.onClickStopPropagation <|
                    Select <|
                        Just { item = item, position = Tuple.mapSecond (\y -> y - settings.size.width + offsetHeight + 72) position, displayAllMenu = False }
                ]
                [ Svg.line
                    [ SvgAttr.x1 <| String.fromInt posX
                    , SvgAttr.y1 <| String.fromInt posY
                    , SvgAttr.x2 <| String.fromInt <| posX + width
                    , SvgAttr.y2 <| String.fromInt posY
                    , SvgAttr.stroke <| Color.toString color
                    , SvgAttr.strokeWidth "6"
                    , SvgAttr.class "ts-line"
                    ]
                    []
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

                    selectedItemSize : Position
                    selectedItemSize =
                        ( settings.size.width, settings.size.height - 1 )
                            |> Tuple.mapBoth
                                (\w -> max 0 (w + Size.getWidth selectedItemOffsetSize))
                                (\h -> max 0 (h + Size.getHeight selectedItemOffsetSize))

                    ( x_, y_ ) =
                        ( Position.getX selectedItemPosition, Position.getY selectedItemPosition )
                in
                Svg.g
                    [ Diagram.dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False ]
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt <| Size.getWidth selectedItemSize + 16
                        , SvgAttr.height "16"
                        , SvgAttr.x (String.fromInt <| x_ - 8)
                        , SvgAttr.y (String.fromInt <| y_ - 8)
                        , SvgAttr.rx "1"
                        , SvgAttr.ry "1"
                        , SvgAttr.fill "transparent"
                        , SvgAttr.stroke <| Color.toString Color.background1Defalut
                        , SvgAttr.strokeWidth "1"
                        ]
                        []
                    , Svg.line
                        [ SvgAttr.x1 (String.fromInt <| x_ - 2)
                        , SvgAttr.y1 (String.fromInt <| y_)
                        , SvgAttr.x2 (String.fromInt <| x_ + Size.getWidth selectedItemSize + 4)
                        , SvgAttr.y2 (String.fromInt <| y_)
                        , SvgAttr.fill "transparent"
                        , SvgAttr.stroke <| Color.toString color
                        , SvgAttr.strokeWidth "6"
                        ]
                        []
                    , resizeCircle item Left ( x_ - 8, y_ )
                    , resizeCircle item Right ( x_ + Size.getWidth selectedItemSize + 8, y_ )
                    ]

            else
                view_

        Nothing ->
            view_


verticalLine :
    { settings : DiagramSettings.Settings
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    }
    -> Svg Msg
verticalLine { settings, position, selectedItem, item } =
    let
        color : Color
        color =
            getLineColor settings item

        ( offsetX, offsetY ) =
            Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getOffset

        ( _, offsetHeight ) =
            Item.getOffsetSize item

        ( posX, posY ) =
            if ( offsetX, offsetY ) == Position.zero then
                position

            else
                position |> Tuple.mapBoth (\x -> x + offsetX) (\y -> y + offsetY)

        height : Int
        height =
            settings.size.height + offsetHeight

        view_ : Svg Msg
        view_ =
            Svg.g
                [ Events.onClickStopPropagation <|
                    Select <|
                        Just { item = item, position = position, displayAllMenu = False }
                ]
                [ Svg.line
                    [ SvgAttr.x1 <| String.fromInt posX
                    , SvgAttr.y1 <| String.fromInt posY
                    , SvgAttr.x2 <| String.fromInt <| posX
                    , SvgAttr.y2 <| String.fromInt <| posY + height
                    , SvgAttr.stroke <| Color.toString color
                    , SvgAttr.strokeWidth "6"
                    , SvgAttr.class "ts-line"
                    ]
                    []
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
                        ( Position.getX selectedItemPosition, Position.getY selectedItemPosition )
                in
                Svg.g
                    [ Diagram.dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False ]
                    [ Svg.rect
                        [ SvgAttr.width "16"
                        , SvgAttr.height <| String.fromInt <| Size.getHeight selectedItemSize + 16
                        , SvgAttr.x <| String.fromInt <| x_ - 8
                        , SvgAttr.y <| String.fromInt <| y_ - 8
                        , SvgAttr.rx "1"
                        , SvgAttr.ry "1"
                        , SvgAttr.fill "transparent"
                        , SvgAttr.stroke <| Color.toString Color.background1Defalut
                        , SvgAttr.strokeWidth "1"
                        ]
                        []
                    , Svg.line
                        [ SvgAttr.x1 (String.fromInt <| x_)
                        , SvgAttr.y1 (String.fromInt <| y_ - 2)
                        , SvgAttr.x2 (String.fromInt <| x_)
                        , SvgAttr.y2 (String.fromInt <| y_ + Size.getHeight selectedItemSize + 8)
                        , SvgAttr.fill "transparent"
                        , SvgAttr.stroke <| Color.toString color
                        , SvgAttr.strokeWidth "6"
                        ]
                        []
                    , resizeCircle item Top ( x_, y_ - 8 )
                    , resizeCircle item Bottom ( x_, y_ + Size.getHeight selectedItemSize + 8 )
                    ]

            else
                view_

        Nothing ->
            view_


resizeCircle : Item -> ResizeDirection -> Position -> Svg Msg
resizeCircle item direction ( x, y ) =
    resizeCircleBase 5 item direction ( x, y )


resizeCircleForCanvas : Item -> ResizeDirection -> Position -> Svg Msg
resizeCircleForCanvas item direction ( x, y ) =
    resizeCircleBase 8 item direction ( x, y )


resizeCircleBase : Int -> Item -> ResizeDirection -> Position -> Svg Msg
resizeCircleBase size item direction ( x, y ) =
    Svg.circle
        [ SvgAttr.cx <| String.fromInt x
        , SvgAttr.cy <| String.fromInt y
        , SvgAttr.r <| String.fromInt size
        , SvgAttr.style <|
            case direction of
                TopLeft ->
                    "cursor: nwse-resize"

                TopRight ->
                    "cursor: nesw-resize"

                BottomLeft ->
                    "cursor: nesw-resize"

                BottomRight ->
                    "cursor: nwse-resize"

                Left ->
                    "cursor: w-resize"

                Right ->
                    "cursor: e-resize"

                Top ->
                    "cursor: n-resize"

                Bottom ->
                    "cursor: s-resize"
        , SvgAttr.fill <| Color.toString Color.white
        , SvgAttr.strokeWidth "2"
        , SvgAttr.stroke <| Color.toString Color.lightGray
        , Diagram.dragStart (ItemResize item direction) False
        ]
        []


inputView :
    { settings : DiagramSettings.Settings
    , fontSize : FontSize
    , position : Position
    , size : Size
    , color : Color
    , item : Item
    }
    -> Svg Msg
inputView { settings, fontSize, position, size, color, item } =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt <| Position.getX position
        , SvgAttr.y <| String.fromInt <| Position.getY position
        , SvgAttr.width <| String.fromInt <| Size.getWidth size
        , SvgAttr.height <| String.fromInt <| Size.getHeight size
        ]
        [ Html.input
            [ Attr.id "edit-item"
            , Attr.type_ "text"
            , Attr.autofocus True
            , Attr.autocomplete False
            , css
                [ padding4 (px 8) (px 8) (px 8) zero
                , DiagramSettings.fontFamiliy settings
                , Css.color <| hex <| Color.toString color
                , Css.backgroundColor transparent
                , borderStyle none
                , outline none
                , Css.width <| px <| toFloat <| Size.getWidth size - 20
                , Css.fontSize <| px <| toFloat <| FontSize.unwrap fontSize
                , marginTop <| px 2
                , marginLeft <| px 2
                , focus
                    [ outline none
                    ]
                ]
            , Attr.value <| " " ++ String.trimLeft (Item.getText item)
            , onInput EditSelectedItem
            , onBlur <| Select Nothing
            , Events.onEnter <| EndEditSelectedItem item
            ]
            []
        ]


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
                colour
                (Item.getText item
                    |> String.trim
                    |> String.dropLeft 3
                    |> String.trim
                )
            ]

    else if Item.isImage item then
        image ( svgWidth, svgHeight ) ( posX, posY ) <| String.trim <| Item.getText item

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
                [ css [ Style.paddingSm, DiagramSettings.fontFamiliy settings, property "word-wrap" "break-word" ] ]
                [ Html.text <| Item.getText item ]
            ]

    else
        plainText settings ( posX, posY ) ( svgWidth, svgHeight ) colour fs <| Item.getText item


plainText : DiagramSettings.Settings -> Position -> Size -> Color -> FontSize -> String -> Svg Msg
plainText settings ( posX, posY ) ( svgWidth, svgHeight ) colour fs t =
    Svg.text_
        [ SvgAttr.x <| String.fromInt <| posX + 6
        , SvgAttr.y <| String.fromInt <| posY + 24
        , SvgAttr.width <| String.fromInt svgWidth
        , SvgAttr.height <| String.fromInt svgHeight
        , SvgAttr.fill <| Color.toString colour
        , SvgAttr.color <| Color.toString colour
        , SvgAttr.fontFamily <| DiagramSettings.fontStyle settings
        , FontSize.svgStyledFontSize fs
        ]
        [ Svg.text t ]


markdown : DiagramSettings.Settings -> Color -> String -> Html Msg
markdown settings colour t =
    Html.fromUnstyled <|
        Markdown.toHtml
            [ LegacyAttr.class "md-content"
            , LegacyAttr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
            , LegacyAttr.style "color" <| Color.toString colour
            ]
            t


canvas : DiagramSettings.Settings -> Property -> Size -> Position -> SelectedItem -> Item -> Svg Msg
canvas settings property svgSize position selectedItem item =
    canvasBase settings property False svgSize position selectedItem item


canvasBottom : DiagramSettings.Settings -> Property -> Size -> Position -> SelectedItem -> Item -> Svg Msg
canvasBottom settings property svgSize position selectedItem item =
    canvasBase settings property True svgSize position selectedItem item


canvasBase : DiagramSettings.Settings -> Property -> Bool -> Size -> Position -> SelectedItem -> Item -> Svg Msg
canvasBase settings property isTitleBottom svgSize position selectedItem item =
    let
        colors : ( Color, Color )
        colors =
            getCanvasColor settings property item

        ( offsetWidth, offsetHeight ) =
            Item.getOffsetSize item

        ( offsetX, offsetY ) =
            Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getOffset

        ( posX, posY ) =
            if ( offsetX, offsetY ) == Position.zero then
                position

            else
                position |> Tuple.mapBoth (\x -> x + offsetX) (\y -> y + offsetY)

        ( svgWidth, svgHeight ) =
            svgSize |> Tuple.mapBoth (\w -> w + offsetWidth) (\h -> h + offsetHeight)
    in
    case selectedItem of
        Just item_ ->
            if Item.getLineNo item_ == Item.getLineNo item then
                let
                    selectedItemOffsetPosition : Position
                    selectedItemOffsetPosition =
                        Item.getOffset item_

                    selectedItemPosition : Position
                    selectedItemPosition =
                        position
                            |> Tuple.mapBoth
                                (\x -> x + Position.getX selectedItemOffsetPosition)
                                (\y -> y + Position.getY selectedItemOffsetPosition)

                    selectedItemOffsetSize : Size
                    selectedItemOffsetSize =
                        Item.getOffsetSize item_

                    selectedItemSize : Size
                    selectedItemSize =
                        svgSize
                            |> Tuple.mapBoth
                                (\w -> max 0 (w + Size.getWidth selectedItemOffsetSize))
                                (\h -> max 0 (h + Size.getHeight selectedItemOffsetSize))
                in
                Svg.g
                    [ Diagram.dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False ]
                    [ canvasRect colors property selectedItemPosition selectedItemSize
                    , inputView
                        { settings = settings
                        , fontSize =
                            Maybe.andThen (\f -> Just <| ItemSettings.getFontSize f) (Item.getItemSettings item)
                                |> Maybe.withDefault FontSize.lg
                        , position =
                            selectedItemPosition
                                |> Tuple.mapBoth
                                    (\x -> x + 14)
                                    (\y ->
                                        y
                                            + (if isTitleBottom then
                                                svgHeight - 38

                                               else
                                                4
                                              )
                                    )
                        , size = ( Size.getWidth selectedItemSize, settings.size.height )
                        , color =
                            Item.getItemSettings item
                                |> Maybe.withDefault ItemSettings.new
                                |> ItemSettings.getForegroundColor
                                |> Maybe.andThen (\c -> Just <| Color.toString c)
                                |> Maybe.withDefault settings.color.label
                                |> Color.fromString
                        , item = item_
                        }
                    , canvasText
                        { settings = settings
                        , property = property
                        , svgWidth = Size.getWidth selectedItemSize
                        , position = selectedItemPosition
                        , selectedItem = selectedItem
                        , items = Item.unwrapChildren <| Item.getChildren item
                        }
                    , resizeCircleForCanvas item TopLeft ( Position.getX selectedItemPosition, Position.getY selectedItemPosition )
                    , resizeCircleForCanvas item TopRight ( Position.getX selectedItemPosition + Size.getWidth selectedItemSize, Position.getY selectedItemPosition )
                    , resizeCircleForCanvas item BottomRight ( Position.getX selectedItemPosition + Size.getWidth selectedItemSize, Position.getY selectedItemPosition + Size.getHeight selectedItemSize )
                    , resizeCircleForCanvas item BottomLeft ( Position.getX selectedItemPosition, Position.getY selectedItemPosition + Size.getHeight selectedItemSize )
                    ]

            else
                Svg.g []
                    [ canvasRect colors property ( posX, posY ) ( svgWidth, svgHeight )
                    , title settings
                        ( posX + 20
                        , posY
                            + (if isTitleBottom then
                                svgHeight - 20

                               else
                                20
                              )
                        )
                        item
                    , canvasText
                        { settings = settings
                        , property = property
                        , svgWidth = svgWidth
                        , position = ( posX, posY )
                        , selectedItem = selectedItem
                        , items = Item.unwrapChildren <| Item.getChildren item
                        }
                    ]

        Nothing ->
            Svg.g
                [ Events.onClickStopPropagation <| Select <| Just { item = item, position = ( posX, posY + settings.size.height ), displayAllMenu = True } ]
                [ canvasRect colors property ( posX, posY ) ( svgWidth, svgHeight )
                , title settings
                    ( posX + 20
                    , posY
                        + (if isTitleBottom then
                            svgHeight - 20

                           else
                            20
                          )
                    )
                    item
                , canvasText { settings = settings, property = property, svgWidth = svgWidth, position = ( posX, posY ), selectedItem = selectedItem, items = Item.unwrapChildren <| Item.getChildren item }
                ]


canvasRect : ( Color, Color ) -> Property -> Position -> Size -> Svg msg
canvasRect ( foregroundColor, backgroundColor ) property ( posX, posY ) ( rectWidth, rectHeight ) =
    Svg.rect
        [ SvgAttr.width <| String.fromInt rectWidth
        , SvgAttr.height <| String.fromInt rectHeight
        , SvgAttr.stroke (Property.getLineColor property |> Maybe.map Color.toString |> Maybe.withDefault (foregroundColor |> Color.toString))
        , SvgAttr.fill <| Color.toString backgroundColor
        , SvgAttr.strokeWidth (Property.getLineSize property |> Maybe.map String.fromInt |> Maybe.withDefault "10")
        , SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        , SvgAttr.class "ts-canvas"
        ]
        []


title : DiagramSettings.Settings -> Position -> Item -> Svg Msg
title settings ( posX, posY ) item =
    Svg.text_
        [ SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt <| posY + 14
        , SvgAttr.fontFamily <| DiagramSettings.fontStyle settings
        , SvgAttr.fill
            (Item.getItemSettings item
                |> Maybe.withDefault ItemSettings.new
                |> ItemSettings.getForegroundColor
                |> Maybe.andThen (\c -> Just <| Color.toString c)
                |> Maybe.withDefault settings.color.label
            )
        , FontSize.svgStyledFontSize FontSize.lg
        , SvgAttr.fontWeight "bold"
        , SvgAttr.class "ts-title"
        , Events.onClickStopPropagation <| Select <| Just { item = item, position = ( posX, posY + settings.size.height ), displayAllMenu = True }
        ]
        [ Svg.text <| Item.getText item ]


canvasText : { settings : DiagramSettings.Settings, property : Property, svgWidth : Int, position : Position, selectedItem : SelectedItem, items : Items } -> Svg Msg
canvasText { settings, property, svgWidth, position, selectedItem, items } =
    let
        ( posX, posY ) =
            position

        newSettings : DiagramSettings.Settings
        newSettings =
            settings |> DiagramSettings.ofWidth.set (svgWidth - Constants.itemMargin * 2)
    in
    Svg.g []
        (Item.indexedMap
            (\i item ->
                card
                    { settings = newSettings
                    , property = property
                    , position = ( posX + 16, posY + i * (settings.size.height + Constants.itemMargin) + Constants.itemMargin + 35 )
                    , selectedItem = selectedItem
                    , item = item
                    , canMove = False
                    }
            )
            items
        )


canvasImage : DiagramSettings.Settings -> Property -> Size -> Position -> Item -> Svg Msg
canvasImage settings property ( svgWidth, svgHeight ) ( posX, posY ) item =
    let
        colors : ( Color, Color )
        colors =
            getCanvasColor settings property item
    in
    Svg.g
        []
        [ canvasRect colors property ( posX, posY ) ( svgWidth, svgHeight )
        , image ( Constants.itemWidth - 5, svgHeight )
            ( posX + 5, posY + 5 )
            (Item.getChildren item
                |> Item.unwrapChildren
                |> Item.map Item.getText
                |> List.head
                |> Maybe.withDefault ""
            )
        , title settings ( posX + 10, posY + 10 ) item
        ]


image : Size -> Position -> String -> Svg msg
image ( imageWidth, imageHeight ) ( posX, posY ) url =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        , SvgAttr.width <| String.fromInt imageWidth
        , SvgAttr.height <| String.fromInt imageHeight
        ]
        [ Html.img
            [ Attr.src url
            , css
                [ Css.width <| px <| toFloat <| imageWidth
                , Css.height <| px <| toFloat <| imageHeight
                , Style.objectFitCover
                ]
            , SvgAttr.class "ts-image"
            ]
            []
        ]


node : DiagramSettings.Settings -> Property -> Position -> SelectedItem -> Item -> Svg Msg
node settings property ( posX, posY ) selectedItem item =
    let
        ( color, _ ) =
            getItemColor settings property item

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
                , textNode settings ( posX, posY ) ( nodeWidth, settings.size.height ) color item
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


rootTextNode : { settings : DiagramSettings.Settings, position : Position, selectedItem : SelectedItem, item : Item } -> Svg Msg
rootTextNode { settings, position, selectedItem, item } =
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
                , textNode settings ( posX, posY ) ( settings.size.width, settings.size.height ) textColor item
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


textNode : DiagramSettings.Settings -> Position -> Size -> Color -> Item -> Svg Msg
textNode settings ( posX, posY ) ( svgWidth, svgHeight ) colour item =
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
            [ Html.div [ css [ FontSize.cssFontSize <| Item.getFontSize item ] ] [ Html.text <| Item.getText item ] ]
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


grid : DiagramSettings.Settings -> Property -> Position -> SelectedItem -> Item -> Svg Msg
grid settings property ( posX, posY ) selectedItem item =
    let
        ( forgroundColor, backgroundColor ) =
            getItemColor settings property item

        view_ : Svg Msg
        view_ =
            Svg.g [ Events.onClickStopPropagation <| Select <| Just { item = item, position = ( posX, posY + settings.size.height ), displayAllMenu = True } ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt settings.size.width
                    , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                    , SvgAttr.x (String.fromInt posX)
                    , SvgAttr.y (String.fromInt posY)
                    , SvgAttr.fill <| Color.toString backgroundColor
                    , SvgAttr.stroke settings.color.line
                    , SvgAttr.strokeWidth "1"
                    ]
                    []
                , text settings
                    ( posX, posY )
                    ( settings.size.width, settings.size.height )
                    forgroundColor
                    (Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getFontSize)
                    item
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.getLineNo item_ == Item.getLineNo item then
                Svg.g []
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt settings.size.width
                        , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                        , SvgAttr.x (String.fromInt posX)
                        , SvgAttr.y (String.fromInt posY)
                        , SvgAttr.stroke "rgba(0, 0, 0, 0.1)"
                        , SvgAttr.fill <| Color.toString backgroundColor
                        , SvgAttr.stroke settings.color.line
                        , SvgAttr.strokeWidth "1"
                        , SvgAttr.class "ts-grid"
                        ]
                        []
                    , inputView
                        { settings = settings
                        , fontSize = Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getFontSize
                        , position = ( posX, posY )
                        , size = ( settings.size.width, settings.size.height )
                        , color = forgroundColor
                        , item = item_
                        }
                    ]

            else
                view_

        Nothing ->
            view_

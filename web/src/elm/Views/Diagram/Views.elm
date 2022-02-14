module Views.Diagram.Views exposing
    ( getItemColor
    , getLineColor
    , image
    , inputView
    , markdown
    , node
    , plainText
    , resizeCircle
    , resizeCircleForCanvas
    , rootTextNode
    , title
    )

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
import Html.Attributes as LegacyAttr
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events exposing (onBlur, onInput)
import Markdown
import Models.Color as Color exposing (Color)
import Models.Diagram as Diagram exposing (MoveState(..), Msg(..), ResizeDirection(..), SelectedItem)
import Models.DiagramSettings as DiagramSettings
import Models.FontSize as FontSize exposing (FontSize)
import Models.Item as Item exposing (Item, ItemType(..))
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


getLineColor : DiagramSettings.Settings -> Item -> Color
getLineColor settings item =
    Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getBackgroundColor |> Maybe.withDefault (Color.fromString settings.color.line)


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

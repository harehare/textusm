module Views.Diagram.Views exposing
    ( DragStart
    , getItemColor
    , image
    , inputBoldView
    , inputView
    , plainText
    , resizeCircle
    , resizeCircleBase
    )

import Css
    exposing
        ( borderStyle
        , focus
        , hex
        , int
        , marginLeft
        , marginTop
        , none
        , outline
        , padding4
        , px
        , transparent
        , zero
        )
import Events
import Html.Styled as Html
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events exposing (onBlur, onInput)
import Models.Color as Color exposing (Color)
import Models.Diagram exposing (MoveState(..), Msg(..), ResizeDirection(..), SelectedItemInfo)
import Models.Diagram.Settings as DiagramSettings
import Models.FontSize as FontSize exposing (FontSize)
import Models.Item as Item exposing (Item)
import Models.Position as Position exposing (Position)
import Models.Property exposing (Property)
import Models.Size as Size exposing (Size)
import String
import Style.Style as Style
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr


type alias DragStart msg =
    MoveState -> Bool -> Svg.Attribute msg


getItemColor : DiagramSettings.Settings -> Property -> Item -> ( Color, Color )
getItemColor settings property item =
    case ( Item.getIndent item, Item.getForegroundColor item, Item.getBackgroundColor item ) of
        ( _, Just c, Just b ) ->
            ( c, b )

        ( 0, Just c, Nothing ) ->
            ( c, DiagramSettings.getCardBackgroundColor1 settings property )

        ( 0, Nothing, Just b ) ->
            ( DiagramSettings.getCardForegroundColor1 settings property, b )

        ( 0, Nothing, Nothing ) ->
            ( DiagramSettings.getCardForegroundColor1 settings property
            , DiagramSettings.getCardBackgroundColor1 settings property
            )

        ( 1, Just c, Nothing ) ->
            ( c, DiagramSettings.getCardBackgroundColor2 settings property )

        ( 1, Nothing, Just b ) ->
            ( DiagramSettings.getCardForegroundColor2 settings property, b )

        ( 1, Nothing, Nothing ) ->
            ( DiagramSettings.getCardForegroundColor2 settings property
            , DiagramSettings.getCardBackgroundColor2 settings property
            )

        ( _, Just c, Nothing ) ->
            ( c, DiagramSettings.getCardBackgroundColor3 settings property )

        ( _, Nothing, Just b ) ->
            ( DiagramSettings.getCardForegroundColor3 settings property, b )

        _ ->
            ( DiagramSettings.getCardForegroundColor3 settings property
            , DiagramSettings.getCardBackgroundColor3 settings property
            )


resizeCircle :
    { item : Item
    , direction : ResizeDirection
    , position : Position
    , dragStart : DragStart msg
    }
    -> Svg msg
resizeCircle { item, direction, position, dragStart } =
    resizeCircleBase
        { size = 5
        , item = item
        , direction = direction
        , position = position
        , dragStart = dragStart
        }


resizeCircleBase :
    { size : Int
    , item : Item
    , direction : ResizeDirection
    , position : Position
    , dragStart : DragStart msg
    }
    -> Svg msg
resizeCircleBase { size, item, direction, position, dragStart } =
    Svg.circle
        [ SvgAttr.cx <| String.fromInt <| Position.getX position
        , SvgAttr.cy <| String.fromInt <| Position.getY position
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
        , dragStart (ItemResize item direction) False
        ]
        []


inputView :
    { settings : DiagramSettings.Settings
    , fontSize : FontSize
    , position : Position
    , size : Size
    , color : Color
    , item : Item
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
inputView { settings, fontSize, position, size, color, item, onEditSelectedItem, onEndEditSelectedItem, onSelect } =
    inputBase
        { settings = settings
        , fontSize = fontSize
        , position = position
        , size = size
        , color = color
        , item = item
        , fontWeight = 400
        , onEditSelectedItem = onEditSelectedItem
        , onEndEditSelectedItem = onEndEditSelectedItem
        , onSelect = onSelect
        }


inputBoldView :
    { settings : DiagramSettings.Settings
    , fontSize : FontSize
    , position : Position
    , size : Size
    , color : Color
    , item : Item
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
inputBoldView { settings, fontSize, position, size, color, item, onEditSelectedItem, onEndEditSelectedItem, onSelect } =
    inputBase
        { settings = settings
        , fontSize = fontSize
        , position = position
        , size = size
        , color = color
        , item = item
        , fontWeight = 600
        , onEditSelectedItem = onEditSelectedItem
        , onEndEditSelectedItem = onEndEditSelectedItem
        , onSelect = onSelect
        }


inputBase :
    { settings : DiagramSettings.Settings
    , fontSize : FontSize
    , position : Position
    , size : Size
    , color : Color
    , item : Item
    , fontWeight : Int
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
inputBase { settings, fontSize, position, size, color, item, fontWeight, onEditSelectedItem, onEndEditSelectedItem, onSelect } =
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
                , Css.fontWeight <| int fontWeight
                , Css.width <| px <| toFloat <| Size.getWidth size - 20
                , Css.fontSize <| px <| toFloat <| FontSize.unwrap fontSize
                , marginTop <| px 2
                , marginLeft <| px 2
                , focus
                    [ outline none
                    ]
                ]
            , Attr.value <| " " ++ String.trimLeft (Item.getMultiLineText item)
            , onInput onEditSelectedItem
            , onBlur <| onSelect Nothing
            , Events.onEnter <| onEndEditSelectedItem item
            ]
            []
        ]


plainText :
    { settings : DiagramSettings.Settings
    , position : Position
    , size : Size
    , foreColor : Color
    , fontSize : FontSize
    , text : String
    , isHighlight : Bool
    }
    -> Svg msg
plainText { settings, position, size, foreColor, fontSize, text, isHighlight } =
    Svg.text_
        [ SvgAttr.x <| String.fromInt <| Position.getX position + 6
        , SvgAttr.y <| String.fromInt <| Position.getY position + 24
        , SvgAttr.width <| String.fromInt <| Size.getWidth size
        , SvgAttr.height <| String.fromInt <| Size.getHeight size
        , SvgAttr.fill <| Color.toString foreColor
        , SvgAttr.color <| Color.toString foreColor
        , SvgAttr.fontFamily <| DiagramSettings.fontStyle settings
        , SvgAttr.cursor "pointer"
        , FontSize.svgStyledFontSize fontSize
        , SvgAttr.filter <|
            if isHighlight then
                "url(#highlight)"

            else
                ""
        ]
        [ Svg.text text ]


image : Size -> Position -> Item -> Svg msg
image ( imageWidth, imageHeight ) ( posX, posY ) url =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        , SvgAttr.width <| String.fromInt imageWidth
        , SvgAttr.height <| String.fromInt imageHeight
        ]
        [ Html.img
            [ Attr.src <| Item.getTextOnly url
            , css
                [ Css.width <| px <| toFloat <| imageWidth
                , Css.height <| px <| toFloat <| imageHeight
                , Style.objectFitCover
                , Css.cursor Css.pointer
                ]
            , SvgAttr.style <| "object-fit: cover; width: " ++ String.fromInt imageWidth ++ "px; height:" ++ String.fromInt imageHeight ++ "px;"
            , SvgAttr.class "ts-image"
            ]
            []
        ]

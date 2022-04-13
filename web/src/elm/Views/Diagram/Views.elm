module Views.Diagram.Views exposing
    ( getItemColor
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
        , color
        , focus
        , hex
        , int
        , marginLeft
        , marginTop
        , none
        , outline
        , padding4
        , position
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
import Models.Diagram as Diagram exposing (MoveState(..), Msg(..), ResizeDirection(..))
import Models.DiagramSettings as DiagramSettings
import Models.FontSize as FontSize exposing (FontSize)
import Models.Item as Item exposing (Item, ItemType(..))
import Models.Position as Position exposing (Position)
import Models.Property exposing (Property)
import Models.Size as Size exposing (Size)
import String
import Style.Style as Style
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr


getItemColor : DiagramSettings.Settings -> Property -> Item -> ( Color, Color )
getItemColor settings property item =
    case ( Item.getItemType item, Item.getForegroundColor item, Item.getBackgroundColor item ) of
        ( _, Just c, Just b ) ->
            ( c, b )

        ( Activities, Just c, Nothing ) ->
            ( c, DiagramSettings.getCardBackgroundColor1 settings property )

        ( Activities, Nothing, Just b ) ->
            ( DiagramSettings.getCardForegroundColor1 settings property, b )

        ( Activities, Nothing, Nothing ) ->
            ( DiagramSettings.getCardForegroundColor1 settings property
            , DiagramSettings.getCardBackgroundColor1 settings property
            )

        ( Tasks, Just c, Nothing ) ->
            ( c, DiagramSettings.getCardBackgroundColor2 settings property )

        ( Tasks, Nothing, Just b ) ->
            ( DiagramSettings.getCardForegroundColor2 settings property, b )

        ( Tasks, Nothing, Nothing ) ->
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


resizeCircle : Item -> ResizeDirection -> Position -> Svg Msg
resizeCircle item direction ( x, y ) =
    resizeCircleBase 5 item direction ( x, y )


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
    inputBase
        { settings = settings
        , fontSize = fontSize
        , position = position
        , size = size
        , color = color
        , item = item
        , fontWeight = 400
        }


inputBoldView :
    { settings : DiagramSettings.Settings
    , fontSize : FontSize
    , position : Position
    , size : Size
    , color : Color
    , item : Item
    }
    -> Svg Msg
inputBoldView { settings, fontSize, position, size, color, item } =
    inputBase
        { settings = settings
        , fontSize = fontSize
        , position = position
        , size = size
        , color = color
        , item = item
        , fontWeight = 600
        }


inputBase :
    { settings : DiagramSettings.Settings
    , fontSize : FontSize
    , position : Position
    , size : Size
    , color : Color
    , item : Item
    , fontWeight : Int
    }
    -> Svg Msg
inputBase { settings, fontSize, position, size, color, item, fontWeight } =
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

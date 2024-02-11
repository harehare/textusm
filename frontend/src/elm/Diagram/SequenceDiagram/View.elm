module Diagram.SequenceDiagram.View exposing (docs, view)

import Constants
import Diagram.SequenceDiagram.Types as SequenceDiagram exposing (Fragment(..), Message(..), MessageType(..), Participant(..), SequenceDiagram(..), SequenceItem(..))
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Data as DiagramData
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import List.Extra as ListEx
import Models.Color as Color
import Models.Diagram exposing (SelectedItem, SelectedItemInfo)
import Models.Item as Item exposing (Item)
import Models.Position as Position exposing (Position)
import Models.Property as Property exposing (Property)
import Models.Size exposing (Size)
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Lazy as Lazy
import Views.Diagram.Card as Card
import Views.Diagram.Views as Views
import Views.Empty as Empty


view :
    { data : DiagramData.Data
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , property : Property
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
view { data, settings, property, selectedItem, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    case data of
        DiagramData.SequenceDiagram (SequenceDiagram participants items) ->
            let
                messageHeight : Int
                messageHeight =
                    SequenceDiagram.sequenceItemCount items
                        * Constants.messageMargin

                messageYList : List Int
                messageYList =
                    ListEx.scanl
                        (\item y ->
                            y + List.length (SequenceDiagram.sequenceItemMessages item) * Constants.messageMargin
                        )
                        (CardSize.toInt settings.size.height + Constants.messageMargin)
                        items
            in
            Svg.g []
                [ markerView settings
                , Svg.g []
                    (List.indexedMap
                        (\i item ->
                            participantView
                                { settings = settings
                                , property = property
                                , selectedItem = selectedItem
                                , position = ( participantX settings i, 8 )
                                , participant = item
                                , messageHeight = messageHeight
                                , onEditSelectedItem = onEditSelectedItem
                                , onEndEditSelectedItem = onEndEditSelectedItem
                                , onSelect = onSelect
                                , dragStart = dragStart
                                }
                        )
                        participants
                    )
                , Svg.g []
                    (ListEx.zip items messageYList
                        |> List.map
                            (\( item, y ) ->
                                sequenceItemView settings property 0 y item
                            )
                    )
                ]

        _ ->
            Empty.view


fragmentAndMessageView : DiagramSettings.Settings -> Property -> Int -> Int -> List Message -> String -> Fragment -> Svg msg
fragmentAndMessageView settings property level y messages fragmentText fragment =
    let
        ( ( fromX, fromY ), ( toX, toY ) ) =
            fragmentRect ( CardSize.toInt settings.size.width, CardSize.toInt settings.size.height ) y level messages
    in
    Svg.g []
        [ mesageViewList settings property level y messages
        , fragmentView settings ( fromX, fromY ) ( toX, toY ) "transparent" fragment
        , fragmentTextView settings property ( fromX, fromY + 16 ) fragmentText
        ]


fragmentRect : Size -> Int -> Int -> List Message -> ( Position, Position )
fragmentRect ( itemWidth, itemHeight ) baseY level messages =
    let
        fragmentFromX : Int
        fragmentFromX =
            orderList
                |> List.minimum
                |> Maybe.withDefault 0
                |> messageX itemWidth

        fragmentToX : Int
        fragmentToX =
            (orderList
                |> List.maximum
                |> Maybe.withDefault 0
                |> messageX itemWidth
            )
                + itemHeight
                // 2

        fragmentYBase : Int
        fragmentYBase =
            baseY - Constants.messageMargin + 24

        messagesLength : Int
        messagesLength =
            SequenceDiagram.messagesCount messages

        offset : Int
        offset =
            level * 8

        orderList : List Int
        orderList =
            List.concatMap
                (\message ->
                    case message of
                        Message _ (Participant _ order1) (Participant _ order2) ->
                            [ order1, order2 ]

                        _ ->
                            []
                )
                messages
    in
    ( ( fragmentFromX - Constants.fragmentOffset + offset
      , fragmentYBase
      )
    , ( fragmentToX + Constants.fragmentOffset - offset
      , fragmentYBase + messagesLength * Constants.messageMargin - offset - 8
      )
    )


fragmentRectView : DiagramSettings.Settings -> Position -> Size -> String -> String -> Svg msg
fragmentRectView settings ( fromX, fromY ) ( fragmentWidth, fragmentHeight ) backgroundColor label =
    Svg.g []
        [ Svg.rect
            [ SvgAttr.x <| String.fromInt fromX
            , SvgAttr.y <| String.fromInt fromY
            , SvgAttr.width <| String.fromInt fragmentWidth
            , SvgAttr.height <| String.fromInt fragmentHeight
            , SvgAttr.stroke <| Color.toString settings.color.activity.backgroundColor
            , SvgAttr.strokeWidth "2"
            , SvgAttr.fill backgroundColor
            ]
            []
        , Svg.rect
            [ SvgAttr.x <| String.fromInt fromX
            , SvgAttr.y <| String.fromInt fromY
            , SvgAttr.width <| String.fromInt <| max 44 (String.length label * 7 + 16)
            , SvgAttr.height "20"
            , SvgAttr.fill <| Color.toString settings.color.activity.backgroundColor
            , SvgAttr.strokeWidth "2"
            ]
            []
        , Svg.text_
            [ SvgAttr.x <| String.fromInt <| fromX + 8
            , SvgAttr.y <| String.fromInt <| fromY + 14
            , SvgAttr.fontFamily (DiagramSettings.fontStyle settings)
            , SvgAttr.fill <| Color.toString settings.color.task.color
            , SvgAttr.fontSize Constants.fontSize
            , SvgAttr.fontWeight "bold"
            ]
            [ Svg.text label ]
        ]


fragmentTextView : DiagramSettings.Settings -> Property -> Position -> String -> Svg msg
fragmentTextView settings property ( fromX, fromY ) fragmentText =
    let
        offset : Int
        offset =
            CardSize.toInt settings.size.width
                // 2
                + 16
    in
    Svg.text_
        [ SvgAttr.x <| String.fromInt <| fromX + offset
        , SvgAttr.y <| String.fromInt <| fromY
        , SvgAttr.fontFamily (DiagramSettings.fontStyle settings)
        , SvgAttr.fill <| Color.toString <| DiagramSettings.getTextColor settings property
        , SvgAttr.fontSize Constants.fontSize
        , SvgAttr.fontWeight "bold"
        ]
        [ Svg.text <| "[" ++ fragmentText ++ "]" ]


fragmentView : DiagramSettings.Settings -> Position -> Position -> String -> Fragment -> Svg msg
fragmentView settings ( fromX, fromY ) ( toX, toY ) backgroundColor fragment =
    let
        fragmentHeight : Int
        fragmentHeight =
            toY - fromY

        fragmentWidth : Int
        fragmentWidth =
            toX - fromX
    in
    Lazy.lazy5 fragmentRectView settings ( fromX, fromY ) ( fragmentWidth, fragmentHeight ) backgroundColor (SequenceDiagram.fragmentToString fragment)


lineView : DiagramSettings.Settings -> Position -> Position -> Svg msg
lineView settings ( fromX, fromY ) ( toX, toY ) =
    Svg.line
        [ SvgAttr.x1 <| String.fromInt fromX
        , SvgAttr.y1 <| String.fromInt fromY
        , SvgAttr.x2 <| String.fromInt toX
        , SvgAttr.y2 <| String.fromInt toY
        , SvgAttr.stroke <| Color.toString settings.color.line
        , SvgAttr.strokeWidth "2"
        ]
        []


markerView : DiagramSettings.Settings -> Svg msg
markerView settings =
    Svg.g []
        [ Svg.marker
            [ SvgAttr.id "sync"
            , SvgAttr.viewBox "0 0 10 10"
            , SvgAttr.markerWidth "5"
            , SvgAttr.markerHeight "5"
            , SvgAttr.refX "5"
            , SvgAttr.refY "5"
            , SvgAttr.orient "auto-start-reverse"
            ]
            [ Svg.polygon
                [ SvgAttr.points "0,0 0,10 10,5"
                , SvgAttr.fill <| Color.toString settings.color.line
                ]
                []
            ]
        , Svg.marker
            [ SvgAttr.id "async"
            , SvgAttr.viewBox "0 0 10 10"
            , SvgAttr.markerWidth "5"
            , SvgAttr.markerHeight "5"
            , SvgAttr.refX "7"
            , SvgAttr.refY "5"
            , SvgAttr.orient "auto-start-reverse"
            ]
            [ Svg.polyline
                [ SvgAttr.points "0,0 10,5 0,10"
                , SvgAttr.fill "none"
                , SvgAttr.stroke <| Color.toString settings.color.line
                , SvgAttr.strokeWidth "2"
                ]
                []
            ]
        , Svg.marker
            [ SvgAttr.id "found"
            , SvgAttr.viewBox "0 0 10 10"
            , SvgAttr.markerWidth "10"
            , SvgAttr.markerHeight "5"
            , SvgAttr.refX "5"
            , SvgAttr.refY "5"
            , SvgAttr.orient "auto-start-reverse"
            ]
            [ Svg.circle
                [ SvgAttr.cx "10"
                , SvgAttr.cy "5"
                , SvgAttr.r "5"
                , SvgAttr.fill <| Color.toString settings.color.line
                ]
                []
            ]
        , Svg.marker
            [ SvgAttr.id "lost"
            , SvgAttr.viewBox "0 0 10 10"
            , SvgAttr.markerWidth "14"
            , SvgAttr.markerHeight "5"
            , SvgAttr.refX "7"
            , SvgAttr.refY "5"
            , SvgAttr.orient "auto-start-reverse"
            ]
            [ Svg.polyline
                [ SvgAttr.points "0,0 10,5 0,10"
                , SvgAttr.fill "none"
                , SvgAttr.stroke <| Color.toString settings.color.line
                , SvgAttr.strokeWidth "2"
                ]
                []
            , Svg.circle
                [ SvgAttr.cx "12"
                , SvgAttr.cy "5"
                , SvgAttr.r "5"
                , SvgAttr.fill <| Color.toString settings.color.line
                ]
                []
            ]
        ]


mesageViewList : DiagramSettings.Settings -> Property -> Int -> Int -> List Message -> Svg msg
mesageViewList settings property level y messages =
    Svg.g []
        (List.indexedMap
            (\i message ->
                let
                    messageY : Int
                    messageY =
                        y + i * Constants.messageMargin
                in
                case message of
                    Message messageType (Participant _ order1) (Participant _ order2) ->
                        if order1 == order2 then
                            selfMessageView settings property ( messageX (CardSize.toInt settings.size.width) order1, messageY ) messageType

                        else
                            messageView settings property ( messageX (CardSize.toInt settings.size.width) order1, messageY ) ( messageX (CardSize.toInt settings.size.width) order2, messageY ) messageType

                    SubMessage subItem ->
                        sequenceItemView settings property (level + 1) messageY subItem
            )
            messages
        )


messageView : DiagramSettings.Settings -> Property -> Position -> Position -> MessageType -> Svg msg
messageView settings property ( fromX, fromY ) ( toX, toY ) messageType =
    let
        ( ( isDot, markerStartId, markerEndId ), ( fromOffset, toOffset ) ) =
            case ( not isReverse, messageType ) of
                ( True, Sync _ ) ->
                    ( ( False, "", "sync" ), ( 0, 4 ) )

                ( True, Async _ ) ->
                    ( ( False, "", "async" ), ( 0, 4 ) )

                ( True, Reply _ ) ->
                    ( ( True, "", "async" ), ( 0, 4 ) )

                ( True, Found _ ) ->
                    ( ( False, "found", "async" ), ( Constants.participantMargin, 5 ) )

                ( True, Lost _ ) ->
                    ( ( False, "", "lost" ), ( 0, Constants.participantMargin ) )

                ( False, Sync _ ) ->
                    ( ( False, "", "sync" ), ( -2, -4 ) )

                ( False, Async _ ) ->
                    ( ( False, "", "async" ), ( -2, -4 ) )

                ( False, Reply _ ) ->
                    ( ( True, "", "async" ), ( -2, -4 ) )

                ( False, Found _ ) ->
                    ( ( False, "found", "async" ), ( -Constants.participantMargin, -4 ) )

                ( False, Lost _ ) ->
                    ( ( False, "", "lost" ), ( -Constants.participantMargin, -10 ) )

        isReverse : Bool
        isReverse =
            fromX - toX > 0
    in
    Svg.g []
        [ Svg.line
            [ SvgAttr.x1 <| String.fromInt <| fromX + fromOffset
            , SvgAttr.y1 <| String.fromInt fromY
            , SvgAttr.x2 <| String.fromInt <| toX - toOffset
            , SvgAttr.y2 <| String.fromInt toY
            , SvgAttr.stroke <| Color.toString settings.color.line
            , SvgAttr.strokeWidth "2"
            , if isDot then
                SvgAttr.strokeDasharray "3"

              else
                SvgAttr.class ""
            , SvgAttr.markerStart <| "url(#" ++ markerStartId ++ ")"
            , SvgAttr.markerEnd ("url(#" ++ markerEndId ++ ")")
            ]
            []
        , if isReverse then
            textView settings property ( fromX + 8 - CardSize.toInt settings.size.width - Constants.participantMargin, fromY - 16 ) ( toX - fromX, 8 ) (SequenceDiagram.unwrapMessageType messageType)

          else
            textView settings property ( fromX + 8 + fromOffset, fromY - 16 ) ( toX - fromX, 8 ) (SequenceDiagram.unwrapMessageType messageType)
        ]


messageX : Int -> Int -> Int
messageX width order =
    width // 2 + (width + Constants.participantMargin) * order + 8


participantView :
    { settings : DiagramSettings.Settings
    , property : Property
    , selectedItem : SelectedItem
    , position : Position
    , participant : Participant
    , messageHeight : Int
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
participantView { settings, property, selectedItem, position, participant, messageHeight, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        fromY : Int
        fromY =
            Position.getY position + CardSize.toInt settings.size.height

        lineX : Int
        lineX =
            Position.getX position + CardSize.toInt settings.size.width // 2

        toY : Int
        toY =
            fromY + messageHeight + CardSize.toInt settings.size.height + Constants.messageMargin

        (Participant item _) =
            participant
    in
    Svg.g []
        [ Lazy.lazy Card.viewWithDefaultColor
            { settings = settings
            , property = property
            , position = ( Position.getX position, toY )
            , selectedItem = selectedItem
            , item = item
            , canMove = False
            , onEditSelectedItem = onEditSelectedItem
            , onEndEditSelectedItem = onEndEditSelectedItem
            , onSelect = onSelect
            , dragStart = dragStart
            }
        , Lazy.lazy3 lineView settings ( lineX, fromY ) ( lineX, toY )
        , Lazy.lazy Card.viewWithDefaultColor
            { settings = settings
            , property = property
            , position = position
            , selectedItem = selectedItem
            , item = item
            , canMove = False
            , onEditSelectedItem = onEditSelectedItem
            , onEndEditSelectedItem = onEndEditSelectedItem
            , onSelect = onSelect
            , dragStart = dragStart
            }
        ]


participantX : DiagramSettings.Settings -> Int -> Int
participantX settings order =
    (CardSize.toInt settings.size.width + Constants.participantMargin) * order + 8


selfMessageView : DiagramSettings.Settings -> Property -> Position -> MessageType -> Svg msg
selfMessageView settings property ( posX, posY ) messageType =
    let
        messagePoints : String
        messagePoints =
            [ [ String.fromInt posX, String.fromInt posY ] |> String.join ","
            , [ String.fromInt <| posX + Constants.participantMargin // 2, String.fromInt posY ] |> String.join ","
            , [ String.fromInt <| posX + Constants.participantMargin // 2, String.fromInt <| posY + Constants.messageMargin // 2 ] |> String.join ","
            , [ String.fromInt <| posX + 4, String.fromInt <| posY + Constants.messageMargin // 2 ] |> String.join ","
            ]
                |> String.join " "
    in
    Svg.g []
        [ Svg.polyline
            [ SvgAttr.points messagePoints
            , SvgAttr.markerEnd "url(#sync)"
            , SvgAttr.fill "none"
            , SvgAttr.stroke <| Color.toString settings.color.line
            , SvgAttr.strokeWidth "2"
            ]
            []
        , textView settings property ( posX + 8, posY - 8 ) ( Constants.participantMargin, 8 ) (SequenceDiagram.unwrapMessageType messageType)
        ]


sequenceItemView : DiagramSettings.Settings -> Property -> Int -> Int -> SequenceItem -> Svg msg
sequenceItemView settings property level y item =
    case item of
        Fragment (Alt ( ifText, ifMessages ) ( elseText, elseMessages )) ->
            let
                elseY : Int
                elseY =
                    y + SequenceDiagram.messagesCount ifMessages * Constants.messageMargin - Constants.messageMargin + 16

                ( ( fromX, fromY ), ( toX, toY ) ) =
                    fragmentRect ( CardSize.toInt settings.size.width, CardSize.toInt settings.size.height ) y level messages

                messages : List Message
                messages =
                    ifMessages ++ elseMessages
            in
            Svg.g []
                [ mesageViewList settings property level y messages
                , fragmentView settings ( fromX, fromY ) ( toX, toY ) "transparent" (Alt ( ifText, ifMessages ) ( elseText, elseMessages ))
                , Svg.line
                    [ SvgAttr.x1 <| String.fromInt <| fromX
                    , SvgAttr.y1 <| String.fromInt elseY
                    , SvgAttr.x2 <| String.fromInt <| toX
                    , SvgAttr.y2 <| String.fromInt elseY
                    , SvgAttr.stroke <| Color.toString settings.color.line
                    , SvgAttr.strokeWidth "2"
                    , SvgAttr.strokeDasharray "3"
                    ]
                    []
                , fragmentTextView settings property ( fromX, fromY + 16 ) ifText
                , fragmentTextView settings property ( fromX, elseY + 16 ) elseText
                ]

        Fragment (Opt t messages) ->
            fragmentAndMessageView settings property level y messages t (Opt t messages)

        Fragment (Par parMessages) ->
            let
                ( ( fromX, fromY ), ( toX, toY ) ) =
                    fragmentRect ( CardSize.toInt settings.size.width, CardSize.toInt settings.size.height ) y level messages

                lines : List (Svg msg)
                lines =
                    messageYList
                        |> List.tail
                        |> Maybe.withDefault []
                        |> List.map
                            (\messageY ->
                                Svg.line
                                    [ SvgAttr.x1 <| String.fromInt <| fromX
                                    , SvgAttr.y1 <| String.fromInt messageY
                                    , SvgAttr.x2 <| String.fromInt <| toX
                                    , SvgAttr.y2 <| String.fromInt messageY
                                    , SvgAttr.stroke <| Color.toString settings.color.line
                                    , SvgAttr.strokeWidth "2"
                                    , SvgAttr.strokeDasharray "3"
                                    ]
                                    []
                            )

                messageYList : List Int
                messageYList =
                    ListEx.scanl
                        (\( _, m ) messageY ->
                            messageY + SequenceDiagram.messagesCount m * Constants.messageMargin
                        )
                        fromY
                        parMessages
                        |> List.take (List.length parMessages)

                messages : List Message
                messages =
                    List.concatMap (\( _, m ) -> m) parMessages

                textList : List (Svg msg)
                textList =
                    ListEx.zip messageYList parMessages
                        |> List.map
                            (\( messageY, ( t, _ ) ) ->
                                fragmentTextView settings
                                    property
                                    ( fromX
                                    , messageY + 16
                                    )
                                    t
                            )
            in
            Svg.g []
                (mesageViewList settings property level y messages
                    :: fragmentView settings ( fromX, fromY ) ( toX, toY ) "transparent" (Par parMessages)
                    :: lines
                    ++ textList
                )

        Fragment (Loop t messages) ->
            fragmentAndMessageView settings property level y messages t (Loop t messages)

        Fragment (Break t messages) ->
            fragmentAndMessageView settings property level y messages t (Break t messages)

        Fragment (Critical t messages) ->
            fragmentAndMessageView settings property level y messages t (Critical t messages)

        Fragment (Assert t messages) ->
            fragmentAndMessageView settings property level y messages t (Assert t messages)

        Fragment (Neg t messages) ->
            fragmentAndMessageView settings property level y messages t (Neg t messages)

        Fragment (Ignore t messages) ->
            fragmentAndMessageView settings property level y messages t (Ignore t messages)

        Fragment (Consider t messages) ->
            fragmentAndMessageView settings property level y messages t (Consider t messages)

        Messages messages ->
            mesageViewList settings property level y messages


textView : DiagramSettings.Settings -> Property -> Position -> Size -> String -> Svg msg
textView settings property ( posX, posY ) ( textWidth, textHeight ) message =
    Svg.text_
        [ SvgAttr.x <| String.fromInt <| posX
        , SvgAttr.y <| String.fromInt <| posY
        , SvgAttr.fontFamily (DiagramSettings.fontStyle settings)
        , SvgAttr.width <| String.fromInt textWidth
        , SvgAttr.height <| String.fromInt textHeight
        , SvgAttr.fill <| Color.toString <| DiagramSettings.getTextColor settings property
        , SvgAttr.fontSize Constants.fontSize
        ]
        [ Svg.text message ]


docs : Chapter x
docs =
    Chapter.chapter "SequenceDiagram"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view
                    { data =
                        DiagramData.SequenceDiagram <|
                            SequenceDiagram.from <|
                                (DiagramType.defaultText DiagramType.SequenceDiagram |> Item.fromString |> Tuple.second)
                    , settings = DiagramSettings.default
                    , selectedItem = Nothing
                    , property = Property.empty
                    , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                    , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , dragStart = \_ _ -> SvgAttr.style ""
                    }
                ]
                |> Svg.toUnstyled
            )

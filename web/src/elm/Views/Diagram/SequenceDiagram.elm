module Views.Diagram.SequenceDiagram exposing (view)

import Constants
import List.Extra as ListEx
import Models.Diagram as Diagram exposing (Model, Msg(..), SelectedItem, Settings, fontStyle, getTextColor)
import Models.Diagram.SequenceDiagram as SequenceDiagram exposing (Fragment(..), Message(..), MessageType(..), Participant(..), SequenceDiagram(..), SequenceItem(..))
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Svg.Lazy as Lazy
import Types.Position as Position exposing (Position)
import Types.Size exposing (Size)
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.SequenceDiagram (SequenceDiagram participants items) ->
            let
                messageHeight =
                    SequenceDiagram.sequenceItemCount items
                        * Constants.messageMargin

                messageYList =
                    ListEx.scanl
                        (\item y ->
                            y + List.length (SequenceDiagram.sequenceItemMessages item) * Constants.messageMargin
                        )
                        (model.settings.size.height + Constants.messageMargin)
                        items
            in
            Svg.g []
                [ markerView model.settings
                , Svg.g [] (List.indexedMap (\i item -> participantView model.settings model.selectedItem ( participantX model.settings i, 8 ) item messageHeight) participants)
                , Svg.g []
                    (ListEx.zip items messageYList
                        |> List.map
                            (\( item, y ) ->
                                sequenceItemView model.settings 0 y item
                            )
                    )
                ]

        _ ->
            Empty.view


participantX : Settings -> Int -> Int
participantX settings order =
    (settings.size.width + Constants.participantMargin) * order + 8


messageX : Int -> Int -> Int
messageX width order =
    width // 2 + (width + Constants.participantMargin) * order + 8


participantView : Settings -> SelectedItem -> Position -> Participant -> Int -> Svg Msg
participantView settings selectedItem pos (Participant item _) messageHeight =
    let
        lineX =
            Position.getX pos + settings.size.width // 2

        fromY =
            Position.getY pos + settings.size.height

        toY =
            fromY + messageHeight + settings.size.height + Constants.messageMargin
    in
    Svg.g []
        [ Lazy.lazy Views.card
            { settings = settings
            , position = ( Position.getX pos, toY )
            , selectedItem = selectedItem
            , item = item
            , canMove = False
            }
        , Lazy.lazy3 lineView settings ( lineX, fromY ) ( lineX, toY )
        , Lazy.lazy Views.card
            { settings = settings
            , position = pos
            , selectedItem = selectedItem
            , item = item
            , canMove = False
            }
        ]


fragmentRect : Size -> Int -> Int -> List Message -> ( Position, Position )
fragmentRect ( itemWidth, itemHeight ) baseY level messages =
    let
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

        fragmentFromX =
            orderList
                |> List.minimum
                |> Maybe.withDefault 0
                |> messageX itemWidth

        fragmentToX =
            (orderList
                |> List.maximum
                |> Maybe.withDefault 0
                |> messageX itemWidth
            )
                + itemHeight
                // 2

        messagesLength =
            SequenceDiagram.messagesCount messages

        offset =
            level * 8

        fragmentYBase =
            baseY - Constants.messageMargin + 24
    in
    ( ( fragmentFromX - Constants.fragmentOffset + offset
      , fragmentYBase
      )
    , ( fragmentToX + Constants.fragmentOffset - offset
      , fragmentYBase + messagesLength * Constants.messageMargin - offset - 8
      )
    )


mesageViewList : Settings -> Int -> Int -> List Message -> Svg Msg
mesageViewList settings level y messages =
    Svg.g []
        (List.indexedMap
            (\i message ->
                let
                    messageY =
                        y + i * Constants.messageMargin
                in
                case message of
                    Message messageType (Participant _ order1) (Participant _ order2) ->
                        if order1 == order2 then
                            selfMessageView settings ( messageX settings.size.width order1, messageY ) messageType

                        else
                            messageView settings ( messageX settings.size.width order1, messageY ) ( messageX settings.size.width order2, messageY ) messageType

                    SubMessage subItem ->
                        sequenceItemView settings (level + 1) messageY subItem
            )
            messages
        )


fragmentAndMessageView : Settings -> Int -> Int -> List Message -> String -> Fragment -> Svg Msg
fragmentAndMessageView settings level y messages fragmentText fragment =
    let
        ( ( fromX, fromY ), ( toX, toY ) ) =
            fragmentRect ( settings.size.width, settings.size.height ) y level messages
    in
    Svg.g []
        [ mesageViewList settings level y messages
        , fragmentView settings ( fromX, fromY ) ( toX, toY ) "transparent" fragment
        , fragmentTextView settings ( fromX, fromY + 16 ) fragmentText
        ]


sequenceItemView : Settings -> Int -> Int -> SequenceItem -> Svg Msg
sequenceItemView settings level y item =
    case item of
        Messages messages ->
            mesageViewList settings level y messages

        Fragment (Alt ( ifText, ifMessages ) ( elseText, elseMessages )) ->
            let
                messages =
                    ifMessages ++ elseMessages

                elseY =
                    y + SequenceDiagram.messagesCount ifMessages * Constants.messageMargin - Constants.messageMargin + 16

                ( ( fromX, fromY ), ( toX, toY ) ) =
                    fragmentRect ( settings.size.width, settings.size.height ) y level messages
            in
            Svg.g []
                [ mesageViewList settings level y messages
                , fragmentView settings ( fromX, fromY ) ( toX, toY ) "transparent" (Alt ( ifText, ifMessages ) ( elseText, elseMessages ))
                , Svg.line
                    [ SvgAttr.x1 <| String.fromInt <| fromX
                    , SvgAttr.y1 <| String.fromInt elseY
                    , SvgAttr.x2 <| String.fromInt <| toX
                    , SvgAttr.y2 <| String.fromInt elseY
                    , SvgAttr.stroke settings.color.line
                    , SvgAttr.strokeWidth "2"
                    , SvgAttr.strokeDasharray "3"
                    ]
                    []
                , fragmentTextView settings ( fromX, fromY + 16 ) ifText
                , fragmentTextView settings ( fromX, elseY + 16 ) elseText
                ]

        Fragment (Opt t messages) ->
            fragmentAndMessageView settings level y messages t (Opt t messages)

        Fragment (Par parMessages) ->
            let
                messages =
                    List.concatMap (\( _, m ) -> m) parMessages

                ( ( fromX, fromY ), ( toX, toY ) ) =
                    fragmentRect ( settings.size.width, settings.size.height ) y level messages

                messageYList =
                    ListEx.scanl
                        (\( _, m ) messageY ->
                            messageY + SequenceDiagram.messagesCount m * Constants.messageMargin
                        )
                        fromY
                        parMessages
                        |> List.take (List.length parMessages)

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
                                    , SvgAttr.stroke settings.color.line
                                    , SvgAttr.strokeWidth "2"
                                    , SvgAttr.strokeDasharray "3"
                                    ]
                                    []
                            )

                textList =
                    ListEx.zip messageYList parMessages
                        |> List.map
                            (\( messageY, ( t, _ ) ) ->
                                fragmentTextView settings
                                    ( fromX
                                    , messageY + 16
                                    )
                                    t
                            )
            in
            Svg.g []
                (mesageViewList settings level y messages
                    :: fragmentView settings ( fromX, fromY ) ( toX, toY ) "transparent" (Par parMessages)
                    :: lines
                    ++ textList
                )

        Fragment (Loop t messages) ->
            fragmentAndMessageView settings level y messages t (Loop t messages)

        Fragment (Break t messages) ->
            fragmentAndMessageView settings level y messages t (Break t messages)

        Fragment (Critical t messages) ->
            fragmentAndMessageView settings level y messages t (Critical t messages)

        Fragment (Assert t messages) ->
            fragmentAndMessageView settings level y messages t (Assert t messages)

        Fragment (Neg t messages) ->
            fragmentAndMessageView settings level y messages t (Neg t messages)

        Fragment (Ignore t messages) ->
            fragmentAndMessageView settings level y messages t (Ignore t messages)

        Fragment (Consider t messages) ->
            fragmentAndMessageView settings level y messages t (Consider t messages)


markerView : Settings -> Svg Msg
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
                , SvgAttr.fill settings.color.line
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
                , SvgAttr.stroke settings.color.line
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
                , SvgAttr.fill settings.color.line
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
                , SvgAttr.stroke settings.color.line
                , SvgAttr.strokeWidth "2"
                ]
                []
            , Svg.circle
                [ SvgAttr.cx "12"
                , SvgAttr.cy "5"
                , SvgAttr.r "5"
                , SvgAttr.fill settings.color.line
                ]
                []
            ]
        ]


selfMessageView : Settings -> Position -> MessageType -> Svg Msg
selfMessageView settings ( posX, posY ) messageType =
    let
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
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "2"
            ]
            []
        , textView settings ( posX + 8, posY - 8 ) ( Constants.participantMargin, 8 ) (SequenceDiagram.unwrapMessageType messageType)
        ]


messageView : Settings -> Position -> Position -> MessageType -> Svg Msg
messageView settings ( fromX, fromY ) ( toX, toY ) messageType =
    let
        isReverse =
            fromX - toX > 0

        ( ( isDot, markerStartId, markerEndId ), ( fromOffset, toOffset ) ) =
            case ( not isReverse, messageType ) of
                ( True, Sync _ ) ->
                    ( ( False, "", "sync" ), ( 0, 4 ) )

                ( False, Sync _ ) ->
                    ( ( False, "", "sync" ), ( -2, -4 ) )

                ( True, Async _ ) ->
                    ( ( False, "", "async" ), ( 0, 4 ) )

                ( False, Async _ ) ->
                    ( ( False, "", "async" ), ( -2, -4 ) )

                ( True, Reply _ ) ->
                    ( ( True, "", "async" ), ( 0, 4 ) )

                ( False, Reply _ ) ->
                    ( ( True, "", "async" ), ( -2, -4 ) )

                ( True, Found _ ) ->
                    ( ( False, "found", "async" ), ( Constants.participantMargin, 5 ) )

                ( False, Found _ ) ->
                    ( ( False, "found", "async" ), ( -Constants.participantMargin, -4 ) )

                ( True, Lost _ ) ->
                    ( ( False, "", "lost" ), ( 0, Constants.participantMargin ) )

                ( False, Lost _ ) ->
                    ( ( False, "", "lost" ), ( -Constants.participantMargin, -10 ) )
    in
    Svg.g []
        [ Svg.line
            [ SvgAttr.x1 <| String.fromInt <| fromX + fromOffset
            , SvgAttr.y1 <| String.fromInt fromY
            , SvgAttr.x2 <| String.fromInt <| toX - toOffset
            , SvgAttr.y2 <| String.fromInt toY
            , SvgAttr.stroke settings.color.line
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
            textView settings ( fromX + 8 - settings.size.width - Constants.participantMargin, fromY - 16 ) ( toX - fromX, 8 ) (SequenceDiagram.unwrapMessageType messageType)

          else
            textView settings ( fromX + 8 + fromOffset, fromY - 16 ) ( toX - fromX, 8 ) (SequenceDiagram.unwrapMessageType messageType)
        ]


textView : Settings -> Position -> Size -> String -> Svg Msg
textView settings ( posX, posY ) ( textWidth, textHeight ) message =
    Svg.text_
        [ SvgAttr.x <| String.fromInt <| posX
        , SvgAttr.y <| String.fromInt <| posY
        , SvgAttr.fontFamily (fontStyle settings)
        , SvgAttr.width <| String.fromInt textWidth
        , SvgAttr.height <| String.fromInt textHeight
        , SvgAttr.fill <| getTextColor settings.color
        , SvgAttr.fontSize Constants.fontSize
        , SvgAttr.class ".select-none"
        ]
        [ Svg.text message ]


fragmentView : Settings -> Position -> Position -> String -> Fragment -> Svg Msg
fragmentView settings ( fromX, fromY ) ( toX, toY ) backgroundColor fragment =
    let
        fragmentWidth =
            toX - fromX

        fragmentHeight =
            toY - fromY
    in
    Lazy.lazy5 fragmentRectView settings ( fromX, fromY ) ( fragmentWidth, fragmentHeight ) backgroundColor (SequenceDiagram.fragmentToString fragment)


fragmentTextView : Settings -> Position -> String -> Svg Msg
fragmentTextView settings ( fromX, fromY ) fragmentText =
    let
        offset =
            settings.size.width
                // 2
                + 16
    in
    Svg.text_
        [ SvgAttr.x <| String.fromInt <| fromX + offset
        , SvgAttr.y <| String.fromInt <| fromY
        , SvgAttr.fontFamily (fontStyle settings)
        , SvgAttr.fill <| getTextColor settings.color
        , SvgAttr.fontSize Constants.fontSize
        , SvgAttr.fontWeight "bold"
        , SvgAttr.class ".select-none"
        ]
        [ Svg.text <| "[" ++ fragmentText ++ "]" ]


fragmentRectView : Settings -> Position -> Size -> String -> String -> Svg Msg
fragmentRectView settings ( fromX, fromY ) ( fragmentWidth, fragmentHeight ) backgroundColor label =
    Svg.g []
        [ Svg.rect
            [ SvgAttr.x <| String.fromInt fromX
            , SvgAttr.y <| String.fromInt fromY
            , SvgAttr.width <| String.fromInt fragmentWidth
            , SvgAttr.height <| String.fromInt fragmentHeight
            , SvgAttr.stroke settings.color.activity.backgroundColor
            , SvgAttr.strokeWidth "2"
            , SvgAttr.fill backgroundColor
            ]
            []
        , Svg.rect
            [ SvgAttr.x <| String.fromInt fromX
            , SvgAttr.y <| String.fromInt fromY
            , SvgAttr.width <| String.fromInt <| max 44 (String.length label * 7 + 16)
            , SvgAttr.height "20"
            , SvgAttr.fill settings.color.activity.backgroundColor
            , SvgAttr.strokeWidth "2"
            ]
            []
        , Svg.text_
            [ SvgAttr.x <| String.fromInt <| fromX + 8
            , SvgAttr.y <| String.fromInt <| fromY + 14
            , SvgAttr.fontFamily (fontStyle settings)
            , SvgAttr.fill settings.color.task.color
            , SvgAttr.fontSize Constants.fontSize
            , SvgAttr.fontWeight "bold"
            , SvgAttr.class ".select-none"
            ]
            [ Svg.text label ]
        ]


lineView : Settings -> Position -> Position -> Svg Msg
lineView settings ( fromX, fromY ) ( toX, toY ) =
    Svg.line
        [ SvgAttr.x1 <| String.fromInt fromX
        , SvgAttr.y1 <| String.fromInt fromY
        , SvgAttr.x2 <| String.fromInt toX
        , SvgAttr.y2 <| String.fromInt toY
        , SvgAttr.stroke settings.color.line
        , SvgAttr.strokeWidth "2"
        ]
        []

module Views.Diagram.SequenceDiagram exposing (view)

import Constants
import Data.Item exposing (Item)
import Data.Position as Position exposing (Position)
import Data.Size exposing (Size)
import List.Extra exposing (scanl, zip)
import Models.Diagram as Diagram exposing (Model, Msg(..), Settings, fontStyle, getTextColor)
import Models.Views.SequenceDiagram as SequenceDiagram exposing (Fragment(..), Message(..), MessageType(..), Participant(..), SequenceDiagram(..), SequenceItem(..))
import Svg exposing (Svg, circle, g, line, marker, polygon, polyline, rect, text, text_)
import Svg.Attributes exposing (class, cx, cy, fill, fontFamily, fontSize, fontWeight, height, id, markerEnd, markerHeight, markerStart, markerWidth, orient, points, r, refX, refY, stroke, strokeDasharray, strokeWidth, viewBox, width, x, x1, x2, y, y1, y2)
import Svg.Lazy as Lazy
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
                    scanl
                        (\item y ->
                            y + List.length (SequenceDiagram.sequenceItemMessages item) * Constants.messageMargin
                        )
                        (model.settings.size.height + Constants.messageMargin)
                        items
            in
            g []
                [ markerView model.settings
                , g [] (List.indexedMap (\i item -> participantView model.settings model.selectedItem ( participantX model.settings i, 8 ) item messageHeight) participants)
                , g []
                    (zip items messageYList
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


participantView : Settings -> Maybe Item -> Position -> Participant -> Int -> Svg Msg
participantView settings selectedItem pos (Participant item _) messageHeight =
    let
        lineX =
            Position.getX pos + settings.size.width // 2

        fromY =
            Position.getY pos + settings.size.height

        toY =
            fromY + messageHeight + settings.size.height + Constants.messageMargin
    in
    g []
        [ Lazy.lazy4 Views.cardView settings ( Position.getX pos, toY ) selectedItem item
        , Lazy.lazy3 lineView settings ( lineX, fromY ) ( lineX, toY )
        , Lazy.lazy4 Views.cardView settings pos selectedItem item
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
    g []
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
    g []
        [ mesageViewList settings level y messages
        , fragmentView settings ( fromX, fromY ) ( toX, toY ) "transparent" fragment
        , fragmentTextiew settings ( fromX + settings.size.width // 2 + 4, fromY + 16 ) fragmentText
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
            g []
                [ mesageViewList settings level y messages
                , fragmentView settings ( fromX, fromY ) ( toX, toY ) "transparent" (Alt ( ifText, ifMessages ) ( elseText, elseMessages ))
                , line
                    [ x1 <| String.fromInt <| fromX
                    , y1 <| String.fromInt elseY
                    , x2 <| String.fromInt <| toX
                    , y2 <| String.fromInt elseY
                    , stroke settings.color.line
                    , strokeWidth "2"
                    , strokeDasharray "3"
                    ]
                    []
                , fragmentTextiew settings ( fromX + settings.size.width // 2 + 4, fromY + 16 ) ifText
                , fragmentTextiew settings ( fromX + settings.size.width // 2 + 4, elseY + 16 ) elseText
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
                    scanl
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
                                line
                                    [ x1 <| String.fromInt <| fromX
                                    , y1 <| String.fromInt messageY
                                    , x2 <| String.fromInt <| toX
                                    , y2 <| String.fromInt messageY
                                    , stroke settings.color.line
                                    , strokeWidth "2"
                                    , strokeDasharray "3"
                                    ]
                                    []
                            )

                textList =
                    zip messageYList parMessages
                        |> List.map
                            (\( messageY, ( t, _ ) ) ->
                                fragmentTextiew settings
                                    ( fromX + settings.size.width // 2 + 4
                                    , messageY + 16
                                    )
                                    t
                            )
            in
            g []
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
    g []
        [ marker [ id "sync", viewBox "0 0 10 10", markerWidth "5", markerHeight "5", refX "5", refY "5", orient "auto-start-reverse" ]
            [ polygon [ points "0,0 0,10 10,5", fill settings.color.line ] [] ]
        , marker [ id "async", viewBox "0 0 10 10", markerWidth "5", markerHeight "5", refX "7", refY "5", orient "auto-start-reverse" ]
            [ polyline [ points "0,0 10,5 0,10", fill "none", stroke settings.color.line, strokeWidth "2" ] [] ]
        , marker [ id "found", viewBox "0 0 10 10", markerWidth "10", markerHeight "5", refX "5", refY "5", orient "auto-start-reverse" ]
            [ circle [ cx "10", cy "5", r "5", fill settings.color.line ] [] ]
        , marker [ id "lost", viewBox "0 0 10 10", markerWidth "14", markerHeight "5", refX "7", refY "5", orient "auto-start-reverse" ]
            [ polyline [ points "0,0 10,5 0,10", fill "none", stroke settings.color.line, strokeWidth "2" ] []
            , circle [ cx "12", cy "5", r "5", fill settings.color.line ] []
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
    g []
        [ polyline [ points messagePoints, markerEnd "url(#sync)", fill "none", stroke settings.color.line, strokeWidth "2" ] []
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
    g []
        [ line
            [ x1 <| String.fromInt <| fromX + fromOffset
            , y1 <| String.fromInt fromY
            , x2 <| String.fromInt <| toX - toOffset
            , y2 <| String.fromInt toY
            , stroke settings.color.line
            , strokeWidth "2"
            , if isDot then
                strokeDasharray "3"

              else
                class ""
            , markerStart <| "url(#" ++ markerStartId ++ ")"
            , markerEnd ("url(#" ++ markerEndId ++ ")")
            ]
            []
        , if isReverse then
            textView settings ( fromX + 8 - settings.size.width - Constants.participantMargin, fromY - 16 ) ( toX - fromX, 8 ) (SequenceDiagram.unwrapMessageType messageType)

          else
            textView settings ( fromX + 8 + fromOffset, fromY - 16 ) ( toX - fromX, 8 ) (SequenceDiagram.unwrapMessageType messageType)
        ]


textView : Settings -> Position -> Size -> String -> Svg Msg
textView settings ( posX, posY ) ( textWidth, textHeight ) message =
    text_
        [ x <| String.fromInt <| posX
        , y <| String.fromInt <| posY
        , fontFamily (fontStyle settings)
        , width <| String.fromInt textWidth
        , height <| String.fromInt textHeight
        , fill <| getTextColor settings.color
        , fontSize Constants.fontSize
        , class ".select-none"
        ]
        [ text message ]


fragmentView : Settings -> Position -> Position -> String -> Fragment -> Svg Msg
fragmentView settings ( fromX, fromY ) ( toX, toY ) backgroundColor fragment =
    let
        fragmentWidth =
            toX - fromX

        fragmentHeight =
            toY - fromY
    in
    Lazy.lazy5 fragmentRectView settings ( fromX, fromY ) ( fragmentWidth, fragmentHeight ) backgroundColor (SequenceDiagram.fragmentToString fragment)


fragmentTextiew : Settings -> Position -> String -> Svg Msg
fragmentTextiew settings ( fromX, fromY ) fragmentText =
    text_
        [ x <| String.fromInt <| fromX
        , y <| String.fromInt <| fromY
        , fontFamily (fontStyle settings)
        , fill <| getTextColor settings.color
        , fontSize Constants.fontSize
        , fontWeight "bold"
        , class ".select-none"
        ]
        [ text <| "[" ++ fragmentText ++ "]" ]


fragmentRectView : Settings -> Position -> Size -> String -> String -> Svg Msg
fragmentRectView settings ( fromX, fromY ) ( fragmentWidth, fragmentHeight ) backgroundColor label =
    g []
        [ rect
            [ x <| String.fromInt fromX
            , y <| String.fromInt fromY
            , width <| String.fromInt fragmentWidth
            , height <| String.fromInt fragmentHeight
            , stroke settings.color.activity.backgroundColor
            , strokeWidth "2"
            , fill backgroundColor
            ]
            []
        , rect
            [ x <| String.fromInt fromX
            , y <| String.fromInt fromY
            , width "44"
            , height "20"
            , fill settings.color.activity.backgroundColor
            , strokeWidth "2"
            ]
            []
        , text_
            [ x <| String.fromInt <| fromX + 8
            , y <| String.fromInt <| fromY + 14
            , fontFamily (fontStyle settings)
            , fill settings.color.task.color
            , fontSize Constants.fontSize
            , fontWeight "bold"
            , class ".select-none"
            ]
            [ text label ]
        ]


lineView : Settings -> Position -> Position -> Svg Msg
lineView settings ( fromX, fromY ) ( toX, toY ) =
    line
        [ x1 <| String.fromInt fromX
        , y1 <| String.fromInt fromY
        , x2 <| String.fromInt toX
        , y2 <| String.fromInt toY
        , stroke settings.color.line
        , strokeWidth "2"
        ]
        []

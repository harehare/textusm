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
                        (\(SequenceItem _ messages) y ->
                            y + List.length messages * Constants.messageMargin
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


messageX : Settings -> Int -> Int
messageX settings order =
    settings.size.width // 2 + (settings.size.width + Constants.participantMargin) * order + 8


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
        [ Lazy.lazy4 Views.cardView settings pos selectedItem item
        , Lazy.lazy4 Views.cardView settings ( Position.getX pos, toY ) selectedItem item
        , Lazy.lazy3 lineView settings ( lineX, fromY ) ( lineX, toY )
        ]


sequenceItemView : Settings -> Int -> Int -> SequenceItem -> Svg Msg
sequenceItemView settings level y (SequenceItem fragment messages) =
    let
        mesageViewList =
            List.indexedMap
                (\i message ->
                    let
                        messageY =
                            y + i * Constants.messageMargin
                    in
                    case message of
                        Message messageType (Participant _ order1) (Participant _ order2) ->
                            if order1 == order2 then
                                selfMessageView settings ( messageX settings order1, messageY ) messageType

                            else
                                messageView settings ( messageX settings order1, messageY ) ( messageX settings order2, messageY ) messageType

                        SubMessage subItem ->
                            sequenceItemView settings (level + 1) messageY subItem
                )
                messages

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
                |> messageX settings

        fragmentToX =
            (orderList
                |> List.maximum
                |> Maybe.withDefault 0
                |> messageX settings
            )
                + settings.size.height
                // 2

        messagesLength =
            SequenceDiagram.messagesCount messages

        offset =
            level * 8
    in
    g []
        [ g [] mesageViewList
        , fragmentView settings ( fragmentFromX - Constants.fragmentOffset + offset, y - (Constants.messageMargin // 2) - 16 ) ( fragmentToX + Constants.fragmentOffset - offset, y + messagesLength * Constants.messageMargin - (Constants.messageMargin // 2) - offset ) fragment
        ]


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

                ( True, Response _ ) ->
                    ( ( True, "", "async" ), ( 0, 4 ) )

                ( False, Response _ ) ->
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
        , width <| String.fromInt textWidth
        , height <| String.fromInt textHeight
        , fill <| getTextColor settings.color
        , fontSize "14"
        , class ".select-none"
        ]
        [ text message ]


fragmentView : Settings -> Position -> Position -> Fragment -> Svg Msg
fragmentView settings ( fromX, fromY ) ( toX, toY ) fragment =
    case fragment of
        Default ->
            g [] []

        _ ->
            let
                fragmentWidth =
                    toX - fromX

                fragmentHeight =
                    toY - fromY

                fragmentText =
                    SequenceDiagram.unwrapFragment fragment
            in
            g []
                [ rect
                    [ x <| String.fromInt fromX
                    , y <| String.fromInt fromY
                    , width <| String.fromInt fragmentWidth
                    , height <| String.fromInt fragmentHeight
                    , stroke settings.color.activity.backgroundColor
                    , strokeWidth "2"
                    , fill "transparent"
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
                    [ text <| SequenceDiagram.fragmentToString fragment ]
                , if not <| String.isEmpty fragmentText then
                    text_
                        [ x <| String.fromInt <| fromX + settings.size.width // 2 + 8
                        , y <| String.fromInt <| fromY + 14
                        , fontFamily (fontStyle settings)
                        , fill <| getTextColor settings.color
                        , fontSize Constants.fontSize
                        , fontWeight "bold"
                        , class ".select-none"
                        ]
                        [ text <| "[" ++ fragmentText ++ "]" ]

                  else
                    g [] []
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

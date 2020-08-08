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
import Svg.Lazy exposing (lazy4)
import Views.Diagram.Views as Views
import Views.Empty as Empty


participantMargin : Int
participantMargin =
    150


messageMargin : Int
messageMargin =
    85


fragmentOffset : Int
fragmentOffset =
    40


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.SequenceDiagram (SequenceDiagram participants items) ->
            let
                messageHeight =
                    SequenceDiagram.messagesCount items
                        * messageMargin

                messageYList =
                    scanl
                        (\(SequenceItem _ messages) y ->
                            y + List.length messages * messageMargin
                        )
                        (model.settings.size.height + messageMargin)
                        items
            in
            g []
                [ markerView model.settings
                , g [] (List.indexedMap (\i item -> participantView model.settings model.selectedItem ( participantX model.settings i, 10 ) item messageHeight) participants)
                , g []
                    (zip items messageYList
                        |> List.map
                            (\( item, y ) ->
                                sequenceItemView model.settings y item
                            )
                    )
                ]

        _ ->
            Empty.view


participantX : Settings -> Int -> Int
participantX settings order =
    (settings.size.width + participantMargin) * order + 10


messageX : Settings -> Int -> Int
messageX settings order =
    settings.size.width // 2 + (settings.size.width + participantMargin) * order + 10


participantView : Settings -> Maybe Item -> Position -> Participant -> Int -> Svg Msg
participantView settings selectedItem pos (Participant item _) messageHeight =
    let
        lineX =
            Position.getX pos + settings.size.width // 2

        fromY =
            Position.getY pos + settings.size.height

        toY =
            fromY + messageHeight + settings.size.height + messageMargin
    in
    g []
        [ lazy4 Views.cardView settings pos selectedItem item
        , lazy4 Views.cardView settings ( Position.getX pos, toY ) selectedItem item
        , lineView settings ( lineX, fromY ) ( lineX, toY )
        ]


sequenceItemView : Settings -> Int -> SequenceItem -> Svg Msg
sequenceItemView settings y (SequenceItem fragment messages) =
    let
        mesageViewList =
            List.indexedMap
                (\i (Message messageType (Participant _ order1) (Participant _ order2)) ->
                    let
                        messageY =
                            y + i * messageMargin
                    in
                    if order1 == order2 then
                        selfMessageView settings ( messageX settings order1, messageY ) messageType

                    else
                        messageView settings ( messageX settings order1, messageY ) ( messageX settings order2, messageY ) messageType
                )
                messages

        orderList =
            List.concatMap
                (\(Message _ (Participant _ order1) (Participant _ order2)) ->
                    [ order1, order2 ]
                )
                messages

        fragmentFromX =
            orderList
                |> List.minimum
                |> Maybe.withDefault 0
                |> messageX settings

        fragmentToX =
            orderList
                |> List.maximum
                |> Maybe.withDefault 0
                |> messageX settings

        messagesLength =
            List.length messages
    in
    g []
        [ g [] mesageViewList
        , fragmentView settings ( fragmentFromX - fragmentOffset, y - (messageMargin // 2) ) ( fragmentToX + fragmentOffset, y + messagesLength * messageMargin - (messageMargin // 2) ) fragment
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
            , [ String.fromInt <| posX + participantMargin // 2, String.fromInt posY ] |> String.join ","
            , [ String.fromInt <| posX + participantMargin // 2, String.fromInt <| posY + messageMargin // 2 ] |> String.join ","
            , [ String.fromInt <| posX + 4, String.fromInt <| posY + messageMargin // 2 ] |> String.join ","
            ]
                |> String.join " "
    in
    g []
        [ polyline [ points messagePoints, markerEnd "url(#sync)", fill "none", stroke settings.color.line, strokeWidth "2" ] []
        , textView settings ( posX + 8, posY - 8 ) ( participantMargin, 8 ) (SequenceDiagram.unwrapMessageType messageType)
        ]


messageView : Settings -> Position -> Position -> MessageType -> Svg Msg
messageView settings ( fromX, fromY ) ( toX, toY ) messageType =
    let
        ( ( isDot, markerStartId, markerEndId ), ( fromOffset, toOffset ) ) =
            case ( fromX - toX < 0, messageType ) of
                ( True, Sync _ ) ->
                    ( ( False, "", "sync" ), ( 0, 4 ) )

                ( False, Sync _ ) ->
                    ( ( False, "", "sync" ), ( 0, 4 ) )

                ( True, Async _ ) ->
                    ( ( False, "", "async" ), ( 0, 4 ) )

                ( False, Async _ ) ->
                    ( ( False, "", "async" ), ( 0, 4 ) )

                ( True, Response _ ) ->
                    ( ( True, "", "async" ), ( 0, 4 ) )

                ( False, Response _ ) ->
                    ( ( True, "", "async" ), ( 0, 4 ) )

                ( True, Found _ ) ->
                    ( ( False, "found", "async" ), ( participantMargin, 5 ) )

                ( False, Found _ ) ->
                    ( ( False, "async", "found" ), ( participantMargin, 5 ) )

                ( True, Lost _ ) ->
                    ( ( False, "", "lost" ), ( 0, participantMargin ) )

                ( False, Lost _ ) ->
                    ( ( False, "lost", "" ), ( 0, participantMargin ) )
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
        , textView settings ( fromX + 8 + fromOffset, fromY - 16 ) ( toX - fromX, 8 ) (SequenceDiagram.unwrapMessageType messageType)
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
                    , width "48"
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

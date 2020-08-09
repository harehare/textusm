module Models.Views.SequenceDiagram exposing (Fragment(..), Message(..), MessageType(..), Participant(..), SequenceDiagram(..), SequenceItem(..), fragmentToString, fromItems, messagesCount, sequenceItemCount, unwrapMessageType)

import Data.Item as Item exposing (Item, Items)
import Dict exposing (Dict)
import Maybe.Extra exposing (isJust)


type SequenceDiagram
    = SequenceDiagram (List Participant) (List SequenceItem)


type SequenceItem
    = SequenceItem Fragment (List Message)


type Participant
    = Participant Item Int


type Message
    = Message MessageType Participant Participant
    | SubMessage SequenceItem


type MessageType
    = Sync String
    | Async String
    | Response String
    | Found String
    | Lost String


type Fragment
    = Ref String
    | Alt String
    | Opt String
    | Par String
    | Loop String
    | Break String
    | Critical String
    | Assert String
    | Neg String
    | Ignore String
    | Consider String
    | Default


emptySequenceItem : SequenceItem
emptySequenceItem =
    SequenceItem Default []


emptyParticipant : Participant
emptyParticipant =
    Participant Item.emptyItem 0


fromItems : Items -> SequenceDiagram
fromItems items =
    let
        participants =
            itemToParticipant <| Item.head items

        messages =
            Item.map (itemToSequenceItem participants) items
                |> List.filter isJust
                |> List.map (\item -> Maybe.withDefault emptySequenceItem item)
    in
    SequenceDiagram (Dict.values participants) messages


sequenceItemCount : List SequenceItem -> Int
sequenceItemCount items =
    items
        |> List.concatMap (\(SequenceItem _ messages) -> List.map messageCount messages)
        |> List.sum


messagesCount : List Message -> Int
messagesCount messages =
    List.map messageCount messages |> List.sum


messageCount : Message -> Int
messageCount message =
    case message of
        SubMessage (SequenceItem _ items) ->
            List.map messageCount items |> List.sum

        _ ->
            1


itemToParticipant : Maybe Item -> Dict String Participant
itemToParticipant maybeItem =
    case ( maybeItem, maybeItem |> Maybe.map .text |> Maybe.withDefault "" |> String.toLower ) of
        ( Just item, "participant" ) ->
            item.children |> Item.unwrapChildren |> Item.indexedMap (\i childItem -> ( String.trim childItem.text, Participant childItem i )) |> Dict.fromList

        _ ->
            Dict.empty


itemsToMessages : Items -> Dict String Participant -> List Message
itemsToMessages items participantDict =
    Item.map (\item -> itemToMessage item participantDict) items
        |> List.filter isJust
        |> List.map (\item -> Maybe.withDefault (Message (Sync "") (Participant Item.emptyItem 0) (Participant Item.emptyItem 0)) item)


itemToSequenceItem : Dict String Participant -> Item -> Maybe SequenceItem
itemToSequenceItem participants item =
    let
        fragment =
            String.trim item.text |> textToFragment
    in
    case fragment of
        Default ->
            case itemToMessage item participants of
                Just msg ->
                    Just <| SequenceItem Default [ msg ]

                Nothing ->
                    Nothing

        _ ->
            Just <| SequenceItem fragment (itemsToMessages (Item.unwrapChildren item.children) participants)


itemToMessage : Item -> Dict String Participant -> Maybe Message
itemToMessage item participantDict =
    let
        fragment =
            String.trim item.text |> textToFragment
    in
    case fragment of
        Default ->
            let
                text =
                    item.children
                        |> Item.unwrapChildren
                        |> Item.head
                        |> Maybe.withDefault Item.emptyItem
                        |> .text
                        |> String.trim
            in
            case String.split " " (String.trim item.text) of
                [ c1, "->o" ] ->
                    let
                        participant1 =
                            Dict.get c1 participantDict

                        (Participant _ order) =
                            Maybe.withDefault emptyParticipant participant1
                    in
                    case participant1 of
                        Just participantFrom ->
                            Just <| Message (Lost text) participantFrom (Participant Item.emptyItem (order + 1))

                        _ ->
                            Nothing

                [ "o->", c1 ] ->
                    let
                        participant1 =
                            Dict.get c1 participantDict

                        (Participant _ order) =
                            Maybe.withDefault emptyParticipant participant1
                    in
                    case participant1 of
                        Just participantTo ->
                            Just <| Message (Found text) (Participant Item.emptyItem (order + 1)) participantTo

                        _ ->
                            Nothing

                [ c1, m, c2 ] ->
                    let
                        participant1 =
                            Dict.get c1 participantDict

                        ( messageType, isReverse ) =
                            textToMessageType m text

                        participant2 =
                            Dict.get c2 participantDict
                    in
                    case
                        if isReverse then
                            ( participant2, participant1 )

                        else
                            ( participant1, participant2 )
                    of
                        ( Just participantFrom, Just participantTo ) ->
                            Just <| Message messageType participantFrom participantTo

                        _ ->
                            Nothing

                _ ->
                    Nothing

        _ ->
            itemToSequenceItem participantDict item
                |> Maybe.andThen (\m -> Just <| SubMessage m)


textToFragment : String -> Fragment
textToFragment text =
    let
        text_ =
            String.toLower text

        ( fragment, fragmentText ) =
            case
                String.split " " text_
            of
                f :: tokens ->
                    ( f, tokens |> String.join " " )

                _ ->
                    ( text_, "" )
    in
    case fragment of
        "ref" ->
            Ref fragmentText

        "alt" ->
            Alt fragmentText

        "opt" ->
            Opt fragmentText

        "par" ->
            Par fragmentText

        "loop" ->
            Loop fragmentText

        "break" ->
            Break fragmentText

        "critical" ->
            Critical fragmentText

        "assert" ->
            Assert fragmentText

        "neg" ->
            Neg fragmentText

        "ignore" ->
            Ignore fragmentText

        "consider" ->
            Consider fragmentText

        _ ->
            Default


fragmentToString : Fragment -> String
fragmentToString fragment =
    case fragment of
        Ref _ ->
            "ref"

        Alt _ ->
            "alt"

        Opt _ ->
            "opt"

        Par _ ->
            "par"

        Loop _ ->
            "loop"

        Break _ ->
            "break"

        Critical _ ->
            "critical"

        Assert _ ->
            "assert"

        Neg _ ->
            "neg"

        Ignore _ ->
            "ignore"

        Consider _ ->
            "consider"

        _ ->
            ""


textToMessageType : String -> String -> ( MessageType, Bool )
textToMessageType message text =
    case message of
        "->" ->
            ( Sync text, False )

        "<-" ->
            ( Sync text, True )

        "->>" ->
            ( Async text, False )

        "<<-" ->
            ( Async text, True )

        "-->" ->
            ( Response text, False )

        "<--" ->
            ( Response text, True )

        "o->" ->
            ( Found text, False )

        "<-o" ->
            ( Found text, True )

        "->o" ->
            ( Lost text, False )

        "o<-" ->
            ( Lost text, True )

        _ ->
            ( Sync text, False )


unwrapMessageType : MessageType -> String
unwrapMessageType messageType =
    case messageType of
        Sync text ->
            text

        Async text ->
            text

        Response text ->
            text

        Found text ->
            text

        Lost text ->
            text

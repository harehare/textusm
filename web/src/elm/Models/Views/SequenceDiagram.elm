module Models.Views.SequenceDiagram exposing (Fragment(..), Message(..), MessageType(..), Participant(..), SequenceDiagram(..), SequenceItem(..), fragmentToString, fromItems, messagesCount, unwrapMessageType)

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


type MessageType
    = Sync String
    | Async String
    | Response String
    | Found String
    | Lost String


type Fragment
    = Ref
    | Alt
    | Opt
    | Par
    | Loop
    | Break
    | Critical
    | Assert
    | Neg
    | Ignore
    | Consider
    | Default


emptySequenceItem : SequenceItem
emptySequenceItem =
    SequenceItem Default []


fromItems : Items -> SequenceDiagram
fromItems items =
    let
        participants =
            itemToParticipant <| Item.head items

        messages =
            Item.map
                (\item ->
                    let
                        fragment =
                            textToFragment item.text
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
                )
                items
                |> List.filter isJust
                |> List.map (\item -> Maybe.withDefault emptySequenceItem item)
    in
    SequenceDiagram (Dict.values participants) messages


messagesCount : List SequenceItem -> Int
messagesCount items =
    items
        |> List.map (\(SequenceItem _ messages) -> List.length messages)
        |> List.sum


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


itemToMessage : Item -> Dict String Participant -> Maybe Message
itemToMessage item participantDict =
    let
        tokens =
            String.split " " (String.trim item.text)
    in
    case tokens of
        [ c1, m, c2 ] ->
            let
                text =
                    item.children
                        |> Item.unwrapChildren
                        |> Item.head
                        |> Maybe.withDefault Item.emptyItem
                        |> .text
                        |> String.trim

                participant1 =
                    Dict.get c1 participantDict

                messageType =
                    textToMessageType m text

                participant2 =
                    Dict.get c2 participantDict
            in
            case ( participant1, participant2 ) of
                ( Just participantFrom, Just participantTo ) ->
                    Just <| Message messageType participantFrom participantTo

                _ ->
                    Nothing

        _ ->
            Nothing


textToFragment : String -> Fragment
textToFragment text =
    case String.toLower text of
        "ref" ->
            Ref

        "alt" ->
            Alt

        "opt" ->
            Opt

        "par" ->
            Par

        "loop" ->
            Loop

        "break" ->
            Break

        "critical" ->
            Critical

        "assert" ->
            Assert

        "neg" ->
            Neg

        "ignore" ->
            Ignore

        "consider" ->
            Consider

        _ ->
            Default


fragmentToString : Fragment -> String
fragmentToString fragment =
    case fragment of
        Ref ->
            "ref"

        Alt ->
            "alt"

        Opt ->
            "opt"

        Par ->
            "par"

        Loop ->
            "loop"

        Break ->
            "break"

        Critical ->
            "critical"

        Assert ->
            "assert"

        Neg ->
            "neg"

        Ignore ->
            "ignore"

        Consider ->
            "consider"

        _ ->
            ""


textToMessageType : String -> String -> MessageType
textToMessageType message text =
    case message of
        "->" ->
            Sync text

        "->>" ->
            Async text

        "-->" ->
            Response text

        "o->" ->
            Found text

        "->o" ->
            Lost text

        _ ->
            Sync text


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

module Models.Views.SequenceDiagram exposing (messagesCount, Fragment(..), Lifeline(..), Message(..), MessageType(..), SequenceDiagram(..), SequenceItem(..), fragmentToString, fromItems, unwrapMessageType)

import Data.Item as Item exposing (Item, Items)
import Dict exposing (Dict)
import Maybe.Extra exposing (isJust)


type SequenceDiagram
    = SequenceDiagram (List Lifeline) (List SequenceItem)


type SequenceItem
    = SequenceItem Fragment (List Message)


type Lifeline
    = Lifeline Item Int


type Message
    = Message MessageType Lifeline Lifeline


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
        lifelines =
            itemToLifeline <| Item.head items

        messages =
            Item.map
                (\item ->
                    let
                        fragment =
                            textToFragment item.text
                    in
                    case fragment of
                        Default ->
                            case itemToMessage item lifelines of
                                Just msg ->
                                    Just <| SequenceItem Default [ msg ]

                                Nothing ->
                                    Nothing

                        _ ->
                            Just <| SequenceItem fragment (itemsToMessages (Item.unwrapChildren item.children) lifelines)
                )
                items
                |> List.filter isJust
                |> List.map (\item -> Maybe.withDefault emptySequenceItem item)
    in
    SequenceDiagram (Dict.values lifelines) messages


messagesCount : List SequenceItem -> Int
messagesCount items =
    items
        |> List.map (\(SequenceItem _ messages) -> List.length messages)
        |> List.sum


itemToLifeline : Maybe Item -> Dict String Lifeline
itemToLifeline maybeItem =
    case ( maybeItem, maybeItem |> Maybe.map .text |> Maybe.withDefault "" |> String.toLower ) of
        ( Just item, "lifeline" ) ->
            item.children |> Item.unwrapChildren |> Item.indexedMap (\i childItem -> ( String.trim childItem.text, Lifeline childItem i )) |> Dict.fromList

        _ ->
            Dict.empty


itemsToMessages : Items -> Dict String Lifeline -> List Message
itemsToMessages items lifelineDict =
    Item.map (\item -> itemToMessage item lifelineDict) items
        |> List.filter isJust
        |> List.map (\item -> Maybe.withDefault (Message (Sync "") (Lifeline Item.emptyItem 0) (Lifeline Item.emptyItem 0)) item)


itemToMessage : Item -> Dict String Lifeline -> Maybe Message
itemToMessage item lifelineDict =
    let
        tokens =
            String.split " " item.text
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

                lifeline1 =
                    Dict.get c1 lifelineDict

                messageType =
                    textToMessageType m text

                lifeline2 =
                    Dict.get c2 lifelineDict
            in
            case ( lifeline1, lifeline2 ) of
                ( Just lifelineFrom, Just lifelineTo ) ->
                    Just <| Message messageType lifelineFrom lifelineTo

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

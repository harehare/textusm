module Models.Views.SequenceDiagram exposing (Fragment(..), Message(..), MessageType(..), Participant(..), SequenceDiagram(..), SequenceItem(..), emptyMessage, fragmentToString, fromItems, messageCountAll, messagesCount, participantCount, sequenceItemCount, sequenceItemMessages, unwrapMessageType)

import Data.Item as Item exposing (Item, Items)
import Dict exposing (Dict)
import Maybe.Extra exposing (isJust)


type SequenceDiagram
    = SequenceDiagram (List Participant) (List SequenceItem)


type SequenceItem
    = Fragment Fragment
    | Messages (List Message)


type Participant
    = Participant Item Int


type Message
    = Message MessageType Participant Participant
    | SubMessage SequenceItem


type MessageType
    = Sync String
    | Async String
    | Reply String
    | Found String
    | Lost String


type alias FragmentText =
    String


type alias AltMessage =
    ( FragmentText, List Message )


type alias ParMessage =
    ( FragmentText, List Message )


type Fragment
    = Alt AltMessage AltMessage
    | Opt FragmentText (List Message)
    | Par (List ParMessage)
    | Loop FragmentText (List Message)
    | Break FragmentText (List Message)
    | Critical FragmentText (List Message)
    | Assert FragmentText (List Message)
    | Neg FragmentText (List Message)
    | Ignore FragmentText (List Message)
    | Consider FragmentText (List Message)


emptySequenceItem : SequenceItem
emptySequenceItem =
    Messages []


emptyParticipant : Participant
emptyParticipant =
    Participant Item.emptyItem 0


emptyMessage : Message
emptyMessage =
    Message (Sync "") emptyParticipant emptyParticipant


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


participantCount : SequenceDiagram -> Int
participantCount (SequenceDiagram participants _) =
    List.length participants


messageCountAll : SequenceDiagram -> Int
messageCountAll (SequenceDiagram _ items) =
    items
        |> List.concatMap
            (\item ->
                sequenceItemMessages item
                    |> List.map messageCount
            )
        |> List.sum


sequenceItemCount : List SequenceItem -> Int
sequenceItemCount items =
    items
        |> List.concatMap
            (\item ->
                sequenceItemMessages item
                    |> List.map messageCount
            )
        |> List.sum


sequenceItemMessages : SequenceItem -> List Message
sequenceItemMessages item =
    case item of
        Fragment (Alt ( _, ifMessages ) ( _, elseMessages )) ->
            ifMessages ++ elseMessages

        Fragment (Opt _ messages) ->
            messages

        Fragment (Par messages) ->
            List.concatMap (\( _, m ) -> m) messages

        Fragment (Loop _ messages) ->
            messages

        Fragment (Break _ messages) ->
            messages

        Fragment (Critical _ messages) ->
            messages

        Fragment (Assert _ messages) ->
            messages

        Fragment (Neg _ messages) ->
            messages

        Fragment (Ignore _ messages) ->
            messages

        Fragment (Consider _ messages) ->
            messages

        Messages messages ->
            messages


messagesCount : List Message -> Int
messagesCount messages =
    List.map messageCount messages |> List.sum


messageCount : Message -> Int
messageCount message =
    case message of
        SubMessage item ->
            sequenceItemMessages item |> List.map messageCount |> List.sum

        _ ->
            1


itemToParticipant : Maybe Item -> Dict String Participant
itemToParticipant maybeItem =
    case ( maybeItem, maybeItem |> Maybe.map .text |> Maybe.withDefault "" |> String.toLower ) of
        ( Just item, "participant" ) ->
            item.children |> Item.unwrapChildren |> Item.indexedMap (\i childItem -> ( String.trim childItem.text, Participant childItem i )) |> Dict.fromList

        _ ->
            Dict.empty


itemsToMessages : Dict String Participant -> Items -> List Message
itemsToMessages participantDict items =
    Item.map (\item -> itemToMessage item participantDict) items
        |> List.filter isJust
        |> List.map (\item -> Maybe.withDefault (Message (Sync "") (Participant Item.emptyItem 0) (Participant Item.emptyItem 0)) item)


itemToSequenceItem : Dict String Participant -> Item -> Maybe SequenceItem
itemToSequenceItem participants item =
    let
        children =
            Item.unwrapChildren item.children

        childrenHead =
            Item.unwrapChildren item.children |> Item.head |> Maybe.withDefault Item.emptyItem

        grandChild =
            childrenHead |> .children |> Item.unwrapChildren
    in
    case String.trim item.text |> String.toLower of
        "alt" ->
            let
                altIf =
                    Item.head children
                        |> Maybe.withDefault Item.emptyItem

                altElse =
                    Item.getAt 1 children
                        |> Maybe.withDefault Item.emptyItem
            in
            Just <|
                Fragment <|
                    Alt ( altIf.text, itemsToMessages participants <| Item.unwrapChildren altIf.children ) ( altElse.text, itemsToMessages participants <| Item.unwrapChildren altElse.children )

        "opt" ->
            Just <| Fragment <| Opt childrenHead.text <| itemsToMessages participants <| grandChild

        "par" ->
            let
                parMesssages =
                    Item.map (\child -> ( child.text, itemsToMessages participants <| Item.unwrapChildren <| child.children )) children
            in
            Just <| Fragment <| Par parMesssages

        "loop" ->
            Just <| Fragment <| Loop childrenHead.text <| itemsToMessages participants <| grandChild

        "break" ->
            Just <| Fragment <| Break childrenHead.text <| itemsToMessages participants <| grandChild

        "critical" ->
            Just <| Fragment <| Critical childrenHead.text <| itemsToMessages participants <| grandChild

        "assert" ->
            Just <| Fragment <| Assert childrenHead.text <| itemsToMessages participants <| grandChild

        "neg" ->
            Just <| Fragment <| Neg childrenHead.text <| itemsToMessages participants <| grandChild

        "ignore" ->
            Just <| Fragment <| Ignore childrenHead.text <| itemsToMessages participants <| grandChild

        "consider" ->
            Just <| Fragment <| Consider childrenHead.text <| itemsToMessages participants <| grandChild

        _ ->
            case itemToMessage item participants of
                Just msg ->
                    Just <| Messages [ msg ]

                Nothing ->
                    Nothing


isFragmentText : String -> Bool
isFragmentText text =
    List.member
        (String.toLower text |> String.trim)
        [ "alt"
        , "opt"
        , "par"
        , "loop"
        , "break"
        , "critical"
        , "assert"
        , "neg"
        , "ignore"
        , "consider"
        ]


itemToMessage : Item -> Dict String Participant -> Maybe Message
itemToMessage item participantDict =
    if isFragmentText item.text then
        itemToSequenceItem participantDict item
            |> Maybe.andThen (\m -> Just <| SubMessage m)

    else
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


fragmentToString : Fragment -> String
fragmentToString fragment =
    case fragment of
        Alt _ _ ->
            "alt"

        Opt _ _ ->
            "opt"

        Par _ ->
            "par"

        Loop _ _ ->
            "loop"

        Break _ _ ->
            "break"

        Critical _ _ ->
            "critical"

        Assert _ _ ->
            "assert"

        Neg _ _ ->
            "neg"

        Ignore _ _ ->
            "ignore"

        Consider _ _ ->
            "consider"


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
            ( Reply text, False )

        "<--" ->
            ( Reply text, True )

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

        Reply text ->
            text

        Found text ->
            text

        Lost text ->
            text

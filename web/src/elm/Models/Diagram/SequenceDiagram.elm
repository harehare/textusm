module Models.Diagram.SequenceDiagram exposing
    ( AltMessage
    , Fragment(..)
    , FragmentText
    , Message(..)
    , MessageType(..)
    , ParMessage
    , Participant(..)
    , SequenceDiagram(..)
    , SequenceItem(..)
    , fragmentToString
    , from
    , messagesCount
    , sequenceItemCount
    , sequenceItemMessages
    , size
    , toMermaidString
    , unwrapMessageType
    )

import Constants
import Dict exposing (Dict)
import Models.DiagramSettings as DiagramSettings
import Models.Item as Item exposing (Item, Items)
import Models.Size exposing (Size)


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


emptyParticipant : Participant
emptyParticipant =
    Participant Item.new 0


from : Items -> SequenceDiagram
from items =
    let
        participants : List ( String, Participant )
        participants =
            itemToParticipant <| Item.head items

        messages : List SequenceItem
        messages =
            Item.map (itemToSequenceItem (Dict.fromList participants)) items
                |> List.filterMap identity
    in
    SequenceDiagram (List.map Tuple.second participants) messages


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


itemToParticipant : Maybe Item -> List ( String, Participant )
itemToParticipant maybeItem =
    case ( maybeItem, maybeItem |> Maybe.map Item.getText |> Maybe.withDefault "" |> String.toLower ) of
        ( Just item, "participant" ) ->
            Item.getChildren item |> Item.unwrapChildren |> Item.indexedMap (\i childItem -> ( Item.getText childItem |> String.trim, Participant childItem i ))

        _ ->
            []


itemsToMessages : Dict String Participant -> Items -> List Message
itemsToMessages participantDict items =
    Item.map (\item -> itemToMessage item participantDict) items
        |> List.filterMap identity


itemToSequenceItem : Dict String Participant -> Item -> Maybe SequenceItem
itemToSequenceItem participants item =
    let
        children : Items
        children =
            Item.getChildren item |> Item.unwrapChildren

        childrenHead : Item
        childrenHead =
            Item.getChildren item |> Item.unwrapChildren |> Item.head |> Maybe.withDefault Item.new

        grandChild : Items
        grandChild =
            childrenHead |> Item.getChildren |> Item.unwrapChildren
    in
    case Item.getText item |> String.trim |> String.toLower of
        "alt" ->
            let
                altIf : Item
                altIf =
                    Item.head children
                        |> Maybe.withDefault Item.new

                altElse : Item
                altElse =
                    Item.getAt 1 children
                        |> Maybe.withDefault Item.new
            in
            Just <|
                Fragment <|
                    Alt ( Item.getText altIf, itemsToMessages participants <| Item.unwrapChildren <| Item.getChildren altIf ) ( Item.getText altElse, itemsToMessages participants <| Item.unwrapChildren <| Item.getChildren altElse )

        "opt" ->
            Just <| Fragment <| Opt (Item.getText childrenHead) <| itemsToMessages participants <| grandChild

        "par" ->
            let
                parMesssages : List ( String, List Message )
                parMesssages =
                    Item.map (\child -> ( Item.getText child, itemsToMessages participants <| Item.unwrapChildren <| Item.getChildren child )) children
            in
            Just <| Fragment <| Par parMesssages

        "loop" ->
            Just <| Fragment <| Loop (Item.getText childrenHead) <| itemsToMessages participants <| grandChild

        "break" ->
            Just <| Fragment <| Break (Item.getText childrenHead) <| itemsToMessages participants <| grandChild

        "critical" ->
            Just <| Fragment <| Critical (Item.getText childrenHead) <| itemsToMessages participants <| grandChild

        "assert" ->
            Just <| Fragment <| Assert (Item.getText childrenHead) <| itemsToMessages participants <| grandChild

        "neg" ->
            Just <| Fragment <| Neg (Item.getText childrenHead) <| itemsToMessages participants <| grandChild

        "ignore" ->
            Just <| Fragment <| Ignore (Item.getText childrenHead) <| itemsToMessages participants <| grandChild

        "consider" ->
            Just <| Fragment <| Consider (Item.getText childrenHead) <| itemsToMessages participants <| grandChild

        _ ->
            Maybe.map (\v -> Messages [ v ]) (itemToMessage item participants)


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
    if isFragmentText <| Item.getText item then
        itemToSequenceItem participantDict item
            |> Maybe.map SubMessage

    else
        let
            text : String
            text =
                Item.getChildren item
                    |> Item.unwrapChildren
                    |> Item.head
                    |> Maybe.withDefault Item.new
                    |> Item.getText
                    |> String.trim
        in
        case String.split " " (String.trim <| Item.getText item) of
            [ c1, "->o" ] ->
                let
                    participant1 : Maybe Participant
                    participant1 =
                        Dict.get c1 participantDict
                in
                case participant1 of
                    Just participantFrom ->
                        let
                            (Participant _ order) =
                                Maybe.withDefault emptyParticipant participant1
                        in
                        Just <| Message (Lost text) participantFrom (Participant Item.new (order + 1))

                    _ ->
                        Nothing

            [ "o->", c1 ] ->
                let
                    participant1 : Maybe Participant
                    participant1 =
                        Dict.get c1 participantDict
                in
                case participant1 of
                    Just participantTo ->
                        let
                            (Participant _ order) =
                                Maybe.withDefault emptyParticipant participant1
                        in
                        Just <| Message (Found text) (Participant Item.new (order + 1)) participantTo

                    _ ->
                        Nothing

            [ c1, m, c2 ] ->
                let
                    participant1 : Maybe Participant
                    participant1 =
                        Dict.get c1 participantDict

                    ( messageType, isReverse ) =
                        textToMessageType m text

                    participant2 : Maybe Participant
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


size : DiagramSettings.Settings -> SequenceDiagram -> Size
size settings sequenceDiagram =
    let
        diagramWidth : Int
        diagramWidth =
            participantCount sequenceDiagram * (settings.size.width + Constants.participantMargin) + 8

        diagramHeight : Int
        diagramHeight =
            messageCountAll sequenceDiagram
                * Constants.messageMargin
                + settings.size.height
                * 4
                + Constants.messageMargin
                + 8
    in
    ( diagramWidth, diagramHeight )



-- mermaid


toMermaidString : SequenceDiagram -> String
toMermaidString (SequenceDiagram participants sequenceItems) =
    let
        sequenceLines : List String
        sequenceLines =
            List.concatMap
                (\item ->
                    case item of
                        Fragment fragment ->
                            fragmentToMermaidString fragment

                        Messages messages ->
                            List.concatMap messageToMermaidString messages
                )
                sequenceItems
    in
    "sequenceDiagram"
        :: List.map participantToMermaidString participants
        ++ sequenceLines
        |> String.join "\n"


participantToMermaidString : Participant -> String
participantToMermaidString (Participant item _) =
    "    participant " ++ Item.getTrimmedText item


fragmentToMermaidString : Fragment -> List String
fragmentToMermaidString fragment =
    case fragment of
        Alt ( ifText, ifMessages ) ( elseText, elseMessags ) ->
            (ifText
                :: List.map
                    (\l ->
                        messageToMermaidString l
                            |> List.map (\l_ -> "    " ++ l_)
                            |> String.join "\n"
                    )
                    ifMessages
            )
                ++ (elseText :: List.map (\l -> messageToMermaidString l |> String.join "\n") elseMessags)
                ++ [ "    end" ]

        Opt text messages ->
            text
                :: List.map
                    (\l ->
                        messageToMermaidString l
                            |> List.map (\l_ -> "    " ++ l_)
                            |> String.join "\n"
                    )
                    messages
                ++ [ "    end" ]

        Par parMessages ->
            case parMessages of
                ( parText, messages ) :: rest ->
                    let
                        parAndMessage : ParMessage -> List String
                        parAndMessage ( _, parMessages_ ) =
                            "    and "
                                :: List.map
                                    (\l ->
                                        messageToMermaidString l
                                            |> List.map (\l_ -> "    " ++ l_)
                                            |> String.join "\n"
                                    )
                                    parMessages_
                    in
                    (parText
                        :: List.map
                            (\l ->
                                messageToMermaidString l
                                    |> List.map (\l_ -> "    " ++ l_)
                                    |> String.join "\n"
                            )
                            messages
                    )
                        ++ List.concatMap parAndMessage rest
                        ++ [ "    end" ]

                [] ->
                    []

        Loop text messages ->
            text
                :: List.map
                    (\l ->
                        messageToMermaidString l
                            |> List.map (\l_ -> "    " ++ l_)
                            |> String.join "\n"
                    )
                    messages
                ++ [ "    end" ]

        _ ->
            []


messageToMermaidString : Message -> List String
messageToMermaidString message =
    case message of
        Message messageType (Participant fromItem _) (Participant toItem _) ->
            case messageType of
                Sync m ->
                    [ Item.getText fromItem ++ "->" ++ Item.getTrimmedText toItem ++ ": " ++ m ]

                Async m ->
                    [ Item.getText fromItem ++ "-)" ++ Item.getTrimmedText toItem ++ ": " ++ m ]

                _ ->
                    []

        SubMessage sequenceItem ->
            case sequenceItem of
                Fragment fragment ->
                    fragmentToMermaidString fragment

                Messages [] ->
                    []

                Messages (firstMessages :: restMessages) ->
                    messageToMermaidString firstMessages ++ List.concatMap messageToMermaidString restMessages

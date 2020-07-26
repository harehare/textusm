module Models.Views.SequenceDiagram exposing (SequenceDiagram)


type SequenceDiagram
    = SequenceDiagram (List Component) (List SequenceItem)


type SequenceItem
    = SequenceItem Fragment (List Message)


type Component
    = Component String


type Message
    = Message MessageType Direction Component Component


type MessageType
    = Sync
    | Async
    | Response
    | Found
    | Lost


type Direction
    = Left
    | Rigth


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
    | None

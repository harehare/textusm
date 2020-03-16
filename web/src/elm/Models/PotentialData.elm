module Models.PotentialData exposing (empty, failed, isEmpty, isPending, pending, ready)


type Pot a
    = Empty
    | Pending
    | Ready a
    | Failed


empty : Pot a
empty =
    Empty


ready : a -> Pot a
ready a =
    Ready a


pending : Pot a
pending =
    Pending


failed : Pot a
failed =
    Failed


isEmpty : Pot a -> Bool
isEmpty a =
    a == Empty


isPending : Pot a -> Bool
isPending a =
    a == Pending

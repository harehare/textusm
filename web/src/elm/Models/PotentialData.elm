module Models.PotentialData exposing (Pot(..), andThen, empty, failed, isEmpty, isPending, isReady, pending, ready)


type Pot a
    = Empty
    | Pending
    | Ready a
    | Failed


andThen : (a -> Pot b) -> Pot a -> Pot b
andThen f a =
    case a of
        Ready v ->
            f v

        Pending ->
            Pending

        Empty ->
            Empty

        Failed ->
            Failed


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


isReady : Pot a -> Bool
isReady a =
    case a of
        Ready _ ->
            True

        _ ->
            False


isPending : Pot a -> Bool
isPending a =
    a == Pending

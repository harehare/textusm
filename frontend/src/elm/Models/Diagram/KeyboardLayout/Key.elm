module Models.Diagram.KeyboardLayout.Key exposing
    ( Key(..)
    , bottomLegend
    , fromItem
    , height
    , marginTop
    , new
    , topLegend
    , unit
    )

import Models.Diagram.KeyboardLayout.Unit as Unit exposing (Unit)
import Models.Item as Item exposing (Item)


type alias Legend =
    String


type alias MarginTop =
    Maybe Unit


type alias KeySize =
    ( Unit, Unit )


type Key
    = Key (Maybe Legend) (Maybe Legend) KeySize MarginTop
    | Blank Unit


new : Maybe Legend -> Maybe Legend -> KeySize -> MarginTop -> Key
new top bottom size mt =
    Key top bottom size mt


topLegend : Key -> Maybe Legend
topLegend k =
    case k of
        Key t _ _ _ ->
            t

        _ ->
            Nothing


bottomLegend : Key -> Maybe Legend
bottomLegend k =
    case k of
        Key _ b _ _ ->
            b

        _ ->
            Nothing


marginTop : Key -> MarginTop
marginTop k =
    case k of
        Key _ _ _ mt ->
            mt

        _ ->
            Nothing


unit : Key -> Unit
unit k =
    case k of
        Key _ _ u _ ->
            Tuple.first u

        Blank u ->
            u


height : Key -> Unit
height k =
    case k of
        Key _ _ u _ ->
            Tuple.second u

        Blank u ->
            u


fromItem : Item -> Key
fromItem item =
    case Item.getText item |> String.split "," of
        top :: bottom :: u :: v :: mt :: _ ->
            new (Just <| replace top)
                (Just <| replace bottom)
                ( Unit.fromString u |> Maybe.withDefault Unit.u1
                , Unit.fromString v |> Maybe.withDefault Unit.u1
                )
                (Unit.fromString mt)

        top :: bottom :: u :: v :: _ ->
            new (Just <| replace top)
                (Just <| replace bottom)
                ( Unit.fromString u |> Maybe.withDefault Unit.u1
                , Unit.fromString v |> Maybe.withDefault Unit.u1
                )
                Nothing

        top :: bottom :: u :: _ ->
            new (Just <| replace top)
                (Just <| replace bottom)
                ( Unit.fromString u |> Maybe.withDefault Unit.u1, Unit.u1 )
                Nothing

        [ top, bottom ] ->
            new (Just <| replace top) (Just <| replace bottom) ( Unit.u1, Unit.u1 ) Nothing

        [ top ] ->
            case Unit.fromString top of
                Just u ->
                    Blank u

                Nothing ->
                    new (Just <| replace top) Nothing ( Unit.u1, Unit.u1 ) Nothing

        _ ->
            new Nothing Nothing ( Unit.u1, Unit.u1 ) Nothing


replace : String -> String
replace t =
    t
        |> String.replace "\\#" "#"
        |> String.replace "comma" ","

module Models.Diagram.KeyboardLayout.Key exposing
    ( Key(..)
    , bottomLegend
    , fromItem
    , height
    , marginTop
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
    = Key Item (Maybe Legend) (Maybe Legend) KeySize MarginTop
    | Blank Unit


topLegend : Key -> Maybe Legend
topLegend k =
    case k of
        Key _ t _ _ _ ->
            t

        _ ->
            Nothing


bottomLegend : Key -> Maybe Legend
bottomLegend k =
    case k of
        Key _ _ b _ _ ->
            b

        _ ->
            Nothing


marginTop : Key -> MarginTop
marginTop k =
    case k of
        Key _ _ _ _ mt ->
            mt

        _ ->
            Nothing


unit : Key -> Unit
unit k =
    case k of
        Key _ _ _ u _ ->
            Tuple.first u

        Blank u ->
            u


height : Key -> Unit
height k =
    case k of
        Key _ _ _ u _ ->
            Tuple.second u

        Blank u ->
            u


fromItem : Item -> Key
fromItem item =
    case Item.getText item |> String.split "," of
        top :: bottom :: u :: v :: mt :: _ ->
            Key item
                (Just <| replace top)
                (Just <| replace bottom)
                ( Unit.fromString u |> Maybe.withDefault Unit.u1
                , Unit.fromString v |> Maybe.withDefault Unit.u1
                )
                (Unit.fromString mt)

        top :: bottom :: u :: v :: _ ->
            Key item
                (Just <| replace top)
                (Just <| replace bottom)
                ( Unit.fromString u |> Maybe.withDefault Unit.u1
                , Unit.fromString v |> Maybe.withDefault Unit.u1
                )
                Nothing

        top :: bottom :: u :: _ ->
            Key item
                (Just <| replace top)
                (Just <| replace bottom)
                ( Unit.fromString u |> Maybe.withDefault Unit.u1, Unit.u1 )
                Nothing

        [ top, bottom ] ->
            Key item
                (Just <| replace top)
                (Just <| replace bottom)
                ( Unit.u1, Unit.u1 )
                Nothing

        [ top ] ->
            case Unit.fromString top of
                Just u ->
                    Blank u

                Nothing ->
                    Key item
                        (Just <| replace top)
                        Nothing
                        ( Unit.u1, Unit.u1 )
                        Nothing

        _ ->
            Key item Nothing Nothing ( Unit.u1, Unit.u1 ) Nothing


replace : String -> String
replace t =
    t
        |> String.replace "\\#" "#"
        |> String.replace "comma" ","

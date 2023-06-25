module Models.Diagram.KeyboardLayout.Key exposing
    ( Key(..)
    , bottomLegend
    , fromItem
    , new
    , topLegend
    , unit
    )

import Models.Diagram.KeyboardLayout.Unit as Unit exposing (Unit)
import Models.Item as Item exposing (Item)
import Models.Diagram.KeyboardLayout.Unit as Unit


type alias Legend =
    String


type Key
    = Key (Maybe Legend) (Maybe Legend) Unit
    | Blank Unit


new : Maybe Legend -> Maybe Legend -> Unit -> Key
new top bottom u =
    Key top bottom u


topLegend : Key -> Maybe Legend
topLegend k =
    case k of
        Key t _ _ ->
            t

        _ ->
            Nothing


bottomLegend : Key -> Maybe Legend
bottomLegend k =
    case k of
        Key _ b _ ->
            b

        _ ->
            Nothing


unit : Key -> Unit
unit k =
    case k of
        Key _ _ u ->
            u

        Blank u ->
            u


fromItem : Item -> Key
fromItem item =
    case Item.getText item |> String.split "," of
        top :: bottom :: u :: _ ->
            new (Just <| replace top) (Just <| replace bottom) (Unit.fromString u |> Maybe.withDefault Unit.u1)

        [ top, bottom ] ->
            new (Just <| replace top) (Just <| replace bottom) Unit.u1

        [ top ] ->
            case Unit.fromString top of
                Just u ->
                    Blank u

                Nothing ->
                    new (Just <| replace top) Nothing Unit.u1

        _ ->
            new Nothing Nothing Unit.u1


replace : String -> String
replace t =
    t
        |> String.replace "\\#" "#"
        |> String.replace "comma" ","

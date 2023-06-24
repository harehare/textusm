module Models.Diagram.KeyboardLayout.Key exposing (Key(..), bottomLegend, fromItem, new, topLegend, unit)

import Models.Diagram.KeyboardLayout.Unit as Unit exposing (Unit)
import Models.Item as Item exposing (Item)


type alias Legend =
    String


type Key
    = Key (Maybe Legend) (Maybe Legend) Unit
    | Empty Unit


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

        Empty u ->
            u


fromItem : Item -> Key
fromItem item =
    case Item.getText item |> String.split "," of
        top :: bottom :: u :: _ ->
            new (Just <| replace top) (Just <| replace bottom) (Unit.fromString u)

        [ top, bottom ] ->
            new (Just <| replace top) (Just <| replace bottom) Unit.u1

        [ top ] ->
            if String.endsWith "u" top then
                String.slice 0 -1 top
                    |> String.toFloat
                    |> Maybe.map (\u -> Empty <| Unit.fromString <| String.fromFloat u)
                    |> Maybe.withDefault (new (Just <| replace top) Nothing Unit.u1)

            else
                new (Just <| replace top) Nothing Unit.u1

        _ ->
            new Nothing Nothing Unit.u1


replace : String -> String
replace t =
    t
        |> String.replace "\\#" "#"
        |> String.replace "comma" ","

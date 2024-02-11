module Diagram.KeyboardLayout.Types.Key exposing
    ( Key(..)
    , KeySize
    , Legend
    , MarginTop
    , bottomLegend
    , fromItem
    , height
    , marginTop
    , topLegend
    , unit
    )

import Diagram.KeyboardLayout.Types.Unit as Unit exposing (Unit)
import Types.Item as Item exposing (Item)


type alias Legend =
    String


type alias MarginTop =
    Maybe Unit


type alias KeySize =
    ( Unit, Unit )


type Key
    = Key
        { item : Item
        , topLegend_ : Maybe Legend
        , bottomLegend_ : Maybe Legend
        , keySize : KeySize
        , marginTop_ : MarginTop
        }
    | Blank Unit


topLegend : Key -> Maybe Legend
topLegend k =
    case k of
        Key { topLegend_ } ->
            topLegend_

        _ ->
            Nothing


bottomLegend : Key -> Maybe Legend
bottomLegend k =
    case k of
        Key { bottomLegend_ } ->
            bottomLegend_

        _ ->
            Nothing


marginTop : Key -> MarginTop
marginTop k =
    case k of
        Key { marginTop_ } ->
            marginTop_

        _ ->
            Nothing


unit : Key -> Unit
unit k =
    case k of
        Key { keySize } ->
            Tuple.first keySize

        Blank u ->
            u


height : Key -> Unit
height k =
    case k of
        Key { keySize } ->
            Tuple.second keySize

        Blank u ->
            u


fromItem : Item -> Key
fromItem item =
    case Item.getText item |> String.split "," of
        top :: bottom :: u :: v :: mt :: _ ->
            Key
                { item = item
                , topLegend_ = Just <| replace top
                , bottomLegend_ = Just <| replace bottom
                , keySize =
                    ( Unit.fromString u |> Maybe.withDefault Unit.u1
                    , Unit.fromString v |> Maybe.withDefault Unit.u1
                    )
                , marginTop_ = Unit.fromString mt
                }

        top :: bottom :: u :: v :: _ ->
            Key
                { item = item
                , topLegend_ = Just <| replace top
                , bottomLegend_ = Just <| replace bottom
                , keySize =
                    ( Unit.fromString u |> Maybe.withDefault Unit.u1
                    , Unit.fromString v |> Maybe.withDefault Unit.u1
                    )
                , marginTop_ = Nothing
                }

        top :: bottom :: u :: _ ->
            Key
                { item = item
                , topLegend_ = Just <| replace top
                , bottomLegend_ = Just <| replace bottom
                , keySize = ( Unit.fromString u |> Maybe.withDefault Unit.u1, Unit.u1 )
                , marginTop_ = Nothing
                }

        [ top, bottom ] ->
            Key
                { item = item
                , topLegend_ = Just <| replace top
                , bottomLegend_ = Just <| replace bottom
                , keySize = ( Unit.u1, Unit.u1 )
                , marginTop_ = Nothing
                }

        [ top ] ->
            case Unit.fromString top of
                Just u ->
                    Blank u

                Nothing ->
                    Key
                        { item = item
                        , topLegend_ = Just <| replace top
                        , bottomLegend_ = Nothing
                        , keySize = ( Unit.u1, Unit.u1 )
                        , marginTop_ = Nothing
                        }

        _ ->
            Key
                { item = item
                , topLegend_ = Nothing
                , bottomLegend_ = Nothing
                , keySize = ( Unit.u1, Unit.u1 )
                , marginTop_ = Nothing
                }


replace : String -> String
replace t =
    t
        |> String.replace "{sharp}" "#"
        |> String.replace "{comma}" ","
        |> String.replace "{backquote}" "`"

module Models.Diagram.CardSize exposing (CardSize, decoder, encoder, fromInt, max, min, toInt)

import Json.Decode as D exposing (Decoder)
import Json.Encode as E


type CardSize
    = CardSize Int


max : Int
max =
    600


min : Int
min =
    50


fromInt : Int -> CardSize
fromInt width =
    if width > max then
        CardSize max

    else if width < min then
        CardSize min

    else
        CardSize width


toInt : CardSize -> Int
toInt (CardSize w) =
    w


decoder : Decoder CardSize
decoder =
    D.map fromInt D.int


encoder : CardSize -> E.Value
encoder width =
    E.int <| toInt width

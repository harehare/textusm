module Models.Diagram.CardSize exposing (CardSize, decoder, encoder, fromInt, toInt)

import Json.Decode as D exposing (Decoder)
import Json.Encode as E


type CardSize
    = CardSize Int


fromInt : Int -> CardSize
fromInt width =
    if width > 600 then
        CardSize 600

    else if width < 50 then
        CardSize 50

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

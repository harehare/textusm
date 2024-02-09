module Diagram.Scale exposing
    ( Scale
    , add
    , decoder
    , default
    , encoder
    , fromFloat
    , max
    , min
    , step
    , sub
    , toFloat
    )

import Json.Decode as D exposing (Decoder)
import Json.Encode as E


type Scale
    = Scale Float


step : Scale
step =
    Scale 0.03


default : Scale
default =
    Scale 1.0


max : Scale
max =
    Scale 10.0


min : Scale
min =
    Scale 0.03


fromFloat : Float -> Scale
fromFloat s =
    if isInfinite s then
        default

    else if isNaN s then
        default

    else if s <= toFloat min then
        min

    else if toFloat max <= s then
        max

    else
        Scale s


add : Scale -> Scale -> Scale
add (Scale a) (Scale b) =
    a + b |> fromFloat


sub : Scale -> Scale -> Scale
sub (Scale a) (Scale b) =
    a - b |> fromFloat


toFloat : Scale -> Float
toFloat (Scale s) =
    s


decoder : Decoder Scale
decoder =
    D.map fromFloat D.float


encoder : Scale -> E.Value
encoder scale =
    E.float <| toFloat scale

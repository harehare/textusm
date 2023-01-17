module Models.Diagram.Scale exposing (Scale, default, fromFloat, map, toFloat)


type Scale
    = Scale Float


default : Scale
default =
    Scale 1.0


fromFloat : Float -> Scale
fromFloat s =
    if isInfinite s then
        default

    else if isNaN s then
        default

    else if s <= 0.03 then
        Scale 0.03

    else if 10.0 <= s then
        Scale 10.0

    else
        Scale s


map : (Float -> Float) -> Scale -> Scale
map f (Scale s) =
    f s |> fromFloat


toFloat : Scale -> Float
toFloat (Scale s) =
    s

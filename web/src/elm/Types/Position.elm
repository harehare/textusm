module Types.Position exposing (Position, X, Y, decoder, getX, getY, zero)

import Json.Decode as D


type alias X =
    Int


type alias Y =
    Int


type alias Position =
    ( X, Y )


getX : Position -> X
getX ( x, _ ) =
    x


getY : Position -> Y
getY ( _, y ) =
    y


zero : Position
zero =
    ( 0, 0 )


decoder : D.Decoder Position
decoder =
    D.map2 Tuple.pair
        (D.index 0 D.int)
        (D.index 1 D.int)

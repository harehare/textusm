module Types.Position exposing
    ( Position
    , X
    , Y
    , concat
    , decoder
    , getX
    , getY
    , zero
    )

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


concat : Position -> Position -> Position
concat ( x1, y1 ) ( x2, y2 ) =
    ( x1 + x2, y1 + y2 )


zero : Position
zero =
    ( 0, 0 )


decoder : D.Decoder Position
decoder =
    D.map2 Tuple.pair
        (D.index 0 D.int)
        (D.index 1 D.int)

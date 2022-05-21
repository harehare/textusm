module Models.Position exposing
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


type alias Position =
    ( X, Y )


type alias X =
    Int


type alias Y =
    Int


concat : Position -> Position -> Position
concat ( x1, y1 ) ( x2, y2 ) =
    ( x1 + x2, y1 + y2 )


decoder : D.Decoder Position
decoder =
    D.map2 Tuple.pair
        (D.index 0 D.int)
        (D.index 1 D.int)


getX : Position -> X
getX ( x, _ ) =
    x


getY : Position -> Y
getY ( _, y ) =
    y


zero : Position
zero =
    ( 0, 0 )

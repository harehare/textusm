module Data.Position exposing (Position, X, Y, getX, getY, zero)


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

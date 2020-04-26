module Data.Position exposing (Position, X, Y, getX, getY)


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

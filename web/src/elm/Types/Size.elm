module Types.Size exposing (Height, Size, Width, getHeight, getWidth, isZero, zero)


type alias Width =
    Int


type alias Height =
    Int


type alias Size =
    ( Width, Height )


getWidth : Size -> Width
getWidth ( width, _ ) =
    width


getHeight : Size -> Width
getHeight ( _, height ) =
    height


zero : Size
zero =
    ( 0, 0 )


isZero : Size -> Bool
isZero size =
    case size of
        ( 0, 0 ) ->
            True

        _ ->
            False

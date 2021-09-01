module Types.Size exposing
    ( Height
    , Size
    , Width
    , decoder
    , getHeight
    , getWidth
    , isZero
    , zero
    )

import Json.Decode as D


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


decoder : D.Decoder Size
decoder =
    D.map2 Tuple.pair
        (D.index 0 D.int)
        (D.index 1 D.int)

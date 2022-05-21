module Models.Size exposing
    ( Height
    , Size
    , Width
    , decoder
    , getHeight
    , getWidth
    , zero
    )

import Json.Decode as D


type alias Height =
    Int


type alias Size =
    ( Width, Height )


type alias Width =
    Int


decoder : D.Decoder Size
decoder =
    D.map2 Tuple.pair
        (D.index 0 D.int)
        (D.index 1 D.int)


getHeight : Size -> Width
getHeight ( _, height ) =
    height


getWidth : Size -> Width
getWidth ( width, _ ) =
    width


zero : Size
zero =
    ( 0, 0 )

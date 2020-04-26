module Data.Size exposing (Height, Size, Width, getHeight, getWidth)


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

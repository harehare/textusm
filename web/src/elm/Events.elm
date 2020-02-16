module Events exposing (onKeyDown)

import Html exposing (Attribute)
import Html.Events exposing (keyCode, on)
import Json.Decode as D


onKeyDown : (Int -> Bool -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (D.map2 tagger keyCode isComposing)


isComposing : D.Decoder Bool
isComposing =
    D.field "isComposing" D.bool

module Events exposing (keyBackspace, keyEnter, onClickStopPropagation, onKeyDown)

import Html exposing (Attribute)
import Html.Events exposing (keyCode, on, stopPropagationOn)
import Json.Decode as D


type alias KeyCode =
    Int


keyEnter : KeyCode
keyEnter =
    13


keyBackspace : KeyCode
keyBackspace =
    8


onClickStopPropagation : msg -> Html.Attribute msg
onClickStopPropagation msg =
    stopPropagationOn "click" (D.map alwaysStopPropagation (D.succeed msg))


alwaysStopPropagation : msg -> ( msg, Bool )
alwaysStopPropagation msg =
    ( msg, True )


onKeyDown : (Int -> Bool -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (D.map2 tagger keyCode isComposing)


isComposing : D.Decoder Bool
isComposing =
    D.field "isComposing" D.bool

module Events exposing (keyBackspace, keyEnter, onClickStopPropagation, onDrop, onKeyDown)

import File exposing (File)
import Html exposing (Attribute)
import Html.Events exposing (keyCode, on, preventDefaultOn, stopPropagationOn)
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


alwaysPreventDefaultOn : msg -> ( msg, Bool )
alwaysPreventDefaultOn msg =
    alwaysStopPropagation msg


onKeyDown : (Int -> Bool -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (D.map2 tagger keyCode isComposing)


isComposing : D.Decoder Bool
isComposing =
    D.field "isComposing" D.bool


onDrop : (List File -> msg) -> Attribute msg
onDrop msg =
    preventDefaultOn "drop" (D.map alwaysPreventDefaultOn (D.map msg filesDecoder))


filesDecoder : D.Decoder (List File)
filesDecoder =
    D.field "dataTransfer" (D.field "files" (D.list File.decoder))

module Events exposing (keyBackspace, keyEnter, onClickStopPropagation, onDblclickstoppropagation, onDrop, onKeyDown, onMouseDown, onMouseMove, onMouseUp, onTouchStart, onWheel, touchCoordinates)

import File exposing (File)
import Html exposing (Attribute)
import Html.Events exposing (keyCode, on, preventDefaultOn, stopPropagationOn)
import Html.Events.Extra.Mouse as Mouse
import Html.Events.Extra.Touch as Touch
import Html.Events.Extra.Wheel as Wheel
import Json.Decode as D


type alias KeyCode =
    Int


keyEnter : KeyCode
keyEnter =
    13


keyBackspace : KeyCode
keyBackspace =
    8


onMouseDown : (Mouse.Event -> msg) -> Html.Attribute msg
onMouseDown =
    { stopPropagation = True, preventDefault = False }
        |> Mouse.onWithOptions "mousedown"


onMouseMove : (Mouse.Event -> msg) -> Html.Attribute msg
onMouseMove =
    { stopPropagation = True, preventDefault = False }
        |> Mouse.onWithOptions "mousemove"


onMouseUp : (Mouse.Event -> msg) -> Html.Attribute msg
onMouseUp =
    { stopPropagation = True, preventDefault = False }
        |> Mouse.onWithOptions "mouseup"


onTouchStart : (Touch.Event -> msg) -> Html.Attribute msg
onTouchStart =
    { stopPropagation = True, preventDefault = False }
        |> Touch.onWithOptions "touchstart"


onClickStopPropagation : msg -> Html.Attribute msg
onClickStopPropagation msg =
    stopPropagationOn "click" (D.map alwaysStopPropagation (D.succeed msg))


onDblclickstoppropagation : msg -> Html.Attribute msg
onDblclickstoppropagation msg =
    stopPropagationOn "dblclick" (D.map alwaysStopPropagation (D.succeed msg))


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


touchCoordinates : Touch.Event -> ( Float, Float )
touchCoordinates touchEvent =
    List.head touchEvent.changedTouches
        |> Maybe.map .clientPos
        |> Maybe.withDefault ( 0, 0 )


onWheel : (Wheel.Event -> msg) -> Html.Attribute msg
onWheel =
    { stopPropagation = True, preventDefault = False }
        |> Wheel.onWithOptions

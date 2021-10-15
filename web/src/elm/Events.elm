module Events exposing (onChange, onClickStopPropagation, onDrop, onEnter, onMouseDown, onMouseMove, onMouseUp, onTouchStart, onWheel, touchCoordinates)

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


onMouseDown : (Mouse.Event -> msg) -> Html.Attribute msg
onMouseDown =
    { stopPropagation = True, preventDefault = True }
        |> Mouse.onWithOptions "mousedown"


onMouseMove : (Mouse.Event -> msg) -> Html.Attribute msg
onMouseMove =
    { stopPropagation = True, preventDefault = True }
        |> Mouse.onWithOptions "mousemove"


onMouseUp : (Mouse.Event -> msg) -> Html.Attribute msg
onMouseUp =
    { stopPropagation = True, preventDefault = True }
        |> Mouse.onWithOptions "mouseup"


onTouchStart : (Touch.Event -> msg) -> Html.Attribute msg
onTouchStart =
    { stopPropagation = True, preventDefault = False }
        |> Touch.onWithOptions "touchstart"


onClickStopPropagation : msg -> Html.Attribute msg
onClickStopPropagation msg =
    stopPropagationOn "click" (D.map alwaysStopPropagation (D.succeed msg))


alwaysStopPropagation : msg -> ( msg, Bool )
alwaysStopPropagation msg =
    ( msg, True )


alwaysPreventDefaultOn : msg -> ( msg, Bool )
alwaysPreventDefaultOn msg =
    alwaysStopPropagation msg


onEnter : msg -> Attribute msg
onEnter msg =
    onKeyCodeDown keyEnter msg


onKeyCodeDown : Int -> msg -> Attribute msg
onKeyCodeDown code msg =
    let
        input inputCode currentComposing =
            if inputCode == code && not currentComposing then
                D.succeed msg

            else
                D.fail "other key"
    in
    on "keydown"
        (D.andThen
            (\k ->
                D.andThen
                    (\c ->
                        input k c
                    )
                    isComposing
            )
            keyCode
        )


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


onChange : (String -> msg) -> Attribute msg
onChange handler =
    on "change" <| D.map handler <| D.at [ "target", "value" ] D.string

module Events exposing
    ( onChange
    , onChangeStyled
    , onClickPreventDefaultOn
    , onClickStopPropagation
    , onDrop
    , onEnter
    , onMouseDown
    , onMouseMove
    , onMouseUp
    , onTouchStart
    , onWheel
    , touchCoordinates
    )

import File exposing (File)
import Html.Events.Extra.Mouse as Mouse
import Html.Events.Extra.Touch as Touch
import Html.Events.Extra.Wheel as Wheel
import Html.Styled exposing (Attribute)
import Html.Styled.Attributes as Attr
import Html.Styled.Events as StyledEvents
import Json.Decode as D


type alias KeyCode =
    Int


keyEnter : KeyCode
keyEnter =
    13


onMouseDown : (Mouse.Event -> msg) -> Attribute msg
onMouseDown =
    \m ->
        Mouse.onWithOptions "mousedown" { stopPropagation = True, preventDefault = True } m
            |> Attr.fromUnstyled


onMouseMove : (Mouse.Event -> msg) -> Attribute msg
onMouseMove =
    \m ->
        Mouse.onWithOptions "mousemove" { stopPropagation = True, preventDefault = True } m
            |> Attr.fromUnstyled


onMouseUp : (Mouse.Event -> msg) -> Attribute msg
onMouseUp =
    \m ->
        Mouse.onWithOptions "mouseup" { stopPropagation = True, preventDefault = True } m
            |> Attr.fromUnstyled


onTouchStart : (Touch.Event -> msg) -> Attribute msg
onTouchStart =
    \m ->
        Touch.onWithOptions "touchstart" { stopPropagation = True, preventDefault = False } m
            |> Attr.fromUnstyled


onClickStopPropagation : msg -> Attribute msg
onClickStopPropagation msg =
    StyledEvents.stopPropagationOn "click" (D.map alwaysStopPropagationStyled (D.succeed msg))


onClickPreventDefaultOn : msg -> Attribute msg
onClickPreventDefaultOn msg =
    StyledEvents.preventDefaultOn "click" (D.map alwaysPreventDefaultOnStyled (D.succeed msg))


alwaysStopPropagation : msg -> ( msg, Bool )
alwaysStopPropagation msg =
    ( msg, True )


alwaysStopPropagationStyled : msg -> ( msg, Bool )
alwaysStopPropagationStyled msg =
    ( msg, True )


alwaysPreventDefaultOn : msg -> ( msg, Bool )
alwaysPreventDefaultOn msg =
    alwaysStopPropagation msg


alwaysPreventDefaultOnStyled : msg -> ( msg, Bool )
alwaysPreventDefaultOnStyled msg =
    alwaysStopPropagationStyled msg


onEnter : msg -> Attribute msg
onEnter msg =
    onKeyCodeDown keyEnter msg


onKeyCodeDown : Int -> msg -> Attribute msg
onKeyCodeDown code msg =
    let
        input : Int -> Bool -> D.Decoder msg
        input inputCode currentComposing =
            if inputCode == code && not currentComposing then
                D.succeed msg

            else
                D.fail "other key"
    in
    StyledEvents.on "keydown"
        (D.andThen
            (\k ->
                D.andThen
                    (\c ->
                        input k c
                    )
                    isComposing
            )
            StyledEvents.keyCode
        )


isComposing : D.Decoder Bool
isComposing =
    D.field "isComposing" D.bool


onDrop : (List File -> msg) -> Attribute msg
onDrop msg =
    StyledEvents.preventDefaultOn "drop" (D.map alwaysPreventDefaultOn (D.map msg filesDecoder))


filesDecoder : D.Decoder (List File)
filesDecoder =
    D.field "dataTransfer" (D.field "files" (D.list File.decoder))


touchCoordinates : Touch.Event -> ( Float, Float )
touchCoordinates touchEvent =
    List.head touchEvent.changedTouches
        |> Maybe.map .clientPos
        |> Maybe.withDefault ( 0, 0 )


onWheel : (Wheel.Event -> msg) -> Attribute msg
onWheel =
    \m ->
        Wheel.onWithOptions { stopPropagation = True, preventDefault = False } m
            |> Attr.fromUnstyled


onChange : (String -> msg) -> Attribute msg
onChange handler =
    StyledEvents.on "change" <| D.map handler <| D.at [ "target", "value" ] D.string


onChangeStyled : (String -> msg) -> Attribute msg
onChangeStyled handler =
    StyledEvents.on "change" <| D.map handler <| D.at [ "target", "value" ] D.string

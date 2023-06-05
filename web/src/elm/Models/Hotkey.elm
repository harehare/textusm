module Models.Hotkey exposing
    ( Hotkey
    , Hotkeys
    , decoder
    , keyDown
    , open
    , save
    , select
    , toMacString
    , toWindowsString
    )

import Bool.Extra as BoolEx
import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import List.Extra as ListEx


type alias Hotkey =
    { ctrl : Bool, shift : Bool, alt : Bool, key : String }


type alias Hotkeys msg =
    List
        { key : Hotkey
        , msg : msg
        }


save : Hotkey
save =
    { ctrl = True, shift = False, alt = False, key = "S" }


open : Hotkey
open =
    { ctrl = True, shift = False, alt = False, key = "O" }


select : Hotkey
select =
    { ctrl = True, shift = False, alt = False, key = "E" }


toMacString : Hotkey -> String
toMacString h =
    [ BoolEx.toMaybe "Cmd" h.ctrl
    , BoolEx.toMaybe "Alt" h.alt
    , BoolEx.toMaybe "Shift" h.shift
    , Just h.key
    ]
        |> List.filterMap identity
        |> String.join " + "


toWindowsString : Hotkey -> String
toWindowsString h =
    [ BoolEx.toMaybe "Ctrl" h.ctrl
    , BoolEx.toMaybe "Alt" h.alt
    , BoolEx.toMaybe "Shift" h.shift
    , Just h.key
    ]
        |> List.filterMap identity
        |> String.join " + "


keyDown : Hotkey -> Hotkeys msg -> Maybe (D.Decoder msg)
keyDown pressedKey hotkeys =
    BoolEx.ifElse
        (ListEx.find
            (\{ key } ->
                key.ctrl
                    == pressedKey.ctrl
                    && key.shift
                    == pressedKey.shift
                    && key.alt
                    == pressedKey.alt
                    && key.key
                    == pressedKey.key
            )
            hotkeys
            |> Maybe.map (\{ msg } -> D.succeed msg)
        )
        Nothing
        (pressedKey.ctrl || pressedKey.shift || pressedKey.alt)


decoder : D.Decoder Hotkey
decoder =
    D.succeed Hotkey
        |> required "ctrlKey" D.bool
        |> required "shiftKey" D.bool
        |> required "altKey" D.bool
        |> required "key" D.string

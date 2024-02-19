module Types.Hotkey exposing
    ( Hotkey(..)
    , HotkeyValue
    , Hotkeys
    , decoder
    , fromString
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


type alias HotkeyValue =
    { ctrl : Bool, shift : Bool, alt : Bool, key : String }


type Hotkey
    = Save HotkeyValue
    | Open HotkeyValue
    | Find HotkeyValue
    | Select HotkeyValue


type alias Hotkeys msg =
    List
        { key : Hotkey
        , msg : msg
        }


save : Hotkey
save =
    Save { ctrl = True, shift = False, alt = False, key = "S" }


open : Hotkey
open =
    Open { ctrl = True, shift = False, alt = False, key = "O" }


select : Hotkey
select =
    Open { ctrl = True, shift = False, alt = False, key = "E" }


find : Hotkey
find =
    Open { ctrl = True, shift = False, alt = False, key = "F" }


eq : HotkeyValue -> HotkeyValue -> Bool
eq value1 value2 =
    value1.alt == value2.alt && value1.ctrl == value2.ctrl && value1.shift == value2.shift && value1.key == value2.key


unwrap : Hotkey -> HotkeyValue
unwrap hotkey =
    case hotkey of
        Save v ->
            v

        Open v ->
            v

        Select v ->
            v

        Find v ->
            v


toMacString : Hotkey -> String
toMacString h =
    let
        hotkey : HotkeyValue
        hotkey =
            unwrap h
    in
    [ BoolEx.toMaybe "Cmd" hotkey.ctrl
    , BoolEx.toMaybe "Alt" hotkey.alt
    , BoolEx.toMaybe "Shift" hotkey.shift
    , Just hotkey.key
    ]
        |> List.filterMap identity
        |> String.join " + "


toWindowsString : Hotkey -> String
toWindowsString h =
    let
        hotkey : HotkeyValue
        hotkey =
            unwrap h
    in
    [ BoolEx.toMaybe "Ctrl" hotkey.ctrl
    , BoolEx.toMaybe "Alt" hotkey.alt
    , BoolEx.toMaybe "Shift" hotkey.shift
    , Just hotkey.key
    ]
        |> List.filterMap identity
        |> String.join " + "


keyDown : Hotkey -> Hotkeys msg -> Maybe (D.Decoder msg)
keyDown pressedKey hotkeys =
    let
        pressed : HotkeyValue
        pressed =
            unwrap pressedKey
    in
    BoolEx.ifElse
        (ListEx.find
            (\hotkey ->
                let
                    key : HotkeyValue
                    key =
                        unwrap hotkey.key
                in
                key.ctrl
                    == pressed.ctrl
                    && key.shift
                    == pressed.shift
                    && key.alt
                    == pressed.alt
                    && key.key
                    == pressed.key
            )
            hotkeys
            |> Maybe.map (\{ msg } -> D.succeed msg)
        )
        Nothing
        (pressed.ctrl || pressed.shift || pressed.alt)


decoder : D.Decoder Hotkey
decoder =
    (D.succeed HotkeyValue
        |> required "ctrlKey" D.bool
        |> required "shiftKey" D.bool
        |> required "altKey" D.bool
        |> required "key" D.string
    )
        |> D.andThen
            (\hotkey ->
                if eq hotkey (unwrap save) then
                    D.succeed <| Save hotkey

                else if eq hotkey (unwrap open) then
                    D.succeed <| Open hotkey

                else if eq hotkey (unwrap find) then
                    D.succeed <| Find hotkey

                else if eq hotkey (unwrap select) then
                    D.succeed <| Select hotkey

                else
                    D.fail "other key"
            )


fromString : String -> Maybe Hotkey
fromString cmd =
    case cmd of
        "open" ->
            Just open

        "save" ->
            Just save

        "find" ->
            Just find

        "select" ->
            Just select

        _ ->
            Nothing

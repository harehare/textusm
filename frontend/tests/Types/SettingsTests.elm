module Types.SettingsTests exposing (suite)

import Expect
import Json.Decode as D
import Json.Encode as E
import Test exposing (Test, describe, fuzz)
import Types.Fuzzer exposing (settingsFuzzer)
import Types.Settings as Settings


suite : Test
suite =
    describe "Settings test"
        [ fuzz settingsFuzzer "Settings decode/legacyEncode test" <|
            \s ->
                E.encode 0 (Settings.legacyEncoder s)
                    |> D.decodeString Settings.decoder
                    |> Expect.equal (Ok s)
        , fuzz settingsFuzzer "Settings decode/encode test" <|
            \s ->
                E.encode 0 (Settings.encoder s)
                    |> D.decodeString Settings.decoder
                    |> Expect.equal (Ok s)
        ]

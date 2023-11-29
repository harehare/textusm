module Models.SettingsTests exposing (suite)

import Expect
import Json.Decode as D
import Json.Encode as E
import Models.Fuzzer exposing (settingsFuzzer)
import Models.Settings as Settings
import Test exposing (Test, describe, fuzz)


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

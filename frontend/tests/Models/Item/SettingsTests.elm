module Models.Item.SettingsTests exposing (suite)

import Expect
import Json.Decode as D
import Models.Fuzzer exposing (itemSettingsFuzzer)
import Models.Item.Settings as ItemSettings
import Test exposing (Test, fuzz)


suite : Test
suite =
    fuzz itemSettingsFuzzer "ItemSettings decode/encode test" <|
        \i ->
            ItemSettings.toString i
                |> D.decodeString ItemSettings.decoder
                |> Expect.equal (Ok i)

module Types.Item.SettingsTests exposing (suite)

import Expect
import Json.Decode as D
import Test exposing (Test, fuzz)
import Types.Fuzzer exposing (itemSettingsFuzzer)
import Types.Item.Settings as ItemSettings


suite : Test
suite =
    fuzz itemSettingsFuzzer "ItemSettings decode/encode test" <|
        \i ->
            ItemSettings.toString i
                |> D.decodeString ItemSettings.decoder
                |> Expect.equal (Ok i)

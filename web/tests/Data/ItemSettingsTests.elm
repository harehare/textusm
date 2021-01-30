module Data.ItemSettingsTests exposing (suite)

import Data.Fuzzer exposing (itemSettingsFuzzer)
import Data.ItemSettings as ItemSettings
import Expect
import Json.Decode as D
import Test exposing (Test, fuzz)


suite : Test
suite =
    fuzz itemSettingsFuzzer "ItemSettings decode/encode test" <|
        \i ->
            ItemSettings.toString i
                |> D.decodeString ItemSettings.decoder
                |> Expect.equal (Ok i)

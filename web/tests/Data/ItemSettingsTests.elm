module Data.ItemSettingsTests exposing (suite)

import Data.Color exposing (Color)
import Data.FontSize as FontSize exposing (FontSize)
import Data.Fuzzer exposing (colorFuzzer, fontSizeFuzzer, itemSettingsFuzzer, positionFuzzer)
import Data.ItemSettings as ItemSettings exposing (ItemSettings)
import Data.Position exposing (Position)
import Expect
import Fuzz exposing (Fuzzer)
import Json.Decode as D
import Json.Encode as E
import Test exposing (Test, describe, fuzz, test)


suite : Test
suite =
    fuzz itemSettingsFuzzer "ItemSettings decode/encode test" <|
        \i ->
            ItemSettings.toString i
                |> D.decodeString ItemSettings.decoder
                |> Expect.equal (Ok i)

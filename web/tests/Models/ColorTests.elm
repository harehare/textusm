module Models.ColorTests exposing (..)

import Expect
import Models.Color as Color
import Models.Fuzzer exposing (colorFuzzer)
import Test exposing (Test, fuzz)


suite : Test
suite =
    fuzz colorFuzzer "Color fromString/toString test" <|
        \i ->
            Color.toString i
                |> Color.fromString
                |> Expect.equal i

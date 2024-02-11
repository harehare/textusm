module Types.ColorTests exposing (suite)

import Expect
import Test exposing (Test, fuzz)
import Types.Color as Color
import Types.Fuzzer exposing (colorFuzzer)


suite : Test
suite =
    fuzz colorFuzzer "Color fromString/toString test" <|
        \i ->
            Color.toString i
                |> Color.fromString
                |> Expect.equal i

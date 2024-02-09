module Models.Diagram.ScaleTests exposing (suite)

import Diagram.Scale as Scale
import Expect
import Fuzz
import Test exposing (Test, fuzz)


suite : Test
suite =
    fuzz Fuzz.float "Scale  test" <|
        \s ->
            Expect.within
                (Expect.Absolute 0.01)
                (Scale.fromFloat s
                    |> Scale.toFloat
                )
                (if isInfinite s then
                    Scale.default |> Scale.toFloat

                 else if isNaN s then
                    Scale.default |> Scale.toFloat

                 else if s <= Scale.toFloat Scale.min then
                    Scale.min |> Scale.toFloat

                 else if Scale.toFloat Scale.max <= s then
                    Scale.max |> Scale.toFloat

                 else
                    s
                )

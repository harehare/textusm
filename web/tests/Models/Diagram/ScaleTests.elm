module Models.Diagram.ScaleTests exposing (..)

import Expect
import Fuzz
import Models.Diagram.Scale as Scale
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
                    1.0

                 else if isNaN s then
                    1.0

                 else if s <= 0.03 then
                    0.03

                 else if 10.0 <= s then
                    10.0

                 else
                    s
                )

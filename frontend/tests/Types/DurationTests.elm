module Types.DurationTests exposing (suite)

import Expect
import Fuzz
import Test exposing (Test, fuzz)
import Types.Duration as Duration


suite : Test
suite =
    fuzz Fuzz.int "Duration seconds/toInt test" <|
        \i ->
            Duration.seconds i
                |> Duration.toInt
                |> Expect.equal
                    (if i < 0 then
                        0

                     else
                        i
                    )

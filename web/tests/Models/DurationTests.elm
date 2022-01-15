module Models.DurationTests exposing (..)

import Expect
import Fuzz as Fuzz
import Models.Duration as Duration
import Test exposing (Test, fuzz)


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

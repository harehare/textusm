module Models.Diagram.CardSizeTests exposing (suite)

import Diagram.CardSize as CardSize
import Expect
import Fuzz
import Test exposing (Test, fuzz)


suite : Test
suite =
    fuzz Fuzz.int "CardSize test" <|
        \s ->
            Expect.equal
                (CardSize.fromInt s
                    |> CardSize.toInt
                )
                (if CardSize.max < s then
                    CardSize.max

                 else if s < CardSize.min then
                    CardSize.min

                 else
                    s
                )

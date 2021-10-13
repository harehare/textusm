module Models.DiagramTypeTests exposing (suite)

import Expect
import Models.DiagramType exposing (fromString, toString)
import Models.Fuzzer exposing (diagramTypeFuzzer)
import Test exposing (Test, describe, fuzz)


suite : Test
suite =
    describe "DiagramType test"
        [ fuzz diagramTypeFuzzer "toString test" <|
            \d ->
                toString d
                    |> fromString
                    |> Expect.equal d
        ]

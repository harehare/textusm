module Models.DiagramTypeTests exposing (suite)

import Diagram.Type exposing (fromString, toString)
import Expect
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

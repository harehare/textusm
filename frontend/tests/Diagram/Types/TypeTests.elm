module Diagram.Types.TypeTests exposing (suite)

import Diagram.Types.Type exposing (fromString, toString)
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

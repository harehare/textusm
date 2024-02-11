module Diagram.Types.TypeTests exposing (suite)

import Diagram.Types.Type exposing (fromString, toString)
import Expect
import Test exposing (Test, describe, fuzz)
import Types.Fuzzer exposing (diagramTypeFuzzer)


suite : Test
suite =
    describe "DiagramType test"
        [ fuzz diagramTypeFuzzer "toString test" <|
            \d ->
                toString d
                    |> fromString
                    |> Expect.equal d
        ]

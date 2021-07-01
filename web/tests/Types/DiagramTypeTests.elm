module Types.DiagramTypeTests exposing (suite)

import Expect
import Graphql.Enum.Diagram exposing (Diagram(..))
import Test exposing (Test, describe, fuzz)
import Types.DiagramType exposing (fromString, toString)
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

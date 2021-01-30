module Data.DiagramTypeTests exposing (suite)

import Data.DiagramType exposing (fromString, toString)
import Data.Fuzzer exposing (diagramTypeFuzzer)
import Expect
import Test exposing (Test, describe, fuzz)
import TextUSM.Enum.Diagram exposing (Diagram(..))


suite : Test
suite =
    describe "DiagramType test"
        [ fuzz diagramTypeFuzzer "toString test" <|
            \d ->
                toString d
                    |> fromString
                    |> Expect.equal d
        ]

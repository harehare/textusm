module Data.DiagramItemTests exposing (suite)

import Data.DiagramItem as DiagramItem
import Data.Fuzzer exposing (diagramItemFuzzer)
import Expect
import Fuzz exposing (Fuzzer)
import Json.Decode as D
import Json.Encode as E
import Test exposing (Test, describe, fuzz, test)


suite : Test
suite =
    fuzz diagramItemFuzzer "DiagramItem  decode/encode test" <|
        \i ->
            E.encode 0 (DiagramItem.encoder i)
                |> D.decodeString DiagramItem.decoder
                |> Expect.equal (Ok i)

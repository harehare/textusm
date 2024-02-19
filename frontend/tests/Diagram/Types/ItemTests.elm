module Diagram.Types.ItemTests exposing (suite)

import Diagram.Types.Item as DiagramItem
import Expect
import Json.Decode as D
import Json.Encode as E
import Test exposing (Test, fuzz)
import Types.Fuzzer exposing (diagramItemFuzzer)


suite : Test
suite =
    fuzz diagramItemFuzzer "DiagramItem  decode/encode test" <|
        \i ->
            E.encode 0 (DiagramItem.encoder i)
                |> D.decodeString DiagramItem.decoder
                |> Expect.equal (Ok i)

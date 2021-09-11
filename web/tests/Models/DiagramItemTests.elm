module Models.DiagramItemTests exposing (suite)

import Expect
import Json.Decode as D
import Json.Encode as E
import Models.DiagramItem as DiagramItem
import Models.Fuzzer exposing (diagramItemFuzzer)
import Test exposing (Test, fuzz)


suite : Test
suite =
    fuzz diagramItemFuzzer "DiagramItem  decode/encode test" <|
        \i ->
            E.encode 0 (DiagramItem.encoder i)
                |> D.decodeString DiagramItem.decoder
                |> Expect.equal (Ok i)

module Data.ShareIdTests exposing (..)

import Data.ShareId as ShareId
import Expect
import Maybe.Extra as MaybeEx
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "ShareId test"
        [ describe "fromString test"
            [ test "ShareId should be alphanumeric character" <|
                \() ->
                    Expect.equal
                        (ShareId.fromString "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
                            |> Maybe.map ShareId.toString
                            |> Maybe.withDefault ""
                        )
                        "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
            , test "Invalid ShareId should be Nothing" <|
                \() ->
                    Expect.true "ShareId is Nothing"
                        (MaybeEx.isNothing <| ShareId.fromString "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a0")
            ]
        ]

module Data.ShareIdTests exposing (..)

import Data.ShareToken as ShareToken
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
                        (ShareToken.fromString "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1MTYyMzkwMjIsInBhcyI6ZmFsc2UsImp0aSI6InRlc3QifQ.IcBz1eTRDCXzq_ZAxLZBu5ECieUTUKPyGWQu6SjGZIc"
                            |> Maybe.map ShareToken.toString
                            |> Maybe.withDefault ""
                        )
                        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1MTYyMzkwMjIsInBhcyI6ZmFsc2UsImp0aSI6InRlc3QifQ.IcBz1eTRDCXzq_ZAxLZBu5ECieUTUKPyGWQu6SjGZIc"
            , test "Invalid ShareId should be Nothing" <|
                \() ->
                    Expect.true "ShareId is Nothing"
                        (MaybeEx.isNothing <| ShareToken.fromString "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a0")
            ]
        ]

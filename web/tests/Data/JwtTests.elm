module Data.JwtTests exposing (suite)

import Data.Jwt as Jwt
import Expect
import Maybe.Extra as MaybeEx
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Jwt test"
        [ test "Jwt shoud be three commas in the string" <|
            \() ->
                Expect.true "" <| MaybeEx.isJust (Jwt.fromString "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1MTYyMzkwMjIsInBhcyI6ZmFsc2UsImp0aSI6InRlc3QifQ.IcBz1eTRDCXzq_ZAxLZBu5ECieUTUKPyGWQu6SjGZIc")
        , test "Error if not three commas in jwt" <|
            \() ->
                Expect.true "" <| MaybeEx.isNothing (Jwt.fromString "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1MTYyMzkwMjIsInBhcyI6ZmFsc2UsImp0aSI6InRlc3QifQ.IcBz1eTRDCXzq_ZAxLZBu5ECieUTUKPyGWQu6SjGZIc")
        ]

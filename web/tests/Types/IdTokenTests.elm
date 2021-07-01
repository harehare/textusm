module Types.IdTokenTests exposing (..)

import Expect
import Test exposing (Test, describe, test)
import Types.IdToken as IdToken


suite : Test
suite =
    describe "IdToken test"
        [ describe "fromString test"
            [ test "bearer test" <|
                \() ->
                    Expect.equal (IdToken.fromString "test" |> IdToken.unwrap) "Bearer test"
            ]
        ]

module Models.IdTokenTests exposing (suite)

import Expect
import Models.IdToken as IdToken
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "IdToken test"
        [ describe "fromString test"
            [ test "bearer test" <|
                \() ->
                    Expect.equal (IdToken.fromString "test" |> IdToken.unwrap) "Bearer test"
            ]
        ]

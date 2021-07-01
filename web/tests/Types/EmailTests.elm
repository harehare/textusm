module Types.EmailTests exposing (..)

import Expect
import Test exposing (Test, describe, test)
import Types.Email as Email


suite : Test
suite =
    describe "Email test"
        [ describe "fromString test"
            [ test "valid Email" <|
                \() ->
                    Expect.equal (Email.fromString "textusm@textusm.com" |> Maybe.withDefault Email.empty |> Email.toString) "textusm@textusm.com"
            , test "invalid Email" <|
                \() ->
                    Expect.equal (Email.fromString "test@test" |> Maybe.withDefault Email.empty |> Email.toString) ""
            ]
        ]

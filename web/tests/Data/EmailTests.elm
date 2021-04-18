module Data.EmailTests exposing (..)

import Data.Email as Email
import Expect
import Test exposing (Test, describe, test)


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

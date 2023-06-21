module Models.TextTests exposing (suite)

import Expect
import Models.Text as Text
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Text test"
        [ describe "isEmpty test"
            [ test "empty" <|
                \() ->
                    Expect.equal (Text.isEmpty Text.empty) True
            , test "not empty" <|
                \() ->
                    Expect.equal (Text.isEmpty (Text.edit Text.empty "test")) False
            ]
        , describe "isChanged test"
            [ test "changed" <|
                \() ->
                    Expect.equal (Text.isChanged (Text.edit Text.empty "test")) True
            , test "not changed" <|
                \() ->
                    Expect.equal (Text.isChanged (Text.edit Text.empty "")) False
            ]
        ]

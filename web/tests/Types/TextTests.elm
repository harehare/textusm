module Types.TextTests exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Types.Text as Text


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

module MessageTests exposing (suite)

import Expect
import Message
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Message test"
        [ describe "fromString test"
            [ test "ja" <|
                \() ->
                    Expect.equal (Message.langFromString "ja") Message.Ja
            , test "en" <|
                \() ->
                    Expect.equal (Message.langFromString "en") Message.En
            , test "de" <|
                \() ->
                    Expect.equal (Message.langFromString "de") Message.En
            ]
        ]

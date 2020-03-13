module TestParser exposing (parserTest)

import Expect
import Models.Diagram exposing (..)
import Parser exposing (..)
import Test exposing (..)


parserTest : Test
parserTest =
    describe "parser test"
        [ test "0 indent" <|
            \() ->
                parse 0 "test\ntest"
                    |> Expect.equal
                        ( [ "test" ], [ "test" ] )
        , test "0 indent and 1 indent" <|
            \() ->
                parse 0 "test1\n    test2\ntest3\n    test4"
                    |> Expect.equal
                        ( [ "test1", "    test2" ], [ "test3", "    test4" ] )
        , test "1 indent" <|
            \() ->
                parse 1 "test\n    test2\n    test3"
                    |> Expect.equal
                        ( [ "test" ], [ "    test2", "    test3" ] )
        , test "2 indent" <|
            \() ->
                parse 2 "    test\n        test2\n        test3"
                    |> Expect.equal
                        ( [ "    test" ], [ "        test2", "        test3" ] )
        ]

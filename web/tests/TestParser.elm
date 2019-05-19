module TestParser exposing (parserTest)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Models.Figure exposing (..)
import Parser exposing (..)
import Test exposing (..)


parserTest : Test
parserTest =
    describe "parser test"
        [ test "0 indent" <|
            \() ->
                parseLines 0 "test\ntest"
                    |> Expect.equal
                        (Ok
                            ( [ "test" ], [ "test" ] )
                        )
        , test "0 indent and 1 indent" <|
            \() ->
                parseLines 0 "test1\n    test2\ntest3\n    test4"
                    |> Expect.equal
                        (Ok
                            ( [ "test1", "    test2" ], [ "test3", "    test4" ] )
                        )
        , test "1 indent" <|
            \() ->
                parseLines 1 "test\n    test2\n    test3"
                    |> Expect.equal
                        (Ok
                            ( [ "test" ], [ "    test2", "    test3" ] )
                        )
        , test "2 indent" <|
            \() ->
                parseLines 2 "    test\n        test2\n        test3"
                    |> Expect.equal
                        (Ok
                            ( [ "    test" ], [ "        test2", "        test3" ] )
                        )
        ]

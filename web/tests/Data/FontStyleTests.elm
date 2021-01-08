module Data.FontStyleTests exposing (suite)

import Data.FontStyle as FontStyle
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "FontStyle test"
        [ describe "apply test"
            [ test "bold test" <|
                \() ->
                    Expect.equal (FontStyle.apply FontStyle.Bold "test") "md:**test**"
            , test "italic test" <|
                \() ->
                    Expect.equal (FontStyle.apply FontStyle.Italic "test") "md:*test*"
            , test "strikethrough test" <|
                \() ->
                    Expect.equal (FontStyle.apply FontStyle.Strikethrough "test") "md:~~test~~"
            ]
        ]

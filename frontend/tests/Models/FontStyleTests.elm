module Models.FontStyleTests exposing (suite)

import Expect
import Models.FontStyle as FontStyle
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

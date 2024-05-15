module Types.FontStyleTests exposing (suite)

import Constants
import Expect
import Test exposing (Test, describe, test)
import Types.FontStyle as FontStyle


suite : Test
suite =
    describe "FontStyle test"
        [ describe "apply test"
            [ test "bold test" <|
                \() ->
                    Expect.equal (FontStyle.apply FontStyle.Bold "test") (Constants.markdownPrefix ++ "**test**")
            , test "italic test" <|
                \() ->
                    Expect.equal (FontStyle.apply FontStyle.Italic "test") (Constants.markdownPrefix ++ "*test*")
            , test "strikethrough test" <|
                \() ->
                    Expect.equal (FontStyle.apply FontStyle.Strikethrough "test") (Constants.markdownPrefix ++ "~~test~~")
            ]
        ]

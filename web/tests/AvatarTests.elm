module AvatarTests exposing (..)

import Avatar
import Expect
import MD5
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Avatar test"
        [ describe "toString test"
            [ test "url and imageurl test" <|
                \() ->
                    Expect.equal (Avatar.toString (Avatar.Avatar (Just "mail") (Just "url"))) "https://www.gravatar.com/avatar/b83a886a5c437ccd9ac15473fd6f1788?d=url&s=40"
            , test "url test" <|
                \() ->
                    Expect.equal (Avatar.toString (Avatar.Avatar Nothing (Just "url"))) "url"
            , test "empty test" <|
                \() ->
                    Expect.equal (Avatar.toString (Avatar.Avatar Nothing Nothing)) ""
            ]
        ]

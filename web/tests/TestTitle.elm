module TestTitle exposing (all)

import Data.Title as Title
import Expect
import Test exposing (Test, describe, test)


all : Test
all =
    describe "Title test"
        [ describe "isUntitled test"
            [ test "untitled" <|
                \() ->
                    Expect.equal (Title.isUntitled (Title.fromString "")) True
            , test "not untitled" <|
                \() ->
                    Expect.equal (Title.isUntitled (Title.fromString "test")) False
            ]
        , describe "isView test"
            [ test "view" <|
                \() ->
                    Expect.equal (Title.isView (Title.view Title.untitled)) True
            , test "not view" <|
                \() ->
                    Expect.equal (Title.isView (Title.edit Title.untitled)) False
            ]
        , describe "isEdit test"
            [ test "edit" <|
                \() ->
                    Expect.equal (Title.isEdit (Title.edit Title.untitled)) True
            , test "not view" <|
                \() ->
                    Expect.equal (Title.isEdit (Title.view Title.untitled)) False
            ]
        ]

module Models.Item.ValueTests exposing (suite)

import Expect
import Models.Item.Value as ItemValue
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "ItemValue test"
        [ fromString, toFullString, toString, update ]


fromString : Test
fromString =
    describe "fromString test"
        [ test "plain text" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "plain text"
                        |> (\v -> ( ItemValue.getIndent v, ItemValue.toString v ))
                    )
                    ( 0, "plain text" )
        , test "has indent" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "        plain text"
                        |> (\v -> ( ItemValue.getIndent v, ItemValue.toString v ))
                    )
                    ( 2, "plain text" )
        , test "markdown" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "    md: **markdown**"
                        |> (\v -> ( ItemValue.getIndent v, ItemValue.toString v ))
                    )
                    ( 1, " **markdown**" )
        , test "image" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "    image:image"
                        |> (\v -> ( ItemValue.getIndent v, ItemValue.toString v ))
                    )
                    ( 1, "image" )
        , test "image data" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "    data:image/image"
                        |> (\v -> ( ItemValue.getIndent v, ItemValue.toString v ))
                    )
                    ( 1, "image" )
        , test "comment" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "    # comment"
                        |> (\v -> ( ItemValue.getIndent v, ItemValue.toString v ))
                    )
                    ( 1, " comment" )
        ]


update : Test
update =
    describe "Update test"
        [ test "plain text" <|
            \() ->
                Expect.equal
                    (ItemValue.update (ItemValue.fromString "plain text") "update text"
                        |> (\v -> ( ItemValue.getIndent v, ItemValue.toString v ))
                    )
                    ( 0, "update text" )
        , test "has indent" <|
            \() ->
                Expect.equal
                    (ItemValue.update (ItemValue.fromString "        plain text") "update text"
                        |> (\v -> ( ItemValue.getIndent v, ItemValue.toString v ))
                    )
                    ( 2, "update text" )
        , test "markdown" <|
            \() ->
                Expect.equal
                    (ItemValue.update (ItemValue.fromString "    md: **markdown**") "update **markdown**"
                        |> (\v -> ( ItemValue.getIndent v, ItemValue.toString v ))
                    )
                    ( 1, "update **markdown**" )
        , test "image" <|
            \() ->
                Expect.equal
                    (ItemValue.update (ItemValue.fromString "    image:image") "update image"
                        |> (\v -> ( ItemValue.getIndent v, ItemValue.toString v ))
                    )
                    ( 1, "update image" )
        , test "image data" <|
            \() ->
                Expect.equal
                    (ItemValue.update (ItemValue.fromString "    data:image/image") "update image"
                        |> (\v -> ( ItemValue.getIndent v, ItemValue.toString v ))
                    )
                    ( 1, "update image" )
        , test "comment" <|
            \() ->
                Expect.equal
                    (ItemValue.update (ItemValue.fromString "    # comment") "update comment"
                        |> (\v -> ( ItemValue.getIndent v, ItemValue.toString v ))
                    )
                    ( 1, "update comment" )
        ]


toFullString : Test
toFullString =
    describe "toFullString test"
        [ test "plain text" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "plain text"
                        |> ItemValue.toFullString
                    )
                    "plain text"
        , test "markdown" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "    md: **markdown**"
                        |> ItemValue.toFullString
                    )
                    "    md: **markdown**"
        , test "image" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "    image:image"
                        |> ItemValue.toFullString
                    )
                    "    image:image"
        , test "image data" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "    data:image/image"
                        |> ItemValue.toFullString
                    )
                    "    data:image/image"
        , test "comment" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "    # comment"
                        |> ItemValue.toFullString
                    )
                    "    # comment"
        ]


toString : Test
toString =
    describe "toString test"
        [ test "plain text" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "plain text"
                        |> ItemValue.toString
                    )
                    "plain text"
        , test "markdown" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "    md:**markdown**\\ntest"
                        |> ItemValue.toString
                    )
                    "**markdown**\ntest"
        , test "image" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "    image:image"
                        |> ItemValue.toString
                    )
                    "image"
        , test "image data" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "    data:image/image"
                        |> ItemValue.toString
                    )
                    "image"
        , test "comment" <|
            \() ->
                Expect.equal
                    (ItemValue.fromString "    # comment"
                        |> ItemValue.toString
                    )
                    " comment"
        ]

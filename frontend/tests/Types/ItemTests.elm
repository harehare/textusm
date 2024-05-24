module Types.ItemTests exposing (suite)

import Expect
import Test exposing (Test, describe, fuzz, test)
import Types.FontSize as FontSize
import Types.Fuzzer exposing (itemFuzzer)
import Types.Item as Item
import Types.Item.Settings as ItemSettings


suite : Test
suite =
    describe "Item test"
        [ getAt
        , head
        , tail
        , map
        , cons
        , indexedMap
        , length
        , isEmpty
        , unwrap
        , splitAt
        , getChildrenCount
        , getHierarchyCount
        , withText
        , fuzzer
        , mapWithRecursive
        , getTextOnly
        ]


getAt : Test
getAt =
    describe "getAt test"
        [ test "got the item at index 0" <|
            \() ->
                Expect.equal (Item.getAt 0 (Item.fromList [ Item.new ])) (Just Item.new)
        , test "got the item at index 1 return Nothing " <|
            \() ->
                Expect.equal (Item.getAt 1 (Item.fromList [ Item.new ])) Nothing
        ]


head : Test
head =
    describe "head test"
        [ test "got head item" <|
            \() ->
                Expect.equal (Item.head (Item.fromList [ Item.new ])) (Just Item.new)
        , test "got head item from items" <|
            \() ->
                Expect.equal
                    (Item.head
                        (Item.fromList [ Item.new ])
                    )
                    (Just Item.new)
        , test "got head item return Nothing" <|
            \() ->
                Expect.equal (Item.head (Item.fromList [])) Nothing
        ]


tail : Test
tail =
    describe "tail test"
        [ test "got tail item" <|
            \() ->
                Expect.equal (Item.tail (Item.fromList [ Item.new ])) (Just (Item.fromList []))
        , test "got tail item from items" <|
            \() ->
                Expect.equal
                    (Item.tail
                        (Item.fromList [ Item.new, Item.new ])
                    )
                    (Just (Item.fromList [ Item.new ]))
        , test "got tail item return Nothing" <|
            \() ->
                Expect.equal (Item.tail (Item.fromList [])) Nothing
        ]


map : Test
map =
    describe "map test"
        [ test "map item" <|
            \() ->
                Expect.equal (Item.map Item.getText (Item.fromList [ Item.new ])) [ "" ]
        ]


cons : Test
cons =
    describe "cons test"
        [ test "got 1 item" <|
            \() ->
                Expect.equal (Item.cons Item.new Item.empty) (Item.fromList [ Item.new ])
        , test "got 2 item" <|
            \() ->
                Expect.equal (Item.cons Item.new (Item.fromList [ Item.new ])) (Item.fromList [ Item.new, Item.new ])
        ]


indexedMap : Test
indexedMap =
    describe "indexedMap test"
        [ test "indexedMap item" <|
            \() ->
                Expect.equal
                    (Item.indexedMap (\i item -> ( i, Item.getText item ))
                        (Item.fromList [ Item.new, Item.new |> Item.withText "test" |> Item.withLineNo 1 ])
                    )
                    [ ( 0, "" ), ( 1, "test" ) ]
        ]


length : Test
length =
    describe "length test"
        [ test "got empty item" <|
            \() ->
                Expect.equal (Item.length Item.empty) 0
        , test "got 1 item" <|
            \() ->
                Expect.equal (Item.length <| Item.fromList [ Item.new ]) 1
        ]


isEmpty : Test
isEmpty =
    describe "isEmpty test"
        [ test "got empty item" <|
            \() ->
                Expect.equal (Item.isEmpty Item.empty) True
        , test "got 1 item" <|
            \() ->
                Expect.equal (Item.isEmpty <| Item.fromList [ Item.new ]) False
        ]


unwrap : Test
unwrap =
    describe "unwrap test"
        [ test "unwrap empty item" <|
            \() ->
                Expect.equal (Item.unwrap Item.empty) []
        , test "unwrap 1 item" <|
            \() ->
                Expect.equal (Item.unwrap <| Item.fromList [ Item.new ]) [ Item.new ]
        ]


splitAt : Test
splitAt =
    describe "splitAt test"
        [ test "splitAt empty item" <|
            \() ->
                Expect.equal (Item.splitAt 1 Item.empty)
                    ( Item.empty, Item.empty )
        , test
            "splitAt 1 item"
          <|
            \() ->
                Expect.equal (Item.splitAt 1 (Item.fromList [ Item.new ])) ( Item.fromList [ Item.new ], Item.empty )
        , test
            "splitAt 2 item"
          <|
            \() ->
                Expect.equal (Item.splitAt 1 (Item.fromList [ Item.new, Item.new ])) ( Item.fromList [ Item.new ], Item.fromList [ Item.new ] )
        ]


getChildrenCount : Test
getChildrenCount =
    describe "getChildrenCount test"
        [ test "got empty item" <|
            \() ->
                Expect.equal (Item.getChildrenCount Item.new) 0
        , test "got 1 children" <|
            \() ->
                Expect.equal
                    (Item.getChildrenCount
                        (Item.new
                            |> Item.withText "test"
                            |> Item.withChildren (Item.childrenFromItems (Item.fromList [ Item.new ]))
                        )
                    )
                    2
        ]


getHierarchyCount : Test
getHierarchyCount =
    describe
        "getHierarchyCount test"
        [ test "empty item" <|
            \() ->
                Expect.equal (Item.getHierarchyCount Item.new) 0
        , test "1 children" <|
            \() ->
                Expect.equal
                    (Item.getHierarchyCount
                        (Item.new
                            |> Item.withText "test"
                            |> Item.withChildren (Item.childrenFromItems (Item.fromList [ Item.new ]))
                        )
                    )
                    1
        ]


withText : Test
withText =
    describe
        "withText test"
        [ test "when multiple |" <|
            \() ->
                Expect.equal
                    (Item.new
                        |> Item.withText "test: |test2: |"
                        |> Item.getText
                    )
                    "test"
        , test "when multiple | and item settings json" <|
            \() ->
                Expect.equal
                    (Item.new
                        |> Item.withText "test: |test2: |{\"bg\":null,\"fg\":null,\"pos\":[0,0],\"font_size\":10}"
                        |> Item.getText
                    )
                    "test"
        , test "when text with comments" <|
            \() ->
                Expect.equal
                    (Item.new
                        |> Item.withText "test # comment"
                        |> (\i -> ( Item.getText i, Item.getComments i ))
                    )
                    ( "test ", Just "# comment" )
        , test "when text with comments and item settings json" <|
            \() ->
                Expect.equal
                    (Item.new
                        |> Item.withText "test # comment: |{\"bg\":null,\"fg\":null,\"pos\":[0,0],\"font_size\":10}"
                        |> (\i -> ( Item.getText i, Item.getComments i, Item.getSettings i |> Maybe.withDefault ItemSettings.new |> ItemSettings.getFontSize |> FontSize.unwrap ))
                    )
                    ( "test ", Just "# comment", 10 )
        , test "when text with invalid comments and item settings json" <|
            \() ->
                Expect.equal
                    (Item.new
                        |> Item.withText "test # comment : |{\"bg\":null,\"fg\":null,\"pos\":[0,0],\"size\":10}"
                        |> (\i -> ( Item.getText i, Item.getComments i, Item.getSettings i ))
                    )
                    ( "test ", Just "# comment ", Nothing )
        ]


fuzzer : Test
fuzzer =
    describe
        "fuzz test"
        [ fuzz itemFuzzer "item  test" <|
            \i ->
                Item.withText (Item.toLineString i) i
                    |> Expect.equal i
        ]


mapWithRecursive : Test
mapWithRecursive =
    describe
        "mapWithRecursive test"
        [ test "with highlight" <|
            \() ->
                Expect.equal
                    (Item.fromList
                        [ Item.new
                            |> Item.withChildren
                                (Item.childrenFromItems
                                    (Item.fromList
                                        [ Item.new
                                            |> Item.withChildren
                                                (Item.childrenFromItems (Item.fromList [ Item.new ]))
                                        ]
                                    )
                                )
                        ]
                        |> Item.mapWithRecursive (\item -> item |> Item.withHighlight True)
                    )
                    (Item.fromList
                        [ Item.new
                            |> Item.withHighlight True
                            |> Item.withChildren
                                (Item.childrenFromItems
                                    (Item.fromList
                                        [ Item.new
                                            |> Item.withHighlight True
                                            |> Item.withChildren
                                                (Item.childrenFromItems
                                                    (Item.fromList
                                                        [ Item.new
                                                            |> Item.withHighlight True
                                                        ]
                                                    )
                                                )
                                        ]
                                    )
                                )
                        ]
                    )
        ]


getTextOnly : Test
getTextOnly =
    describe
        "getTextOnly test"
        [ test "when text only" <|
            \() ->
                Expect.equal
                    (Item.new |> Item.withText "test" |> Item.getTextOnly)
                    "test"
        , test "has image:" <|
            \() ->
                Expect.equal
                    (Item.new |> Item.withText "image: http://example.com" |> Item.getTextOnly)
                    "http://example.com/"
        , test "has image: and settings" <|
            \() ->
                Expect.equal
                    (Item.new |> Item.withText "image: https://avatars.githubusercontent.com/u/533078?v=4: |{\"size\":[192,209]}" |> Item.getTextOnly)
                    "https://avatars.githubusercontent.com/u/533078?v=4"
        ]

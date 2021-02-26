module Data.ItemTests exposing (suite)

import Data.Item as Item exposing (ItemType(..), Items(..))
import Expect
import Test exposing (Test, describe, test)
import TextUSM.Enum.Diagram exposing (Diagram(..))


suite : Test
suite =
    describe "Item test"
        [ describe "getAt test"
            [ test "got the item at index 0" <|
                \() ->
                    Expect.equal (Item.getAt 0 (Item.fromList [ Item.new ])) (Just Item.new)
            , test "got the item at index 1 return Nothing " <|
                \() ->
                    Expect.equal (Item.getAt 1 (Item.fromList [ Item.new ])) Nothing
            ]
        , describe "head test"
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
        , describe "tail test"
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
        , describe "map test"
            [ test "map item" <|
                \() ->
                    Expect.equal (Item.map Item.getText (Item.fromList [ Item.new ])) [ "" ]
            ]
        , describe "cons test"
            [ test "got 1 item" <|
                \() ->
                    Expect.equal (Item.cons Item.new Item.empty) (Item.fromList [ Item.new ])
            , test "got 2 item" <|
                \() ->
                    Expect.equal (Item.cons Item.new (Item.fromList [ Item.new ])) (Item.fromList [ Item.new, Item.new ])
            ]
        , describe "indexed map test"
            [ test "indexed map item" <|
                \() ->
                    Expect.equal
                        (Item.indexedMap (\i item -> ( i, Item.getText item ))
                            (Item.fromList [ Item.new, Item.new |> Item.withText "test" |> Item.withLineNo 1 ])
                        )
                        [ ( 0, "" ), ( 1, "test" ) ]
            ]
        , describe "length test"
            [ test "got empty item" <|
                \() ->
                    Expect.equal (Item.length Item.empty) 0
            , test "got 1 item" <|
                \() ->
                    Expect.equal (Item.length <| Item.fromList [ Item.new ]) 1
            ]
        , describe "isEmpty test"
            [ test "got empty item" <|
                \() ->
                    Expect.equal (Item.isEmpty Item.empty) True
            , test "got 1 item" <|
                \() ->
                    Expect.equal (Item.isEmpty <| Item.fromList [ Item.new ]) False
            ]
        , describe "unwrap test"
            [ test "unwrap empty item" <|
                \() ->
                    Expect.equal (Item.unwrap Item.empty) []
            , test "unwrap 1 item" <|
                \() ->
                    Expect.equal (Item.unwrap <| Item.fromList [ Item.new ]) [ Item.new ]
            ]
        , describe "splitAt test"
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
        , describe "getChildrenCount test"
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
        , describe
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
        , describe
            "withText test"
            [ test "when multiple |" <|
                \() ->
                    Expect.equal
                        (Item.new
                            |> Item.withText "test|test2|"
                            |> Item.getText
                        )
                        "test|test2|"
            , test "when multiple | and item settings json" <|
                \() ->
                    Expect.equal
                        (Item.new
                            |> Item.withText "test|test2|{\"b\":null,\"f\":null,\"o\":[0,0],\"s\":10}"
                            |> Item.getText
                        )
                        "test|test2|{\"b\":null,\"f\":null,\"o\":[0,0],\"s\":10}"
            ]
        ]

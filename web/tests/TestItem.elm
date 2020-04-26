module TestItem exposing (all)

import Data.Item as Item exposing (ItemType(..), Items(..))
import Expect
import Test exposing (Test, describe, test)
import TextUSM.Enum.Diagram exposing (Diagram(..))


all : Test
all =
    describe "Item test"
        [ describe "getAt test"
            [ test "get the item at index 0" <|
                \() ->
                    Expect.equal (Item.getAt 0 (Items [ Item.emptyItem ])) (Just Item.emptyItem)
            , test "get the item at index 1 return Nothing " <|
                \() ->
                    Expect.equal (Item.getAt 1 (Items [ Item.emptyItem ])) Nothing
            ]
        , describe "head test"
            [ test "get head item" <|
                \() ->
                    Expect.equal (Item.head (Items [ Item.emptyItem ])) (Just Item.emptyItem)
            , test "get head item from items" <|
                \() ->
                    Expect.equal
                        (Item.head
                            (Items
                                [ Item.emptyItem
                                , { lineNo = 0
                                  , text = ""
                                  , itemType = Activities
                                  , children = Item.emptyChildren
                                  }
                                ]
                            )
                        )
                        (Just Item.emptyItem)
            , test "get head item return Nothing" <|
                \() ->
                    Expect.equal (Item.head (Items [])) Nothing
            ]
        , describe "tail test"
            [ test "get tail item" <|
                \() ->
                    Expect.equal (Item.tail (Items [ Item.emptyItem ])) (Just (Items []))
            , test "get tail item from items" <|
                \() ->
                    Expect.equal
                        (Item.tail
                            (Items
                                [ { lineNo = 0
                                  , text = ""
                                  , itemType = Activities
                                  , children = Item.emptyChildren
                                  }
                                , Item.emptyItem
                                ]
                            )
                        )
                        (Just (Items [ Item.emptyItem ]))
            , test "get tail item return Nothing" <|
                \() ->
                    Expect.equal (Item.tail (Items [])) Nothing
            ]
        , describe "map test"
            [ test "map item" <|
                \() ->
                    Expect.equal (Item.map .text (Items [ Item.emptyItem ])) [ "" ]
            ]
        , describe "cons test"
            [ test "1 item" <|
                \() ->
                    Expect.equal (Item.cons Item.emptyItem Item.empty) (Items [ Item.emptyItem ])
            , test "2 item" <|
                \() ->
                    Expect.equal (Item.cons Item.emptyItem (Items [ Item.emptyItem ])) (Items [ Item.emptyItem, Item.emptyItem ])
            ]
        , describe "indexed map test"
            [ test "indexed map item" <|
                \() ->
                    Expect.equal
                        (Item.indexedMap (\i item -> ( i, item.text ))
                            (Items
                                [ Item.emptyItem
                                , { lineNo = 0
                                  , text = "test"
                                  , itemType = Activities
                                  , children = Item.emptyChildren
                                  }
                                ]
                            )
                        )
                        [ ( 0, "" ), ( 1, "test" ) ]
            ]
        , describe "length test"
            [ test "empty item" <|
                \() ->
                    Expect.equal (Item.length Item.empty) 0
            , test "1 item" <|
                \() ->
                    Expect.equal (Item.length <| Items [ Item.emptyItem ]) 1
            ]
        , describe "isEmpty test"
            [ test "empty item" <|
                \() ->
                    Expect.equal (Item.isEmpty Item.empty) True
            , test "1 item" <|
                \() ->
                    Expect.equal (Item.isEmpty <| Items [ Item.emptyItem ]) False
            ]
        , describe "unwrap test"
            [ test "unwrap empty item" <|
                \() ->
                    Expect.equal (Item.unwrap Item.empty) []
            , test "unwrap 1 item" <|
                \() ->
                    Expect.equal (Item.unwrap <| Items [ Item.emptyItem ]) [ Item.emptyItem ]
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
                    Expect.equal (Item.splitAt 1 (Items [ Item.emptyItem ])) ( Items [ Item.emptyItem ], Item.empty )
            , test
                "splitAt 2 item"
              <|
                \() ->
                    Expect.equal (Item.splitAt 1 (Items [ Item.emptyItem, Item.emptyItem ])) ( Items [ Item.emptyItem ], Items [ Item.emptyItem ] )
            ]
        , describe "getChildrenCount test"
            [ test "empty item" <|
                \() ->
                    Expect.equal (Item.getChildrenCount Item.emptyItem) 0
            , test "1 children" <|
                \() ->
                    Expect.equal
                        (Item.getChildrenCount
                            { lineNo = 0
                            , text = "test"
                            , itemType = Activities
                            , children = Item.childrenFromItems (Items [ Item.emptyItem ])
                            }
                        )
                        2
            ]
        , describe
            "getHierarchyCount test"
            [ test "empty item" <|
                \() ->
                    Expect.equal (Item.getHierarchyCount Item.emptyItem) 0
            , test "1 children" <|
                \() ->
                    Expect.equal
                        (Item.getHierarchyCount
                            { lineNo = 0
                            , text = "test"
                            , itemType = Activities
                            , children = Item.childrenFromItems (Items [ Item.emptyItem ])
                            }
                        )
                        1
            ]
        ]

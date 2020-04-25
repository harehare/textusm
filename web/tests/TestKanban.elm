module TestKanban exposing (all)

import Data.Item as Item exposing (ItemType(..))
import Expect
import Models.Views.Kanban as Kanban
import Test exposing (Test, describe, test)


all : Test
all =
    describe "Kanban test"
        [ describe "getListCount test"
            [ test "empty items" <|
                \() ->
                    Expect.equal (Kanban.getListCount <| Kanban.fromItems Item.empty) 0
            , test "2 item" <|
                \() ->
                    Expect.equal (Kanban.getListCount <| Kanban.fromItems (Item.fromList [ Item.emptyItem, Item.emptyItem ])) 2
            ]
        ]

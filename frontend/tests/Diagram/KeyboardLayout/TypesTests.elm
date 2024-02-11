module Diagram.KeyboardLayout.TypesTests exposing (suite)

import Diagram.KeyboardLayout.Types as KeyboardLayout
import Diagram.KeyboardLayout.Types.Key as Key
import Diagram.KeyboardLayout.Types.Unit as Unit
import Expect
import Test exposing (Test, describe, test)
import Types.Item as Item


suite : Test
suite =
    describe "Keyboard Layout test"
        [ describe "from"
            [ test "key matches" <|
                \() ->
                    let
                        item : Item.Items
                        item =
                            Item.fromList
                                [ Item.new
                                    |> Item.withText "r1"
                                    |> Item.withChildren
                                        (Item.fromList [ Item.new |> Item.withText "    1,@,2u" ]
                                            |> Item.childrenFromItems
                                        )
                                ]
                    in
                    Expect.equal
                        (KeyboardLayout.from item |> KeyboardLayout.rows)
                        [ KeyboardLayout.Row
                            [ Key.Key
                                { item = Item.new |> Item.withText "    1,@,2u" |> Item.withLineNo 0
                                , topLegend_ = Just "1"
                                , bottomLegend_ = Just "@"
                                , keySize = ( Unit.fromString "2u" |> Maybe.withDefault Unit.u1, Unit.u1 )
                                , marginTop_ = Nothing
                                }
                            ]
                        ]
            ]
        ]

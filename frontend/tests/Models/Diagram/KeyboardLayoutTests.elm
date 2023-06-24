module Models.Diagram.KeyboardLayoutTests exposing (suite)

import Expect
import Models.Diagram.KeyboardLayout as KeyboardLayout
import Models.Diagram.KeyboardLayout.Key as Key
import Models.Diagram.KeyboardLayout.Unit as Unit
import Models.Item as Item
import Models.Property as Property
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Keyboard Layout test"
        [ describe "from"
            [ test "key matches" <|
                \() ->
                    let
                        item =
                            Item.fromList
                                [ Item.new
                                    |> Item.withText "r1"
                                    |> Item.withChildren
                                        (Item.fromList [ Item.new |> Item.withText "    1,@,2" ]
                                            |> Item.childrenFromItems
                                        )
                                ]
                    in
                    Expect.equal
                        (KeyboardLayout.from item Property.empty |> KeyboardLayout.rows)
                        [ KeyboardLayout.Row [ Key.new (Just "1") (Just "@") (Unit.fromString "2") ] ]
            ]
        ]

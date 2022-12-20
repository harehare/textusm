module Models.ImageTest exposing (..)

import Expect
import Models.Image as Image
import Models.Item as Item
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Image test"
        [ test "url text" <|
            \() ->
                Expect.equal
                    (Item.new
                        |> Item.withText "image: text"
                        |> Image.from
                        |> Maybe.map Image.isUrl
                    )
                    (Just True)
        , test "data url text" <|
            \() ->
                Expect.equal
                    (Item.new
                        |> Item.withText "data:image/text"
                        |> Image.from
                        |> Maybe.map Image.isDataUrl
                    )
                    (Just True)
        ]

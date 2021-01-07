module Data.ItemSettingsTests exposing (all)

import Data.Color as Color
import Data.FontSize as FontSize
import Data.ItemSettings as ItemSettings
import Expect
import Json.Decode as D
import Json.Encode as E
import Test exposing (Test, describe, test)


all : Test
all =
    describe "ItemSettings test"
        [ describe "encoder test"
            [ test "encode null test" <|
                \() ->
                    Expect.equal (ItemSettings.encoder ItemSettings.new |> E.encode 0) "{\"b\":null,\"f\":null,\"o\":[0,0],\"s\":20}"
            , test "encode test" <|
                \() ->
                    Expect.equal
                        (ItemSettings.encoder
                            (ItemSettings.new
                                |> ItemSettings.withBackgroundColor (Just Color.white)
                                |> ItemSettings.withForegroundColor (Just Color.black)
                                |> ItemSettings.withFontSize FontSize.fontSize20
                            )
                            |> E.encode 0
                        )
                        "{\"b\":\"#FFFFFF\",\"f\":\"#000000\",\"o\":[0,0],\"s\":14}"
            ]
        , describe "decoder test"
            [ test "decode null test" <|
                \() ->
                    Expect.equal (D.decodeString ItemSettings.decoder "{\"b\":null,\"f\":null,\"o\":[0,0],\"s\":14}") (Ok ItemSettings.new)
            , test "decode test" <|
                \() ->
                    Expect.equal (D.decodeString ItemSettings.decoder "{\"b\":\"#FFFFFF\",\"f\":\"#000000\",\"o\":[0,0],\"s\":14}")
                        (Ok
                            (ItemSettings.new
                                |> ItemSettings.withBackgroundColor (Just Color.white)
                                |> ItemSettings.withForegroundColor (Just Color.black)
                            )
                        )
            ]
        ]

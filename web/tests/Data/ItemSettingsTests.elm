module Data.ItemSettingsTests exposing (all)

import Data.Color as Color
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
                    Expect.equal (ItemSettings.encoder ItemSettings.new |> E.encode 0) "{\"bg\":null,\"fg\":null,\"offset\":[0,0]}"
            , test "encode test" <|
                \() ->
                    Expect.equal
                        (ItemSettings.encoder
                            (ItemSettings.new
                                |> ItemSettings.withBackgroundColor (Just Color.white)
                                |> ItemSettings.withForegroundColor (Just Color.black)
                            )
                            |> E.encode 0
                        )
                        "{\"bg\":\"#FFFFFF\",\"fg\":\"#000000\",\"offset\":[0,0]}"
            ]
        , describe "decoder test"
            [ test "decode null test" <|
                \() ->
                    Expect.equal (D.decodeString ItemSettings.decoder "{\"bg\":null,\"fg\":null,\"offset\":[0,0]}") (Ok ItemSettings.new)
            , test "decode test" <|
                \() ->
                    Expect.equal (D.decodeString ItemSettings.decoder "{\"bg\":\"#FFFFFF\",\"fg\":\"#000000\",\"offset\":[0,0]}")
                        (Ok
                            (ItemSettings.new
                                |> ItemSettings.withBackgroundColor (Just Color.white)
                                |> ItemSettings.withForegroundColor (Just Color.black)
                            )
                        )
            ]
        ]

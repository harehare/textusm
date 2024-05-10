module Types.Item.ParserTests exposing (all)

import DataUrl
import Expect
import Parser
import Test exposing (Test, describe, test)
import Types.Color as Color
import Types.Fuzzer exposing (itemSettingsFuzzer)
import Types.Item.Constants as ItemConstants
import Types.Item.Parser as ItemParser
import Types.Item.Settings as ItemSettings
import Types.Item.Value exposing (Value(..))
import Types.Text as Text
import Url


all : Test
all =
    describe "parser test"
        [ parse
        , markdown
        , image
        , imageData
        , commentLine
        , plainText
        , settings
        ]


parse : Test
parse =
    describe "parse test"
        ([ ( "text only", "test", ItemParser.Parsed (PlainText 0 (Text.fromString "test")) Nothing Nothing )
         , ( "text and comment", "test # comment", ItemParser.Parsed (PlainText 0 (Text.fromString "test ")) (Just " comment") Nothing )
         , ( "text and comment and settings"
           , "test # comment : |{\"bg\":\"#8C9FAE\"}"
           , ItemParser.Parsed (PlainText 0 (Text.fromString "test "))
                (Just " comment ")
                (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
           )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.parse data |> Result.withDefault (ItemParser.Parsed (PlainText 0 Text.empty) Nothing Nothing))
                                expect
                )
        )


markdown : Test
markdown =
    describe "markdown test"
        ([ ( "no indent", "md:test", Markdown 0 (Text.fromString "test") )
         , ( "1 indent", "    md:**test**", Markdown 1 (Text.fromString "**test**") )
         , ( "2 indent", "        md:*test*", Markdown 2 (Text.fromString "*test*") )
         , ( "3 indent", "            md:test", Markdown 3 (Text.fromString "test") )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.markdown data |> Result.withDefault (Markdown 0 Text.empty))
                                expect
                )
        )


image : Test
image =
    describe "image test"
        ([ ( "no indent", "image:http://example.com", Url.fromString "http://example.com" |> Maybe.map (\url -> Image 0 url) |> Maybe.withDefault (PlainText 0 Text.empty) )
         , ( "1 indent", "    image:http://example.com", Url.fromString "http://example.com" |> Maybe.map (\url -> Image 1 url) |> Maybe.withDefault (PlainText 0 Text.empty) )
         , ( "not url", "    image:test", PlainText 1 (Text.fromString "test") )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.image data |> Result.withDefault (Markdown 0 Text.empty))
                                expect
                )
        )


imageData : Test
imageData =
    describe "imagedata test"
        ([ ( "no indent", "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D", DataUrl.fromString "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D" |> Maybe.map (\url -> ImageData 0 url) |> Maybe.withDefault (PlainText 0 Text.empty) )
         , ( "1 indent", "    data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D", DataUrl.fromString "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D" |> Maybe.map (\url -> ImageData 1 url) |> Maybe.withDefault (PlainText 0 Text.empty) )
         , ( "not url", "    data:image/test", PlainText 1 (Text.fromString "test") )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.imageData data |> Result.withDefault (Markdown 0 Text.empty))
                                expect
                )
        )


commentLine : Test
commentLine =
    describe "comment test"
        ([ ( "no indent", "# test", Comment 0 (Text.fromString " test") )
         , ( "1 indent", "    # test", Comment 1 (Text.fromString " test") )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.commentLine data |> Result.withDefault (Comment 0 Text.empty))
                                expect
                )
        )


plainText : Test
plainText =
    describe "plainText test"
        ([ ( "no indent", "test", PlainText 0 (Text.fromString "test") )
         , ( "1 indent", "    test", PlainText 1 (Text.fromString "test") )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.plainText data |> Result.withDefault (PlainText 0 Text.empty))
                                expect
                )
        )


settings : Test
settings =
    Test.fuzz itemSettingsFuzzer "settings test" <|
        \i ->
            (ItemConstants.settingsPrefix ++ ItemSettings.toString i)
                |> Parser.run ItemParser.settings
                |> Expect.equal (Ok (Just i))

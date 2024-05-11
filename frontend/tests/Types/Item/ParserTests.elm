module Types.Item.ParserTests exposing (all)

import DataUrl
import Expect
import Parser
import Test exposing (Test, describe, test)
import Types.Color as Color
import Types.Fuzzer exposing (itemSettingsFuzzer)
import Types.Item as Item
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
        ([ ( "text only", "test ", Item.new |> Item.withValue (PlainText 0 (Text.fromString "test ")) )
         , ( "text only 1 indent", "    test ", Item.new |> Item.withValue (PlainText 1 (Text.fromString "test ")) )
         , ( "markdown only 1 indent", "    md:*test* ", Item.new |> Item.withValue (Markdown 1 (Text.fromString "*test* ")) )
         , ( "image only 1 indent", "    image:http://example.com ", Item.new |> Item.withValue (Url.fromString "http://example.com" |> Maybe.map (\url -> Image 1 url) |> Maybe.withDefault (PlainText 0 Text.empty)) )
         , ( "imageData only 1 indent", "    data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D", Item.new |> Item.withValue (DataUrl.fromString "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D" |> Maybe.map (\url -> ImageData 1 url) |> Maybe.withDefault (PlainText 0 Text.empty)) )
         , ( "comment only 1 indent", "    # comment", Item.new |> Item.withValue (Comment 1 (Text.fromString " comment")) )
         , ( "text and comment", "test # comment", Item.new |> Item.withValue (PlainText 0 (Text.fromString "test ")) |> Item.withComments (Just " comment") )
         , ( "text and empty comment", "test # ", Item.new |> Item.withValue (PlainText 0 (Text.fromString "test ")) |> Item.withComments (Just " ") )
         , ( "text, comment and empty settings", "test # comment : |", Item.new |> Item.withValue (PlainText 0 (Text.fromString "test ")) |> Item.withComments (Just " comment ") )
         , ( "text, comment and settings"
           , "test # comment : |{\"bg\":\"#8C9FAE\"}"
           , Item.new
                |> Item.withValue (PlainText 0 (Text.fromString "test "))
                |> Item.withComments (Just " comment ")
                |> Item.withSettings (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
           )
         , ( "markdown, comment and settings"
           , "md:*test* # comment : |{\"bg\":\"#8C9FAE\"}"
           , Item.new
                |> Item.withValue (Markdown 0 (Text.fromString "*test* "))
                |> Item.withComments (Just " comment ")
                |> Item.withSettings (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
           )
         , ( "image, comment and settings"
           , "image:http://example.com # comment : |{\"bg\":\"#8C9FAE\"}"
           , Item.new
                |> Item.withValue (Url.fromString "http://example.com" |> Maybe.map (\url -> Image 0 url) |> Maybe.withDefault (PlainText 0 Text.empty))
                |> Item.withComments (Just " comment ")
                |> Item.withSettings (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
           )
         , ( "imageData, comment and settings"
           , "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D # comment : |{\"bg\":\"#8C9FAE\"}"
           , Item.new
                |> Item.withValue (DataUrl.fromString "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D" |> Maybe.map (\url -> ImageData 0 url) |> Maybe.withDefault (PlainText 0 Text.empty))
                |> Item.withComments (Just " comment ")
                |> Item.withSettings (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
           )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.parse data |> Result.withDefault Item.new)
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

module Types.Item.ParserTests exposing (all)

import DataUrl
import Expect
import Parser
import Test exposing (Test, describe, test)
import Types.Color as Color
import Types.FontSize as FontSize
import Types.Fuzzer exposing (itemSettingsFuzzer)
import Types.Item.Constants as ItemConstants
import Types.Item.Parser as ItemParser exposing (Parsed(..))
import Types.Item.Settings as ItemSettings
import Types.Item.Value exposing (Value(..))
import Types.Text as Text
import Url


all : Test
all =
    describe "parser test"
        [ parser
        , markdown
        , image
        , imageData
        , commentLine
        , plainText
        , settings
        ]


parser : Test
parser =
    describe "parse test"
        ([ ( "text only", "test ", Parsed (PlainText 0 (Text.fromString "test ")) Nothing Nothing )
         , ( "text only 1 indent", "    test ", Parsed (PlainText 1 (Text.fromString "test ")) Nothing Nothing )
         , ( "markdown only 1 indent", "    md:*test* ", Parsed (Markdown 1 (Text.fromString "*test* ")) Nothing Nothing )
         , ( "image only 1 indent", "    image:http://example.com ", Parsed (Url.fromString "http://example.com" |> Maybe.map (\url -> Image 1 url) |> Maybe.withDefault (PlainText 0 Text.empty)) Nothing Nothing )
         , ( "imageData only 1 indent"
           , "    data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D"
           , Parsed (DataUrl.fromString "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D" |> Maybe.map (\url -> ImageData 1 url) |> Maybe.withDefault (PlainText 0 Text.empty)) Nothing Nothing
           )
         , ( "comment only 1 indent", "    # comment", Parsed (Comment 1 (Text.fromString " comment")) Nothing Nothing )
         , ( "text and comment", "test # comment", Parsed (PlainText 0 (Text.fromString "test ")) (Just " comment") Nothing )
         , ( "text and empty comment", "test # ", Parsed (PlainText 0 (Text.fromString "test ")) (Just " ") Nothing )
         , ( "text, comment and empty settings", "test # comment : |", Parsed (PlainText 0 (Text.fromString "test ")) (Just " comment ") Nothing )
         , ( "colon, comment and empty settings"
           , "\\: #test : |{\"font_size\":8}"
           , Parsed (PlainText 0 (Text.fromString "\\: "))
                (Just "test ")
                (Just (ItemSettings.new |> ItemSettings.withFontSize (FontSize.fromInt 8)))
           )
         , ( "text, comment and settings"
           , "test # comment : |{\"bg\":\"#8C9FAE\"}"
           , Parsed (PlainText 0 (Text.fromString "test "))
                (Just " comment ")
                (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
           )
         , ( "markdown, comment and settings"
           , "md:*test* # comment : |{\"bg\":\"#8C9FAE\"}"
           , Parsed (Markdown 0 (Text.fromString "*test* "))
                (Just " comment ")
                (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
           )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (ItemParser.parse data |> Result.withDefault (Parsed (PlainText 0 Text.empty) Nothing Nothing))
                                expect
                )
        )


markdown : Test
markdown =
    describe "markdown test"
        ([ ( "no indent", "md:test", Parsed (Markdown 0 (Text.fromString "test")) Nothing Nothing )
         , ( "1 indent", "    md:**test**", Parsed (Markdown 1 (Text.fromString "**test**")) Nothing Nothing )
         , ( "2 indent", "        md:*test*", Parsed (Markdown 2 (Text.fromString "*test*")) Nothing Nothing )
         , ( "3 indent", "            md:test", Parsed (Markdown 3 (Text.fromString "test")) Nothing Nothing )
         , ( "text and comment", "md:test # test", Parsed (Markdown 0 (Text.fromString "test ")) (Just " test") Nothing )
         , ( "text and settings"
           , "md:test : |{\"bg\":\"#8C9FAE\"}"
           , Parsed (Markdown 0 (Text.fromString "test "))
                Nothing
                (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
           )
         , ( "text, comment and settings"
           , "md:test # test : |{\"bg\":\"#8C9FAE\"}"
           , Parsed (Markdown 0 (Text.fromString "test "))
                (Just " test ")
                (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
           )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.markdown data |> Result.withDefault (Parsed (Markdown 0 Text.empty) Nothing Nothing))
                                expect
                )
        )


image : Test
image =
    describe "image test"
        ([ ( "no indent", "image:http://example.com", Parsed (Url.fromString "http://example.com" |> Maybe.map (\url -> Image 0 url) |> Maybe.withDefault (PlainText 0 Text.empty)) Nothing Nothing )
         , ( "1 indent", "    image:http://example.com", Parsed (Url.fromString "http://example.com" |> Maybe.map (\url -> Image 1 url) |> Maybe.withDefault (PlainText 0 Text.empty)) Nothing Nothing )
         , ( "not url", "    image:test", Parsed (PlainText 1 (Text.fromString "test")) Nothing Nothing )
         , ( "text and settings"
           , "image:http://example.com : |{\"bg\":\"#8C9FAE\"}"
           , Parsed (Url.fromString "http://example.com" |> Maybe.map (\url -> Image 0 url) |> Maybe.withDefault (PlainText 0 Text.empty))
                Nothing
                (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
           )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.image data |> Result.withDefault (Parsed (PlainText 0 Text.empty) Nothing Nothing))
                                expect
                )
        )


imageData : Test
imageData =
    describe "imagedata test"
        ([ ( "no indent"
           , "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D"
           , Parsed (DataUrl.fromString "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D" |> Maybe.map (\url -> ImageData 0 url) |> Maybe.withDefault (PlainText 0 Text.empty)) Nothing Nothing
           )
         , ( "1 indent"
           , "    data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D"
           , Parsed (DataUrl.fromString "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D" |> Maybe.map (\url -> ImageData 1 url) |> Maybe.withDefault (PlainText 0 Text.empty)) Nothing Nothing
           )
         , ( "not url"
           , "    data:image/test"
           , Parsed (PlainText 1 (Text.fromString "test")) Nothing Nothing
           )
         , ( "text and settings"
           , "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D : |{\"bg\":\"#8C9FAE\"}"
           , Parsed (DataUrl.fromString "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D" |> Maybe.map (\url -> ImageData 0 url) |> Maybe.withDefault (PlainText 0 Text.empty))
                Nothing
                (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
           )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.imageData data |> Result.withDefault (Parsed (PlainText 0 Text.empty) Nothing Nothing))
                                expect
                )
        )


commentLine : Test
commentLine =
    describe "comment test"
        ([ ( "no indent", "# test", Parsed (Comment 0 (Text.fromString " test")) Nothing Nothing )
         , ( "1 indent", "    # test", Parsed (Comment 1 (Text.fromString " test")) Nothing Nothing )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.commentLine data |> Result.withDefault (Parsed (Comment 0 Text.empty) Nothing Nothing))
                                expect
                )
        )


plainText : Test
plainText =
    describe "plainText test"
        ([ ( "no indent", "test", Parsed (PlainText 0 (Text.fromString "test")) Nothing Nothing )
         , ( "1 indent", "    test", Parsed (PlainText 1 (Text.fromString "test")) Nothing Nothing )
         , ( "text and comment", "test # test", Parsed (PlainText 0 (Text.fromString "test ")) (Just " test") Nothing )
         , ( "text and settings"
           , "test : |{\"bg\":\"#8C9FAE\"}"
           , Parsed (PlainText 0 (Text.fromString "test "))
                Nothing
                (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
           )
         , ( "text, comment and settings"
           , "test # test : |{\"bg\":\"#8C9FAE\"}"
           , Parsed (PlainText 0 (Text.fromString "test "))
                (Just " test ")
                (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
           )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.plainText data |> Result.withDefault (Parsed (PlainText 0 Text.empty) Nothing Nothing))
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

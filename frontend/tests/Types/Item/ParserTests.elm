module Types.Item.ParserTests exposing (suite)

import Constants
import DataUrl
import Expect
import Parser
import Test exposing (Test, describe, test)
import Types.Color as Color
import Types.FontSize as FontSize
import Types.Fuzzer exposing (itemSettingsFuzzer)
import Types.Item.Parser as ItemParser exposing (Parsed(..))
import Types.Item.Settings as ItemSettings
import Types.Item.Value exposing (Value(..))
import Types.Text as Text
import Url


suite : Test
suite =
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
        ([ ( "text only", "test ", Just (Parsed (PlainText 0 (Text.fromString "test ")) Nothing Nothing) )
         , ( "text only 1 indent", "    test ", Just (Parsed (PlainText 1 (Text.fromString "test ")) Nothing Nothing) )
         , ( "markdown only 1 indent", "    md:*test* ", Just (Parsed (Markdown 1 (Text.fromString "*test* ")) Nothing Nothing) )
         , ( "image only 1 indent", "    image:http://example.com ", Just (Parsed (Url.fromString "http://example.com" |> Maybe.map (\url -> Image 1 url) |> Maybe.withDefault (PlainText 0 Text.empty)) Nothing Nothing) )
         , ( "imageData only 1 indent"
           , "    data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D"
           , Just (Parsed (DataUrl.fromString "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D" |> Maybe.map (\url -> ImageData 1 url) |> Maybe.withDefault (PlainText 0 Text.empty)) Nothing Nothing)
           )
         , ( "comment only 1 indent", "    # comment", Just (Parsed (Comment 1 (Text.fromString " comment")) Nothing Nothing) )
         , ( "text and comment", "test # comment", Just (Parsed (PlainText 0 (Text.fromString "test ")) (Just " comment") Nothing) )
         , ( "text and empty comment", "test # ", Just (Parsed (PlainText 0 (Text.fromString "test ")) (Just " ") Nothing) )
         , ( "text, comment and empty settings", "test # comment : |", Just (Parsed (PlainText 0 (Text.fromString "test ")) (Just " comment ") Nothing) )
         , ( "colon, comment and empty settings"
           , "\\: #test : |{\"font_size\":8}"
           , Just
                (Parsed (PlainText 0 (Text.fromString "\\: "))
                    (Just "test ")
                    (Just (ItemSettings.new |> ItemSettings.withFontSize (FontSize.fromInt 8)))
                )
           )
         , ( "text, comment and settings"
           , "test # comment : |{\"bg\":\"#8C9FAE\"}"
           , Just
                (Parsed (PlainText 0 (Text.fromString "test "))
                    (Just " comment ")
                    (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
                )
           )
         , ( "text, comment and legacy settings"
           , "test # comment |{\"bg\":\"#8C9FAE\"}"
           , Just
                (Parsed (PlainText 0 (Text.fromString "test "))
                    (Just " comment ")
                    (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
                )
           )
         , ( "markdown, comment and settings"
           , "md:*test* # comment : |{\"bg\":\"#8C9FAE\"}"
           , Just
                (Parsed (Markdown 0 (Text.fromString "*test* "))
                    (Just " comment ")
                    (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
                )
           )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (ItemParser.parse data |> Result.toMaybe)
                                expect
                )
        )


markdown : Test
markdown =
    describe "markdown test"
        ([ ( "no indent", "md:test", Just (Parsed (Markdown 0 (Text.fromString "test")) Nothing Nothing) )
         , ( "1 indent", "    md:**test**", Just (Parsed (Markdown 1 (Text.fromString "**test**")) Nothing Nothing) )
         , ( "2 indent", "        md:*test*", Just (Parsed (Markdown 2 (Text.fromString "*test*")) Nothing Nothing) )
         , ( "3 indent", "            md:test", Just (Parsed (Markdown 3 (Text.fromString "test")) Nothing Nothing) )
         , ( "text and comment", "md:test # test", Just (Parsed (Markdown 0 (Text.fromString "test ")) (Just " test") Nothing) )
         , ( "text and settings"
           , "md:test : |{\"bg\":\"#8C9FAE\"}"
           , Just
                (Parsed (Markdown 0 (Text.fromString "test "))
                    Nothing
                    (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
                )
           )
         , ( "text, comment and settings"
           , "md:test # test : |{\"bg\":\"#8C9FAE\"}"
           , Just
                (Parsed (Markdown 0 (Text.fromString "test "))
                    (Just " test ")
                    (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
                )
           )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.markdown data |> Result.toMaybe)
                                expect
                )
        )


image : Test
image =
    describe "image test"
        ([ ( "no indent", "image:http://example.com", Just (Parsed (Url.fromString "http://example.com" |> Maybe.map (\url -> Image 0 url) |> Maybe.withDefault (PlainText 0 Text.empty)) Nothing Nothing) )
         , ( "1 indent", "    image:http://example.com", Just (Parsed (Url.fromString "http://example.com" |> Maybe.map (\url -> Image 1 url) |> Maybe.withDefault (PlainText 0 Text.empty)) Nothing Nothing) )
         , ( "not url", "    image:test", Just (Parsed (PlainText 1 (Text.fromString "test")) Nothing Nothing) )
         , ( "text and settings"
           , "image:http://example.com : |{\"bg\":\"#8C9FAE\"}"
           , Just
                (Parsed (Url.fromString "http://example.com" |> Maybe.map (\url -> Image 0 url) |> Maybe.withDefault (PlainText 0 Text.empty))
                    Nothing
                    (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
                )
           )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.image data |> Result.toMaybe)
                                expect
                )
        )


imageData : Test
imageData =
    describe "imagedata test"
        ([ ( "no indent"
           , "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D"
           , Just (Parsed (DataUrl.fromString "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D" |> Maybe.map (\url -> ImageData 0 url) |> Maybe.withDefault (PlainText 0 Text.empty)) Nothing Nothing)
           )
         , ( "1 indent"
           , "    data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D"
           , Just (Parsed (DataUrl.fromString "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D" |> Maybe.map (\url -> ImageData 1 url) |> Maybe.withDefault (PlainText 0 Text.empty)) Nothing Nothing)
           )
         , ( "not url"
           , "    data:image/test"
           , Just (Parsed (PlainText 1 (Text.fromString "test")) Nothing Nothing)
           )
         , ( "text and settings"
           , "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D : |{\"bg\":\"#8C9FAE\"}"
           , Just
                (Parsed (DataUrl.fromString "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D" |> Maybe.map (\url -> ImageData 0 url) |> Maybe.withDefault (PlainText 0 Text.empty))
                    Nothing
                    (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
                )
           )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.imageData data |> Result.toMaybe)
                                expect
                )
        )


commentLine : Test
commentLine =
    describe "comment test"
        ([ ( "no indent", "# test", Just (Parsed (Comment 0 (Text.fromString " test")) Nothing Nothing) )
         , ( "1 indent", "    # test", Just (Parsed (Comment 1 (Text.fromString " test")) Nothing Nothing) )
         , ( "comment", "    # test #test", Just (Parsed (Comment 1 (Text.fromString " test #test")) Nothing Nothing) )
         , ( "settings", "    # test: |{\"bg\":\"#8C9FAE\"}", Just (Parsed (Comment 1 (Text.fromString " test")) Nothing Nothing) )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.commentLine data |> Result.toMaybe)
                                expect
                )
        )


plainText : Test
plainText =
    describe "plainText test"
        ([ ( "no indent", "test", Just (Parsed (PlainText 0 (Text.fromString "test")) Nothing Nothing) )
         , ( "1 indent", "    test", Just (Parsed (PlainText 1 (Text.fromString "test")) Nothing Nothing) )
         , ( "text and comment", "test # test", Just (Parsed (PlainText 0 (Text.fromString "test ")) (Just " test") Nothing) )
         , ( "text and settings"
           , "test : |{\"bg\":\"#8C9FAE\"}"
           , Just
                (Parsed (PlainText 0 (Text.fromString "test "))
                    Nothing
                    (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
                )
           )
         , ( "text, comment and settings"
           , "test # test : |{\"bg\":\"#8C9FAE\"}"
           , Just
                (Parsed (PlainText 0 (Text.fromString "test "))
                    (Just " test ")
                    (Just (ItemSettings.new |> ItemSettings.withBackgroundColor (Just Color.labelDefalut)))
                )
           )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run ItemParser.plainText data |> Result.toMaybe)
                                expect
                )
        )


settings : Test
settings =
    Test.fuzz itemSettingsFuzzer "settings test" <|
        \i ->
            (Constants.settingsPrefix ++ ItemSettings.toString i)
                |> Parser.run ItemParser.settings
                |> Result.toMaybe
                |> Expect.equal (Just (Just i))

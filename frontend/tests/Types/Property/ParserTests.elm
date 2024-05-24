module Types.Property.ParserTests exposing (suite)

import Expect
import Parser
import Test exposing (Test, describe, test)
import Types.Property.Parser as PropertyParser exposing (Parsed(..))


suite : Test
suite =
    describe "parser test"
        [ parser
        ]


parser : Test
parser =
    describe "parse test"
        ([ ( "background_color", "# background_color:   #FFFFFF", Just (Parsed "background_color" "#FFFFFF") )
         , ( "background_image", "# background_image: http://localhost", Just (Parsed "background_image" "http://localhost") )
         , ( "canvas_background_color", "# canvas_background_color:   #FFFFFF", Just (Parsed "canvas_background_color" "#FFFFFF") )
         , ( "card_background_color2", "# card_background_color2:   #FFFFFF", Just (Parsed "card_background_color2" "#FFFFFF") )
         , ( "card_background_color3", "# card_background_color3:   #FFFFFF", Just (Parsed "card_background_color3" "#FFFFFF") )
         , ( "card_foreground_color1", "# card_foreground_color1:   #FFFFFF", Just (Parsed "card_foreground_color1" "#FFFFFF") )
         , ( "card_foreground_color2", "# card_foreground_color2:   #FFFFFF", Just (Parsed "card_foreground_color2" "#FFFFFF") )
         , ( "card_foreground_color3", "# card_foreground_color3:   #FFFFFF", Just (Parsed "card_foreground_color3" "#FFFFFF") )
         , ( "card_height", "# card_height: 100", Just (Parsed "card_height" "100") )
         , ( "card_width", "# card_width: 100", Just (Parsed "card_width" "100") )
         , ( "font_size", "# font_size: 8", Just (Parsed "font_size" "8") )
         , ( "line_color", "# line_color: #FFFFFF", Just (Parsed "line_color" "#FFFFFF") )
         , ( "line_size", "# line_size: 8", Just (Parsed "line_size" "8") )
         , ( "node_height", "# node_height: 80", Just (Parsed "node_height" "80") )
         , ( "node_width", "# node_width: 80", Just (Parsed "node_width" "80") )
         , ( "text_color", "# text_color: #FFFFFF", Just (Parsed "text_color" "#FFFFFF") )
         , ( "title", "# title: title", Just (Parsed "title" "title") )
         , ( "toolbar", "# toolbar: toolbar", Just (Parsed "toolbar" "toolbar") )
         , ( "user_activities", "# user_activities: user_activities", Just (Parsed "user_activities" "user_activities") )
         , ( "user_stories", "# user_stories: user_stories", Just (Parsed "user_stories" "user_stories") )
         , ( "user_tasks", "# user_tasks: user_tasks", Just (Parsed "user_tasks" "user_tasks") )
         , ( "zoom_control", "# zoom_control: true", Just (Parsed "zoom_control" "true") )
         , ( "release1", "# release1: release1", Just (Parsed "release1" "release1") )
         , ( "test", "# test: test", Nothing )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run PropertyParser.parser data |> Result.toMaybe)
                                expect
                )
        )

module Types.Property.ParserTests exposing (all)

import Expect
import Parser
import Test exposing (Test, describe, test)
import Types.Item.Value exposing (Value(..))
import Types.Property.Parser as PropertyParser exposing (Parsed(..))


all : Test
all =
    describe "parser test"
        [ parser
        ]


parser : Test
parser =
    describe "parse test"
        ([ ( "background_color", "# background_color:   #FFFFFF", Parsed "background_color" "#FFFFFF" )
         , ( "background_image", "# background_image: http://localhost", Parsed "background_image" "http://localhost" )
         , ( "canvas_background_color", "# canvas_background_color:   #FFFFFF", Parsed "canvas_background_color" "#FFFFFF" )
         , ( "card_background_color2", "# card_background_color2:   #FFFFFF", Parsed "card_background_color2" "#FFFFFF" )
         , ( "card_background_color3", "# card_background_color3:   #FFFFFF", Parsed "card_background_color3" "#FFFFFF" )
         , ( "card_foreground_color1", "# card_foreground_color1:   #FFFFFF", Parsed "card_foreground_color1" "#FFFFFF" )
         , ( "card_foreground_color2", "# card_foreground_color2:   #FFFFFF", Parsed "card_foreground_color2" "#FFFFFF" )
         , ( "card_foreground_color3", "# card_foreground_color3:   #FFFFFF", Parsed "card_foreground_color3" "#FFFFFF" )
         , ( "card_height", "# card_height: 100", Parsed "card_height" "100" )
         , ( "card_width", "# card_width: 100", Parsed "card_width" "100" )
         , ( "font_size", "# font_size: 8", Parsed "font_size" "8" )
         , ( "line_color", "# line_color: #FFFFFF", Parsed "line_color" "#FFFFFF" )
         , ( "line_size", "# line_size: 8", Parsed "line_size" "8" )
         , ( "node_height", "# node_height: 80", Parsed "node_height" "80" )
         , ( "node_width", "# node_width: 80", Parsed "node_width" "80" )
         , ( "text_color", "# text_color: #FFFFFF", Parsed "text_color" "#FFFFFF" )
         , ( "title", "# title: title", Parsed "title" "title" )
         , ( "toolbar", "# toolbar: toolbar", Parsed "toolbar" "toolbar" )
         , ( "user_activities", "# user_activities: user_activities", Parsed "user_activities" "user_activities" )
         , ( "user_stories", "# user_stories: user_stories", Parsed "user_stories" "user_stories" )
         , ( "user_tasks", "# user_tasks: user_tasks", Parsed "user_tasks" "user_tasks" )
         , ( "zoom_control", "# zoom_control: true", Parsed "zoom_control" "true" )
         , ( "release1", "# release1: release1", Parsed "release1" "release1" )
         ]
            |> List.map
                (\( title, data, expect ) ->
                    test title <|
                        \_ ->
                            Expect.equal
                                (Parser.run PropertyParser.parser data |> Debug.log "v" |> Result.withDefault (Parsed "" ""))
                                expect
                )
        )

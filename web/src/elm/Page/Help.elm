module Page.Help exposing (view)

import Asset
import Html exposing (Html, div, img, span, text)
import Html.Attributes exposing (alt, class, style)
import Maybe.Extra exposing (isNothing)


view : Html msg
view =
    div
        [ class "help"
        ]
        [ div [ class "font-semibold flex items-center p-3 justify-start", style "padding" "16px 0" ]
            [ img [ Asset.src Asset.logo, class "ml-2", style "width" "32px", alt "logo" ] []
            , span [ class "text-2xl ml-2" ] [ text "TextUSM" ]
            ]
        , div [ class "text-sm", style "padding" "0 16px" ]
            [ text "TextUSM is a simple tool. Help you draw user story map using indented text."
            ]

        -- Text Syntax
        , section (Just "Text Syntax")
        , div [ class "text activity", style "padding" "0 16px 16px" ]
            [ div [ class "activity" ] [ text "md: **Markdown Text**" ]
            , div [ class "task" ] [ indentedText "User Task" 1 ]
            , div [ class "story" ] [ indentedText "User Story Release 1" 2 ]
            , div [ class "story" ] [ indentedText "User Story Release 2..." 3 ]
            , div [ class "story" ] [ indentedText "Add Images" 4 ]
            , div [ class "story" ] [ indentedText "https://app.textusm.com/images/logo.svg" 5 ]
            , div [ class "story" ] [ indentedText "Change font size, font color or background color." 1 ]
            , div [ class "story" ] [ indentedText "test|{\"b\":\"#CEE5F2\",\"f\":\"#EE8A8B\",\"o\":[0,0],\"s\":9}" 2 ]
            ]

        -- Comment Syntax
        , section (Just "Comment Syntax")
        , div [ class "text comment", style "padding" "0 16px 16px" ] [ text "# Comment..." ]

        -- User Story Map Syntax
        , section (Just "User Story Map Syntax")
        , div [ class "text comment", style "padding" "0 16px 0px" ] [ text "# user_activities: Changed text" ]
        , div [ class "text comment", style "padding" "0 16px 0px" ] [ text "# user_tasks: Changed text" ]
        , div [ class "text comment", style "padding" "0 16px 0px" ] [ text "# user_stories: Changed text" ]
        , div [ class "text comment", style "padding" "0 16px 0px" ] [ text "# release1: Changed text" ]

        -- Free form
        , section (Just "Freeform")
        , div [ class "text comment", style "padding" "0 16px 0px" ] [ text "# Vertical line" ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ text "|" ]
        , div [ class "text comment", style "padding" "0 16px 0px" ] [ text "# Horizontal line" ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ text "---" ]
        , div [ class "text comment", style "padding" "0 16px 0px" ] [ text "# Item" ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ text "freeform" ]

        -- Use Case Diagram
        , section (Just "Use Case Diagram Syntax")
        , div [ class "text activity", style "padding" "0 16px 0px" ] [ text "[Actor Name]" ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "Use Caser" 1 ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "Use Case2" 1 ]
        , div [ class "text activity", style "padding" "0 16px 0px" ] [ text "(Use Case Name1)" ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "<extend" 1 ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText ">include" 1 ]
        , div [ class "text activity", style "padding" "0 16px 0px" ] [ text "(Use Case Name2)" ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "<extend" 1 ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText ">include" 1 ]

        -- Gantt Chart
        , section (Just "Gantt Chart Syntax")
        , div [ class "text activity", style "padding" "0 16px 0px" ] [ text "YYYY-MM-DD YYYY-MM-DD" ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "Section" 1 ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "Task" 2 ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "YYYY-MM-DD YYYY-MM-DD" 3 ]

        -- ER Diagram
        , section (Just "ER Diagram Syntax")

        -- relations
        , div [ class "text activity", style "padding" "0 16px 0px" ] [ text "relations" ]
        , div [ class "text comment", style "padding" "0 16px 0px" ] [ indentedText "# one to one" 1 ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "table1 - table2" 1 ]
        , div [ class "text comment", style "padding" "0 16px 0px" ] [ indentedText "# one to many" 1 ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "table1 < table2" 1 ]
        , div [ class "text comment", style "padding" "0 16px 0px" ] [ indentedText "# meny to many" 1 ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "table1 = table2" 1 ]

        -- tables
        , div [ class "text activity", style "padding" "0 16px 0px" ] [ text "tables" ]
        , div [ class "text task", style "padding" "0 16px 0px" ] [ indentedText "table1" 1 ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "id int pk auto_increment" 2 ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "name varchar(255) unique" 2 ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "json json null" 2 ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "value double not null" 2 ]
        , div [ class "text", style "padding" "0 16px 0px" ] [ indentedText "enum enum(value1,value2) not null" 2 ]

        -- Hot Keys
        , section (Just "Hotkeys")
        , div [ class "rows" ]
            [ div [ class "row header" ]
                [ div [ class "item" ] [ text "Windows" ]
                , div [ class "item" ] [ text "Mac" ]
                , div [ class "item" ] [ text "Action" ]
                ]
            , div [ class "row" ]
                [ div [ class "item" ] [ text "Ctrl+S" ]
                , div [ class "item" ] [ text "Command+S" ]
                , div [ class "item" ] [ text "Save" ]
                ]
            , div [ class "row" ]
                [ div [ class "item" ] [ text "Ctrl+O" ]
                , div [ class "item" ] [ text "Command+O" ]
                , div [ class "item" ] [ text "Open" ]
                ]
            ]
        ]


section : Maybe String -> Html msg
section title =
    div
        [ if isNothing title then
            style "" ""

          else
            style "border-top" "1px solid #323B46"
        , if isNothing title then
            style "padding" "0px"

          else
            style "padding" "32px 0px 8px 0px"
        , class "font-semibold"
        , style "border-bottom" "1px solid #666"
        , style "margin" "8px 16px 8px 16px"
        ]
        [ div [] [ text (title |> Maybe.withDefault "") ]
        ]


indentedText : String -> Int -> Html msg
indentedText s indent =
    text <|
        (String.fromChar '\u{00A0}' |> String.repeat (4 * indent))
            ++ s

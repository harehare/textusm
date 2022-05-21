module Page.Help exposing (view)

import Asset
import Css
    exposing
        ( alignItems
        , border3
        , borderBottom3
        , borderTop3
        , center
        , color
        , column
        , displayFlex
        , flexDirection
        , flexStart
        , hex
        , hidden
        , justifyContent
        , margin4
        , overflowX
        , padding
        , padding2
        , padding3
        , padding4
        , px
        , solid
        , width
        , zero
        )
import Html.Styled exposing (Html, div, img, span, text)
import Html.Styled.Attributes exposing (alt, css)
import Maybe.Extra exposing (isNothing)
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text


view : Html msg
view =
    div
        [ css [ Text.xs, Color.bgDefault, Style.widthFull, Color.textColor, overflowX hidden ]
        ]
        [ div
            [ css
                [ Font.fontSemiBold
                , displayFlex
                , alignItems center
                , justifyContent flexStart
                , padding2 (px 16) zero
                , Style.padding3
                ]
            ]
            [ img [ Asset.src Asset.logo, css [ Style.ml2, width <| px 32 ], alt "logo" ] []
            , span [ css [ Text.xl2, Style.ml2 ] ] [ text "TextUSM" ]
            ]
        , div [ css [ Text.sm, padding2 zero (px 16) ] ]
            [ text "TextUSM is a simple tool. Help you draw user story map using indented text."
            ]

        -- Text Syntax
        , section (Just "Text Syntax")
        , textActivityView
            [ activityView [ text "md: **Markdown Text**" ]
            , taskView [ indentedText "User Task" 1 ]
            , storyView [ indentedText "User Story Release 1" 2 ]
            , storyView [ indentedText "User Story Release 2..." 3 ]
            , storyView [ indentedText "Add Images" 4 ]
            , storyView [ indentedText "https://app.textusm.com/images/logo.svg" 5 ]
            , storyView [ indentedText "Change font size, font color or background color." 1 ]
            , storyView [ indentedText "test|{\"b\":\"#CEE5F2\",\"f\":\"#EE8A8B\",\"o\":[0,0],\"s\":9}" 2 ]
            ]

        -- Comment Syntax
        , section (Just "Comment Syntax")
        , textCommentView [ text "# Comment..." ]
        , textCommentView [ text "# backgroundColor: #FFFFFF" ]
        , textCommentView [ text "# zoom_control: true" ]
        , textCommentView [ text "# line_color: #FF0000" ]
        , textCommentView [ text "# line_size: 4" ]
        , textCommentView [ text "# toolbar: true" ]
        , textCommentView [ text "# card_foreground_color1: #FFFFFF" ]
        , textCommentView [ text "# card_foreground_color2: #FFFFFF" ]
        , textCommentView [ text "# card_foreground_color3: #333333" ]
        , textCommentView [ text "# card_background_color1: #266B9A" ]
        , textCommentView [ text "# card_background_color2: #3E9BCD" ]
        , textCommentView [ text "# card_background_color3: #FFFFFF" ]
        , textCommentView [ text "# canvas_background_color: #434343" ]
        , textCommentView [ text "# card_height: 120" ]
        , textCommentView [ text "# card_height: 70" ]
        , textCommentView [ text "# text_color: #111111" ]
        , textCommentView [ text "# font_size: 14" ]

        -- User Story Map Syntax
        , section (Just "User Story Map Syntax")
        , textCommentView [ text "# user_activities: Changed text" ]
        , textCommentView [ text "# user_tasks: Changed text" ]
        , textCommentView [ text "# user_stories: Changed text" ]
        , textCommentView [ text "# release1: Changed text" ]

        -- Free form
        , section (Just "Freeform")
        , textCommentView [ text "# Vertical line" ]
        , textView [ text "/" ]
        , textCommentView [ text "# Horizontal line" ]
        , textView [ text "---" ]
        , textCommentView [ text "# Item" ]
        , textView [ text "freeform" ]

        -- Use Case Diagram
        , section (Just "Use Case Diagram Syntax")
        , textActivityView [ text "[Actor Name]" ]
        , textView [ indentedText "Use Caser" 1 ]
        , textView [ indentedText "Use Case2" 1 ]
        , textActivityView [ text "(Use Case Name1)" ]
        , textView [ indentedText "<extend" 1 ]
        , textView [ indentedText ">include" 1 ]
        , textActivityView [ text "(Use Case Name2)" ]
        , textView [ indentedText "<extend" 1 ]
        , textView [ indentedText ">include" 1 ]

        -- Gantt Chart
        , section (Just "Gantt Chart Syntax")
        , textActivityView [ text "YYYY-MM-DD YYYY-MM-DD" ]
        , textView [ indentedText "Section" 1 ]
        , textView [ indentedText "Task" 2 ]
        , textView [ indentedText "YYYY-MM-DD YYYY-MM-DD" 3 ]

        -- ER Diagram
        , section (Just "ER Diagram Syntax")

        -- relations
        , textActivityView [ text "relations" ]
        , textCommentView [ indentedText "# one to one" 1 ]
        , textView [ indentedText "table1 - table2" 1 ]
        , textCommentView [ indentedText "# one to many" 1 ]
        , textView [ indentedText "table1 < table2" 1 ]
        , textCommentView [ indentedText "# meny to many" 1 ]
        , textView [ indentedText "table1 = table2" 1 ]

        -- tables
        , textActivityView [ text "tables" ]
        , textTaskStyle [ indentedText "table1" 1 ]
        , textView [ indentedText "id int pk auto_increment" 2 ]
        , textView [ indentedText "name varchar(255) unique" 2 ]
        , textView [ indentedText "json json null" 2 ]
        , textView [ indentedText "value double not null" 2 ]
        , textView [ indentedText "enum enum(value1,value2) not null" 2 ]

        -- Hot Keys
        , section (Just "Hotkeys")
        , div
            [ css
                [ displayFlex
                , Text.base
                , flexDirection column
                , padding <| px 16
                ]
            ]
            [ div [ css [ Font.fontSemiBold, displayFlex ] ]
                [ itemView [ text "Windows" ]
                , itemView [ text "Mac" ]
                , itemView [ text "Action" ]
                ]
            , div [ css [ displayFlex ] ]
                [ itemView [ text "Ctrl+S" ]
                , itemView [ text "Command+S" ]
                , itemView [ text "Save" ]
                ]
            , div [ css [ displayFlex ] ]
                [ itemView [ text "Ctrl+O" ]
                , itemView [ text "Command+O" ]
                , itemView [ text "Open" ]
                ]
            ]
        ]


activityView : List (Html msg) -> Html msg
activityView chlldren =
    div [ css [ Color.textActivity ] ] chlldren


indentedText : String -> Int -> Html msg
indentedText s indent =
    text <|
        (String.fromChar '\u{00A0}' |> String.repeat (4 * indent))
            ++ s


itemView : List (Html msg) -> Html msg
itemView children =
    div [ css [ width <| px 96, Text.sm, Style.flexCenter, border3 (px 1) solid Color.borderColor, Style.paddingSm ] ] children


section : Maybe String -> Html msg
section title =
    div
        [ css
            [ if isNothing title then
                Css.batch []

              else
                Css.batch [ borderTop3 (px 1) solid (hex "#323B46") ]
            , if isNothing title then
                Css.batch [ padding <| px 0 ]

              else
                Css.batch [ padding4 (px 32) zero (px 8) zero ]
            , Css.batch [ Font.fontSemiBold, borderBottom3 (px 1) solid (hex "#666666"), margin4 (px 8) (px 16) (px 8) (px 16) ]
            ]
        ]
        [ div [] [ text (title |> Maybe.withDefault "") ]
        ]


storyView : List (Html msg) -> Html msg
storyView children =
    div [ css [ color <| hex "#ffffff" ] ] children


taskView : List (Html msg) -> Html msg
taskView children =
    div [ css [ Color.textAccent ] ] children


textActivityView : List (Html msg) -> Html msg
textActivityView children =
    div [ css [ Text.base, Color.textActivity, padding3 zero (px 16) zero ] ] children


textCommentView : List (Html msg) -> Html msg
textCommentView children =
    div [ css [ Text.base, Color.textComment, padding3 zero (px 16) zero ] ] children


textTaskStyle : List (Html msg) -> Html msg
textTaskStyle children =
    div [ css [ Text.base, Color.textAccent, padding3 zero (px 16) zero ] ] children


textView : List (Html msg) -> Html msg
textView children =
    div [ css [ Text.base, padding3 zero (px 16) zero ] ] children

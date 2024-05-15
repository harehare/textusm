module Page.Help exposing (view)

import Asset
import Constants
import Css
import Html.Styled exposing (Html, div, img, span, text)
import Html.Styled.Attributes as Attr
import Maybe.Extra exposing (isNothing)
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text
import Types.Hotkey as Hotkey


view : Html msg
view =
    div
        [ Attr.css [ Text.xs, Color.bgDefault, Style.widthFull, Color.textColor, Css.overflowX Css.hidden ]
        ]
        [ div
            [ Attr.css
                [ Font.fontSemiBold
                , Css.displayFlex
                , Css.alignItems Css.center
                , Css.justifyContent Css.flexStart
                , Css.padding2 (Css.px 16) Css.zero
                , Style.padding3
                ]
            ]
            [ img [ Asset.src Asset.logo, Attr.css [ Style.ml2, Css.width <| Css.px 32 ], Attr.alt "logo" ] []
            , span [ Attr.css [ Text.xl2, Style.ml2 ] ] [ text "TextUSM" ]
            ]
        , div [ Attr.css [ Text.sm, Css.padding2 Css.zero (Css.px 16) ] ]
            [ text "TextUSM is a simple tool. Help you draw user story map using indented text."
            ]

        -- Text Syntax
        , section (Just "Text Syntax")
        , textActivityView
            [ activityView [ text <| Constants.markdownPrefix ++ "**Markdown Text**" ]
            , taskView [ indentedText "User Task" 1 ]
            , storyView [ indentedText "User Story Release 1" 2 ]
            , storyView [ indentedText "User Story Release 2..." 3 ]
            , storyView [ indentedText "Add Images" 4 ]
            , storyView [ indentedText (Constants.imagePrefix ++ "https://app.textusm.com/images/logo.svg") 5 ]
            , storyView [ indentedText "Change font size, font color or background color." 1 ]
            , storyView [ indentedText "test: |{\"bg\":\"#CEE5F2\",\"fg\":\"#EE8A8B\",\"pos\":[0,0],\"font_size\":9}" 2 ]
            ]

        -- Comment Syntax
        , section (Just "Comment Syntax")
        , textCommentView [ text <| Constants.commentPrefix ++ " Comment..." ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " backgroundColor: #FFFFFF" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " background_image: https://app.textusm.com/images/logo.svg" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " zoom_control: true" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " line_color: #FF0000" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " line_size: 4" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " toolbar: true" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " card_foreground_color1: #FFFFFF" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " card_foreground_color2: #FFFFFF" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " card_foreground_color3: #333333" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " card_background_color1: #266B9A" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " card_background_color2: #3E9BCD" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " card_background_color3: #FFFFFF" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " canvas_background_color: #434343" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " card_height: 120" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " card_height: 70" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " text_color: #111111" ]
        , textPropertyView [ text <| Constants.commentPrefix ++ " font_size: 14" ]

        -- User Story Map Syntax
        , section (Just "User Story Map Syntax")
        , textCommentView [ text <| Constants.commentPrefix ++ " user_activities: Changed text" ]
        , textCommentView [ text <| Constants.commentPrefix ++ " user_tasks: Changed text" ]
        , textCommentView [ text <| Constants.commentPrefix ++ " user_stories: Changed text" ]
        , textCommentView [ text <| Constants.commentPrefix ++ " release1: Changed text" ]

        -- Free form
        , section (Just "Freeform")
        , textCommentView [ text <| Constants.commentPrefix ++ " Vertical line" ]
        , textView [ text "/" ]
        , textCommentView [ text <| Constants.commentPrefix ++ " Horizontal line" ]
        , textView [ text "---" ]
        , textCommentView [ text <| Constants.commentPrefix ++ " Item" ]
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
        , textCommentView [ indentedText (Constants.commentPrefix ++ " one to one") 1 ]
        , textView [ indentedText "table1 - table2" 1 ]
        , textCommentView [ indentedText (Constants.commentPrefix ++ " one to many") 1 ]
        , textView [ indentedText "table1 < table2" 1 ]
        , textCommentView [ indentedText (Constants.commentPrefix ++ " meny to many") 1 ]
        , textView [ indentedText "table1 = table2" 1 ]

        -- tables
        , textActivityView [ text "tables" ]
        , textTaskStyle [ indentedText "table1" 1 ]
        , textView [ indentedText "id int pk auto_increment" 2 ]
        , textView [ indentedText "name varchar(255) unique" 2 ]
        , textView [ indentedText "json json null" 2 ]
        , textView [ indentedText "value double not null" 2 ]
        , textView [ indentedText "enum enum(value1,value2) not null" 2 ]

        -- Keyboard Layout
        , section (Just "Keyboard Layout Syntax")
        , textActivityView [ text "1u" ]
        , textView [ indentedText "!,1,1u" 1 ]
        , textView [ indentedText "@,2,1u,0.25u" 1 ]
        , textView [ indentedText "{sharp},3" 1 ]
        , textView [ indentedText "{comma},4" 1 ]

        -- Hot Keys
        , section (Just "Hotkeys")
        , div
            [ Attr.css
                [ Css.displayFlex
                , Text.base
                , Css.flexDirection Css.column
                , Css.padding <| Css.px 16
                ]
            ]
            [ div [ Attr.css [ Font.fontSemiBold, Css.displayFlex ] ]
                [ itemView [ text "Windows" ]
                , itemView [ text "Mac" ]
                , itemView [ text "Action" ]
                ]
            , div [ Attr.css [ Css.displayFlex ] ]
                [ itemView [ text <| Hotkey.toWindowsString Hotkey.save ]
                , itemView [ text <| Hotkey.toMacString Hotkey.save ]
                , itemView [ text "Save" ]
                ]
            , div [ Attr.css [ Css.displayFlex ] ]
                [ itemView [ text <| Hotkey.toWindowsString Hotkey.open ]
                , itemView [ text <| Hotkey.toMacString Hotkey.open ]
                , itemView [ text "Open" ]
                ]
            , div [ Attr.css [ Css.displayFlex ] ]
                [ itemView [ text <| Hotkey.toWindowsString Hotkey.select ]
                , itemView [ text <| Hotkey.toMacString Hotkey.select ]
                , itemView [ text "Select the card in the current row" ]
                ]
            ]
        ]


activityView : List (Html msg) -> Html msg
activityView chlldren =
    div [ Attr.css [ Color.textActivity ] ] chlldren


indentedText : String -> Int -> Html msg
indentedText s indent =
    text <|
        (String.fromChar '\u{00A0}' |> String.repeat (4 * indent))
            ++ s


itemView : List (Html msg) -> Html msg
itemView children =
    div [ Attr.css [ Css.width <| Css.px 96, Text.sm, Style.flexCenter, Css.border3 (Css.px 1) Css.solid Color.borderColor, Style.paddingSm ] ] children


section : Maybe String -> Html msg
section title =
    div
        [ Attr.css
            [ if isNothing title then
                Css.batch []

              else
                Css.batch [ Css.borderTop3 (Css.px 1) Css.solid (Css.hex "#323B46") ]
            , if isNothing title then
                Css.batch [ Css.padding <| Css.px 0 ]

              else
                Css.batch [ Css.padding4 (Css.px 32) Css.zero (Css.px 8) Css.zero ]
            , Css.batch [ Font.fontSemiBold, Css.borderBottom3 (Css.px 1) Css.solid (Css.hex "#666666"), Css.margin4 (Css.px 8) (Css.px 16) (Css.px 8) (Css.px 16) ]
            ]
        ]
        [ div [] [ text (title |> Maybe.withDefault "") ]
        ]


storyView : List (Html msg) -> Html msg
storyView children =
    div [ Attr.css [ Css.color <| Css.hex "#ffffff" ] ] children


taskView : List (Html msg) -> Html msg
taskView children =
    div [ Attr.css [ Color.textAccent ] ] children


textActivityView : List (Html msg) -> Html msg
textActivityView children =
    div [ Attr.css [ Text.base, Color.textActivity, Css.padding3 Css.zero (Css.px 16) Css.zero ] ] children


textCommentView : List (Html msg) -> Html msg
textCommentView children =
    div [ Attr.css [ Text.base, Color.textComment, Css.padding3 Css.zero (Css.px 16) Css.zero ] ] children


textPropertyView : List (Html msg) -> Html msg
textPropertyView children =
    div [ Attr.css [ Text.base, Color.textPropertyColor, Css.padding3 Css.zero (Css.px 16) Css.zero ] ] children


textTaskStyle : List (Html msg) -> Html msg
textTaskStyle children =
    div [ Attr.css [ Text.base, Color.textAccent, Css.padding3 Css.zero (Css.px 16) Css.zero ] ] children


textView : List (Html msg) -> Html msg
textView children =
    div [ Attr.css [ Text.base, Css.padding3 Css.zero (Css.px 16) Css.zero ] ] children

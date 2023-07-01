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
import Html.Styled.Attributes as Attr
import Maybe.Extra exposing (isNothing)
import Models.Hotkey as Hotkey
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text


view : Html msg
view =
    div
        [ Attr.css [ Text.xs, Color.bgDefault, Style.widthFull, Color.textColor, overflowX hidden ]
        ]
        [ div
            [ Attr.css
                [ Font.fontSemiBold
                , displayFlex
                , alignItems center
                , justifyContent flexStart
                , padding2 (px 16) zero
                , Style.padding3
                ]
            ]
            [ img [ Asset.src Asset.logo, Attr.css [ Style.ml2, width <| px 32 ], Attr.alt "logo" ] []
            , span [ Attr.css [ Text.xl2, Style.ml2 ] ] [ text "TextUSM" ]
            ]
        , div [ Attr.css [ Text.sm, padding2 zero (px 16) ] ]
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
            , storyView [ indentedText "image:https://app.textusm.com/images/logo.svg" 5 ]
            , storyView [ indentedText "Change font size, font color or background color." 1 ]
            , storyView [ indentedText "test|{\"bg\":\"#CEE5F2\",\"fg\":\"#EE8A8B\",\"pos\":[0,0],\"font_size\":9}" 2 ]
            ]

        -- Comment Syntax
        , section (Just "Comment Syntax")
        , textCommentView [ text "# Comment..." ]
        , textPropertyView [ text "# backgroundColor: #FFFFFF" ]
        , textPropertyView [ text "# background_image: https://app.textusm.com/images/logo.svg" ]
        , textPropertyView [ text "# zoom_control: true" ]
        , textPropertyView [ text "# line_color: #FF0000" ]
        , textPropertyView [ text "# line_size: 4" ]
        , textPropertyView [ text "# toolbar: true" ]
        , textPropertyView [ text "# card_foreground_color1: #FFFFFF" ]
        , textPropertyView [ text "# card_foreground_color2: #FFFFFF" ]
        , textPropertyView [ text "# card_foreground_color3: #333333" ]
        , textPropertyView [ text "# card_background_color1: #266B9A" ]
        , textPropertyView [ text "# card_background_color2: #3E9BCD" ]
        , textPropertyView [ text "# card_background_color3: #FFFFFF" ]
        , textPropertyView [ text "# canvas_background_color: #434343" ]
        , textPropertyView [ text "# card_height: 120" ]
        , textPropertyView [ text "# card_height: 70" ]
        , textPropertyView [ text "# text_color: #111111" ]
        , textPropertyView [ text "# font_size: 14" ]

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
                [ displayFlex
                , Text.base
                , flexDirection column
                , padding <| px 16
                ]
            ]
            [ div [ Attr.css [ Font.fontSemiBold, displayFlex ] ]
                [ itemView [ text "Windows" ]
                , itemView [ text "Mac" ]
                , itemView [ text "Action" ]
                ]
            , div [ Attr.css [ displayFlex ] ]
                [ itemView [ text <| Hotkey.toWindowsString Hotkey.save ]
                , itemView [ text <| Hotkey.toMacString Hotkey.save ]
                , itemView [ text "Save" ]
                ]
            , div [ Attr.css [ displayFlex ] ]
                [ itemView [ text <| Hotkey.toWindowsString Hotkey.open ]
                , itemView [ text <| Hotkey.toMacString Hotkey.open ]
                , itemView [ text "Open" ]
                ]
            , div [ Attr.css [ displayFlex ] ]
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
    div [ Attr.css [ width <| px 96, Text.sm, Style.flexCenter, border3 (px 1) solid Color.borderColor, Style.paddingSm ] ] children


section : Maybe String -> Html msg
section title =
    div
        [ Attr.css
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
    div [ Attr.css [ color <| hex "#ffffff" ] ] children


taskView : List (Html msg) -> Html msg
taskView children =
    div [ Attr.css [ Color.textAccent ] ] children


textActivityView : List (Html msg) -> Html msg
textActivityView children =
    div [ Attr.css [ Text.base, Color.textActivity, padding3 zero (px 16) zero ] ] children


textCommentView : List (Html msg) -> Html msg
textCommentView children =
    div [ Attr.css [ Text.base, Color.textComment, padding3 zero (px 16) zero ] ] children


textPropertyView : List (Html msg) -> Html msg
textPropertyView children =
    div [ Attr.css [ Text.base, Color.textPropertyColor, padding3 zero (px 16) zero ] ] children


textTaskStyle : List (Html msg) -> Html msg
textTaskStyle children =
    div [ Attr.css [ Text.base, Color.textAccent, padding3 zero (px 16) zero ] ] children


textView : List (Html msg) -> Html msg
textView children =
    div [ Attr.css [ Text.base, padding3 zero (px 16) zero ] ] children

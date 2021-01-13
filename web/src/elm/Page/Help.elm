module Page.Help exposing (view)

import Asset
import Html exposing (Html, div, img, span, text)
import Html.Attributes exposing (alt, class, src, style)
import Maybe.Extra exposing (isNothing)


view : Html msg
view =
    div
        [ class "help"
        ]
        [ div
            [ style "font-weight" "600"
            , style "padding" "16px"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "flex-start"
            ]
            [ span [ style "margin-right" "2px" ] [ text "ABOUT" ]
            , span [ style "margin-left" "2px" ] [ text "Text" ]
            , img [ Asset.src Asset.logo, style "width" "32px", alt "logo" ] []
            , span [ style "margin-left" "2px" ] [ text "USM" ]
            ]
        , div [ class "text", style "padding" "0 16px 16px" ]
            [ text "TextUSM is a simple tool. Help you draw user story map using indented text."
            ]
        , section (Just "Text Syntax")
        , div [ class "text activity", style "padding" "0 16px 16px" ]
            [ div [ class "activity" ] [ text "md: **Markdown Text**" ]
            , div [ class "task" ]
                [ text <|
                    (String.fromChar '\u{00A0}' |> String.repeat 4)
                        ++ "User Task"
                ]
            , div [ class "story" ]
                [ text <|
                    (String.fromChar '\u{00A0}' |> String.repeat 8)
                        ++ "User Story Release 1"
                ]
            , div [ class "story" ]
                [ text <|
                    (String.fromChar '\u{00A0}' |> String.repeat 12)
                        ++ "User Story Release 2..."
                ]
            , div [ class "story" ]
                [ text <|
                    (String.fromChar '\u{00A0}' |> String.repeat 16)
                        ++ "Add Images"
                ]
            , div [ class "story" ]
                [ text <|
                    (String.fromChar '\u{00A0}' |> String.repeat 20)
                        ++ "https://app.textusm.com/images/logo.svg"
                ]
            , div [ class "story" ]
                [ text <|
                    (String.fromChar '\u{00A0}' |> String.repeat 4)
                        ++ "Change font size, font color or background color."
                ]
            , div [ class "story" ]
                [ text <|
                    (String.fromChar '\u{00A0}' |> String.repeat 8)
                        ++ "test|{\"b\":\"#CEE5F2\",\"f\":\"#EE8A8B\",\"o\":[0,0],\"s\":9}"
                ]
            ]
        , section (Just "Comment Syntax")
        , div [ class "text comment", style "padding" "0 16px 16px" ]
            [ text "# Comment..."
            ]
        , section (Just "User Story Map Syntax")
        , div [ class "text comment", style "padding" "0 16px 8px" ]
            [ text "# user_activities: Changed text"
            ]
        , div [ class "text comment", style "padding" "0 16px 8px" ]
            [ text "# user_tasks: Changed text"
            ]
        , div [ class "text comment", style "padding" "0 16px 8px" ]
            [ text "# user_stories: Changed text"
            ]
        , div [ class "text comment", style "padding" "0 16px 8px" ]
            [ text "# release1: Changed text"
            ]
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
            style "padding" "16px"
        , style "font-weight" "400"
        ]
        [ div [] [ text (title |> Maybe.withDefault "") ]
        ]

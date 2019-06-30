module Views.Settings exposing (view)

import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, style, value)
import Html.Events exposing (onInput)
import Maybe.Extra exposing (isNothing)
import Models.Model exposing (Msg(..), Settings)


view : Settings -> Html Msg
view settings =
    div
        [ class "settings"
        ]
        [ div
            [ style "font-weight" "400"
            , style "padding" "16px"
            ]
            [ text "SETTINGS" ]
        , section (Just "Basic")
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Font Family" ]
                , div [ class "input-area" ]
                    [ input
                        [ value settings.font
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    { settings | font = x }
                                )
                            )
                        ]
                        []
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Background color" ]
                , div [ class "input-area" ]
                    [ input
                        [ value settings.storyMap.backgroundColor
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        storyMap =
                                            settings.storyMap

                                        newStoryMap =
                                            { storyMap | backgroundColor = x }
                                    in
                                    { settings | storyMap = newStoryMap }
                                )
                            )
                        ]
                        []
                    ]
                ]
            ]
        , section (Just "Card Size")
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Card Width" ]
                , div [ class "input-area" ]
                    [ input
                        [ value (String.fromInt settings.storyMap.size.width)
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        storyMap =
                                            settings.storyMap

                                        size =
                                            storyMap.size

                                        newSize =
                                            { size | width = String.toInt x |> Maybe.withDefault 150 }

                                        newStoryMap =
                                            { storyMap | size = newSize }
                                    in
                                    { settings | storyMap = newStoryMap }
                                )
                            )
                        ]
                        []
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Card Height" ]
                , div [ class "input-area" ]
                    [ input
                        [ value (String.fromInt settings.storyMap.size.height)
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        storyMap =
                                            settings.storyMap

                                        size =
                                            storyMap.size

                                        newSize =
                                            { size | height = String.toInt x |> Maybe.withDefault 45 }

                                        newStoryMap =
                                            { storyMap | size = newSize }
                                    in
                                    { settings | storyMap = newStoryMap }
                                )
                            )
                        ]
                        []
                    ]
                ]
            ]
        , section (Just "Story Map Color")
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Background for User Activity" ]
                , div [ class "input-area" ]
                    [ input
                        [ value settings.storyMap.color.activity.backgroundColor
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        storyMap =
                                            settings.storyMap

                                        color =
                                            storyMap.color

                                        activity =
                                            color.activity

                                        newActivity =
                                            { activity | backgroundColor = x }

                                        newColor =
                                            { color | activity = newActivity }

                                        newStoryMap =
                                            { storyMap | color = newColor }
                                    in
                                    { settings | storyMap = newStoryMap }
                                )
                            )
                        ]
                        []
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Foreground for User Activity" ]
                , div [ class "input-area" ]
                    [ input
                        [ value settings.storyMap.color.activity.color
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        storyMap =
                                            settings.storyMap

                                        color =
                                            storyMap.color

                                        activity =
                                            color.activity

                                        newActivity =
                                            { activity | color = x }

                                        newColor =
                                            { color | activity = newActivity }

                                        newStoryMap =
                                            { storyMap | color = newColor }
                                    in
                                    { settings | storyMap = newStoryMap }
                                )
                            )
                        ]
                        []
                    ]
                ]
            ]
        , section Nothing
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Background for User Task" ]
                , div [ class "input-area" ]
                    [ input
                        [ value settings.storyMap.color.task.backgroundColor
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        storyMap =
                                            settings.storyMap

                                        color =
                                            storyMap.color

                                        task =
                                            color.task

                                        newTask =
                                            { task | backgroundColor = x }

                                        newColor =
                                            { color | task = newTask }

                                        newStoryMap =
                                            { storyMap | color = newColor }
                                    in
                                    { settings | storyMap = newStoryMap }
                                )
                            )
                        ]
                        []
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Foreground for User Task" ]
                , div [ class "input-area" ]
                    [ input
                        [ value settings.storyMap.color.task.color
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        storyMap =
                                            settings.storyMap

                                        color =
                                            storyMap.color

                                        task =
                                            color.task

                                        newTask =
                                            { task | color = x }

                                        newColor =
                                            { color | task = newTask }

                                        newStoryMap =
                                            { storyMap | color = newColor }
                                    in
                                    { settings | storyMap = newStoryMap }
                                )
                            )
                        ]
                        []
                    ]
                ]
            ]
        , section Nothing
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Background for User Story" ]
                , div [ class "input-area" ]
                    [ input
                        [ value settings.storyMap.color.story.backgroundColor
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        storyMap =
                                            settings.storyMap

                                        color =
                                            storyMap.color

                                        story =
                                            color.story

                                        newStory =
                                            { story | backgroundColor = x }

                                        newColor =
                                            { color | story = newStory }

                                        newStoryMap =
                                            { storyMap | color = newColor }
                                    in
                                    { settings | storyMap = newStoryMap }
                                )
                            )
                        ]
                        []
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Foreground for User Story" ]
                , div [ class "input-area" ]
                    [ input
                        [ value settings.storyMap.color.story.color
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        storyMap =
                                            settings.storyMap

                                        color =
                                            storyMap.color

                                        story =
                                            color.story

                                        newStory =
                                            { story | color = x }

                                        newColor =
                                            { color | story = newStory }

                                        newStoryMap =
                                            { storyMap | color = newColor }
                                    in
                                    { settings | storyMap = newStoryMap }
                                )
                            )
                        ]
                        []
                    ]
                ]
            ]
        , section Nothing
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Background for Comment" ]
                , div [ class "input-area" ]
                    [ input
                        [ value settings.storyMap.color.comment.backgroundColor
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        storyMap =
                                            settings.storyMap

                                        color =
                                            storyMap.color

                                        comment =
                                            color.comment

                                        newComment =
                                            { comment | backgroundColor = x }

                                        newColor =
                                            { color | story = newComment }

                                        newStoryMap =
                                            { storyMap | color = newColor }
                                    in
                                    { settings | storyMap = newStoryMap }
                                )
                            )
                        ]
                        []
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Foreground for Comment" ]
                , div [ class "input-area" ]
                    [ input
                        [ value settings.storyMap.color.comment.color
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        storyMap =
                                            settings.storyMap

                                        color =
                                            storyMap.color

                                        comment =
                                            color.comment

                                        newComment =
                                            { comment | color = x }

                                        newColor =
                                            { color | story = newComment }

                                        newStoryMap =
                                            { storyMap | color = newColor }
                                    in
                                    { settings | storyMap = newStoryMap }
                                )
                            )
                        ]
                        []
                    ]
                ]
            ]
        , section Nothing
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Line Color" ]
                , div [ class "input-area" ]
                    [ input
                        [ value settings.storyMap.color.line
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        storyMap =
                                            settings.storyMap

                                        color =
                                            storyMap.color

                                        newColor =
                                            { color | line = x }

                                        newStoryMap =
                                            { storyMap | color = newColor }
                                    in
                                    { settings | storyMap = newStoryMap }
                                )
                            )
                        ]
                        []
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Label Color" ]
                , div [ class "input-area" ]
                    [ input
                        [ value settings.storyMap.color.label
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        storyMap =
                                            settings.storyMap

                                        color =
                                            storyMap.color

                                        newColor =
                                            { color | label = x }

                                        newStoryMap =
                                            { storyMap | color = newColor }
                                    in
                                    { settings | storyMap = newStoryMap }
                                )
                            )
                        ]
                        []
                    ]
                ]
            ]
        , section (Just "GitHub")
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Owner" ]
                , div [ class "input-area" ]
                    [ input
                        [ value (Maybe.withDefault { owner = "", repo = "" } settings.github).owner
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        github =
                                            settings.github
                                                |> Maybe.withDefault { owner = "", repo = "" }

                                        newGithub =
                                            { github | owner = x }
                                    in
                                    { settings | github = Just newGithub }
                                )
                            )
                        ]
                        []
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Repository" ]
                , div [ class "input-area" ]
                    [ input
                        [ value (Maybe.withDefault { owner = "", repo = "" } settings.github).repo
                        , onInput
                            (UpdateSettings
                                (\x ->
                                    let
                                        github =
                                            settings.github
                                                |> Maybe.withDefault { owner = "", repo = "" }

                                        newGithub =
                                            { github | repo = x }
                                    in
                                    { settings | github = Just newGithub }
                                )
                            )
                        ]
                        []
                    ]
                ]
            ]
        ]


section : Maybe String -> Html Msg
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
        , style "margin" "0 0 16px 0px"
        ]
        [ div [] [ text (title |> Maybe.withDefault "") ]
        ]

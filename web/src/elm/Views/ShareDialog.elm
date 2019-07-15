module Views.ShareDialog exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events exposing (on, onClick, onInput)
import Json.Decode as Json
import Models.DiagramItem as DiagramItem exposing (DiagramUser)
import Models.Model exposing (Msg(..))
import Models.User as User exposing (User)
import Views.Icon as Icon


onChange : (String -> msg) -> Attribute msg
onChange handler =
    on "change" (Json.map handler Events.targetValue)


view : String -> Bool -> String -> User -> Maybe (List DiagramUser) -> Html Msg
view inputMail isOwner url user diagramUsers =
    div [ class "dialog-background" ]
        [ div [ class "dialog", style "padding" "16px" ]
            [ div [ class "title" ]
                ([ text "Sharing settings"
                 , link url
                 ]
                    ++ (if isOwner then
                            [ userList user diagramUsers
                            , invitePeople inputMail
                            , div [ style "margin" "8px" ]
                                [ button
                                    [ if String.isEmpty inputMail then
                                        class "disabled-button"

                                      else
                                        class "save-button"
                                    , style "padding" "8px"
                                    , style "margin-right" "16px"
                                    , if String.isEmpty inputMail then
                                        onClick NoOp

                                      else
                                        onClick InviteUser
                                    ]
                                    [ text "OK" ]
                                , button [ class "cancel-button", style "padding" "8px", onClick CancelSharing ] [ text "Close" ]
                                ]
                            ]

                        else
                            [ div [ style "margin" "8px" ]
                                [ button [ class "save-button", style "padding" "8px", onClick CancelSharing ] [ text "Close" ]
                                ]
                            ]
                       )
                )
            ]
        ]


link : String -> Html Msg
link url =
    div [ style "padding-top" "16px" ]
        [ div [ class "label" ] [ text "Link to share" ]
        , input
            [ class "input"
            , style "color" "#555"
            , style "width" "calc(100% - 40px)"
            , style "border" "1px solid #8C9FAE"
            , readonly True
            , value url
            , id "share-url"
            , onClick <| SelectAll "share-url"
            ]
            []
        ]


invitePeople : String -> Html Msg
invitePeople mail =
    div []
        [ div [ class "label", style "padding-top" "16px" ] [ text "Invite people" ]
        , input
            [ class "input"
            , style "color" "#555"
            , style "width" "calc(100% - 40px)"
            , style "border" "1px solid #8C9FAE"
            , value mail
            , placeholder "Enter email"
            , onInput EditInviteMail
            ]
            []
        ]


userList : User -> Maybe (List DiagramUser) -> Html Msg
userList loginUser users =
    div []
        [ div [ class "label", style "padding-top" "16px" ] [ text "Who has access" ]
        , case users of
            Just u ->
                div
                    [ style "max-height" "300px"
                    , style "overflow-x" "hidden"
                    , style "overflow-y" "auto"
                    , style "padding" "0 8px"
                    ]
                    (userRow Nothing loginUser.displayName loginUser.photoURL loginUser.email "Owner"
                        :: List.map
                            (\x ->
                                userRow (Just x.id) x.name x.photoURL x.mail x.role
                            )
                            u
                    )

            Nothing ->
                div [ style "padding" "0 8px" ]
                    [ userRow Nothing loginUser.displayName loginUser.photoURL loginUser.email "Owner"
                    ]
        ]


userRow : Maybe String -> String -> String -> String -> String -> Html Msg
userRow userId name photoURL mail role =
    div
        [ style "display" "flex"
        , style "align-items" "center"
        , style "padding" "8px 0 8px 0"
        , style "border-bottom" "1px solid #CCC"
        ]
        [ img
            [ src photoURL
            , style "width" "32px"
            , style "font-size" "0.9rem"
            , style "margin-right" "8px"
            ]
            []
        , div []
            [ div [ style "font-size" "0.9rem" ] [ text name ]
            , div
                [ style "font-size" "0.7rem"
                , style "color" "#555"
                ]
                [ text mail ]
            ]
        , if role == "Owner" then
            div
                [ style "margin-left" "auto"
                , style "font-size" "0.8rem"
                ]
                [ text "Owner" ]

          else
            select
                [ style "margin-left" "auto"
                , style "font-size" "0.8rem"
                , value role
                , onChange (UpdateRole (Maybe.withDefault "" userId))
                ]
                [ option
                    [ value "Viewer"
                    , if role == "Viewer" then
                        selected True

                      else
                        selected False
                    ]
                    [ text "Viewer" ]
                , option
                    [ value "Editor"
                    , if role == "Editor" then
                        selected True

                      else
                        selected False
                    ]
                    [ text "Editor" ]
                ]
        , if role == "Owner" then
            div [ style "margin" "0 16px", style "width" "24px" ] []

          else
            div
                [ style "margin" "0 16px"
                , style "cursor" "pointer"
                , onClick (DeleteUser (Maybe.withDefault "" userId))
                ]
                [ Icon.clear 18 ]
        ]

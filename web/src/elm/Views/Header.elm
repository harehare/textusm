module Views.Header exposing (view)

import Asset
import Avatar exposing (Avatar(..))
import Data.DiagramItem as DiagramItem exposing (DiagramItem)
import Data.LoginProvider as LoginProvider exposing (LoginProvider(..))
import Data.Session as Session exposing (Session)
import Data.Text as Text exposing (Text)
import Data.Title as Title exposing (Title)
import Events exposing (onKeyDown)
import Html exposing (Html, a, div, header, img, input, span, text)
import Html.Attributes exposing (alt, attribute, class, href, id, placeholder, src, style, value)
import Html.Events exposing (onBlur, onClick, onInput, stopPropagationOn)
import Json.Decode as D
import Maybe.Extra exposing (isJust)
import Models.Model as Page exposing (Menu(..), Msg(..), Page(..))
import Route exposing (Route(..))
import Translations exposing (Lang)
import Views.Empty as Empty
import Views.Icon as Icon
import Views.Menu as Menu


type alias Props =
    { session : Session
    , page : Page
    , title : Title
    , isFullscreen : Bool
    , currentDiagram : Maybe DiagramItem
    , menu : Maybe Menu
    , currentText : Text
    , lang : Lang
    }


view : Props -> Html Msg
view props =
    let
        isPublic =
            props.currentDiagram |> Maybe.withDefault DiagramItem.empty |> .isPublic
    in
    if props.isFullscreen then
        header [] []

    else
        header
            [ class "flex items-center w-screen bg-main"
            , style "height" "40px"
            ]
            [ div
                [ class "flex items-center w-full"
                , style "height" "40px"
                ]
                [ div
                    [ class "flex-center"
                    , style "width" "56px"
                    , style "height" "40px"
                    ]
                    [ a [ href "/", attribute "aria-label" "Top", style "margin-top" "8px" ] [ img [ Asset.src Asset.logo, style "width" "32px", style "height" "32px", alt "logo" ] [] ] ]
                , case props.page of
                    Page.Main ->
                        if Title.isEdit props.title then
                            input
                                [ id "title"
                                , class "title bg-main border-none font text-lg"
                                , style "padding" "2px"
                                , style "color" "#f4f4f4"
                                , value <| Title.toString props.title
                                , onInput EditTitle
                                , onBlur (EndEditTitle Events.keyEnter False)
                                , onKeyDown EndEditTitle
                                , placeholder "UNTITLED"
                                ]
                                []

                        else
                            div
                                [ class "title header-title"
                                , style "cursor" "pointer"
                                , onClick StartEditTitle
                                ]
                                [ text <| Title.toString props.title
                                , div
                                    [ style "margin-left" "8px" ]
                                    [ if Text.isChanged props.currentText then
                                        Icon.circle "#FEFEFE" 10

                                      else
                                        Empty.view
                                    ]
                                ]

                    Page.New ->
                        div [ class "title header-title" ] [ text "New" ]

                    Page.List ->
                        div [ class "title header-title" ] [ text "All" ]

                    Page.Settings ->
                        div [ class "title header-title" ] [ text "Settings" ]

                    Page.Help ->
                        div [ class "title header-title" ] [ text "Help" ]

                    Page.Tags _ ->
                        div [ class "title header-title" ] [ text "Tags" ]

                    Page.Share ->
                        div [ class "title header-title" ] [ text "Share" ]

                    _ ->
                        Empty.view
                ]
            , if isJust (Maybe.andThen .id props.currentDiagram) && (Maybe.map .isRemote props.currentDiagram |> Maybe.withDefault False) then
                div
                    [ class "button", onClick <| ChangePublicStatus (not isPublic) ]
                    [ if isPublic then
                        Icon.lockOpen "#F5F5F6" 17

                      else
                        Icon.lock "#F5F5F6" 17
                    , span [ class "bottom-tooltip" ]
                        [ span [ class "text" ]
                            [ text <|
                                if isPublic then
                                    Translations.toolPublic props.lang

                                else
                                    Translations.toolPrivate props.lang
                            ]
                        ]
                    ]

              else
                Empty.view
            , if isJust <| Maybe.andThen .id props.currentDiagram then
                a [ attribute "aria-label" "Tag", style "display" "flex", href <| Route.toString Route.Tag ]
                    [ div [ class "button" ]
                        [ Icon.tag 17
                        , span [ class "bottom-tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipTags props.lang ] ]
                        ]
                    ]

              else
                Empty.view
            , a [ attribute "aria-label" "Help", style "display" "flex", href <| Route.toString Route.Help ]
                [ div [ class "button" ]
                    [ Icon.helpOutline 20
                    , span [ class "bottom-tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipHelp props.lang ] ]
                    ]
                ]
            , a
                [ class "flex"
                , href <| Route.toString Route.SharingDiagram
                , attribute "aria-label" "Share"
                ]
                [ div [ class "button" ]
                    [ Icon.people 24
                    , span [ class "bottom-tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipShare props.lang ] ]
                    ]
                ]
            , if Session.isSignedIn props.session then
                let
                    user =
                        Session.getUser props.session
                in
                div
                    [ class "button"
                    , stopPropagationOn "click" (D.succeed ( OpenMenu HeaderMenu, True ))
                    ]
                    [ div
                        [ class "text-sm"
                        , style "padding" "0 8px"
                        , style "margin-right" "4px"
                        ]
                        [ img
                            [ Avatar.src <| Avatar (Maybe.map .email user) (Maybe.map .photoURL user)
                            , class "avatar"
                            , alt "avatar"
                            ]
                            []
                        , case props.menu of
                            Just HeaderMenu ->
                                Menu.menu (Just "36px")
                                    Nothing
                                    Nothing
                                    (Just "5px")
                                    [ Menu.Item
                                        { e = NoOp
                                        , title = Maybe.map .email user |> Maybe.withDefault ""
                                        }
                                    , Menu.Item
                                        { e = SignOut
                                        , title = "SIGN OUT"
                                        }
                                    ]

                            _ ->
                                Empty.view
                        ]
                    ]

              else
                div
                    [ class "button m-2"
                    , stopPropagationOn "click" (D.succeed ( OpenMenu LoginMenu, True ))
                    ]
                    [ div [ style "width" "70px" ] [ text "SIGN IN" ]
                    , case props.menu of
                        Just LoginMenu ->
                            Menu.menu (Just "30px")
                                Nothing
                                Nothing
                                (Just "5px")
                                [ Menu.Item
                                    { e = SignIn Google
                                    , title = LoginProvider.toString Google
                                    }
                                , Menu.Item
                                    { e = SignIn Github
                                    , title = LoginProvider.toString Github
                                    }
                                ]

                        _ ->
                            Empty.view
                    ]
            ]

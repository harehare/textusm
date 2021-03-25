module Views.Header exposing (view)

import Asset
import Avatar exposing (Avatar(..))
import Constants
import Data.DiagramItem as DiagramItem exposing (DiagramItem)
import Data.LoginProvider as LoginProvider exposing (LoginProvider(..))
import Data.Session as Session exposing (Session)
import Data.Text as Text exposing (Text)
import Data.Title as Title exposing (Title)
import Events exposing (onKeyDown)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
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
    , route : Route
    }


view : Props -> Html Msg
view props =
    let
        isPublic =
            props.currentDiagram |> Maybe.withDefault DiagramItem.empty |> .isPublic

        canEdit =
            case props.route of
                ViewFile _ _ ->
                    False

                _ ->
                    True

        isRemoteDiagram =
            props.currentDiagram
                |> Maybe.withDefault DiagramItem.empty
                |> .isRemote

        canShare =
            Session.isSignedIn props.session && isRemoteDiagram && canEdit
    in
    if props.isFullscreen then
        Html.header [] []

    else
        Html.header
            [ Attr.class "flex items-center w-screen bg-main"
            , Attr.style "height" "40px"
            ]
            [ Html.div
                [ Attr.class "flex items-center w-full"
                , Attr.style "height" "40px"
                ]
                [ Html.div
                    [ Attr.class "flex-center"
                    , Attr.style "width" "40px"
                    , Attr.style "height" "40px"
                    ]
                    [ Html.a [ Attr.href "/", Attr.attribute "aria-label" "Top" ] [ Html.img [ Asset.src Asset.logo, Attr.style "width" "32px", Attr.style "height" "32px", Attr.alt "logo" ] [] ] ]
                , case props.page of
                    Page.Main ->
                        if canEdit && Title.isEdit props.title then
                            Html.input
                                [ Attr.id "title"
                                , Attr.class "title bg-main border-none font text-base font-bold"
                                , Attr.style "padding" "2px"
                                , Attr.style "margin-left" "8px"
                                , Attr.style "color" "#f4f4f4"
                                , Attr.value <| Title.toString props.title
                                , Events.onInput EditTitle
                                , Events.onBlur (EndEditTitle Events.keyEnter False)
                                , onKeyDown EndEditTitle
                                , Attr.placeholder "UNTITLED"
                                ]
                                []

                        else
                            Html.div
                                [ Attr.class "title header-title"
                                , Attr.style "cursor" "pointer"
                                , Events.onClick StartEditTitle
                                ]
                                [ Html.text <| Title.toString props.title
                                , Html.div
                                    [ Attr.style "margin-left" "8px" ]
                                    [ if canEdit && Text.isChanged props.currentText then
                                        Icon.circle "#FEFEFE" 10

                                      else
                                        Empty.view
                                    ]
                                ]

                    Page.New ->
                        Html.div [ Attr.class "title header-title" ] [ Html.text "New Diagram" ]

                    Page.List ->
                        Html.div [ Attr.class "title header-title" ] [ Html.text "All Diagrams" ]

                    Page.Settings ->
                        Html.div [ Attr.class "title header-title" ] [ Html.text "Settings" ]

                    Page.Help ->
                        Html.div [ Attr.class "title header-title" ] [ Html.text "Help" ]

                    Page.Tags _ ->
                        Html.div [ Attr.class "title header-title" ] [ Html.text "Tags" ]

                    Page.Share ->
                        Html.div [ Attr.class "title header-title" ] [ Html.text "Share" ]

                    _ ->
                        Empty.view
                ]
            , if (isJust (Maybe.andThen .id props.currentDiagram) && (Maybe.map .isRemote props.currentDiagram |> Maybe.withDefault False)) && canEdit then
                Html.div
                    [ Attr.class "button", Events.onClick <| ChangePublicStatus (not isPublic) ]
                    [ if isPublic then
                        Icon.lockOpen "#F5F5F6" 14

                      else
                        Icon.lock "#F5F5F6" 14
                    , Html.span [ Attr.class "bottom-tooltip" ]
                        [ Html.span [ Attr.class "text" ]
                            [ Html.text <|
                                if isPublic then
                                    Translations.toolPublic props.lang

                                else
                                    Translations.toolPrivate props.lang
                            ]
                        ]
                    ]

              else
                Html.div [ Attr.class "button" ]
                    [ Icon.lock Constants.disabledIconColor 14
                    , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Translations.toolPrivate props.lang ] ]
                    ]
            , if (isJust <| Maybe.andThen .id props.currentDiagram) && canEdit then
                Html.a [ Attr.attribute "aria-label" "Tag", Attr.style "display" "flex", Attr.href <| Route.toString Route.Tag ]
                    [ Html.div [ Attr.class "button" ]
                        [ Icon.tag Constants.iconColor 14
                        , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Translations.toolTipTags props.lang ] ]
                        ]
                    ]

              else
                Html.div [ Attr.class "button" ]
                    [ Icon.tag Constants.disabledIconColor 14
                    , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Translations.toolTipTags props.lang ] ]
                    ]
            , Html.a [ Attr.attribute "aria-label" "Help", Attr.style "display" "flex", Attr.href <| Route.toString Route.Help ]
                [ Html.div [ Attr.class "button" ]
                    [ Icon.helpOutline 16
                    , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Translations.toolTipHelp props.lang ] ]
                    ]
                ]
            , if canShare then
                Html.a
                    [ Attr.class "flex"
                    , Attr.href <| Route.toString Route.Share
                    , Attr.attribute "aria-label" "Share"
                    ]
                    [ Html.div [ Attr.class "button" ]
                        [ Icon.people Constants.iconColor 20
                        , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Translations.toolTipShare props.lang ] ]
                        ]
                    ]

              else
                Html.div [ Attr.class "button" ]
                    [ Icon.people Constants.disabledIconColor 20
                    , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Translations.toolTipShare props.lang ] ]
                    ]
            , if Session.isSignedIn props.session then
                let
                    user =
                        Session.getUser props.session
                in
                Html.div
                    [ Attr.class "button"
                    , Events.stopPropagationOn "click" (D.succeed ( OpenMenu HeaderMenu, True ))
                    ]
                    [ Html.div
                        [ Attr.class "text-sm"
                        , Attr.style "padding" "0 8px"
                        , Attr.style "margin-right" "4px"
                        ]
                        [ Html.img
                            [ Avatar.src <| Avatar (Maybe.map .email user) (Maybe.map .photoURL user)
                            , Attr.class "avatar"
                            , Attr.alt "avatar"
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
                Html.div
                    [ Attr.class "button m-2"
                    , Events.stopPropagationOn "click" (D.succeed ( OpenMenu LoginMenu, True ))
                    ]
                    [ Html.div [ Attr.style "width" "70px", Attr.class "text-base font-bold" ] [ Html.text "SIGN IN" ]
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

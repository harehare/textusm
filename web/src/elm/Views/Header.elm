module Views.Header exposing (view)

import Asset
import Avatar exposing (Avatar(..))
import Constants
import Events as E
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as D
import Maybe.Extra exposing (isJust)
import Message exposing (Lang)
import Models.Model exposing (Menu(..), Msg(..))
import Models.Page as Page exposing (Page)
import Route exposing (Route(..))
import Types.DiagramItem as DiagramItem exposing (DiagramItem)
import Types.DiagramLocation as DiagramLocation
import Types.DiagramType as DiagramType
import Types.LoginProvider as LoginProvider exposing (LoginProvider(..))
import Types.Session as Session exposing (Session)
import Types.Text as Text exposing (Text)
import Types.Title as Title exposing (Title)
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
    , prevRoute : Maybe Route
    , isOnline : Bool
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
            Maybe.andThen .location props.currentDiagram
                |> Maybe.map DiagramLocation.isRemote
                |> Maybe.withDefault False

        canShare =
            Session.isSignedIn props.session && isRemoteDiagram && canEdit && props.isOnline
    in
    if props.isFullscreen then
        Html.header [] []

    else
        Html.header
            [ Attr.class "flex items-center w-screen bg-main"
            , Attr.style "height" "40px"
            ]
            [ Html.div
                [ Attr.class "flex items-center lg:w-full w-1/2"
                , Attr.style "height" "40px"
                ]
                [ case props.page of
                    Page.Main ->
                        Html.div
                            [ Attr.class "flex-center"
                            , Attr.style "width" "32px"
                            , Attr.style "height" "32px"
                            ]
                            [ Html.a [ Attr.href "/", Attr.attribute "aria-label" "Top" ]
                                [ Html.img
                                    [ Asset.src Asset.logo
                                    , Attr.style "width" "28px"
                                    , Attr.style "height" "28px"
                                    , Attr.style "margin-left" "4px"
                                    , Attr.alt "logo"
                                    ]
                                    []
                                ]
                            ]

                    _ ->
                        case props.prevRoute of
                            Just r ->
                                Html.div
                                    [ Attr.class "flex-center"
                                    , Attr.style "padding" "8px 8px 8px 12px"
                                    , Attr.style "cursor" "pointer"
                                    , Events.onClick <| MoveTo r
                                    ]
                                    [ Icon.arrowLeft "#F5F5F6" 18 ]

                            Nothing ->
                                Html.div
                                    [ Attr.class "flex-center"
                                    , Attr.style "padding" "8px 8px 8px 12px"
                                    , Attr.style "cursor" "pointer"
                                    ]
                                    [ Icon.arrowLeft "#555" 18 ]
                , case props.page of
                    Page.Main ->
                        if canEdit && Title.isEdit props.title then
                            Html.input
                                [ Attr.id "title"
                                , Attr.class "w-full bg-main border-none font text-base font-bold"
                                , Attr.style "padding" "8px"
                                , Attr.style "margin-left" "8px"
                                , Attr.style "color" "#f4f4f4"
                                , Attr.value <| Title.toString props.title
                                , Events.onInput EditTitle
                                , Events.onBlur EndEditTitle
                                , E.onEnter EndEditTitle
                                , Attr.placeholder "UNTITLED"
                                ]
                                []

                        else
                            viewTitle
                                [ Attr.style "cursor" "pointer"
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
                        viewTitle [] [ Html.text "New Diagram" ]

                    Page.List ->
                        viewTitle [] [ Html.text "All Diagrams" ]

                    Page.Settings ->
                        viewTitle []
                            [ Html.text <|
                                case ( Session.isSignedIn props.session, props.currentDiagram ) of
                                    ( True, Just d ) ->
                                        DiagramType.toLongString d.diagram ++ " Settings"

                                    _ ->
                                        "Settings"
                            ]

                    Page.Help ->
                        viewTitle [] [ Html.text "Help" ]

                    _ ->
                        Empty.view
                ]
            , if (isJust (Maybe.andThen .id props.currentDiagram) && (Maybe.map .isRemote props.currentDiagram |> Maybe.withDefault False)) && canEdit && props.isOnline then
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
                                    Message.toolPublic props.lang

                                else
                                    Message.toolPrivate props.lang
                            ]
                        ]
                    ]

              else
                Html.div [ Attr.class "button" ]
                    [ Icon.lock Constants.disabledIconColor 14
                    , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolPrivate props.lang ] ]
                    ]
            , Html.a [ Attr.attribute "aria-label" "Help", Attr.style "display" "flex", Attr.href <| Route.toString Route.Help ]
                [ Html.div [ Attr.class "button" ]
                    [ Icon.helpOutline 16
                    , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipHelp props.lang ] ]
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
                        , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipShare props.lang ] ]
                        ]
                    ]

              else
                Html.div [ Attr.class "button" ]
                    [ Icon.people Constants.disabledIconColor 20
                    , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipShare props.lang ] ]
                    ]
            , if Session.isSignedIn props.session then
                let
                    user =
                        Session.getUser props.session
                in
                Html.div
                    [ Attr.class "button"
                    , Attr.style "width" "96px;"
                    , Attr.style "height" "50px"
                    , Events.stopPropagationOn "click" (D.succeed ( OpenMenu HeaderMenu, True ))
                    ]
                    [ Html.div
                        [ Attr.class "text-sm"
                        , Attr.style "margin-right" "4px"
                        ]
                        [ Html.img
                            [ Avatar.src <| Avatar (Maybe.map .email user) (Maybe.map .photoURL user)
                            , Attr.class "h-6 w-6 object-cover rounded-full lg:w-8 lg:h-8 h-full mt-xs"
                            , Attr.alt "avatar"
                            ]
                            []
                        , case props.menu of
                            Just HeaderMenu ->
                                let
                                    user_ =
                                        Maybe.andThen
                                            (\u ->
                                                if not <| String.isEmpty u.email then
                                                    Just u

                                                else
                                                    Nothing
                                            )
                                            user
                                in
                                Menu.menu (Just "36px")
                                    Nothing
                                    Nothing
                                    (Just "5px")
                                    (case user_ of
                                        Just u ->
                                            [ Menu.Item
                                                { e = NoOp
                                                , title = u.email
                                                }
                                            , Menu.Item
                                                { e = SignOut
                                                , title = "SIGN OUT"
                                                }
                                            ]

                                        Nothing ->
                                            [ Menu.Item
                                                { e = SignOut
                                                , title = "SIGN OUT"
                                                }
                                            ]
                                    )

                            _ ->
                                Empty.view
                        ]
                    ]

              else
                Html.div
                    [ Attr.class "button"
                    , Attr.style "width" "96px"
                    , Attr.style "height" "50px"
                    , Events.stopPropagationOn "click" (D.succeed ( OpenMenu LoginMenu, True ))
                    ]
                    [ Html.div [ Attr.class "text-base font-bold" ]
                        [ Html.text "SIGN IN" ]
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
                                    { e = SignIn <| Github Nothing
                                    , title = LoginProvider.toString <| Github Nothing
                                    }
                                ]

                        _ ->
                            Empty.view
                    ]
            ]


viewTitle : List (Html.Attribute msg) -> List (Html msg) -> Html msg
viewTitle attrs children =
    Html.div ([ Attr.class "w-full header-title", Attr.style "padding" "8px" ] ++ attrs) children

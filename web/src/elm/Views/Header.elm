module Views.Header exposing (view)

import Asset
import Avatar exposing (Avatar(..))
import Events as E
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Html.Lazy as Lazy
import Json.Decode as D
import Message exposing (Lang)
import Models.Color as Color
import Models.DiagramItem exposing (DiagramItem)
import Models.DiagramLocation as DiagramLocation
import Models.DiagramType as DiagramType
import Models.LoginProvider as LoginProvider exposing (LoginProvider(..))
import Models.Model exposing (Menu(..), Msg(..))
import Models.Page as Page exposing (Page)
import Models.Session as Session exposing (Session)
import Models.Text as Text exposing (Text)
import Models.Title as Title
import Route exposing (Route(..))
import Views.Empty as Empty
import Views.Icon as Icon
import Views.Menu as Menu


type alias Props =
    { session : Session
    , page : Page
    , currentDiagram : DiagramItem
    , menu : Maybe Menu
    , currentText : Text
    , lang : Lang
    , route : Route
    , prevRoute : Maybe Route
    , isOnline : Bool
    }


isRemoteDiagram : Props -> Bool
isRemoteDiagram props =
    props.currentDiagram.location
        |> Maybe.map DiagramLocation.isRemote
        |> Maybe.withDefault False


canShare : Props -> Bool
canShare props =
    Session.isSignedIn props.session && isRemoteDiagram props && canEdit props && props.isOnline


canEdit : Props -> Bool
canEdit props =
    case props.route of
        ViewFile _ _ ->
            False

        _ ->
            True


canChangePublicState : Props -> Bool
canChangePublicState props =
    case ( props.currentDiagram.id, props.currentDiagram.isRemote ) of
        ( Just _, True ) ->
            canEdit props && props.isOnline

        _ ->
            False


view : Props -> Html Msg
view props =
    Html.header
        [ Attr.class "flex items-center w-screen bg-main"
        , Attr.style "height" "40px"
        ]
        (Html.div
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
                                [ Icon.arrowLeft Color.iconColor 18 ]

                        Nothing ->
                            Html.div
                                [ Attr.class "flex-center"
                                , Attr.style "padding" "8px 8px 8px 12px"
                                , Attr.style "cursor" "pointer"
                                ]
                                [ Icon.arrowLeft Color.disabledIconColor 18 ]
            , case props.page of
                Page.Main ->
                    if canEdit props && Title.isEdit props.currentDiagram.title then
                        Html.input
                            [ Attr.id "title"
                            , Attr.class "w-full bg-main border-none font text-base font-bold"
                            , Attr.style "padding" "8px"
                            , Attr.style "margin-left" "8px"
                            , Attr.style "color" <| Color.toString Color.white2
                            , Attr.value <| Title.toString props.currentDiagram.title
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
                            [ Html.text <| Title.toString props.currentDiagram.title
                            , Html.div
                                [ Attr.style "margin-left" "8px" ]
                                [ if canEdit props && Text.isChanged props.currentText then
                                    Icon.circle Color.white 10

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
                            if Session.isSignedIn props.session then
                                DiagramType.toLongString props.currentDiagram.diagram ++ " Settings"

                            else
                                "Settings"
                        ]

                Page.Help ->
                    viewTitle [] [ Html.text "Help" ]

                _ ->
                    Empty.view
            ]
            :: (case props.route of
                    Route.New ->
                        [ Lazy.lazy viewHelpButton props.lang, Lazy.lazy2 viewSignInButton props.menu props.session ]

                    Route.Settings ->
                        [ Lazy.lazy viewHelpButton props.lang, Lazy.lazy2 viewSignInButton props.menu props.session ]

                    Route.DiagramList ->
                        [ Lazy.lazy viewHelpButton props.lang, Lazy.lazy2 viewSignInButton props.menu props.session ]

                    _ ->
                        [ Lazy.lazy3 viewChangePublicStateButton props.lang props.currentDiagram.isPublic (canChangePublicState props)
                        , Lazy.lazy viewHelpButton props.lang
                        , Lazy.lazy2 viewShareButton props.lang <| canShare props
                        , Lazy.lazy2 viewSignInButton props.menu props.session
                        ]
               )
        )


viewTitle : List (Html.Attribute msg) -> List (Html msg) -> Html msg
viewTitle attrs children =
    Html.div ([ Attr.class "w-full header-title", Attr.style "padding" "8px" ] ++ attrs) children


viewChangePublicStateButton : Lang -> Bool -> Bool -> Html Msg
viewChangePublicStateButton lang isPublic_ canChangePublicState_ =
    if canChangePublicState_ then
        Html.div
            [ Attr.class "button", Events.onClick <| ChangePublicStatus (not isPublic_) ]
            [ if isPublic_ then
                Icon.lockOpen Color.iconColor 14

              else
                Icon.lock Color.iconColor 14
            , Html.span [ Attr.class "bottom-tooltip" ]
                [ Html.span [ Attr.class "text" ]
                    [ Html.text <|
                        if isPublic_ then
                            Message.toolPublic lang

                        else
                            Message.toolPrivate lang
                    ]
                ]
            ]

    else
        Html.div [ Attr.class "button" ]
            [ Icon.lock Color.disabledIconColor 14
            , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolPrivate lang ] ]
            ]


viewHelpButton : Lang -> Html Msg
viewHelpButton lang =
    Html.a [ Attr.attribute "aria-label" "Help", Attr.style "display" "flex", Attr.href <| Route.toString Route.Help ]
        [ Html.div [ Attr.class "button" ]
            [ Icon.helpOutline 16
            , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipHelp lang ] ]
            ]
        ]


viewShareButton : Lang -> Bool -> Html Msg
viewShareButton lang canShare_ =
    if canShare_ then
        Html.a
            [ Attr.class "flex"
            , Attr.href <| Route.toString Route.Share
            , Attr.attribute "aria-label" "Share"
            ]
            [ Html.div [ Attr.class "button" ]
                [ Icon.people Color.iconColor 20
                , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipShare lang ] ]
                ]
            ]

    else
        Html.div [ Attr.class "button" ]
            [ Icon.people Color.disabledIconColor 20
            , Html.span [ Attr.class "bottom-tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipShare lang ] ]
            ]


viewSignInButton : Maybe Menu -> Session -> Html Msg
viewSignInButton menu session =
    if Session.isSignedIn session then
        let
            user =
                Session.getUser session
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
                    , Attr.class "h-5 w-5 object-cover rounded-full lg:w-7 lg:h-7 h-full mt-xs"
                    , Attr.alt "avatar"
                    ]
                    []
                , case menu of
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
            , case menu of
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

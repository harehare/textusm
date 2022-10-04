module Page.Settings exposing (Model, Msg(..), init, isFetchedUsableFont, load, update, view)

import Api.Http.UsableFontList as UsableFontListRequest
import Api.RequestError exposing (RequestError)
import Css
    exposing
        ( alignItems
        , borderTop3
        , calc
        , center
        , column
        , displayFlex
        , flexDirection
        , flexWrap
        , fontWeight
        , height
        , hex
        , int
        , justifyContent
        , margin4
        , marginBottom
        , maxWidth
        , minus
        , overflowY
        , padding
        , padding2
        , padding4
        , pct
        , px
        , scroll
        , solid
        , spaceBetween
        , vh
        , width
        , wrap
        , zero
        )
import Html.Styled exposing (Html, div, text)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick)
import Maybe.Extra exposing (isNothing)
import Message exposing (Lang)
import Models.Color as Color exposing (colors)
import Models.DiagramLocation as DiagramLocation
import Models.DiagramType exposing (DiagramType)
import Models.FontSize as FontSize
import Models.Session as Session exposing (Session)
import RemoteData exposing (isLoading)
import Return
import Settings
    exposing
        ( Settings
        , defaultEditorSettings
        , ofActivityBackgroundColor
        , ofActivityColor
        , ofBackgroundColor
        , ofFontSize
        , ofHeight
        , ofLabelColor
        , ofLineColor
        , ofShowLineNumber
        , ofStoryBackgroundColor
        , ofStoryColor
        , ofTaskBackgroundColor
        , ofTaskColor
        , ofTextColor
        , ofToolbar
        , ofWidth
        , ofWordWrap
        , ofZoomControl
        )
import Style.Breakpoint as Breakpoint
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text
import Task
import Views.DropDownList as DropDownList exposing (DropDownValue)
import Views.Switch as Switch


type alias FontList =
    List String


type alias Model =
    { dropDownIndex : Maybe String
    , diagramType : DiagramType
    , settings : Settings
    , session : Session
    , canUseNativeFileSystem : Bool
    , usableFontList : FontList
    , lang : Lang
    , isLoading : Bool
    }


type Msg
    = UpdateSettings (String -> Settings) String
    | ToggleDropDownList String
    | DropDownClose
    | UpdateUsableFontList (Result RequestError FontList)


loadUsableFontList :
    (Result RequestError FontList -> msg)
    -> Lang
    -> Return.ReturnF msg model
loadUsableFontList msg lang =
    UsableFontListRequest.usableFontList
        lang
        |> Task.attempt msg
        |> Return.command



-- loadUsableFontList UpdateUsableFontList (Message.langFromString "ja")


init : { canUseNativeFileSystem : Bool, diagramType : DiagramType, session : Session, settings : Settings, lang : Lang, usableFontList : Maybe FontList } -> Return.Return Msg Model
init { canUseNativeFileSystem, diagramType, session, settings, lang, usableFontList } =
    case usableFontList of
        Just fontList ->
            Return.singleton
                { dropDownIndex = Nothing
                , diagramType = diagramType
                , settings = settings
                , session = session
                , canUseNativeFileSystem = canUseNativeFileSystem
                , usableFontList = fontList
                , lang = lang
                , isLoading = False
                }

        Nothing ->
            Return.singleton
                { dropDownIndex = Nothing
                , diagramType = diagramType
                , settings = settings
                , session = session
                , canUseNativeFileSystem = canUseNativeFileSystem
                , usableFontList = [ settings.storyMap.font ]
                , lang = lang
                , isLoading = True
                }


load : DiagramType -> Model -> Return.Return Msg Model
load diagramType model =
    Return.singleton { model | diagramType = diagramType }
        |> loadUsableFontList UpdateUsableFontList (Message.langFromString "ja")


update : Msg -> Return.ReturnF Msg Model
update msg =
    case msg of
        UpdateSettings getSetting value ->
            Return.andThen (\m -> Return.singleton { m | dropDownIndex = Nothing, settings = getSetting value })

        ToggleDropDownList id ->
            Return.andThen
                (\m ->
                    Return.singleton
                        { m
                            | dropDownIndex =
                                if (m.dropDownIndex |> Maybe.withDefault "") == id then
                                    Nothing

                                else
                                    Just id
                        }
                )

        DropDownClose ->
            Return.andThen (\m -> Return.singleton { m | dropDownIndex = Nothing })

        UpdateUsableFontList (Ok fontList) ->
            Return.andThen (\m -> Return.singleton { m | usableFontList = fontList, isLoading = False })

        UpdateUsableFontList (Err _) ->
            Return.andThen (\m -> Return.singleton { m | usableFontList = [], isLoading = False })


isFetchedUsableFont : Model -> Bool
isFetchedUsableFont model =
    List.length model.usableFontList > 1


view : Model -> Html Msg
view model =
    view_
        { dropDownIndex = model.dropDownIndex
        , canUseNativeFileSystem = model.canUseNativeFileSystem
        , settings = model.settings
        , session = model.session
        , usableFontList = model.usableFontList
        , isLoading = model.isLoading
        }


baseColorItems : List { name : String, value : DropDownValue }
baseColorItems =
    List.map
        (\color ->
            { name = Color.name color, value = DropDownList.colorValue <| Color.toString color }
        )
        colors


baseSizeItems : List { name : String, value : DropDownValue }
baseSizeItems =
    List.range 0 100
        |> List.map
            (\i ->
                { name = String.fromInt <| 50 + i * 5, value = DropDownList.stringValue <| String.fromInt <| 50 + i * 5 }
            )


columnView : List (Html msg) -> Html msg
columnView children =
    div [ css [ width <| px 300 ] ] children


conrtolRowView : List (Html msg) -> Html msg
conrtolRowView children =
    div
        [ css
            [ displayFlex
            , alignItems center
            , justifyContent spaceBetween
            , width <| px 250
            , padding2 (px 8) zero
            ]
        ]
        children


conrtolView : List (Html msg) -> Html msg
conrtolView children =
    div [ css [ Style.flexStart, flexDirection column, marginBottom <| px 8 ] ] children


conrtolsView : List (Html msg) -> Html msg
conrtolsView children =
    div [ css [ padding2 (px 4) (px 8), marginBottom <| px 8 ] ] children


fontFamilyItems : FontList -> List { name : String, value : DropDownValue }
fontFamilyItems usableFontList =
    List.map (\font -> { name = font, value = DropDownList.stringValue font }) usableFontList


fontSizeItems : List { name : String, value : DropDownValue }
fontSizeItems =
    List.map
        (\f ->
            let
                size : Int
                size =
                    FontSize.unwrap f
            in
            { name = String.fromInt size, value = DropDownList.stringValue <| String.fromInt size }
        )
        FontSize.list


inputAreaView : List (Html msg) -> Html msg
inputAreaView children =
    div [ css [ maxWidth <| px 300, width <| pct 90, padding2 (px 4) (px 8) ] ] children


nameView : List (Html msg) -> Html msg
nameView children =
    div [ css [ Text.sm, Font.fontBold, padding2 (px 1) (px 8) ] ] children


section : Maybe String -> Html Msg
section title =
    div
        [ css
            [ fontWeight <| int 400
            , margin4 zero zero (px 16) zero
            , if isNothing title then
                Css.batch []

              else
                Css.batch [ borderTop3 (px 1) solid (hex <| Color.toString Color.gray) ]
            , if isNothing title then
                Css.batch [ padding zero ]

              else
                Css.batch [ padding4 (px 16) zero zero (px 16) ]
            ]
        ]
        [ div [ css [ Text.xl, Font.fontSemiBold ] ] [ text (title |> Maybe.withDefault "") ]
        ]


view_ :
    { dropDownIndex : Maybe String
    , canUseNativeFileSystem : Bool
    , settings : Settings
    , session : Session
    , usableFontList : FontList
    , isLoading : Bool
    }
    -> Html Msg
view_ { dropDownIndex, canUseNativeFileSystem, settings, session, usableFontList, isLoading } =
    div
        [ css
            [ Breakpoint.style
                [ Color.bgDefault
                , Style.widthFull
                , Color.textColor
                , overflowY scroll
                , displayFlex
                , flexWrap wrap
                , height <| calc (vh 100) minus (px 130)
                ]
                [ Breakpoint.large
                    [ Style.widthScreen
                    , height <| calc (vh 100) minus (px 35)
                    ]
                ]
            ]
        , onClick DropDownClose
        ]
        [ columnView
            [ section (Just "Basic")
            , conrtolsView
                [ conrtolView
                    [ nameView [ text "Font Family" ]
                    , inputAreaView
                        [ if isLoading then
                            DropDownList.loadingView "Loading..."

                          else
                            DropDownList.view ToggleDropDownList
                                "font-family"
                                dropDownIndex
                                (UpdateSettings
                                    (\x ->
                                        { settings | font = x }
                                    )
                                )
                                (fontFamilyItems usableFontList)
                                settings.font
                        ]
                    ]
                , conrtolView
                    [ nameView [ text "Background color" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "background-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> ofBackgroundColor.set x
                                )
                            )
                            baseColorItems
                            settings.storyMap.backgroundColor
                        ]
                    ]
                , conrtolView
                    [ nameView [ text "Save location" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "save-location"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    { settings | location = Just <| DiagramLocation.fromString x }
                                )
                            )
                            (List.map (\( k, v ) -> { name = k, value = DropDownList.stringValue (DiagramLocation.toString v) }) <| DiagramLocation.enabled canUseNativeFileSystem (Session.isGithubUser session))
                            ((case ( settings.location, canUseNativeFileSystem, Session.isGithubUser session ) of
                                ( Just DiagramLocation.Gist, _, True ) ->
                                    DiagramLocation.Gist

                                ( Just DiagramLocation.LocalFileSystem, True, _ ) ->
                                    DiagramLocation.LocalFileSystem

                                ( _, _, True ) ->
                                    DiagramLocation.Remote

                                _ ->
                                    DiagramLocation.Remote
                             )
                                |> DiagramLocation.toString
                            )
                        ]
                    ]
                , conrtolRowView
                    [ nameView [ text "Zoom Control" ]
                    , Switch.view (Maybe.withDefault True settings.storyMap.zoomControl)
                        (\v ->
                            UpdateSettings
                                (\_ -> settings |> ofZoomControl.set (Just v))
                                ""
                        )
                    ]
                , conrtolRowView
                    [ nameView [ text "Toolbar" ]
                    , Switch.view (Maybe.withDefault True settings.storyMap.toolbar)
                        (\v ->
                            UpdateSettings
                                (\_ -> settings |> ofToolbar.set (Just v))
                                ""
                        )
                    ]
                ]
            ]
        , columnView
            [ section (Just "Editor")
            , conrtolsView
                [ conrtolView
                    [ nameView [ text "Font Size" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "editor-font-size"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> ofFontSize.set (Maybe.withDefault 0 <| String.toInt x)
                                )
                            )
                            fontSizeItems
                            (String.fromInt <| (settings.editor |> defaultEditorSettings |> .fontSize))
                        ]
                    ]
                , conrtolRowView
                    [ nameView [ text "Show Line Number" ]
                    , Switch.view (settings.editor |> defaultEditorSettings |> .showLineNumber)
                        (\v ->
                            UpdateSettings
                                (\_ -> settings |> ofShowLineNumber.set v)
                                ""
                        )
                    ]
                , conrtolRowView
                    [ nameView [ text "Word Wrap" ]
                    , Switch.view (settings.editor |> defaultEditorSettings |> .wordWrap)
                        (\v ->
                            UpdateSettings
                                (\_ ->
                                    settings |> ofWordWrap.set v
                                )
                                ""
                        )
                    ]
                ]
            ]
        , columnView
            [ section (Just "Card Size")
            , conrtolsView
                [ conrtolView
                    [ nameView [ text "Card Width" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "card-width"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> ofWidth.set (String.toInt x |> Maybe.withDefault 150)
                                )
                            )
                            baseSizeItems
                            (String.fromInt settings.storyMap.size.width)
                        ]
                    ]
                , conrtolView
                    [ nameView [ text "Card Height" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "card-height"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> ofHeight.set (String.toInt x |> Maybe.withDefault 45)
                                )
                            )
                            baseSizeItems
                            (String.fromInt settings.storyMap.size.height)
                        ]
                    ]
                ]
            ]
        , columnView
            [ section (Just "Color")
            , conrtolsView
                [ conrtolView
                    [ nameView [ text "Background Color1" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "activity-background-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> ofActivityBackgroundColor.set x
                                )
                            )
                            baseColorItems
                            settings.storyMap.color.activity.backgroundColor
                        ]
                    ]
                , conrtolView
                    [ nameView [ text "Foreground Color1" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "activity-foreground-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> ofActivityColor.set x
                                )
                            )
                            baseColorItems
                            settings.storyMap.color.activity.color
                        ]
                    ]
                ]
            , section Nothing
            , conrtolsView
                [ conrtolView
                    [ nameView [ text "Background Color2" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "task-background-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> ofTaskBackgroundColor.set x
                                )
                            )
                            baseColorItems
                            settings.storyMap.color.task.backgroundColor
                        ]
                    ]
                , conrtolView
                    [ nameView [ text "Foreground Color2" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "task-foreground-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> ofTaskColor.set x
                                )
                            )
                            baseColorItems
                            settings.storyMap.color.task.color
                        ]
                    ]
                ]
            , section Nothing
            , conrtolsView
                [ conrtolView
                    [ nameView [ text "Background Color3" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "story-background-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> ofStoryBackgroundColor.set x
                                )
                            )
                            baseColorItems
                            settings.storyMap.color.story.backgroundColor
                        ]
                    ]
                , conrtolView
                    [ nameView [ text "Foreground Color3" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "story-foreground-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> ofStoryColor.set x
                                )
                            )
                            baseColorItems
                            settings.storyMap.color.story.color
                        ]
                    ]
                ]
            , section Nothing
            , section Nothing
            , conrtolsView
                [ conrtolView
                    [ nameView [ text "Line Color" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "line-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> ofLineColor.set x
                                )
                            )
                            baseColorItems
                            settings.storyMap.color.line
                        ]
                    ]
                , conrtolView
                    [ nameView [ text "Label Color" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "label-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> ofLabelColor.set x
                                )
                            )
                            baseColorItems
                            settings.storyMap.color.label
                        ]
                    ]
                , conrtolView
                    [ nameView [ text "Text Color" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "text-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> ofTextColor.set x
                                )
                            )
                            baseColorItems
                            (settings.storyMap.color.text |> Maybe.withDefault (Color.toString Color.textDefalut))
                        ]
                    ]
                ]
            ]
        ]

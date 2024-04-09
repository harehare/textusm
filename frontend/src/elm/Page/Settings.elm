module Page.Settings exposing (FontList, Model, Msg(..), diagramSettings, init, isFetchedUsableFont, load, settings, update, view)

import Api.Http.UsableFontList as UsableFontListRequest
import Api.RequestError exposing (RequestError)
import Css
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Location as DiagramLocation
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType exposing (DiagramType)
import File exposing (File)
import File.Download as Download
import File.Select as Select
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick)
import Json.Decode as D
import Json.Encode as E
import Maybe.Extra exposing (isNothing)
import Message exposing (Lang)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Return
import String.Extra
import Style.Breakpoint as Breakpoint
import Style.Color as ColorStyle
import Style.Font as FontStyle
import Style.Style as Style
import Style.Text as Text
import Task
import Types.Color as Color
import Types.Font as Font exposing (Font)
import Types.FontSize as FontSize
import Types.Session as Session exposing (Session)
import Types.Settings as Settings exposing (Settings)
import Types.SplitDirection as SplitDirection
import Types.Theme as Theme
import View.DropDownList as DropDownList exposing (DropDownValue)
import View.Icon as Icon
import View.Switch as Switch


type alias FontList =
    List Font


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
    | ImportFile File
    | Import
    | Export
    | LoadSettings (Result String Settings)


loadUsableFontList :
    (Result RequestError FontList -> Msg)
    -> Lang
    -> Return.ReturnF Msg Model
loadUsableFontList msg lang =
    UsableFontListRequest.usableFontList
        lang
        |> Task.attempt msg
        |> Return.command


init :
    { canUseNativeFileSystem : Bool
    , diagramType : DiagramType
    , session : Session
    , settings : Settings
    , lang : Lang
    , usableFontList : Maybe FontList
    }
    -> Return.Return Msg Model
init m =
    Return.singleton
        { dropDownIndex = Nothing
        , diagramType = m.diagramType
        , settings = m.settings
        , session = m.session
        , canUseNativeFileSystem = m.canUseNativeFileSystem
        , usableFontList = m.usableFontList |> Maybe.withDefault [ m.settings.diagramSettings.font ]
        , lang = m.lang
        , isLoading = False
        }


load : { diagramType : DiagramType, session : Session } -> Return.ReturnF Msg Model
load { diagramType, session } =
    Return.andThen <|
        \m ->
            Return.singleton { m | diagramType = diagramType, session = session }
                |> loadUsableFontList UpdateUsableFontList (Message.langFromString "ja")


update : Msg -> Return.ReturnF Msg Model
update msg =
    case msg of
        LoadSettings (Ok s) ->
            Return.map <| \m -> { m | settings = s }

        LoadSettings (Err _) ->
            Return.zero

        UpdateSettings getSetting value ->
            Return.map <| \m -> { m | dropDownIndex = Nothing, settings = getSetting value }

        ToggleDropDownList id ->
            Return.map <|
                \m ->
                    { m
                        | dropDownIndex =
                            if (m.dropDownIndex |> Maybe.withDefault "") == id then
                                Nothing

                            else
                                Just id
                    }

        DropDownClose ->
            Return.map <| \m -> { m | dropDownIndex = Nothing }

        UpdateUsableFontList (Ok fontList) ->
            Return.map <| \m -> { m | usableFontList = fontList, isLoading = False }

        UpdateUsableFontList (Err _) ->
            Return.map <| \m -> { m | usableFontList = [], isLoading = False }

        Export ->
            Return.andThen <|
                \m ->
                    Return.singleton m
                        |> Return.command
                            (Download.string ((m.diagramType |> DiagramType.toTypeString |> String.toLower) ++ "_settings.json")
                                "application/json"
                                (E.encode
                                    2
                                    (Settings.exportEncoder m.settings)
                                )
                            )

        Import ->
            Return.command <| Select.file [ "application/json" ] ImportFile

        ImportFile file ->
            Return.andThen <|
                \m ->
                    Return.singleton m
                        |> (File.toString file
                                |> Task.map (\s -> D.decodeString (Settings.importDecoder m.settings) s |> Result.mapError D.errorToString)
                                |> Task.perform LoadSettings
                                |> Return.command
                           )


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
        , lang = model.lang
        }


baseColorItems : List { name : String, value : DropDownValue }
baseColorItems =
    List.map
        (\color ->
            { name = Color.name color, value = DropDownList.colorValue <| Color.toString color }
        )
        Color.colors


baseSizeItems : List { name : String, value : DropDownValue }
baseSizeItems =
    List.range 0 100
        |> List.map
            (\i ->
                { name = String.fromInt <| 50 + i * 5, value = DropDownList.stringValue <| String.fromInt <| 50 + i * 5 }
            )


columnView : List (Html msg) -> Html msg
columnView children =
    Html.div [ Attr.css [ Css.width <| Css.px 300 ] ] children


conrtolRowView : List (Html msg) -> Html msg
conrtolRowView children =
    Html.div
        [ Attr.css
            [ Css.displayFlex
            , Css.alignItems Css.center
            , Css.justifyContent Css.spaceBetween
            , Css.width <| Css.px 250
            , Css.padding2 (Css.px 8) Css.zero
            ]
        ]
        children


conrtolView : List (Html msg) -> Html msg
conrtolView children =
    Html.div [ Attr.css [ Style.flexStart, Css.flexDirection Css.column, Css.marginBottom <| Css.px 8 ] ] children


conrtolsView : List (Html msg) -> Html msg
conrtolsView children =
    Html.div [ Attr.css [ Css.padding2 (Css.px 4) (Css.px 8), Css.marginBottom <| Css.px 8 ] ] children


fontFamilyItems : FontList -> List { name : String, value : DropDownValue }
fontFamilyItems usableFontList =
    List.map (\font -> { name = Font.name font, value = DropDownList.stringValue <| Font.name font }) usableFontList


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
    Html.div [ Attr.css [ Css.maxWidth <| Css.px 300, Css.width <| Css.pct 90, Css.padding2 (Css.px 4) (Css.px 8) ] ] children


nameView : List (Html msg) -> Html msg
nameView children =
    Html.div [ Attr.css [ Text.sm, FontStyle.fontBold, Css.padding2 (Css.px 1) (Css.px 8) ] ] children


section : Maybe String -> Html Msg
section title =
    Html.div
        [ Attr.css
            [ Css.fontWeight <| Css.int 400
            , Css.margin4 Css.zero Css.zero (Css.px 16) Css.zero
            , if isNothing title then
                Css.batch []

              else
                Css.batch [ Css.borderTop3 (Css.px 1) Css.solid (Css.hex <| Color.toString Color.gray) ]
            , if isNothing title then
                Css.batch [ Css.padding Css.zero ]

              else
                Css.batch [ Css.padding4 (Css.px 16) Css.zero Css.zero (Css.px 16) ]
            ]
        ]
        [ Html.div [ Attr.css [ Text.xl, FontStyle.fontSemiBold ] ] [ Html.text (title |> Maybe.withDefault "") ]
        ]


view_ :
    { dropDownIndex : Maybe String
    , canUseNativeFileSystem : Bool
    , settings : Settings
    , session : Session
    , usableFontList : FontList
    , isLoading : Bool
    , lang : Lang
    }
    -> Html Msg
view_ m =
    Html.div
        [ Attr.css
            [ Breakpoint.style
                [ ColorStyle.bgDefault
                , Style.widthFull
                , ColorStyle.textColor
                , Css.overflowY Css.scroll
                , Css.displayFlex
                , Css.flexWrap Css.wrap
                , Css.height <| Css.calc (Css.vh 100) Css.minus (Css.px 130)
                ]
                [ Breakpoint.large
                    [ Style.widthScreen
                    , Css.height <| Css.calc (Css.vh 100) Css.minus (Css.px 35)
                    ]
                ]
            ]
        , onClick DropDownClose
        ]
        [ columnView
            [ section (Just "Basic")
            , conrtolsView
                [ conrtolView
                    [ nameView [ Html.text "Font Family" ]
                    , inputAreaView
                        [ if m.isLoading then
                            DropDownList.loadingView "Loading..."

                          else
                            DropDownList.view ToggleDropDownList
                                "font-family"
                                m.dropDownIndex
                                (UpdateSettings
                                    (\x ->
                                        m.settings |> Settings.font.set (Font.googleFont x) |> Settings.mainFont.set (Font.googleFont x)
                                    )
                                )
                                (fontFamilyItems m.usableFontList)
                                (Font.name m.settings.font)
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Background color" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "background-color"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.backgroundColor.set (Color.fromString x) m.settings
                                )
                            )
                            baseColorItems
                            (m.settings.diagramSettings.backgroundColor |> Color.toString)
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Save location" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "save-location"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    m.settings |> Settings.location.set (DiagramLocation.fromString x)
                                )
                            )
                            (List.map (\( k, v ) -> { name = k, value = DropDownList.stringValue (DiagramLocation.toString v) }) <| DiagramLocation.enabled m.canUseNativeFileSystem (Session.isGithubUser m.session))
                            ((case ( m.settings.location, m.canUseNativeFileSystem, Session.isGithubUser m.session ) of
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
                , conrtolView
                    [ nameView [ Html.text "Theme" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "editor-theme"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    m.settings |> Settings.theme.set (Theme.fromString x)
                                )
                            )
                            [ { name = Theme.toDisplayString <| Theme.System True, value = DropDownList.stringValue <| Theme.toString <| Theme.System True }
                            , { name = Theme.toDisplayString Theme.Light, value = DropDownList.stringValue <| Theme.toString Theme.Light }
                            , { name = Theme.toDisplayString Theme.Dark, value = DropDownList.stringValue <| Theme.toString Theme.Dark }
                            ]
                            (m.settings.theme |> Maybe.map Theme.toString |> Maybe.withDefault (Theme.toString <| Theme.System True))
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Panel split direction" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "split-direction"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.splitDirection.set (SplitDirection.fromString x) m.settings
                                )
                            )
                            ([ SplitDirection.Vertical, SplitDirection.Horizontal ]
                                |> List.map (\item -> { name = String.Extra.toSentenceCase <| SplitDirection.toString item, value = DropDownList.stringValue <| SplitDirection.toString item })
                            )
                            (m.settings.splitDirection |> Maybe.withDefault SplitDirection.Vertical |> SplitDirection.toString)
                        ]
                    ]
                , conrtolRowView
                    [ nameView [ Html.text "Zoom Control" ]
                    , Switch.view (Maybe.withDefault True m.settings.diagramSettings.zoomControl)
                        (\v ->
                            UpdateSettings
                                (\_ -> m.settings |> Settings.zoomControl.set (Just v))
                                ""
                        )
                    ]
                , conrtolRowView
                    [ nameView [ Html.text "Toolbar" ]
                    , Switch.view (Maybe.withDefault True m.settings.diagramSettings.toolbar)
                        (\v ->
                            UpdateSettings
                                (\_ -> Settings.toolbar.set (Just v) m.settings)
                                ""
                        )
                    ]
                , conrtolRowView
                    [ nameView [ Html.text "Grid" ]
                    , Switch.view (Maybe.withDefault False m.settings.diagramSettings.showGrid)
                        (\v ->
                            UpdateSettings
                                (\_ -> Settings.showGrid.set (Just v) m.settings)
                                ""
                        )
                    ]
                ]
            ]
        , columnView
            [ section (Just "Editor")
            , conrtolsView
                [ conrtolView
                    [ nameView [ Html.text "Font Size" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "editor-font-size"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.fontSize.set (x |> String.toInt |> Maybe.withDefault 0 |> FontSize.fromInt) m.settings
                                )
                            )
                            fontSizeItems
                            (String.fromInt <| FontSize.unwrap <| (m.settings.editor |> Settings.defaultEditorSettings |> .fontSize))
                        ]
                    ]
                , conrtolRowView
                    [ nameView [ Html.text "Show Line Number" ]
                    , Switch.view (m.settings.editor |> Settings.defaultEditorSettings |> .showLineNumber)
                        (\v ->
                            UpdateSettings
                                (\_ -> Settings.showLineNumber.set v m.settings)
                                ""
                        )
                    ]
                , conrtolRowView
                    [ nameView [ Html.text "Word Wrap" ]
                    , Switch.view (m.settings.editor |> Settings.defaultEditorSettings |> .wordWrap)
                        (\v ->
                            UpdateSettings
                                (\_ ->
                                    Settings.wordWrap.set v m.settings
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
                    [ nameView [ Html.text "Card Width" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "card-width"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.width.set (String.toInt x |> Maybe.withDefault 150 |> CardSize.fromInt) m.settings
                                )
                            )
                            baseSizeItems
                            (String.fromInt <| CardSize.toInt m.settings.diagramSettings.size.width)
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Card Height" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "card-height"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    m.settings |> Settings.height.set (String.toInt x |> Maybe.withDefault 45 |> CardSize.fromInt)
                                )
                            )
                            baseSizeItems
                            (String.fromInt <| CardSize.toInt m.settings.diagramSettings.size.height)
                        ]
                    ]
                ]
            ]
        , columnView
            [ section (Just "Color")
            , conrtolsView
                [ conrtolView
                    [ nameView [ Html.text "Background Color1" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "activity-background-color"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.activityBackgroundColor.set (Color.fromString x) m.settings
                                )
                            )
                            baseColorItems
                            (m.settings.diagramSettings.color.activity.backgroundColor |> Color.toString)
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Foreground Color1" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "activity-foreground-color"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.activityColor.set (Color.fromString x) m.settings
                                )
                            )
                            baseColorItems
                            (m.settings.diagramSettings.color.activity.color |> Color.toString)
                        ]
                    ]
                ]
            , section Nothing
            , conrtolsView
                [ conrtolView
                    [ nameView [ Html.text "Background Color2" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "task-background-color"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.taskBackgroundColor.set (Color.fromString x) m.settings
                                )
                            )
                            baseColorItems
                            (m.settings.diagramSettings.color.task.backgroundColor |> Color.toString)
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Foreground Color2" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "task-foreground-color"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    m.settings |> Settings.taskColor.set (Color.fromString x)
                                )
                            )
                            baseColorItems
                            (m.settings.diagramSettings.color.task.color |> Color.toString)
                        ]
                    ]
                ]
            , section Nothing
            , conrtolsView
                [ conrtolView
                    [ nameView [ Html.text "Background Color3" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "story-background-color"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.storyBackgroundColor.set (Color.fromString x) m.settings
                                )
                            )
                            baseColorItems
                            (m.settings.diagramSettings.color.story.backgroundColor |> Color.toString)
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Foreground Color3" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "story-foreground-color"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.storyColor.set (Color.fromString x) m.settings
                                )
                            )
                            baseColorItems
                            (m.settings.diagramSettings.color.story.color |> Color.toString)
                        ]
                    ]
                ]
            , section Nothing
            , section Nothing
            , conrtolsView
                [ conrtolView
                    [ nameView [ Html.text "Line Color" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "line-color"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    m.settings |> Settings.lineColor.set (Color.fromString x)
                                )
                            )
                            baseColorItems
                            (m.settings.diagramSettings.color.line |> Color.toString)
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Label Color" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "label-color"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    m.settings |> Settings.labelColor.set (Color.fromString x)
                                )
                            )
                            baseColorItems
                            (m.settings.diagramSettings.color.label |> Color.toString)
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Text Color" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "text-color"
                            m.dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    m.settings |> Settings.textColor.set (Color.fromString x)
                                )
                            )
                            baseColorItems
                            (m.settings.diagramSettings.color.text |> Maybe.withDefault Color.textDefalut |> Color.toString)
                        ]
                    ]
                ]
            ]
        , Html.div
            [ Attr.css [ Style.button, Css.position Css.absolute, Css.right <| Css.px 48, Css.top <| Css.px 8 ]
            , onClick Import
            ]
            [ Icon.cloudUpload Color.white 24
            , Html.span [ Attr.class "bottom-tooltip" ]
                [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipImport m.lang ] ]
            ]
        , Html.div
            [ Attr.css [ Style.button, Css.position Css.absolute, Css.right <| Css.px 8, Css.top <| Css.px 8 ]
            , onClick Export
            ]
            [ Icon.cloudDownload Color.white 24
            , Html.span
                [ Attr.class "bottom-tooltip"
                ]
                [ Html.span [ Attr.class "text" ]
                    [ Html.text <| Message.toolTipExport m.lang ]
                ]
            ]
        ]



-- Lens


settings : Lens Model Settings
settings =
    Lens .settings (\b a -> { a | settings = b })


diagramSettings : Lens Model DiagramSettings.Settings
diagramSettings =
    Compose.lensWithLens settingsOfDiagramSettings settings


settingsOfDiagramSettings : Lens Settings DiagramSettings.Settings
settingsOfDiagramSettings =
    Lens .diagramSettings (\b a -> { a | diagramSettings = b })

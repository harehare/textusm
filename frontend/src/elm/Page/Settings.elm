module Page.Settings exposing (FontList, Model, Msg(..), init, isFetchedUsableFont, load, update, view)

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
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick)
import Maybe.Extra exposing (isNothing)
import Message exposing (Lang)
import Models.Color as Color exposing (colors)
import Models.Diagram.Location as DiagramLocation
import Models.Diagram.Type exposing (DiagramType)
import Models.FontSize as FontSize
import Models.Session as Session exposing (Session)
import Models.Settings as Settings exposing (Settings)
import Models.Theme as Theme
import Return
import Style.Breakpoint as Breakpoint
import Style.Color as ColorStyle
import Style.Font as FontStyle
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
init { canUseNativeFileSystem, diagramType, session, settings, lang, usableFontList } =
    Return.singleton
        { dropDownIndex = Nothing
        , diagramType = diagramType
        , settings = settings
        , session = session
        , canUseNativeFileSystem = canUseNativeFileSystem
        , usableFontList = usableFontList |> Maybe.withDefault [ settings.storyMap.font ]
        , lang = lang
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
        UpdateSettings getSetting value ->
            Return.map (\m -> { m | dropDownIndex = Nothing, settings = getSetting value })

        ToggleDropDownList id ->
            Return.map
                (\m ->
                    { m
                        | dropDownIndex =
                            if (m.dropDownIndex |> Maybe.withDefault "") == id then
                                Nothing

                            else
                                Just id
                    }
                )

        DropDownClose ->
            Return.map (\m -> { m | dropDownIndex = Nothing })

        UpdateUsableFontList (Ok fontList) ->
            Return.map (\m -> { m | usableFontList = fontList, isLoading = False })

        UpdateUsableFontList (Err _) ->
            Return.map (\m -> { m | usableFontList = [], isLoading = False })


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
    Html.div [ Attr.css [ width <| px 300 ] ] children


conrtolRowView : List (Html msg) -> Html msg
conrtolRowView children =
    Html.div
        [ Attr.css
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
    Html.div [ Attr.css [ Style.flexStart, flexDirection column, marginBottom <| px 8 ] ] children


conrtolsView : List (Html msg) -> Html msg
conrtolsView children =
    Html.div [ Attr.css [ padding2 (px 4) (px 8), marginBottom <| px 8 ] ] children


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
    Html.div [ Attr.css [ maxWidth <| px 300, width <| pct 90, padding2 (px 4) (px 8) ] ] children


nameView : List (Html msg) -> Html msg
nameView children =
    Html.div [ Attr.css [ Text.sm, FontStyle.fontBold, padding2 (px 1) (px 8) ] ] children


section : Maybe String -> Html Msg
section title =
    Html.div
        [ Attr.css
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
        [ Html.div [ Attr.css [ Text.xl, FontStyle.fontSemiBold ] ] [ Html.text (title |> Maybe.withDefault "") ]
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
    Html.div
        [ Attr.css
            [ Breakpoint.style
                [ ColorStyle.bgDefault
                , Style.widthFull
                , ColorStyle.textColor
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
                    [ nameView [ Html.text "Font Family" ]
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
                    [ nameView [ Html.text "Background color" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "background-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.backgroundColor.set x settings
                                )
                            )
                            baseColorItems
                            settings.storyMap.backgroundColor
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Save location" ]
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
                , conrtolView
                    [ nameView [ Html.text "Theme" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "editor-theme"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    { settings | theme = Just <| Theme.fromString x }
                                )
                            )
                            [ { name = Theme.toDisplayString <| Theme.System True, value = DropDownList.stringValue <| Theme.toString <| Theme.System True }
                            , { name = Theme.toDisplayString Theme.Light, value = DropDownList.stringValue <| Theme.toString Theme.Light }
                            , { name = Theme.toDisplayString Theme.Dark, value = DropDownList.stringValue <| Theme.toString Theme.Dark }
                            ]
                            (settings.theme |> Maybe.map Theme.toString |> Maybe.withDefault (Theme.toString <| Theme.System True))
                        ]
                    ]
                , conrtolRowView
                    [ nameView [ Html.text "Zoom Control" ]
                    , Switch.view (Maybe.withDefault True settings.storyMap.zoomControl)
                        (\v ->
                            UpdateSettings
                                (\_ -> settings |> Settings.zoomControl.set (Just v))
                                ""
                        )
                    ]
                , conrtolRowView
                    [ nameView [ Html.text "Toolbar" ]
                    , Switch.view (Maybe.withDefault True settings.storyMap.toolbar)
                        (\v ->
                            UpdateSettings
                                (\_ -> Settings.toolbar.set (Just v) settings)
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
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.fontSize.set (Maybe.withDefault 0 <| String.toInt x) settings
                                )
                            )
                            fontSizeItems
                            (String.fromInt <| (settings.editor |> Settings.defaultEditorSettings |> .fontSize))
                        ]
                    ]
                , conrtolRowView
                    [ nameView [ Html.text "Show Line Number" ]
                    , Switch.view (settings.editor |> Settings.defaultEditorSettings |> .showLineNumber)
                        (\v ->
                            UpdateSettings
                                (\_ -> Settings.showLineNumber.set v settings)
                                ""
                        )
                    ]
                , conrtolRowView
                    [ nameView [ Html.text "Word Wrap" ]
                    , Switch.view (settings.editor |> Settings.defaultEditorSettings |> .wordWrap)
                        (\v ->
                            UpdateSettings
                                (\_ ->
                                    Settings.wordWrap.set v settings
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
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.width.set (String.toInt x |> Maybe.withDefault 150) settings
                                )
                            )
                            baseSizeItems
                            (String.fromInt settings.storyMap.size.width)
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Card Height" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "card-height"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> Settings.height.set (String.toInt x |> Maybe.withDefault 45)
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
                    [ nameView [ Html.text "Background Color1" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "activity-background-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.activityBackgroundColor.set x settings
                                )
                            )
                            baseColorItems
                            settings.storyMap.color.activity.backgroundColor
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Foreground Color1" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "activity-foreground-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.activityColor.set x settings
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
                    [ nameView [ Html.text "Background Color2" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "task-background-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.taskBackgroundColor.set x settings
                                )
                            )
                            baseColorItems
                            settings.storyMap.color.task.backgroundColor
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Foreground Color2" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "task-foreground-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    settings |> Settings.taskColor.set x
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
                    [ nameView [ Html.text "Background Color3" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "story-background-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.storyBackgroundColor.set x settings
                                )
                            )
                            baseColorItems
                            settings.storyMap.color.story.backgroundColor
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Foreground Color3" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "story-foreground-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.storyColor.set x settings
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
                    [ nameView [ Html.text "Line Color" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "line-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.lineColor.set x settings
                                )
                            )
                            baseColorItems
                            settings.storyMap.color.line
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Label Color" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "label-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.labelColor.set x settings
                                )
                            )
                            baseColorItems
                            settings.storyMap.color.label
                        ]
                    ]
                , conrtolView
                    [ nameView [ Html.text "Text Color" ]
                    , inputAreaView
                        [ DropDownList.view ToggleDropDownList
                            "text-color"
                            dropDownIndex
                            (UpdateSettings
                                (\x ->
                                    Settings.textColor.set x settings
                                )
                            )
                            baseColorItems
                            (settings.storyMap.color.text |> Maybe.withDefault (Color.toString Color.textDefalut))
                        ]
                    ]
                ]
            ]
        ]

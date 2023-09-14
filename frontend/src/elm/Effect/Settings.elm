module Effect.Settings exposing
    ( load
    , save
    , saveToLocal
    )

import Api.Request as Request
import Api.RequestError exposing (RequestError)
import Graphql.OptionalArgument as OptionalArgument
import Models.Diagram.Settings as DiagramSettings
import Models.Diagram.Type as DiagramType exposing (DiagramType)
import Models.Session as Session exposing (Session)
import Models.Settings as Settings
import Models.SettingsCache as SettingCache exposing (SettingsCache)
import Ports
import Return
import Task


load :
    (Result RequestError DiagramSettings.Settings -> msg)
    ->
        { cache : SettingsCache
        , diagramType : DiagramType
        , session : Session
        }
    -> Return.ReturnF msg model
load msg { cache, diagramType, session } =
    if Session.isSignedIn session then
        case SettingCache.get cache diagramType of
            Just setting ->
                Ok setting
                    |> msg
                    |> Task.succeed
                    |> Task.perform identity
                    |> Return.command

            Nothing ->
                Request.settings
                    (Session.getIdToken session)
                    diagramType
                    |> Task.attempt msg
                    |> Return.command

    else
        DiagramType.toString diagramType
            |> Ports.loadSettingsFromLocal
            |> Return.command


saveToLocal : Settings.Settings -> Return.ReturnF msg model
saveToLocal settings =
    Settings.settingsEncoder settings |> Ports.saveSettingsToLocal |> Return.command


save :
    (Result RequestError DiagramSettings.Settings -> msg)
    ->
        { diagramType : DiagramType
        , session : Session
        , settings : Settings.Settings
        }
    -> Return.ReturnF msg model
save msg { diagramType, session, settings } =
    if Session.isSignedIn session then
        Request.saveSettings
            (Session.getIdToken session)
            diagramType
            { font = settings.storyMap.font
            , width = settings.storyMap.size.width
            , height = settings.storyMap.size.height
            , backgroundColor = settings.storyMap.backgroundColor
            , activityColor =
                { foregroundColor = settings.storyMap.color.activity.color
                , backgroundColor = settings.storyMap.color.activity.backgroundColor
                }
            , taskColor =
                { foregroundColor = settings.storyMap.color.task.color
                , backgroundColor = settings.storyMap.color.task.backgroundColor
                }
            , storyColor =
                { foregroundColor = settings.storyMap.color.story.color
                , backgroundColor = settings.storyMap.color.story.backgroundColor
                }
            , lineColor = settings.storyMap.color.line
            , labelColor = settings.storyMap.color.label
            , textColor =
                case settings.storyMap.color.text of
                    Just c ->
                        OptionalArgument.Present c

                    Nothing ->
                        OptionalArgument.Absent
            , zoomControl =
                case settings.storyMap.zoomControl of
                    Just z ->
                        OptionalArgument.Present z

                    Nothing ->
                        OptionalArgument.Absent
            , scale =
                case settings.storyMap.scale of
                    Just s ->
                        OptionalArgument.Present s

                    Nothing ->
                        OptionalArgument.Absent
            , toolbar =
                case settings.storyMap.toolbar of
                    Just z ->
                        OptionalArgument.Present z

                    Nothing ->
                        OptionalArgument.Absent
            }
            |> Task.attempt msg
            |> Return.command

    else
        saveToLocal { settings | diagram = Maybe.map (\d -> { d | diagram = diagramType }) settings.diagram }

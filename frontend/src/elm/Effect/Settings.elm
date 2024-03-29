module Effect.Settings exposing
    ( load
    , save
    , saveToLocal
    )

import Api.Request as Request
import Api.RequestError exposing (RequestError)
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Scale as Scale
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType exposing (DiagramType)
import Graphql.OptionalArgument as OptionalArgument
import Ports
import Return
import Task
import Types.Color as Color
import Types.Font as Font
import Types.Session as Session exposing (Session)
import Types.Settings as Settings
import Types.SettingsCache as SettingCache exposing (SettingsCache)


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
    Settings.encoder settings |> Ports.saveSettingsToLocal |> Return.command


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
            { font = Font.name settings.diagramSettings.font
            , width = CardSize.toInt settings.diagramSettings.size.width
            , height = CardSize.toInt settings.diagramSettings.size.height
            , backgroundColor = Color.toString settings.diagramSettings.backgroundColor
            , activityColor =
                { foregroundColor = Color.toString settings.diagramSettings.color.activity.color
                , backgroundColor = Color.toString settings.diagramSettings.color.activity.backgroundColor
                }
            , taskColor =
                { foregroundColor = Color.toString settings.diagramSettings.color.task.color
                , backgroundColor = Color.toString settings.diagramSettings.color.task.backgroundColor
                }
            , storyColor =
                { foregroundColor = Color.toString settings.diagramSettings.color.story.color
                , backgroundColor = Color.toString settings.diagramSettings.color.story.backgroundColor
                }
            , lineColor = Color.toString settings.diagramSettings.color.line
            , labelColor = Color.toString settings.diagramSettings.color.label
            , textColor =
                case settings.diagramSettings.color.text of
                    Just c ->
                        OptionalArgument.Present <| Color.toString c

                    Nothing ->
                        OptionalArgument.Absent
            , zoomControl =
                case settings.diagramSettings.zoomControl of
                    Just z ->
                        OptionalArgument.Present z

                    Nothing ->
                        OptionalArgument.Absent
            , scale =
                case settings.diagramSettings.scale of
                    Just s ->
                        OptionalArgument.Present <| Scale.toFloat s

                    Nothing ->
                        OptionalArgument.Absent
            , toolbar =
                case settings.diagramSettings.toolbar of
                    Just z ->
                        OptionalArgument.Present z

                    Nothing ->
                        OptionalArgument.Absent
            , lockEditing =
                case settings.diagramSettings.lockEditing of
                    Just l ->
                        OptionalArgument.Present l

                    Nothing ->
                        OptionalArgument.Absent
            , showGrid =
                case settings.diagramSettings.showGrid of
                    Just s ->
                        OptionalArgument.Present s

                    Nothing ->
                        OptionalArgument.Absent
            }
            |> Task.attempt msg
            |> Return.command

    else
        saveToLocal { settings | diagram = Maybe.map (\d -> { d | diagram = diagramType }) settings.diagram }

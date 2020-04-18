module Models.Settings exposing (EditorSettings, Settings, defaultEditorSettings, defaultSettings, settingsOfActivityBackgroundColor, settingsOfActivityColor, settingsOfBackgroundColor, settingsOfFontSize, settingsOfHeight, settingsOfLabelColor, settingsOfLineColor, settingsOfShowLineNumber, settingsOfStoryBackgroundColor, settingsOfStoryColor, settingsOfTaskBackgroundColor, settingsOfTaskColor, settingsOfTextColor, settingsOfWidth, settingsOfWordWrap, settingsOfZoomControl)

import GraphQL.Models.DiagramItem exposing (DiagramItem)
import Models.Diagram as Diagram
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)


type alias Settings =
    { position : Maybe Int
    , font : String
    , diagramId : Maybe String
    , storyMap : Diagram.Settings
    , text : Maybe String
    , title : Maybe String
    , editor : Maybe EditorSettings
    , diagram : Maybe DiagramItem
    }


type alias EditorSettings =
    { fontSize : Int
    , wordWrap : Bool
    , showLineNumber : Bool
    }


defaultSettings : Settings
defaultSettings =
    { position = Just -10
    , font = "Nunito Sans"
    , diagramId = Nothing
    , storyMap =
        { font = "Nunito Sans"
        , size = { width = 140, height = 65 }
        , color =
            { activity =
                { color = "#FFFFFF"
                , backgroundColor = "#266B9A"
                }
            , task =
                { color = "#FFFFFF"
                , backgroundColor = "#3E9BCD"
                }
            , story =
                { color = "#333333"
                , backgroundColor = "#FFFFFF"
                }
            , line = "#434343"
            , label = "#8C9FAE"
            , text = Just "#111111"
            }
        , backgroundColor = "#F4F4F5"
        , zoomControl = Just True
        }
    , text = Nothing
    , title = Nothing
    , editor = Nothing
    , diagram = Nothing
    }


editorOfSettings : Optional Settings EditorSettings
editorOfSettings =
    Optional .editor (\b a -> { a | editor = Just b })


editorOfFontSize : Lens EditorSettings Int
editorOfFontSize =
    Lens .fontSize (\b a -> { a | fontSize = b })


editorOfWordWrap : Lens EditorSettings Bool
editorOfWordWrap =
    Lens .wordWrap (\b a -> { a | wordWrap = b })


editorOfShowLineNumber : Lens EditorSettings Bool
editorOfShowLineNumber =
    Lens .showLineNumber (\b a -> { a | showLineNumber = b })


settingsOfShowLineNumber : Optional Settings Bool
settingsOfShowLineNumber =
    Compose.optionalWithLens editorOfShowLineNumber editorOfSettings


settingsOfWordWrap : Optional Settings Bool
settingsOfWordWrap =
    Compose.optionalWithLens editorOfWordWrap editorOfSettings


settingsOfFontSize : Optional Settings Int
settingsOfFontSize =
    Compose.optionalWithLens editorOfFontSize editorOfSettings


settingsOfWidth : Lens Settings Int
settingsOfWidth =
    Compose.lensWithLens Diagram.settingsOfWidth storyMapOfSettings


settingsOfHeight : Lens Settings Int
settingsOfHeight =
    Compose.lensWithLens Diagram.settingsOfHeight storyMapOfSettings


settingsOfBackgroundColor : Lens Settings String
settingsOfBackgroundColor =
    Compose.lensWithLens Diagram.settingsOfBackgroundColor storyMapOfSettings


settingsOfZoomControl : Lens Settings (Maybe Bool)
settingsOfZoomControl =
    Compose.lensWithLens Diagram.settingsOfZoomControl storyMapOfSettings


settingsOfLineColor : Lens Settings String
settingsOfLineColor =
    Compose.lensWithLens Diagram.settingsOfLineColor storyMapOfSettings


settingsOfLabelColor : Lens Settings String
settingsOfLabelColor =
    Compose.lensWithLens Diagram.settingsOfLabelColor storyMapOfSettings


settingsOfTextColor : Optional Settings String
settingsOfTextColor =
    Compose.lensWithOptional Diagram.settingsOfTextColor storyMapOfSettings


settingsOfActivityColor : Lens Settings String
settingsOfActivityColor =
    Compose.lensWithLens Diagram.settingsOfActivityColor storyMapOfSettings


settingsOfTaskColor : Lens Settings String
settingsOfTaskColor =
    Compose.lensWithLens Diagram.settingsOfTaskColor storyMapOfSettings


settingsOfStoryColor : Lens Settings String
settingsOfStoryColor =
    Compose.lensWithLens Diagram.settingsOfStoryColor storyMapOfSettings


settingsOfActivityBackgroundColor : Lens Settings String
settingsOfActivityBackgroundColor =
    Compose.lensWithLens Diagram.settingsOfActivityBackgroundColor storyMapOfSettings


settingsOfTaskBackgroundColor : Lens Settings String
settingsOfTaskBackgroundColor =
    Compose.lensWithLens Diagram.settingsOfTaskBackgroundColor storyMapOfSettings


settingsOfStoryBackgroundColor : Lens Settings String
settingsOfStoryBackgroundColor =
    Compose.lensWithLens Diagram.settingsOfStoryBackgroundColor storyMapOfSettings


storyMapOfSettings : Lens Settings Diagram.Settings
storyMapOfSettings =
    Lens .storyMap (\b a -> { a | storyMap = b })


defaultEditorSettings : Maybe EditorSettings -> EditorSettings
defaultEditorSettings settings =
    Maybe.withDefault
        { fontSize = 14
        , wordWrap = False
        , showLineNumber = True
        }
        settings

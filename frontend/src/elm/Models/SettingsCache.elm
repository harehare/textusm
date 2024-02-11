module Models.SettingsCache exposing (SettingsCache, get, new, set)

import Diagram.Types.Settings exposing (Settings)
import Diagram.Types.Type as DiagramType exposing (DiagramType)
import Dict exposing (Dict)


type SettingsCache
    = SettingsCache (Dict String Settings)


new : SettingsCache
new =
    SettingsCache <| Dict.empty


get : SettingsCache -> DiagramType -> Maybe Settings
get (SettingsCache cache) diagram =
    Dict.get (DiagramType.toString diagram) cache


set : SettingsCache -> DiagramType -> Settings -> SettingsCache
set (SettingsCache cache) diagram settings =
    SettingsCache <| Dict.update (DiagramType.toString diagram) (\_ -> Just settings) cache

module Models.SettingsCache exposing (SettingsCache, get, new, set)

import Dict exposing (Dict)
import Graphql.Enum.Diagram exposing (Diagram(..))
import Models.DiagramSettings exposing (Settings)
import Models.DiagramType as DiagramType


type SettingsCache
    = SettingsCache (Dict String Settings)


new : SettingsCache
new =
    SettingsCache <| Dict.empty


get : SettingsCache -> Diagram -> Maybe Settings
get (SettingsCache cache) diagram =
    Dict.get (DiagramType.toString diagram) cache


set : SettingsCache -> Diagram -> Settings -> SettingsCache
set (SettingsCache cache) diagram settings =
    SettingsCache <| Dict.update (DiagramType.toString diagram) (\_ -> Just settings) cache

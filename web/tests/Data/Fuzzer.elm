module Data.Fuzzer exposing (..)

import Data.Color as Color exposing (Color)
import Data.FontSize as FontSize exposing (FontSize)
import Data.ItemSettings as ItemSettings exposing (ItemSettings)
import Data.Position exposing (Position)
import Fuzz exposing (Fuzzer)
import TextUSM.Enum.Diagram exposing (Diagram(..))


itemSettingsFuzzer : Fuzzer ItemSettings
itemSettingsFuzzer =
    Fuzz.map4
        (\bg fg offset fontSize ->
            ItemSettings.new
                |> ItemSettings.withBackgroundColor bg
                |> ItemSettings.withForegroundColor fg
                |> ItemSettings.withPosition offset
                |> ItemSettings.withFontSize fontSize
        )
        maybeColorFuzzer
        maybeColorFuzzer
        positionFuzzer
        fontSizeFuzzer


diagramTypeFuzzer : Fuzzer Diagram
diagramTypeFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant UserStoryMap
        , Fuzz.constant OpportunityCanvas
        , Fuzz.constant BusinessModelCanvas
        , Fuzz.constant Fourls
        , Fuzz.constant StartStopContinue
        , Fuzz.constant Kpt
        , Fuzz.constant UserPersona
        , Fuzz.constant MindMap
        , Fuzz.constant EmpathyMap
        , Fuzz.constant Table
        , Fuzz.constant SiteMap
        , Fuzz.constant GanttChart
        , Fuzz.constant ImpactMap
        , Fuzz.constant ErDiagram
        , Fuzz.constant Kanban
        , Fuzz.constant SequenceDiagram
        , Fuzz.constant Freeform
        ]


maybeColorFuzzer : Fuzzer (Maybe Color)
maybeColorFuzzer =
    Fuzz.maybe colorFuzzer


positionFuzzer : Fuzzer Position
positionFuzzer =
    Fuzz.tuple
        ( Fuzz.intRange -100 100
        , Fuzz.intRange -100 100
        )


fontSizeFuzzer : Fuzzer FontSize
fontSizeFuzzer =
    Fuzz.map (\i -> FontSize.fromInt i) (Fuzz.intRange 8 48)


colorFuzzer : Fuzzer Color
colorFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Color.white
        , Fuzz.constant Color.black
        , Fuzz.constant Color.gray
        , Fuzz.constant Color.lightGray
        , Fuzz.constant Color.yellow
        , Fuzz.constant Color.green
        , Fuzz.constant Color.blue
        , Fuzz.constant Color.orange
        , Fuzz.constant Color.pink
        , Fuzz.constant Color.red
        , Fuzz.constant Color.purple
        , Fuzz.constant Color.background1Defalut
        , Fuzz.constant Color.background2Defalut
        , Fuzz.constant Color.lineDefalut
        , Fuzz.constant Color.labelDefalut
        , Fuzz.constant Color.backgroundDefalut
        ]

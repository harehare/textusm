module Data.Fuzzer exposing (..)

import Data.Color as Color exposing (Color)
import Data.DiagramId as DiagramId exposing (DiagramId)
import Data.DiagramItem exposing (DiagramItem)
import Data.FontSize as FontSize exposing (FontSize)
import Data.Item as Item exposing (Children, Item, ItemType(..), Items)
import Data.ItemSettings as ItemSettings exposing (ItemSettings)
import Data.Position exposing (Position)
import Data.Text as Text exposing (Text)
import Data.Title as Title exposing (Title)
import Fuzz exposing (Fuzzer)
import TextUSM.Enum.Diagram exposing (Diagram(..))
import Time exposing (Posix)


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
        (Fuzz.maybe colorFuzzer)
        (Fuzz.maybe colorFuzzer)
        positionFuzzer
        fontSizeFuzzer


itemTypeFuzzer : Fuzzer ItemType
itemTypeFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Activities
        , Fuzz.constant Tasks
        , Fuzz.map Stories (Fuzz.intRange 0 3)
        , Fuzz.constant Comments
        ]


itemFuzzer : Fuzzer Item
itemFuzzer =
    Fuzz.map5
        (\lineNo text itemType itemSettings children ->
            Item.new
                |> Item.withLineNo lineNo
                |> Item.withText text
                |> Item.withItemType itemType
                |> Item.withItemSettings itemSettings
                |> Item.withChildren children
        )
        Fuzz.int
        Fuzz.string
        itemTypeFuzzer
        (Fuzz.maybe itemSettingsFuzzer)
        childrenFuzzer


itemsFuzzer : Fuzzer Items
itemsFuzzer =
    Fuzz.map Item.fromList (Fuzz.list itemFuzzer)


childrenFuzzer : Fuzzer Children
childrenFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Item.emptyChildren
        ]


diagramItemFuzzer : Fuzzer DiagramItem
diagramItemFuzzer =
    Fuzz.map DiagramItem (Fuzz.maybe diagramIdFuzzer)
        |> Fuzz.andMap textFuzzer
        |> Fuzz.andMap diagramTypeFuzzer
        |> Fuzz.andMap titleFuzzer
        |> Fuzz.andMap (Fuzz.maybe Fuzz.string)
        |> Fuzz.andMap Fuzz.bool
        |> Fuzz.andMap Fuzz.bool
        |> Fuzz.andMap Fuzz.bool
        |> Fuzz.andMap tagFuzzer
        |> Fuzz.andMap posixFuzzer
        |> Fuzz.andMap posixFuzzer


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


diagramIdFuzzer : Fuzzer DiagramId
diagramIdFuzzer =
    Fuzz.map DiagramId.fromString Fuzz.string


textFuzzer : Fuzzer Text
textFuzzer =
    Fuzz.map Text.fromString Fuzz.string


titleFuzzer : Fuzzer Title
titleFuzzer =
    Fuzz.map Title.fromString Fuzz.string


tagFuzzer : Fuzzer (Maybe (List (Maybe String)))
tagFuzzer =
    Fuzz.maybe Fuzz.string
        |> Fuzz.list
        |> Fuzz.maybe


posixFuzzer : Fuzzer Posix
posixFuzzer =
    Fuzz.map Time.millisToPosix (Fuzz.intRange 0 100000)

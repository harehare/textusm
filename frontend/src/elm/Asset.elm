module Asset exposing
    ( Asset
    , businessModelCanvas
    , empathyMap
    , erDiagram
    , fourLs
    , freeform
    , ganttChart
    , impactMap
    , kanban
    , kpt
    , logo
    , mindMap
    , opportunityCanvas
    , sequenceDiagram
    , siteMap
    , src
    , startStopContinue
    , table
    , useCaseDiagram
    , userPersona
    , userStoryMap
    )

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes as Attr


type Asset
    = Asset String


businessModelCanvas : Asset
businessModelCanvas =
    asset "diagram/bmc.svg"


empathyMap : Asset
empathyMap =
    asset "diagram/emm.svg"


erDiagram : Asset
erDiagram =
    asset "diagram/erd.svg"


fourLs : Asset
fourLs =
    asset "diagram/4ls.svg"


freeform : Asset
freeform =
    asset "diagram/free.svg"


ganttChart : Asset
ganttChart =
    asset "diagram/gct.svg"


impactMap : Asset
impactMap =
    asset "diagram/imm.svg"


kanban : Asset
kanban =
    asset "diagram/kanban.svg"


kpt : Asset
kpt =
    asset "diagram/kpt.svg"


logo : Asset
logo =
    asset "logo.svg"


mindMap : Asset
mindMap =
    asset "diagram/mmp.svg"


opportunityCanvas : Asset
opportunityCanvas =
    asset "diagram/opc.svg"


sequenceDiagram : Asset
sequenceDiagram =
    asset "diagram/sed.svg"


siteMap : Asset
siteMap =
    asset "diagram/smp.svg"


src : Asset -> Attribute msg
src (Asset url) =
    Attr.src url


startStopContinue : Asset
startStopContinue =
    asset "diagram/ssc.svg"


table : Asset
table =
    asset "diagram/table.svg"


useCaseDiagram : Asset
useCaseDiagram =
    asset "diagram/ucd.svg"


userPersona : Asset
userPersona =
    asset "diagram/persona.svg"


userStoryMap : Asset
userStoryMap =
    asset "diagram/usm.svg"


asset : String -> Asset
asset name =
    Asset ("/images/" ++ name)

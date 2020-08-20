module Asset exposing
    ( Asset
    , businessModelCanvas
    , empathyMap
    , erDiagram
    , fourLs
    , ganttChart
    , impactMap
    , kanban
    , kpt
    , logo
    , markdown
    , mindMap
    , opportunityCanvas
    , sequenceDiagram
    , siteMap
    , src
    , startStopContinue
    , table
    , userPersona
    , userStoryMap
    )

import Html exposing (Attribute)
import Html.Attributes as Attr


type Asset
    = Asset String


logo : Asset
logo =
    asset "logo.svg"


userStoryMap : Asset
userStoryMap =
    asset "diagram/usm.svg"


mindMap : Asset
mindMap =
    asset "diagram/mmp.svg"


impactMap : Asset
impactMap =
    asset "diagram/imm.svg"


empathyMap : Asset
empathyMap =
    asset "diagram/emm.svg"


siteMap : Asset
siteMap =
    asset "diagram/smp.svg"


businessModelCanvas : Asset
businessModelCanvas =
    asset "diagram/bmc.svg"


opportunityCanvas : Asset
opportunityCanvas =
    asset "diagram/opc.svg"


userPersona : Asset
userPersona =
    asset "diagram/persona.svg"


markdown : Asset
markdown =
    asset "diagram/md.svg"


ganttChart : Asset
ganttChart =
    asset "diagram/gct.svg"


erDiagram : Asset
erDiagram =
    asset "diagram/erd.svg"


kanban : Asset
kanban =
    asset "diagram/kanban.svg"


fourLs : Asset
fourLs =
    asset "diagram/4ls.svg"


startStopContinue : Asset
startStopContinue =
    asset "diagram/ssc.svg"


kpt : Asset
kpt =
    asset "diagram/kpt.svg"


table : Asset
table =
    asset "diagram/table.svg"


sequenceDiagram : Asset
sequenceDiagram =
    asset "diagram/sed.svg"


asset : String -> Asset
asset name =
    Asset ("/images/" ++ name)


src : Asset -> Attribute msg
src (Asset url) =
    Attr.src url

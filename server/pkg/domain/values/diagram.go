package values

import (
	"fmt"

	"github.com/99designs/gqlgen/graphql"
)

type Diagram string

const (
	DiagramUserStoryMap        Diagram = "USER_STORY_MAP"
	DiagramOpportunityCanvas   Diagram = "OPPORTUNITY_CANVAS"
	DiagramBusinessModelCanvas Diagram = "BUSINESS_MODEL_CANVAS"
	DiagramFourls              Diagram = "FOURLS"
	DiagramStartStopContinue   Diagram = "START_STOP_CONTINUE"
	DiagramKpt                 Diagram = "KPT"
	DiagramUserPersona         Diagram = "USER_PERSONA"
	DiagramMindMap             Diagram = "MIND_MAP"
	DiagramEmpathyMap          Diagram = "EMPATHY_MAP"
	DiagramSiteMap             Diagram = "SITE_MAP"
	DiagramGanttChart          Diagram = "GANTT_CHART"
	DiagramImpactMap           Diagram = "IMPACT_MAP"
	DiagramErDiagram           Diagram = "ER_DIAGRAM"
	DiagramKanban              Diagram = "KANBAN"
	DiagramTable               Diagram = "TABLE"
	DiagramSequenceDiagram     Diagram = "SEQUENCE_DIAGRAM"
	DiagramFreeform            Diagram = "FREEFORM"
	DiagramUseCaseDiagram      Diagram = "USE_CASE_DIAGRAM"
)

var AllDiagram = []Diagram{
	DiagramUserStoryMap,
	DiagramOpportunityCanvas,
	DiagramBusinessModelCanvas,
	DiagramFourls,
	DiagramStartStopContinue,
	DiagramKpt,
	DiagramUserPersona,
	DiagramMindMap,
	DiagramEmpathyMap,
	DiagramSiteMap,
	DiagramGanttChart,
	DiagramImpactMap,
	DiagramErDiagram,
	DiagramKanban,
	DiagramTable,
	DiagramSequenceDiagram,
	DiagramFreeform,
	DiagramUseCaseDiagram,
}

func (e Diagram) IsValid() bool {
	switch e {
	case DiagramUserStoryMap, DiagramOpportunityCanvas, DiagramBusinessModelCanvas, DiagramFourls, DiagramStartStopContinue, DiagramKpt, DiagramUserPersona, DiagramMindMap, DiagramEmpathyMap, DiagramSiteMap, DiagramGanttChart, DiagramImpactMap, DiagramErDiagram, DiagramKanban, DiagramTable, DiagramSequenceDiagram, DiagramFreeform, DiagramUseCaseDiagram:
		return true
	}
	return false
}

func (e Diagram) String() string {
	return string(e)
}

func MarshalDiagram(d *Diagram) graphql.Marshaler {
	return graphql.MarshalString(d.String())
}

func UnmarshalDiagram(v interface{}) (*Diagram, error) {
	v2, err := graphql.UnmarshalString(v)
	if err != nil {
		return nil, err
	}
	d := Diagram(v2)
	if !d.IsValid() {
		return nil, fmt.Errorf("%s is not a valid Diagram", v2)
	}
	return &d, nil
}

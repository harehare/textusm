import { CanvasItem } from "./CanvasItem";

type OpportunityCanvas = {
  name: "OpportunityCanvas";
  problems: CanvasItem;
  solutionIdeas: CanvasItem;
  usersAndCustomers: CanvasItem;
  solutionsToday: CanvasItem;
  businessChallenges: CanvasItem;
  howWillUsersUseSolution: CanvasItem;
  userMetrics: CanvasItem;
  adoptionStrategy: CanvasItem;
  businessBenefitsAndMetrics: CanvasItem;
  budget: CanvasItem;
};

let OpportunityCanvas = {
  toString: (opportunityCanvas: OpportunityCanvas): string => {
    const items = [
      "problems",
      "solutionIdeas",
      "usersAndCustomers",
      "solutionsToday",
      "businessChallenges",
      "howWillUsersUseSolution",
      "userMetrics",
      "adoptionStrategy",
      "businessBenefitsAndMetrics",
      "budget",
    ];

    return items
      .map((item) => {
        return CanvasItem.toString(opportunityCanvas[item]);
      })
      .join("");
  },
};

export { OpportunityCanvas };

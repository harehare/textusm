import { toString, toTypeString } from "../model";

test("KPT to string.", () => {
  const text = `k
    k
    text
p
    p
    text
t
    t
    text
`;
  expect(
    toString({
      keep: {
        title: "k",
        text: ["k", "text"]
      },
      problem: {
        title: "p",
        text: ["p", "text"]
      },
      try: {
        title: "t",
        text: ["t", "text"]
      }
    })
  ).toBe(text);
});

test("Start stop continue to string.", () => {
  const text = `start
    start
    text
stop
    stop
    text
continue
    continue
    text
`;
  expect(
    toString({
      start: {
        title: "start",
        text: ["start", "text"]
      },
      stop: {
        title: "stop",
        text: ["stop", "text"]
      },
      continue: {
        title: "continue",
        text: ["continue", "text"]
      }
    })
  ).toBe(text);
});

test("4LS to string.", () => {
  const text = `liked
    liked
    text
learned
    learned
    text
lacked
    lacked
    text
longedFor
    longedFor
    text
`;
  expect(
    toString({
      liked: {
        title: "liked",
        text: ["liked", "text"]
      },
      learned: {
        title: "learned",
        text: ["learned", "text"]
      },
      lacked: {
        title: "lacked",
        text: ["lacked", "text"]
      },
      longedFor: {
        title: "longedFor",
        text: ["longedFor", "text"]
      }
    })
  ).toBe(text);
});

test("Opportunity Canvas to string.", () => {
  const text = `problems
    problems
    text
solutionIdeas
    solutionIdeas
    text
usersAndCustomers
    usersAndCustomers
    text
solutionsToday
    solutionsToday
    text
businessChallenges
    businessChallenges
    text
howWillUsersUseSolution
    howWillUsersUseSolution
    text
userMetrics
    userMetrics
    text
adoptionStrategy
    adoptionStrategy
    text
businessBenefitsAndMetrics
    businessBenefitsAndMetrics
    text
budget
    budget
    text
`;
  expect(
    toString({
      problems: {
        title: "problems",
        text: ["problems", "text"]
      },
      solutionIdeas: {
        title: "solutionIdeas",
        text: ["solutionIdeas", "text"]
      },
      usersAndCustomers: {
        title: "usersAndCustomers",
        text: ["usersAndCustomers", "text"]
      },
      solutionsToday: {
        title: "solutionsToday",
        text: ["solutionsToday", "text"]
      },
      businessChallenges: {
        title: "businessChallenges",
        text: ["businessChallenges", "text"]
      },
      howWillUsersUseSolution: {
        title: "howWillUsersUseSolution",
        text: ["howWillUsersUseSolution", "text"]
      },
      userMetrics: {
        title: "userMetrics",
        text: ["userMetrics", "text"]
      },
      adoptionStrategy: {
        title: "adoptionStrategy",
        text: ["adoptionStrategy", "text"]
      },
      businessBenefitsAndMetrics: {
        title: "businessBenefitsAndMetrics",
        text: ["businessBenefitsAndMetrics", "text"]
      },
      budget: {
        title: "budget",
        text: ["budget", "text"]
      }
    })
  ).toBe(text);
});

test("Business Model Canvas to string.", () => {
  const text = `keyPartners
    keyPartners
    text
customerSegments
    customerSegments
    text
valueProposition
    valueProposition
    text
keyActivities
    keyActivities
    text
channels
    channels
    text
revenueStreams
    revenueStreams
    text
costStructure
    costStructure
    text
keyResources
    keyResources
    text
customerRelationships
    customerRelationships
    text
`;
  expect(
    toString({
      keyPartners: {
        title: "keyPartners",
        text: ["keyPartners", "text"]
      },
      customerSegments: {
        title: "customerSegments",
        text: ["customerSegments", "text"]
      },
      valueProposition: {
        title: "valueProposition",
        text: ["valueProposition", "text"]
      },
      keyActivities: {
        title: "keyActivities",
        text: ["keyActivities", "text"]
      },
      channels: {
        title: "channels",
        text: ["channels", "text"]
      },
      revenueStreams: {
        title: "revenueStreams",
        text: ["revenueStreams", "text"]
      },
      costStructure: {
        title: "costStructure",
        text: ["costStructure", "text"]
      },
      keyResources: {
        title: "keyResources",
        text: ["keyResources", "text"]
      },
      customerRelationships: {
        title: "customerRelationships",
        text: ["customerRelationships", "text"]
      }
    })
  ).toBe(text);
});

test("User Persona to string.", () => {
  const text = `title
    url
whoAmI
    whoAmI
    text
item1
    item1
    text
item2
    item2
    text
item3
    item3
    text
item4
    item4
    text
item5
    item5
    text
item6
    item6
    text
item7
    item7
    text
`;

  expect(
    toString({
      url: {
        title: "title",
        url: "url"
      },
      whoAmI: {
        title: "whoAmI",
        text: ["whoAmI", "text"]
      },
      item1: {
        title: "item1",
        text: ["item1", "text"]
      },
      item2: {
        title: "item2",
        text: ["item2", "text"]
      },
      item3: {
        title: "item3",
        text: ["item3", "text"]
      },
      item4: {
        title: "item4",
        text: ["item4", "text"]
      },
      item5: {
        title: "item5",
        text: ["item5", "text"]
      },
      item6: {
        title: "item6",
        text: ["item6", "text"]
      },
      item7: {
        title: "item7",
        text: ["item7", "text"]
      }
    })
  ).toBe(text);
});

test("Empathy Map to string.", () => {
  const text = `imageUrl
says
    says
    text
thinks
    thinks
    text
does
    does
    text
feels
    feels
    text
`;

  expect(
    toString({
      imageUrl: "imageUrl",
      says: {
        title: "says",
        text: ["says", "text"]
      },
      thinks: {
        title: "thinks",
        text: ["thinks", "text"]
      },
      does: {
        title: "does",
        text: ["does", "text"]
      },
      feels: {
        title: "feels",
        text: ["feels", "text"]
      }
    })
  ).toBe(text);
});

test("User Story Map to string.", () => {
  const text = `activity
    task
        story1
            story2`;

  expect(
    toString({
      activities: [
        {
          name: "activity",
          tasks: [
            {
              name: "task",
              stories: [
                {
                  name: "story1",
                  release: 1
                },
                {
                  name: "story2",
                  release: 2
                }
              ]
            }
          ]
        }
      ]
    })
  ).toBe(text);
});

test("Site Map, Mind Map to string.", () => {
  const text = `test1
    test2
        test22
    test3
        test33
    test4
        test44`;

  expect(
    toString({
      node: {
        text: "test1",
        children: [
          { text: "test2", children: [{ text: "test22", children: [] }] },
          { text: "test3", children: [{ text: "test33", children: [] }] },
          { text: "test4", children: [{ text: "test44", children: [] }] }
        ]
      }
    })
  ).toBe(text);
});

test("Customer Journey Map to string.", () => {
  const text = `Header
    Task
    Questions
    Touchpoints
    Emotions
    Influences
    Weaknesses
Discover
    Task
    Questions
    Touchpoints
    Emotions
    Influences
    Weaknesses
Research
    Task
    Questions
    Touchpoints
    Emotions
    Influences
    Weaknesses
Purchase
    Task
    Questions
    Touchpoints
    Emotions
    Influences
    Weaknesses
Delivery
    Task
    Questions
    Touchpoints
    Emotions
    Influences
    Weaknesses
Post-Sales
    Task
    Questions
    Touchpoints
    Emotions
    Influences
    Weaknesses`;

  expect(
    toString({
      header: {
        title: "Header",
        text: [
          "Task",
          "Questions",
          "Touchpoints",
          "Emotions",
          "Influences",
          "Weaknesses"
        ]
      },
      items: [
        {
          title: "Discover",
          text: [
            "Task",
            "Questions",
            "Touchpoints",
            "Emotions",
            "Influences",
            "Weaknesses"
          ]
        },
        {
          title: "Research",
          text: [
            "Task",
            "Questions",
            "Touchpoints",
            "Emotions",
            "Influences",
            "Weaknesses"
          ]
        },
        {
          title: "Purchase",
          text: [
            "Task",
            "Questions",
            "Touchpoints",
            "Emotions",
            "Influences",
            "Weaknesses"
          ]
        },
        {
          title: "Delivery",
          text: [
            "Task",
            "Questions",
            "Touchpoints",
            "Emotions",
            "Influences",
            "Weaknesses"
          ]
        },
        {
          title: "Post-Sales",
          text: [
            "Task",
            "Questions",
            "Touchpoints",
            "Emotions",
            "Influences",
            "Weaknesses"
          ]
        }
      ]
    })
  ).toBe(text);
});

test("KPT type to string.", () => {
  expect(
    toTypeString({
      keep: {
        title: "k",
        text: ["k", "text"]
      },
      problem: {
        title: "p",
        text: ["p", "text"]
      },
      try: {
        title: "t",
        text: ["t", "text"]
      }
    })
  ).toBe("Kpt");
});

test("Start stop continue type to string.", () => {
  expect(
    toTypeString({
      start: {
        title: "start",
        text: ["start", "text"]
      },
      stop: {
        title: "stop",
        text: ["stop", "text"]
      },
      continue: {
        title: "continue",
        text: ["continue", "text"]
      }
    })
  ).toBe("StartStopContinue");
});

test("4LS type to string.", () => {
  expect(
    toTypeString({
      liked: {
        title: "liked",
        text: ["liked", "text"]
      },
      learned: {
        title: "learned",
        text: ["learned", "text"]
      },
      lacked: {
        title: "lacked",
        text: ["lacked", "text"]
      },
      longedFor: {
        title: "longedFor",
        text: ["longedFor", "text"]
      }
    })
  ).toBe("4Ls");
});

test("Opportunity Canvas type to string.", () => {
  expect(
    toTypeString({
      problems: {
        title: "problems",
        text: ["problems", "text"]
      },
      solutionIdeas: {
        title: "solutionIdeas",
        text: ["solutionIdeas", "text"]
      },
      usersAndCustomers: {
        title: "usersAndCustomers",
        text: ["usersAndCustomers", "text"]
      },
      solutionsToday: {
        title: "solutionsToday",
        text: ["solutionsToday", "text"]
      },
      businessChallenges: {
        title: "businessChallenges",
        text: ["businessChallenges", "text"]
      },
      howWillUsersUseSolution: {
        title: "howWillUsersUseSolution",
        text: ["howWillUsersUseSolution", "text"]
      },
      userMetrics: {
        title: "userMetrics",
        text: ["userMetrics", "text"]
      },
      adoptionStrategy: {
        title: "adoptionStrategy",
        text: ["adoptionStrategy", "text"]
      },
      businessBenefitsAndMetrics: {
        title: "businessBenefitsAndMetrics",
        text: ["businessBenefitsAndMetrics", "text"]
      },
      budget: {
        title: "budget",
        text: ["budget", "text"]
      }
    })
  ).toBe("OpportunityCanvas");
});

test("Business Model Canvas type to string.", () => {
  expect(
    toTypeString({
      keyPartners: {
        title: "keyPartners",
        text: ["keyPartners", "text"]
      },
      customerSegments: {
        title: "customerSegments",
        text: ["customerSegments", "text"]
      },
      valueProposition: {
        title: "valueProposition",
        text: ["valueProposition", "text"]
      },
      keyActivities: {
        title: "keyActivities",
        text: ["keyActivities", "text"]
      },
      channels: {
        title: "channels",
        text: ["channels", "text"]
      },
      revenueStreams: {
        title: "revenueStreams",
        text: ["revenueStreams", "text"]
      },
      costStructure: {
        title: "costStructure",
        text: ["costStructure", "text"]
      },
      keyResources: {
        title: "keyResources",
        text: ["keyResources", "text"]
      },
      customerRelationships: {
        title: "customerRelationships",
        text: ["customerRelationships", "text"]
      }
    })
  ).toBe("BusinessModelCanvas");
});

test("User Persona type to string.", () => {
  expect(
    toTypeString({
      url: {
        title: "title",
        url: "url"
      },
      whoAmI: {
        title: "whoAmI",
        text: ["whoAmI", "text"]
      },
      item1: {
        title: "item1",
        text: ["item1", "text"]
      },
      item2: {
        title: "item2",
        text: ["item2", "text"]
      },
      item3: {
        title: "item3",
        text: ["item3", "text"]
      },
      item4: {
        title: "item4",
        text: ["item4", "text"]
      },
      item5: {
        title: "item5",
        text: ["item5", "text"]
      },
      item6: {
        title: "item6",
        text: ["item6", "text"]
      },
      item7: {
        title: "item7",
        text: ["item7", "text"]
      }
    })
  ).toBe("UserPersona");
});

test("Empathy Map type to string.", () => {
  expect(
    toTypeString({
      imageUrl: "imageUrl",
      says: {
        title: "says",
        text: ["says", "text"]
      },
      thinks: {
        title: "thinks",
        text: ["thinks", "text"]
      },
      does: {
        title: "does",
        text: ["does", "text"]
      },
      feels: {
        title: "feels",
        text: ["feels", "text"]
      }
    })
  ).toBe("EmpathyMap");
});

test("User Story Map type to string.", () => {
  expect(
    toTypeString({
      activities: [
        {
          name: "activity",
          tasks: [
            {
              name: "task",
              stories: [
                {
                  name: "story1",
                  release: 1
                },
                {
                  name: "story2",
                  release: 2
                }
              ]
            }
          ]
        }
      ]
    })
  ).toBe("UserStoryMap");
});

test("Mind Map type to string.", () => {
  expect(
    toTypeString({
      node: {
        text: "test1",
        children: [
          { text: "test2", children: [{ text: "test22", children: [] }] },
          { text: "test3", children: [{ text: "test33", children: [] }] },
          { text: "test4", children: [{ text: "test44", children: [] }] }
        ]
      }
    })
  ).toBe("MindMap");
});

test("Customer Journey Map type to string.", () => {
  expect(
    toTypeString({
      header: {
        title: "header",
        text: [
          "Task",
          "Questions",
          "Touchpoints",
          "Emotions",
          "Influences",
          "Weaknesses"
        ]
      },
      items: [
        {
          title: "Discover",
          text: [
            "Task",
            "Questions",
            "Touchpoints",
            "Emotions",
            "Influences",
            "Weaknesses"
          ]
        },
        {
          title: "Research",
          text: [
            "Task",
            "Questions",
            "Touchpoints",
            "Emotions",
            "Influences",
            "Weaknesses"
          ]
        },
        {
          title: "Purchase",
          text: [
            "Task",
            "Questions",
            "Touchpoints",
            "Emotions",
            "Influences",
            "Weaknesses"
          ]
        },
        {
          title: "Delivery",
          text: [
            "Task",
            "Questions",
            "Touchpoints",
            "Emotions",
            "Influences",
            "Weaknesses"
          ]
        },
        {
          title: "Post-Sales",
          text: [
            "Task",
            "Questions",
            "Touchpoints",
            "Emotions",
            "Influences",
            "Weaknesses"
          ]
        }
      ]
    })
  ).toBe("CustomerJourneyMap");
});

test("Gantt Chart type to string.", () => {
  expect(
    toString({
      from: "2019-12-26",
      to: "2020-01-31",
      title: "Test",
      chartitems: [
        {
          title: "subtitle1",
          schedules: [{ from: "2019-12-26", to: "2019-12-31", title: "task1" }]
        }
      ]
    })
  ).toBe(
    `2019-12-26,2020-01-31: Test\n    subtitle1\n        2019-12-26,2019-12-31: task1`
  );
});

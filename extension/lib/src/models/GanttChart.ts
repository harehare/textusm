type GanttChart = {
  name: "GanttChart";
  from: string;
  to: string;
  chartItems: GanttChartItem[];
};

type GanttChartItem = {
  title: string;
  schedules: Schedule[];
};

type Schedule = {
  from: string;
  to: string;
  title: string;
};

function toString(ganttChart: GanttChart): string {
  return `${ganttChart.from} ${ganttChart.to}\n${ganttChart.chartItems
    .map((item) => {
      return `    ${item.title}\n${item.schedules
        .map((schedule) => {
          return `        ${schedule.title}\n            ${schedule.from} ${schedule.to}`;
        })
        .join("\n")}`;
    })
    .join("\n")}`;
}

export { GanttChart, toString };

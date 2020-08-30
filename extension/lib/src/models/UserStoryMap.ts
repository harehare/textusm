type UserStoryMap = {
  name: "UserStoryMap";
  labels?: string[];
  activities: Activity[];
};

type Activity = {
  name: string;
  tasks: Task[];
};

type Task = {
  name: string;
  stories: Story[];
};

type Story = {
  name: string;
  release: number;
};

function concat<T>(x: T[], y: T[]): T[] {
  return x.concat(y);
}

function flatMap<T, U>(f: (x: T) => U[], xs: T[]): U[] {
  return xs.map(f).reduce(concat, []);
}

function toString(userStoryMap: UserStoryMap): string {
  const labels =
    userStoryMap.labels && userStoryMap.labels.length > 0
      ? `#labels: ${userStoryMap.labels.join(",")}\n`
      : "";
  return `${labels}${flatMap((activity) => {
    return [activity.name].concat(
      flatMap((task) => {
        return ["    " + task.name].concat(
          flatMap((story) => {
            return ["    ".repeat(story.release + 1) + story.name];
          }, task.stories)
        );
      }, activity.tasks)
    );
  }, userStoryMap.activities).join("\n")}`;
}

export { UserStoryMap, toString };

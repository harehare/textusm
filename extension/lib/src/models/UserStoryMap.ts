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

export { UserStoryMap };

package main

import (
	"context"
	"fmt"
	"time"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

type GithubExporter struct {
	client     *github.Client
	project    *github.Project
	columns    map[string]*github.ProjectColumn
	milestones map[string]*github.Milestone
}

func NewGithubExporter(data *UsmData) *GithubExporter {
	ctx := context.Background()
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: data.OauthToken},
	)
	tc := oauth2.NewClient(ctx, ts)
	client := github.NewClient(tc)

	return &GithubExporter{
		client:     client,
		columns:    map[string]*github.ProjectColumn{},
		milestones: map[string]*github.Milestone{},
	}
}

func (e *GithubExporter) CreateProject(ctx context.Context, data *UsmData) error {
	project, _, err := e.client.Repositories.CreateProject(ctx, data.Github.Owner, data.Github.Repo, &github.ProjectOptions{
		Name: data.Name,
	})
	e.project = project

	return err
}

func (e *GithubExporter) CreateList(ctx context.Context, data *UsmData, release Release) error {
	column, _, err := e.client.Projects.CreateProjectColumn(ctx, *e.project.ID, &github.ProjectColumnOptions{Name: release.Name})

	if err != nil {
		return err
	}

	e.columns[release.Name] = column

	period, _ := time.Parse("2006-01-02", release.Period)
	milestone, response, err := e.client.Issues.CreateMilestone(ctx, data.Github.Owner, data.Github.Repo, &github.Milestone{
		Title: &release.Name,
		DueOn: &period,
	})

	if response.StatusCode == 422 {
		allMilestone, _, err := e.client.Issues.ListMilestones(ctx, data.Github.Owner, data.Github.Repo, &github.MilestoneListOptions{})

		if err != nil {
			return err
		}

		for _, m := range allMilestone {
			if *m.Title == release.Name {
				milestone = m
				break
			}
		}
	}

	if milestone == nil {
		return err
	}

	e.milestones[release.Name] = milestone

	return nil
}

func (e *GithubExporter) CreateCard(ctx context.Context, data *UsmData, task Task) error {
	for _, story := range task.Stories {
		releaseName := fmt.Sprintf("RELEASE%d", story.Release)
		var issue *github.Issue

		if _, ok := e.milestones[releaseName]; ok {
			i, _, err := e.client.Issues.Create(ctx, data.Github.Owner, data.Github.Repo, &github.IssueRequest{
				Title:     &story.Name,
				Milestone: e.milestones[releaseName].Number,
			})

			if err != nil {
				return err
			}
			issue = i
		}

		if column, ok := e.columns[releaseName]; ok {
			_, _, err := e.client.Projects.CreateProjectCard(ctx, *column.ID, &github.ProjectCardOptions{
				ContentID:   *issue.ID,
				ContentType: "Issue",
			})

			if err != nil {
				return err
			}
		}
	}

	return nil
}

func (e *GithubExporter) CreateURL(data *UsmData) string {
	return "https://github.com/" + data.Github.Owner + "/" + data.Github.Repo + "/issues"
}

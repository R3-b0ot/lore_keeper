# Overview Module

## Purpose
The Overview is the project's home, not a dashboard full of unrelated widgets. It answers: **What is this project, what was I doing, and where should I continue?**

## Layout

```text
Project Header
├── Project name / icon / description
├── Global search
└── Quick actions

Main
├── Continue Writing
├── Recent Activity
├── Project Snapshot
├── Recent Characters / Locations / Events
└── Pinned / Favorite items
```

## Core Behavior

- Open directly when a project is selected.
- Remember the last useful workspace per project.
- Continue Writing opens the last manuscript/scene.
- Recent items are real persisted entities, not generated placeholders.
- Snapshot counts are lightweight and never dominate the page.
- Quick actions create entities through shared creation flows.

## Quick Actions

- New Manuscript
- New Character
- New Location
- New Event
- New Arc
- Add Map
- Open Calendar

## Interactions

Clicking any entity opens its contextual workspace/inspector. The user should not lose project context when opening an item.

## Connections

Overview aggregates data from every module but owns none of it. It must never duplicate entity records.

## Out of Scope

- analytics dashboard;
- fake productivity metrics;
- complex charts;
- module-specific editing forms.

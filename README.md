# Roblox-Quest-Demo
A Roblox quest system I built with configurable objectives, rewards, progress tracking, and DataStore saving.

# Roblox Quest Framework

A quest framework I built for Roblox as a portfolio project.

The goal of this project was to create a reusable quest system that can track different objective types, save player progress, and reward players when quests are completed.

## Features

* Configurable quests
* Multiple objective types
* Progress tracking
* Reward system
* Quest persistence using DataStores
* Serverside validation
* Modular service architecture

## Objective Types

### Walk

Tracks the distance a player walks.

### Jump

Tracks the number of jumps performed by a player.

The framework can easily be expanded with additional objective types such as:

* Collect Items
* Reach Location
* Interact With NPC
* Defeat Enemy

## Structure

### QuestService

Handles quest assignment, progress updates, objective completion checks, and quest completion.

### QuestStore

Stores active quest data for players while they are in the server.

### QuestTracker

Tracks player actions and updates quest progress.

### RewardService

Handles quest rewards.

### DataService

Loads and saves quest progress using DataStores.

### QuestConfig

Contains all quest definitions and objectives.

## Example Quest

```lua
StarterQuest = {
	Name = "Starter Quest",

	Objectives = {
		{
			Type = "Walk",
			Amount = 250
		},

		{
			Type = "Jump",
			Amount = 10
		}
	},

	Rewards = {
		Coins = 100
	}
}
```

## Demo

Video: https://www.youtube.com/watch?v=_z80Y18qDKo

Roblox Place: https://www.roblox.com/games/112016084362258/Quest-Demo

## Notes

This project was built to practice designing modular gameplay systems and working with DataStores, serverside validation, and progress tracking. The framework was intentionally designed to be easy to extend with new quest types, rewards, and objectives.

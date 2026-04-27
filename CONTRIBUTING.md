# Contributing

This document walks you through the basic contributing guidelines we will attempt to stick to.

## Communication

Communication should be done primarily through the custom Discord server. This will centralize our communication and make it easier for cross-platform communication.

## File Structure

- File/Dir Names: utilize underscores (\_) for spaces.
- File/Dir Locations: Should be located in their appropriate location (examples: a hardware feature should go in rpi, a frontend feature should go in podwork/packages/frontend, etc.)

## Issues

Issues (sometimes referred to as "tickets") should be managed in the [project kanban board](https://github.com/users/m-riley04/projects/17/views/1). They should have the following attached to them from the board:

1. Estimate/Story Points
2. Priority
3. Sprint (aka Milestone)
4. Assignees

Using the board, you can move the issues into their respective states (backlog, in-progress, review, etc.)

## Branches

### Release Branch

All releases should be based on `main`, with no `dev` branch existing.

- This is slightly different than some popular methods, but it is what was advised to us for this class.

### Feature Branches

Feature branches should be named according to the issue/ticket they are connected to.

The format should be `I-[issue_id]`, where `I` stands for "Issue", and `issue_id` is the issue's ID.

Examples:

    Issue ID: 5
    Branch Name: I-5
<!-- break -->
    Issue ID: 42
    Branch Name: I-42
<!-- break -->
    Issue ID: 102
    Branch Name: I-102

## Pull Requests

PRs should be prefixed with the branch's name, followed by a brief description of the PR. Most likely, this should closely mirror the issue/ticket name.

## Coding

### General IDE Conventions

- Tabs vs Spaces: spaces
- Tab Size: 4

### Coding Conventions

For coding conventions, we should try to stick to whatever the recommended conventions are dictated by the language/framework. However in general, prefer the following:

- Class names: PascalCase
- Function names: camelCase
- Variable/param names: camelCase or snake_case (snake_case might be better for JS/TS and DTOs)
- Constant/global variable names: UPPER_SNAKE

There are also other things we could think about that could be enabled in the linter (import organizing, unused imports, long functions/parameters, etc.), but for now, this is what we should try to stick to for consistency.

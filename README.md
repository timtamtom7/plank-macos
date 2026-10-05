# Plank

Bookmarks and a cleaning scheduler for macOS.

## What it does

- Bookmark store
- scheduled cleaning
- reports

## Targets

- macOS with widgets

## Structure

Key types:

- ``BookmarkStore`/`BookmarkRow``
- ``ScheduleManager``
- ``CleaningReport`/`CleaningTask``
- ``WidgetIntelligenceEngine``
- ``ImportExportService``

`WidgetIntelligenceEngine` suggests it surfaces cleaning opportunities rather than only reporting them.

## Status

Apple-platform experiment built to explore what an AI coding agent could produce for a native app. Not actively maintained.

Xcode projects here were generated with XcodeGen (`project.yml`) unless noted; open the `.xcodeproj` directly.

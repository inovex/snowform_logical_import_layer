# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Views of source tables without a comment no longer get the literal comment `'None'`. Columns without a comment no longer get an empty `COMMENT ''`.
- Single quotes in table comments are now escaped.

### Changed

- README usage examples now reference the GitHub module source.

## [0.0.4] - 2026-03-22

### Fixed

- Creating views from imported tables whose columns have no comments no longer fails (#3).

## [0.0.3] - 2026-03-22

Same commit as 0.0.2.

## [0.0.2] - 2026-03-22

### Changed

- The stored procedure is named `CREATE_VIEW_WITH_COLUMN_COMMENTS` (capitalized) for easier usage (#2).

## [0.0.1] - 2025-11-21

### Added

- This CHANGELOG file to serve as a standardized open source project CHANGELOG.
- README now contains a working example of module usage.

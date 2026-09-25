# Inventory Staging Location Uniqueness Design

## Goal

Ensure staging imports only affect staged inventory while allowing the same card variant to exist in multiple live inventory locations.

## Current Problem

`inventory_cards` currently has a global unique index on `(scryfall_id, foil, condition)`. That means:

- staging imports can collide with live inventory rows
- live inventory cannot store the same card variant in multiple locations
- converting staged rows into a location can fail or produce incorrect merge behavior

The recent ManaBox import fix also introduced an application-level merge that can currently match any card with the same key, including live inventory rows, which is broader than intended.

## Intended Behavior

- Staging imports merge only with other staged rows.
- Live inventory may contain the same `(scryfall_id, foil, condition)` in different `inventory_location_id` values.
- When converting staged rows into a selected location, matching rows in that destination location should have their `quantity` increased rather than creating duplicates.
- Inventory in unrelated locations must not be changed during staging import or conversion.

## Recommended Model

Use separate uniqueness boundaries for staged and live rows:

- staged rows: unique on `(scryfall_id, foil, condition)` where `staged = true`
- live rows: unique on `(scryfall_id, foil, condition, inventory_location_id)` where `staged = false`

This keeps staging isolated while letting live inventory be location-scoped.

## Application Changes

### Staging Import

`InventoryImporter::Manabox` should:

- continue collapsing duplicate rows within a single CSV by `(scryfall_id, foil, condition)`
- only look up existing rows with `staged: true`
- never merge into live inventory rows

### Convert To Inventory

`Inventory::CardsController#convert_to_inventory` should stop using a blanket `update_all` for staged rows.

Instead, for each staged card:

- find an existing live inventory row in the selected location with the same `(scryfall_id, foil, condition)`
- if found, add the staged quantity into that live row and remove the staged row
- otherwise, convert the staged row into a live row by assigning the chosen location and clearing `staged`
- apply `tcgplayer` consistently during conversion

## Migration Strategy

Replace the current unique index on `(scryfall_id, foil, condition)` with two partial unique indexes:

- `(scryfall_id, foil, condition)` where `staged = true`
- `(scryfall_id, foil, condition, inventory_location_id)` where `staged = false`

Because existing data may contain live rows with `staged = nil`, the migration should normalize that state before creating partial indexes or make the app treat `nil` consistently as live during backfill.

## Tests

Add regression coverage for:

- staging import merges duplicate rows in one CSV
- staging import merges into existing staged rows only
- staging import does not modify a live row with the same card key
- converting staged rows merges into an existing live row in the chosen location
- the same card key can exist in two different live locations

## Risks

- Existing rows with `staged = nil` need explicit handling during migration.
- Bulk `update_all` conversion currently skips merge logic, so conversion behavior must move to row-wise logic.
- Partial unique indexes rely on consistent staged/live state; leaving ambiguous booleans will create future edge cases.

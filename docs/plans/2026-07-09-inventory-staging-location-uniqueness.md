# Inventory Staging Location Uniqueness Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Keep staging imports isolated from live inventory while allowing duplicate card variants across different live inventory locations and merging quantities only within the selected destination location.

**Architecture:** Replace the global inventory uniqueness rule with separate staged and live partial unique indexes. Update the ManaBox staging importer to merge only staged rows, then update inventory conversion to merge row-by-row into the chosen location instead of moving every staged row with `update_all`.

**Tech Stack:** Rails 7, ActiveRecord, PostgreSQL partial indexes, RSpec

---

### Task 1: Add failing importer regression tests

**Files:**
- Modify: `spec/services/csv_service_spec.rb`

**Step 1: Write the failing tests**

Add tests covering:

- staging import does not change a live inventory row with the same `(scryfall_id, foil, condition)`
- staging import merges with an existing staged row only

**Step 2: Run test to verify it fails**

Run: `docker compose exec iron_tusk_toolbox bundle exec rspec spec/services/csv_service_spec.rb`
Expected: FAIL with the importer merging into the wrong row or raising uniqueness errors.

**Step 3: Write minimal implementation**

Update the importer lookup to scope merges to staged rows only.

**Step 4: Run test to verify it passes**

Run: `docker compose exec iron_tusk_toolbox bundle exec rspec spec/services/csv_service_spec.rb`
Expected: PASS

### Task 2: Add failing conversion and location uniqueness tests

**Files:**
- Modify: `spec/services/csv_service_spec.rb` if shared helpers are useful
- Modify: `spec/services/inventory/location_merge_service_spec.rb` only if needed
- Create: `spec/requests/inventory/cards_convert_to_inventory_spec.rb`

**Step 1: Write the failing tests**

Add request or controller-level tests covering:

- converting staged cards merges into an existing live row in the chosen location
- the same card key can exist in two different live locations

**Step 2: Run test to verify it fails**

Run: `docker compose exec iron_tusk_toolbox bundle exec rspec spec/requests/inventory/cards_convert_to_inventory_spec.rb`
Expected: FAIL because conversion still uses `update_all` and the schema still forbids cross-location duplicates.

**Step 3: Write minimal implementation**

Refactor conversion into row-wise merge logic and prepare schema changes.

**Step 4: Run test to verify it passes**

Run: `docker compose exec iron_tusk_toolbox bundle exec rspec spec/requests/inventory/cards_convert_to_inventory_spec.rb`
Expected: PASS

### Task 3: Replace global uniqueness with staged/live partial indexes

**Files:**
- Create: `db/migrate/*_scope_inventory_card_uniqueness_by_stage_and_location.rb`
- Modify: `db/schema.rb`

**Step 1: Write the migration**

The migration should:

- normalize ambiguous `staged` values if needed
- remove the unique index on `(scryfall_id, foil, condition)`
- add a unique partial index for staged rows on `(scryfall_id, foil, condition)` where `staged = true`
- add a unique partial index for live rows on `(scryfall_id, foil, condition, inventory_location_id)` where `staged = false`

**Step 2: Run migration in test/dev**

Run: `docker compose exec iron_tusk_toolbox bin/rails db:migrate`
Expected: migration succeeds

**Step 3: Re-run affected tests**

Run: `docker compose exec iron_tusk_toolbox bundle exec rspec spec/services/csv_service_spec.rb spec/requests/inventory/cards_convert_to_inventory_spec.rb`
Expected: PASS

### Task 4: Tighten importer merge scope

**Files:**
- Modify: `app/services/inventory_importer/manabox.rb`

**Step 1: Scope lookup to staged rows**

Use `find_or_initialize_by` with `staged: true` so staging imports only ever merge with staged rows.

**Step 2: Preserve duplicate-row aggregation**

Keep `prepare_rows` collapsing duplicates within the uploaded file.

**Step 3: Run importer specs**

Run: `docker compose exec iron_tusk_toolbox bundle exec rspec spec/services/csv_service_spec.rb`
Expected: PASS

### Task 5: Refactor conversion to merge into destination location

**Files:**
- Modify: `app/controllers/inventory/cards_controller.rb`

**Step 1: Replace bulk update conversion**

Iterate staged cards and:

- find a live destination row by `scryfall_id`, `foil`, `condition`, `inventory_location_id`, `staged: false`
- merge quantity and delete staged row when a destination row exists
- otherwise assign destination location, clear `staged`, and set `tcgplayer`

**Step 2: Run conversion tests**

Run: `docker compose exec iron_tusk_toolbox bundle exec rspec spec/requests/inventory/cards_convert_to_inventory_spec.rb`
Expected: PASS

### Task 6: Final verification

**Files:**
- Verify only

**Step 1: Run focused test suite**

Run: `docker compose exec iron_tusk_toolbox bundle exec rspec spec/services/csv_service_spec.rb spec/requests/inventory/cards_convert_to_inventory_spec.rb spec/services/inventory/location_merge_service_spec.rb`
Expected: PASS

**Step 2: Run lint**

Run: `docker compose exec iron_tusk_toolbox bundle exec rubocop app/services/inventory_importer/manabox.rb app/controllers/inventory/cards_controller.rb spec/services/csv_service_spec.rb spec/requests/inventory/cards_convert_to_inventory_spec.rb`
Expected: no offenses

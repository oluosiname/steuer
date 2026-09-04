# Changelog

## 1.2.0 - 2026-09-04

* Add `Steuernummer#finanzamt_code`, returning the four-digit Bundesfinanzamtsnummer (BUFA-Nr) — the leading four digits of the federal-13 form — so callers no longer slice the converted number themselves.
* Add `Steuernummer#finanzamt_name`, resolving that code to the tax office's name via a bundled copy of the BZSt GemFA directory (594 offices, revision 2026-09-02).
* Add `Steuer::FinanzamtRegistry` with `.name_for`, `.state_for`, `.known?`, `.revision` and `.entries` for direct lookups against the bundled table.
  * Unknown or retired codes return `nil` rather than raising, so a number issued after the bundled revision still converts — it just has no name yet.
  * `.state_for` is `nil` where a federal prefix is shared between states (`3` → BB/SN/ST, `4` → MV/TH), matching the gem's existing ambiguity handling.
* Add `rake update_finanzaemter` to regenerate the bundled table from the BZSt GemFA export.
* Add a manually triggered workflow that refreshes the table and opens a pull request only when the data differs, with a summary of added, removed and renamed offices.

## 1.1.0 - 2026-09-04

* [#1](https://github.com/oluosiname/steuer/pull/1) Accept all valid Steuernummer separator groupings.
  * Separators are presentational: Baden-Württemberg prints `93815/08152` for the digits the BZSt Standardschema groups as `93/815/08152`. Only the canonical grouping was accepted, so filers copying the number from their own Finanzamt correspondence were rejected with `InvalidTaxNumberError`.
  * Standard-format numbers are now regrouped into the state's canonical grouping before pattern matching. This affected all 16 states, not only Baden-Württemberg.

## 1.0.4 - 2025-12-23

* Fix ambiguous standard-format tax number detection. Numbers matching more than one state's standard pattern now raise `UnsupportedStateError` requiring an explicit `state:`, rather than silently resolving to whichever state matched first.

## 1.0.0 - 2025-12-02

* First stable release.
* `Steuer.steuernummer` with format detection across the standard, 12-digit federal, and 13-digit electronic-transmission schemes.
* Conversion via `#to_federal_12`, `#to_federal_13` (aliased `#to_elster`) and `#to_standard`.
* State detection and validation for all 16 Bundesländer, with auto-detection where the format is unambiguous.

## 0.3.0-alpha - 2025-08-17

* Relax the required Ruby version.

## 0.2.0-alpha - 2025-08-17

* Rename the `state` method to `state_name`.

## 0.1.0-alpha - 2025-08-17

* Initial release with state mapping, tax number validation, and format conversion.

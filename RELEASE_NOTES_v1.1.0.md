# Release v1.1.0

## Bug Fixes

### Fixed Rejection of Valid Steuernummern Written in Non-Canonical Groupings

**Issue**: Baden-Württemberg filers entering their real Steuernummer were rejected with `Steuer::InvalidTaxNumberError`.

```ruby
Steuer.steuernummer('93815/08152', state: 'BW')  # => InvalidTaxNumberError
Steuer.steuernummer('24019/00832', state: 'BW')  # => InvalidTaxNumberError
```

**Root Cause**: Separators were treated as significant rather than presentational.

Baden-Württemberg prints its Steuernummer grouped as 5/5 on Finanzamt correspondence, while the BZSt Standardschema writes the same digits as 2/3/5. These are the same number:

```
93815/08152   → digits 9381508152
93/815/08152  → digits 9381508152   ← identical
```

Only the canonical grouping was accepted, so a filer copying the number from their own tax office letter was rejected.

This was **not** a wrong pattern for Baden-Württemberg. The [BZSt Bundesschema table](https://www.bzst.de/SharedDocs/Downloads/DE/WIdNr/AufbauSteuernummerBundesschema.pdf?__blob=publicationFile&v=1) lists Baden-Württemberg as `FF/BBB/UUUUP` → `28FF0BBBUUUUP`, which is what the gem already had. Changing the pattern to 5/5 would have broken every filer using the canonical form.

The issue affected **all 16 states**, not just Baden-Württemberg — `133/8150/8159` was accepted for Nordrhein-Westfalen while `1338150/8159` was not. Baden-Württemberg surfaced it because 5/5 is the common printed rendering there.

**Solution**:
- Standard-format numbers are regrouped into the state's canonical grouping before pattern matching
- Group sizes are derived from each state's own `standard_pattern`, so the pattern table remains the single source of truth and no parallel table can drift out of sync
- Range-expressed groups (Hessen's `0(1[3-9])`, Saarland's `(01[0-2])`) are measured rather than read off `\d{n}`, so they size correctly
- A bare digit string is read as standard format only when an explicit state fixes the expected length; the 12- and 13-digit federal forms keep priority and are never shadowed

**Now Accepted**:

```ruby
Steuer.steuernummer('93815/08152', state: 'BW').to_federal_13   # => "2893081508152"
Steuer.steuernummer('93/815/08152', state: 'BW').to_federal_13  # => "2893081508152"
Steuer.steuernummer('9381508152', state: 'BW').to_federal_13    # => "2893081508152"
```

**Behaviour Change**:
- `to_standard` now returns the canonical BZSt grouping rather than the input as typed:

```ruby
Steuer.steuernummer('93815/08152', state: 'BW').to_standard  # => "93/815/08152"
```

  This only affects input that was previously rejected outright, so no working call changes its result. It is a deliberate normalisation towards the form ELSTER expects. Callers that echo `to_standard` back to end users should be aware the rendering may differ from what was typed.

**Not Changed**:
- No state's `standard_pattern` was modified
- Auto-detection behaviour is unchanged, including the ambiguity rules introduced in v1.0.4
- Numbers with a digit count that does not fit the selected state are still rejected

## Maintenance

### Gemspec Version Drift

`steuer.gemspec` hardcoded `spec.version = '1.0.4'` independently of `lib/steuer/version.rb`, so the two could be updated separately and disagree. The gemspec now reads `Steuer::VERSION`.

## Testing

- Added 7 regression tests covering grouping tolerance, canonical normalisation, federal-form priority, and rejection of wrong digit counts
- Verified against the BZSt specification for all 16 states: derived group sizes match the published table, and canonical, unseparated and regrouped input produce identical federal output
- All 88 tests passing; RuboCop clean

## Files Changed

- `lib/steuer/state_mapping.rb` - Added `standard_group_sizes`, `standard_group_size` and `canonicalize_standard_format`
- `lib/steuer/steuernummer.rb` - Grouping-tolerant validation and conversion; `to_standard` normalisation
- `lib/steuer/version.rb` - Bumped to 1.1.0
- `steuer.gemspec` - Read `spec.version` from `Steuer::VERSION`
- `Gemfile.lock` - Regenerated
- `spec/steuer/steuernummer_spec.rb` - Added grouping tolerance regression tests

## Upgrading

No migration required. This release only widens what is accepted; input that validated under v1.0.4 continues to validate and produces the same federal output.

Consumers that previously worked around the rejection by asking filers to re-type their number in 2/3/5 form can drop that workaround.

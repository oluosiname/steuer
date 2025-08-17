# Steuer

A Ruby gem for German tax system utilities, including Steuernummer (tax number) conversion between different formats and validation.

Based on the official specifications from the [German Wikipedia page on Steuernummer](https://de.wikipedia.org/wiki/Steuernummer#Deutschland).

## Features

- **Format Detection**: Automatically detects the format of German tax numbers
- **Format Conversion**: Convert between three different formats:
  - Standard scheme (state-specific format, e.g., `93/815/08152`)
  - Unified federal scheme (12-digit, e.g., `289381508152`)
  - Unified federal scheme for electronic transmission (13-digit, e.g., `2893081508152`)
- **State Detection**: Automatically detects the German state (Bundesland) from tax numbers
- **Validation**: Validates tax numbers according to official patterns
- **Object-Oriented**: Clean, object-oriented API design
- **Extensible**: Designed to be extended with additional German tax utilities (VAT validation, etc.)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'steuer'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install steuer
```

## Usage

### Basic Usage

```ruby
require 'steuer'

# Create a tax number object (auto-detects state from unambiguous formats)
tax_number = Steuer.steuernummer('93/815/08152')  # Auto-detects Baden-Württemberg

# Check if valid
puts tax_number.valid?  # => true

# Get information
puts tax_number.state_code    # => "BW"
puts tax_number.state_name    # => "Baden-Württemberg"
puts tax_number.format_type   # => :standard

# Convert between formats
puts tax_number.to_federal_12  # => "289381508152"
puts tax_number.to_federal_13  # => "2893081508152"
puts tax_number.to_standard    # => "93/815/08152"
```

### Auto-Detection vs Explicit State

```ruby
# ✅ Auto-detects from standard format (each state has unique pattern)
standard = Steuer.steuernummer('181/815/08155')  # Auto-detects Bayern
puts standard.state_code  # => "BY"

# ✅ Auto-detects from unambiguous federal prefixes
federal_12 = Steuer.steuernummer('289381508152')  # Prefix '28' is unique to BW
puts federal_12.state_name  # => "Baden-Württemberg"

# ❌ Requires explicit state for ambiguous prefixes
begin
  Steuer.steuernummer('304881508155')  # Prefix '3' shared by BB, SN, ST
rescue Steuer::UnsupportedStateError => e
  puts e.message  # => "Cannot determine state from tax number..."
end

# ✅ Works with explicit state for ambiguous cases
ambiguous = Steuer.steuernummer('304881508155', state: 'BB')
puts ambiguous.state_code  # => "BB"
```

### Ambiguous vs Unambiguous Prefixes

**✅ Unambiguous prefixes (auto-detected):**

- `28` → Baden-Württemberg
- `9` → Bayern
- `11` → Berlin
- `24` → Bremen
- `22` → Hamburg
- `26` → Hessen
- `23` → Niedersachsen
- `5` → Nordrhein-Westfalen
- `27` → Rheinland-Pfalz
- `1` → Saarland
- `21` → Schleswig-Holstein

**❌ Ambiguous prefixes (require explicit state):**

- `3` → Brandenburg, Sachsen, or Sachsen-Anhalt
- `4` → Mecklenburg-Vorpommern or Thüringen

### Error Handling

```ruby
begin
  # Invalid format
  Steuer.steuernummer('invalid')
rescue Steuer::InvalidTaxNumberError => e
  puts "Invalid format: #{e.message}"
end

begin
  # Unsupported state or undetectable
  Steuer.steuernummer('99/999/99999')
rescue Steuer::UnsupportedStateError => e
  puts "Unsupported state: #{e.message}"
end
```

## Supported German States

The gem supports all 16 German states (Bundesländer):

| State Code | State Name             | Standard Format Example | 12-digit Example | 13-digit Example |
| ---------- | ---------------------- | ----------------------- | ---------------- | ---------------- |
| BW         | Baden-Württemberg      | `93/815/08152`          | `289381508152`   | `2893081508152`  |
| BY         | Bayern                 | `181/815/08155`         | `918181508155`   | `9181081508155`  |
| BE         | Berlin                 | `21/815/08150`          | `112181508150`   | `1121081508150`  |
| BB         | Brandenburg            | `048/815/08155`         | `304881508155`   | `3048081508155`  |
| HB         | Bremen                 | `75/815/08152`          | `247581508152`   | `2475081508152`  |
| HH         | Hamburg                | `02/815/08156`          | `220281508156`   | `2202081508156`  |
| HE         | Hessen                 | `013/815/08153`         | `261381508153`   | `2613081508153`  |
| MV         | Mecklenburg-Vorpommern | `79/815/08151`          | `407981508151`   | `4079081508151`  |
| NI         | Niedersachsen          | `24/815/08151`          | `232481508151`   | `2324081508151`  |
| NW         | Nordrhein-Westfalen    | `133/8150/8159`         | `513381508159`   | `5133081508159`  |
| RP         | Rheinland-Pfalz        | `22/815/08154`          | `272281508154`   | `2722081508154`  |
| SL         | Saarland               | `010/815/08182`         | `101081508182`   | `1010081508182`  |
| SN         | Sachsen                | `201/815/08156`         | `320181508156`   | `3201081508156`  |
| ST         | Sachsen-Anhalt         | `101/815/08153`         | `310181508153`   | `3101081508153`  |
| SH         | Schleswig-Holstein     | `01/815/08155`          | `210181508155`   | `2101081508155`  |
| TH         | Thüringen              | `151/815/08154`         | `415181508154`   | `4151081508154`  |

## API Reference

### `Steuer.steuernummer(tax_number, state_code = nil)`

Creates a new `Steuer::Steuernummer` object.

**Parameters:**

- `tax_number` (String): The tax number in any supported format
- `state_code` (String, optional): The German state code (auto-detected if not provided)

**Returns:** `Steuer::Steuernummer` instance

### `Steuer::Steuernummer` Methods

#### Instance Methods

- `valid?` - Returns `true` if the tax number is valid
- `to_federal_12` - Converts to 12-digit unified federal scheme
- `to_federal_13` - Converts to 13-digit electronic transmission format
- `to_standard` - Converts to standard state-specific format
- `state_code` - Returns the German state code (e.g., "BW")
- `state_name` - Returns the full state name (e.g., "Baden-Württemberg")
- `format_type` - Returns the detected format (`:standard`, `:federal_12`, or `:federal_13`)
- `original_input` - Returns the original input string

## Development

After checking out the repo, run:

```bash
bundle install
```

To run the tests:

```bash
bundle exec rspec
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Future Features

This gem is designed to be extensible. Planned features include:

- German VAT number validation
- Steuer-ID (tax identification number) handling
- Wirtschafts-Identifikationsnummer support
- Additional German tax system utilities

## References

- [German Steuernummer Wikipedia Page](https://de.wikipedia.org/wiki/Steuernummer#Deutschland)
- [Bundeszentralamt für Steuern](https://www.bzst.de/)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

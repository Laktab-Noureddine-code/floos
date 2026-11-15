# Contract: CSV

## Export
- Encoding UTF-8 with BOM (`EF BB BF`); separator `,` (default) or `;`; CRLF line endings; RFC 4180 quoting.
- Header (fixed order):
  `date,time,type,amount,currency,account,to_account,to_amount,category,parent_category,payee,note,tags,id`
- `date` `yyyy-MM-dd` (local day); `time` `HH:mm` or empty; `type` `expense|income|transfer`;
  amounts positive, decimal point, no grouping, exactly currency minor digits (e.g. `354.25`, `1200`
  for 0-digit currencies); `to_amount` in destination currency; `tags` `|`-separated; `id` uuid.
- Pending transactions excluded unless exporting a selection that contains them.

## Import wizard
1. File → detect delimiter (`,` `;` `\t` `|`), encoding (UTF-8 BOM/UTF-8/Latin-1) → preview 20 rows.
2. Map columns (auto-match EN/FR synonyms), date format (auto-detect), decimal separator (`.`/`,`),
   amount mode: `signed` (negative = expense, positive = income) or `type column`.
3. Resolve unknown accounts/categories → map to existing or create.
4. Duplicates = same local date + amount + payee (case-insensitive) + account → skip or import.
5. Dry-run summary → import in one DB transaction → report `{imported, skipped, errors:[{row, reason}]}`.
- Round-trip guarantee: export → import (Floos format, auto-mapped) reproduces identical
  transactions (ids preserved when present and not already existing).

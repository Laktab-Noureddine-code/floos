# Contract: Backup file `floos_backup_YYYYMMDD_HHmm.floos`

Zip archive:

```
manifest.json
data.db            # plaintext SQLite copy (VACUUM INTO / sqlcipher_export) OR AES-GCM ciphertext if encrypted
attachments/<id>.jpg   # plaintext or ciphertext (same rule)
```

`manifest.json`:
```json
{
  "app": "floos",
  "app_version": "1.0.0+1",
  "schema_version": 1,
  "created_at": "2026-11-15T19:30:00Z",
  "device_locale": "fr",
  "base_currency": "MAD",
  "counts": {"transactions": 0, "accounts": 0, "categories": 0, "budgets": 0, "goals": 0,
             "recurring_rules": 0, "debts": 0, "tags": 0, "attachments": 0},
  "sha256": {"data.db": "<hex of stored bytes>", "attachments/<id>.jpg": "<hex>"},
  "encrypted": false,
  "kdf": {"algo": "pbkdf2", "salt": "<b64>", "iterations": 310000},
  "cipher": {"algo": "aes-256-gcm", "nonces": {"data.db": "<b64>", "attachments/<id>.jpg": "<b64>"}}
}
```
- `kdf`/`cipher` present only when `encrypted = true`. Ciphertext = nonce-separate, GCM tag appended.
- Checksums are over the stored (possibly encrypted) bytes, verified before decryption; a password
  check is the GCM tag of `data.db`.

Restore rules: `app != "floos"` → importFormat error; `schema_version > current` → refuse;
`<` → migrate after swap; checksum mismatch → refuse; wrong password → crypto error.
Safety backup (unencrypted, local only, prefix `floos_safety_`) is written before any swap.
Auto backups: `<appDocs>/backups/floos_backup_*.floos`, rotation keeps newest N (safety backups
rotated separately, keep 3).

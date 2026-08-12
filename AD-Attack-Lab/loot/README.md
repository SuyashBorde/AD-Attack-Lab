# Loot

This folder holds captured hashes/tickets during the engagement.

**Real hash and password values are intentionally excluded from git** (see root
`.gitignore`) — even in a disposable lab, it's good practice not to publish captured
credential material, and it keeps the habit consistent for real engagements.

## Expected file formats (for reference)

**`asrep_hashes.txt`** — AS-REP roast output (hashcat mode `18200`):
```
$krb5asrep$23$username@DOMAIN.LOCAL:<32-byte-hex>$<ciphertext-hex>
```

**`kerberoast_hashes.txt`** — Kerberoast TGS output (hashcat mode `13100`):
```
$krb5tgs$23$*svc-account$DOMAIN.LOCAL$DOMAIN.LOCAL/svc-account*$<checksum>$<ciphertext-hex>
```

**`usernames.txt`** — plaintext list of known/enumerated usernames, one per line.

If you want to include redacted/example output in your portfolio, truncate the hash
and replace the crackable ciphertext with `[REDACTED]` rather than committing the
real value.

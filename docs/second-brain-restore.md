# Restoring second_brain from an encrypted bundle

second_brain has no git remote on purpose. The only copies are encrypted
bundles in iCloud Drive → Documents → backups, written monthly by
`scripts/second-brain-bundle.sh`.

A backup nobody has restored is a hope, not a backup. Do the drill below once,
now, while there is nothing at stake.

## What you need

1. **The age private key.** It is in Passwords.app (synced through iCloud
   Keychain, end-to-end encrypted, so it survives this disk dying). A working
   copy also sits at `~/.config/age/second-brain-backup.txt`, which is on the
   disk being backed up and therefore does not count.
2. **The bundle.** `second_brain-YYYY-MM-DD.bundle.age` in iCloud Drive →
   Documents → backups. It is stored evicted, so Finder shows it with a cloud
   icon and downloads it on demand.

Sanity-check the key before trusting it — this prints the public half, which
must equal the recipient the bundles were encrypted to:

```
age-keygen -y ~/.config/age/second-brain-backup.txt
# expect: age1l6ke0fsvpdmqx97nk638mze5rs0u7g67njfhaqxl6th9zxwejp4su8ae59
```

To check the copy in Passwords.app instead, copy the note and run:

```
pbpaste | age-keygen -y /dev/stdin
```

## Restore

```sh
B="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/backups"
LATEST=$(ls -1t "$B"/second_brain-*.bundle.age | head -1)

# 1. pull it down from iCloud (it is evicted; this materialises it)
brctl download "$LATEST"

# 2. decrypt
age -d -i ~/.config/age/second-brain-backup.txt -o /tmp/sb.bundle "$LATEST"

# 3. confirm the bundle is sound BEFORE trusting it
git bundle verify /tmp/sb.bundle

# 4. clone from it
git clone /tmp/sb.bundle ~/repos/second_brain-restored

# 5. REQUIRED — the clone does NOT bring the stash
git -C ~/repos/second_brain-restored fetch /tmp/sb.bundle 'refs/stash:refs/stash'
```

**Step 5 is not optional, and it is easy to miss.** `git clone` fetches only
`refs/heads` and `refs/tags`. `refs/stash` IS in the bundle, but a clone leaves
it behind — a restore drill on 2026-10-19 came back with 822 commits against
the live repo's 824, and the two missing ones were the stash. Nothing warns you;
the clone looks complete.

After step 5 the counts match exactly (verified: 824 = 824, all 11 refs
present). One nuance: `git stash list` will still show nothing, because
fetching a ref creates no reflog and that list is read from the reflog. The
content is there and reachable:

```
git -C ~/repos/second_brain-restored show refs/stash
git -C ~/repos/second_brain-restored stash apply refs/stash
```

The clone has every branch the bundle captured, full history, and `origin`
pointing at the bundle file — remove that remote afterwards, since
second_brain is deliberately remote-less.

## What the bundle does NOT contain

Roughly 12 GB of `second_brain`'s working tree is gitignored — imported
ChatGPT and Claude exports, YouTube audio. Those are not in git, so they are
not in the bundle. They are themselves copies of exports that can be made
again, which is why this is acceptable; but do not expect a restore to bring
them back.

## If the bundle will not decrypt

The key is wrong or lost. There is no recovery path — that is the point of
encrypting it. Check Passwords.app first, then
`~/.config/age/second-brain-backup.txt` on any machine that still has it.

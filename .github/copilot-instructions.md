# Hexo JP KLC - Copilot Instructions

## Project Overview
A specialized Hexo-based Japanese learning blog that generates daily kanji study posts. The system combines:
- **Hexo static site generator** (Node.js) for blog generation
- **PostgreSQL database** (Dockerized via native Docker CLI) containing KLC kanji dictionary data
- **Perl scripts** (`db/*.pl`) for querying DB and generating markdown posts
- **GNU Make** (Makefile) for all workflows (not npm scripts or docker compose)

**Purpose**: Progressively introduce KLC kanji (currently at #`last_known_klc_num` in `db/config.yaml`), generating posts with readings, meanings, and sample words using only "known" kanji.

## Architecture & Data Flow

### Daily Post Generation Pipeline
1. `make daily` → runs `db/daily.pl`
2. Script reads `db/config.yaml` for `last_known_klc_num` and `daily_study_number`
3. Queries PostgreSQL for next N kanji (e.g., kanji 1-20 on first run)
4. Calls stored procedure `add_matching_words()` to populate `known_words` table with vocabulary containing only known kanji + kana
5. Generates Hexo post via `hexo new post MM-DD-YYYY`
6. Appends kanji data (meanings, on/kun readings) and shuffled word list to `source/_posts/MM-DD-YYYY.md`
7. Updates `last_known_klc_num` in `db/config.yaml`

### Database Schema (Key Tables)
- `character`: Kanji literals and IDs
- `klc_kanji`: Maps KLC sequence numbers to character IDs
- `reading`: On (音読み) and kun (訓読み) readings (type: `ja_on`, `ja_kun`)
- `meaning`: English meanings
- `word`: Full dictionary of Japanese words (entry format: `かんじ [漢字]` with definition)
- `known_words`: Temporary table populated per-run with words matching regex of known kanji

## Critical Configuration Files

### `db/config.yaml` (Perl Scripts Config)
```yaml
last_known_klc_num: 0      # Auto-incremented by daily.pl
daily_study_number: 20     # Kanji per post
max_words: 50              # Random words to display
```
**Do not manually edit while scripts are running**. Values are coerced to numeric to prevent string conversion bugs.

### `settings.env` (Docker/DB Connection)
Loaded by Makefile via `include settings.env` directive. Defines `DB_HOST`, `DB_PORT`, `DB_USER`, container configs, etc.

### `_config.yml` (Hexo Site Config)
Standard Hexo configuration. Theme is set to `butterfly` (line 100).

## Essential Workflows

### Standard Development Cycle
```bash
make daily          # Generate new post (increments kanji progress)
# Edit source/_posts/*.md manually to add sentences/stories
make generate       # hexo generate
make server         # hexo server --port $SERVER_PORT (default 4000)
```

### Database Management
```bash
make init                # First-time setup: starts Docker container
make db-restore          # pg_restore from db/hexojp.tar.gz
make db-dump             # pg_dump to db/hexojp.tar.gz (removes old dumps)
make db-connect          # Bash into container as root
make db-logs             # View PostgreSQL logs
```

### Docker Operations (Native Docker CLI)
```bash
make docker-up           # Create/start PostgreSQL container with network & volume
make docker-stop         # Stop container without removing volumes
make docker-down         # Stop + remove container and volume (destructive!)
make docker-build        # Pull latest PostgreSQL image
make docker-prune-db     # Nuclear option: remove container, volume, and image
make docker-logs         # View container logs (one-time)
make docker-logs-follow  # Follow container logs in real-time
```

**Note**: Docker operations use native `docker` CLI commands, not `docker compose`. The Makefile handles network and volume creation automatically.

## Project-Specific Patterns

### Perl Script Conventions
- All DB scripts use `DBI` + `DBD::Pg` + `YAML::Tiny`
- UTF-8 handling: `use utf8;` for string literals in scripts
- Config loaded via `YAML::Tiny->read("config.yaml")`
- **Numeric coercion required**: YAML::Tiny converts numbers to strings on write; use `$value + 0` to force numeric type

### Post Generation Pattern
`daily.pl` uses **append mode** (`>>`) to add content after Hexo's frontmatter scaffold:
```perl
my $filename = "../source/_posts/$note_name.md";
open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
say $fh $output;
```

### Known Words Filtering
The stored procedure `add_matching_words(max_klc)` uses PostgreSQL regex to filter words:
```sql
regexp_count(entry, '^([ぁ-んァ-ン' || agg_kanji || ']+) \[(.+)\] $') > 0
```
This ensures only entries like `ひらがな [平仮名]` containing known kanji are selected.

## Common Pitfalls

1. **Perl dependencies**: First-time setup requires Perl modules: `sudo apt install libdbi-perl libdbd-pg-perl libyaml-tiny-perl` or `cpan DBI DBD::Pg YAML::Tiny`.

2. **Port conflicts**: Hexo server defaults to 4000 (`$SERVER_PORT`). On Windows/WSL, run `hexo server` in PowerShell/CMD for proper port exposure.

3. **Database not ready**: After `make init`, wait for PostgreSQL to fully initialize (5-10 seconds) before running `make db-restore`. Check logs with `make db-logs`.

4. **Docker container persistence**: `make docker-up` intelligently checks if container exists before creating a new one. Use `make docker-down` to fully reset.

4. **Theme submodules**: Themes (`hexo-theme-butterfly`, `hexo-theme-aero-dual`) are Git submodules. Run `git submodule update --init --recursive` if missing.

5. **Config sync**: Two separate configs for DB (`db/config.yaml`) and environment (`settings.env`). DB host/port/credentials must match.

6. **Numeric values in YAML**: When adding new numeric config to `db/config.yaml`, Perl scripts must coerce with `+ 0` to prevent string conversion.

7. **Make vs docker compose**: This project uses native Docker CLI via Makefile, not `docker-compose.yml`. The compose file is legacy and may be removed.

## Code Modification Guidelines

### Adding New Kanji Data to Posts
Modify `db/daily.pl` around lines 50-110 where kanji info is queried. Follow pattern:
1. Prepare SQL statement
2. Execute with `$kanji_sth->execute($daily_min, $daily_max)`
3. Append to `$output` with markdown formatting

### Changing Word Selection Logic
Edit stored procedure in `db/create_add_matching_words_proc.pl`, then:
```bash
cd db && perl create_add_matching_words_proc.pl
```
Test by running `make daily` and inspecting generated word list.

### Hexo Theme Customization
- Active theme: `butterfly` (defined in `_config.yml` line 100)
- Theme config: `themes/hexo-theme-butterfly/_config.yml`
- After changes: `make generate` to rebuild static site

## Key File Locations
- Posts: `source/_posts/`
- DB scripts: `db/*.pl`
- Scaffolds: `scaffolds/post.md`
- Docker init: `dockerfiles/db/init-user-db.sh` (creates `hexojp` tablespace)
- DB dump: `dockerfiles/db/hexojp.tar.gz` (auto-restored on container init)

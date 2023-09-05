# Hexo JP KLC
### Hexo-Based Japanese KLC Practice Blogging

## Overview
This project is designed for studying the KLC list of kanji by introducing a fixed number of kanji per blog entry and encouraging the creation of sentences that use a a selection of words gathered from all "known" kanji.

## Design:
Each blog entry will introduce a fixed number of kanji from the KLC list, in order introduced in the KLC book. The last known kanji number is stored in config.yaml.  The daily script increments this number and fetches the daily kanji and a selection of words that use all known kanji, including the new kanji for today.

The note generated displays each kanji, along with a brief description and readings.  Sample words are also included that use only known kanji and kana.
It is the task of the writer to construct some sentences that use these words, ideally in some sort of story.
This will help build vocabulary and reinforce grammar.
There is no time limit to finishing a blog post, so each entry does not have to be daily. But in the interest of learning 2300 kanji, it is recommended to write a blog entry at least a few times a week.

## Daily Kanji with Meanings and On/Kun Readings
![Main page showing readings](/images/Readings.jpg)

## Daily Random Selection of Words with Only Known Kanji and Kana
![Main page showing words](/images/Words.jpg)

## Tech Stack: Dev Container
- [Arch Linux](https://archlinux.org/) is used as a dev container for generating notes and hosting/maintaining the website.
- [Node JS](https://nodejs.org/en) is used with [Hexo](https://hexo.io/index.html) to serve as a static website generator.
- [Perl 5](https://www.perl.org) + [DBI](https://dbi.perl.org/)  + [DBD::Pg](https://metacpan.org/pod/DBD::Pg) is used for DB scripts.
- [Cargo-Make](https://github.com/sagiegurari/cargo-make) is used as a build/task runner.

## Tech Stack: DB Container
- [Postgresql](https://www.postgresql.org/) is used for the DB backend (used for note creation only).

## Tech Stack: Host
- [Podman](https://podman.io/) is used locally to host Postgresql, rootless containers preferred.
- [Podman-compose](https://github.com/containers/podman-compose) is used to simplify DB setup.
- [Cargo-Make](https://github.com/sagiegurari/cargo-make) is used as a build/task runner.

## Prerequisites for Host
Note: it is possible to use Docker as well instead of Podman.  You will have to update the Makefile.toml file though, as all the tasks reference podman.
1. Install [Podman](https://podman.io/).
2. Install [Podman-compose](https://github.com/containers/podman-compose).
3. If needed, [configure Podman rootless support](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md) (recommended for security reasons). If you do not use rootless containers, then you may need to update the tasks in Makefile.toml.
5. Install [Rust](https://www.rust-lang.org/) by using either [rustup](https://rustup.rs/) or your system's package manager.
6. Install [Cargo-Make](https://github.com/sagiegurari/cargo-make) - Either by `cargo install cargo-make` or using your system's package manager.

## Initial one-time setup
1. Clone this repository. `git clone https://github.com/darkmusic/hexojp-klc`
2. Copy **dockerfiles/dev/db/config_template.yaml** to **dockerfiles/dev/db/config.yaml** and edit accordingly.
3. Edit **dockerfiles/dev/_config.yml** as needed.
4. In **dockerfiles/dev/Dockerfile**, edit the country code if needed in this line:
```docker
RUN reflector -l 5 --protocol https --sort rate --country US --save /etc/pacman.d/mirrorlist
```
You can use either a 2-character country code or a country name here.  If you use a country name that has spaces, you must enclose it in double quotes.

5. Run `cargo make init` to initialize the containers.

## Regular daily steps
1. `cargo make daily`
2. Edit note as needed (under **dockerfiles/dev/source/_posts**).
3. `cargo make generate`
4. `cargo make server`
5. [View the site in a browser.](http://localhost:4000)

## As needed
- Edit dockerfiles/dev/_config.yml, then run `cargo make generate`
- Edit dockerfiles/dev/themes, then run  `cargo make generate`
- Edit dockerfiles/dev/scaffolds, then run  `cargo make generate`
- Edit dockerfiles/dev/db/config.yaml, then run  `cargo make generate`
- Edit any post under dockerfiles/dev/source/_posts, then run  `cargo make generate`
- Run `cargo make dev sync down` to sync changes from the container to the local directory.  Note that if you've made any local changes, this will overwrite them!
- Run `cargo make podman up` to start the podman stack.
- Run `cargo make podman stop` to stop the podman stack.
- Run `cargo make podman build` to manually build the containers.
- Run `cargo make podman build_nocache` to build the containers without using the cache.
- Run `cargo make dev pacman_update` to update the dev OS packages.
- Run `cargo make dev connect` to connect to the dev container.
- Run `cargo make db connect` to connect to the db container.
- Run `cargo make dev logs` to see the dev container logs.
- Run `cargo make db logs` to see the db container logs.

## System Requirements
Windows, Linux, or Mac should work.

## Config
The config.yaml defaults should work fine.  As-is, the defaults will include kanji 1-20 in the initial blog entry.

By default, this will start from **last_known_klc_num + 1** (1), and end at **start + daily_study_number** (20).  Only sample words containing these 20 kanji (and any kana) will be included.
After creating the daily note, the **last_known_klc_num** will be incremented to 20.

You can always manually edit the **last_known_klc_num** if needed.
```yaml
daily_study_number: 20
database: hexojp
host: 127.0.0.1
last_known_klc_num: 0
max_words: 50
password: hexojpadmin
port: 5432
userid: hexojpadmin
```

## Other notes
- To re-generate a daily note, you'll need to connect to the dev container and delete the post like doing the following:
```
cargo make dev connect
rm source/_posts/09-05-2023.md
exit
```
and then run the `cargo make daily` task again.

- The DB contains kanji imported from [KANJIDIC](http://www.edrdg.org/wiki/index.php/KANJIDIC_Project) using [KanjiDicParser](https://github.com/WinteryFox/KanjidicParser), and words imported from [EDICT](http://www.edrdg.org/jmdict/edict.html).  A list of 2300 KLC kanji was used to number the KLC kanji in the DB. 
- The `daily.pl` script has all of the logic for generating the daily note.  This makes use of a procedure called `add_matching_words` to perform a regex match (using all known kanji) against the word table and populating a known_words table with results. It also queries other tables to retrieve kanji-specific information.
- The character 〇 (KLC 14) is ignored, as it is not a kanji.
- The Hexo theme is configurable.  See: [Hexo Themes](https://hexo.io/themes/index.html).  It should be noted that not all Hexo themes work properly, so you may have to adjust things or find another theme if you run into issues.
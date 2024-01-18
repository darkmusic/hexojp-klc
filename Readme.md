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
- [Podman](https://podman.io/) or [Docker](https://www.docker.com/products/docker-desktop/) is used locally to host Postgresql, rootless containers preferred.
- [Podman Compose](https://github.com/containers/podman-compose) or [Docker Compose](https://docs.docker.com/compose/) is used to simplify DB setup.
- [Cargo-Make](https://github.com/sagiegurari/cargo-make) is used as a build/task runner.

## Prerequisites for Host
1. Install [Podman](https://podman.io/) or [Docker](https://www.docker.com/products/docker-desktop/) if not installed already.
2. If using Podman, install [Podman-compose](https://github.com/containers/podman-compose).
3. If needed, [configure Podman rootless support](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md) (recommended for security reasons). If you are using Podman and do not use rootless containers, then you may need to update the tasks in Makefile.toml.
4. You may also need `aardvark-dns` if on Linux, for dns support between containers.
5. Install [Rust](https://www.rust-lang.org/) if needed by using either [rustup](https://rustup.rs/) or your system's package manager.
6. Install [Cargo-Make](https://github.com/sagiegurari/cargo-make) - Either by `cargo install cargo-make` or using your system's package manager.

## Initial one-time setup
1. Clone this (or your) repository. Change URL as needed.  `git clone https://github.com/darkmusic/hexojp-klc`
2. Initialize submodules if needed. `git submodule update --init --recursive`
3. Copy **dockerfiles/dev/db/config_template.yaml** to **dockerfiles/dev/db/config.yaml** and edit accordingly.
4. Edit **dockerfiles/dev/_config.yml** as needed.
5. In **dockerfiles/dev/Dockerfile**, edit the country code if needed in this line:
```docker
RUN reflector -l 5 --protocol https --sort rate --country US --save /etc/pacman.d/mirrorlist
```
You can use either a 2-character country code or a country name here.  If you use a country name that has spaces, you must enclose it in double quotes.
6. Copy **Makefile-docker.toml** or **Makefile-podman.toml** (depending on whether you use [Docker](https://www.docker.com/products/docker-desktop/) or [Podman](https://podman.io/)) and rename the copied file to Makefile.toml.
7. Run `cargo make init` to initialize the containers.

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
- Run `cargo make dev sync_down` to sync changes from the container to the local directory.  Note that if you've made any local changes, this will overwrite them!
- Run `cargo make dev sync_up` if you have local changes that are not in the server (this may be needed if re-creating the dev container, for example).
- Run `cargo make podman up` to start the podman stack.
- Run `cargo make podman stop` to stop the podman stack.
- Run `cargo make podman build` to manually build the containers.
- Run `cargo make podman build_nocache` to build the containers without using the cache.
- Run `cargo make dev pacman_update` to update the dev OS packages.
- Run `cargo make dev connect` to connect to the dev container.
- Run `cargo make dev connect_root` to connect to the dev container as root.
- Run `cargo make db connect` to connect to the db container.
- Run `cargo make dev logs` to see the dev container logs.
- Run `cargo make db logs` to see the db container logs.
- Run `cargo make dev fix_permissions` to fix permissions in the dev container.  This may be needed after doing a `cargo make dev sync_up`.

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

## Using submodules for themes
It can be convenient to use submodules for themes.

For example:
```shell
cd dockerfiles/dev/themes
git submodule add https://github.com/xbmlz/hexo-theme-maple.git
cargo make generate
cargo make server
```
With this, you can do a `git add` on your repository and it will add the submodule instead of adding everything inside the theme's folder.  Also if you re-clone your repository from scratch, if you follow the instructions in the **Initial one-time setup** above, your themes will be downloaded automatically.

## Example for adding a theme and dealing with theme-related issues
Using [hexo-theme-clean-dark](https://github.com/howardliu-cn/hexo-theme-clean-dark) as an example, do the following:
1. Add submodule to themes directory
```shell
cd dockerfiles/dev/themes
git submodule add https://github.com/howardliu-cn/hexo-theme-clean-dark
```
2. Read installation notes at [the theme repo](https://github.com/howardliu-cn/hexo-theme-clean-dark).  Note that this particular theme repo is in Chinese, but it is usually not required to know how to read Chinese even if the readme for the repo is entirely in Chinese.  In this particular repo, there are steps listed where are pretty straightforward.  Note that you can skip the "clone" step as you already added the submodule.  If it's still to difficult to understand the repository readme, go to [Google Translate - websites](https://translate.google.com/?sl=zh-CN&tl=en&op=websites) and enter the URL for the repository and translate to your desired language.  For this example, the translated repository (from Simplified Chinese to English) is [here](https://github-com.translate.goog/howardliu-cn/hexo-theme-clean-dark?_x_tr_sl=zh-CN&_x_tr_tl=en&_x_tr_hl=en&_x_tr_pto=wapp).

In this particular theme repository, there is the next step of adding a NPM dependency.  This can be done by doing the following:
```shell
cargo make dev connect
npm install --save hexo-renderer-sass
exit
```
3. Edit dockerfiles/dev/themes/_config.yml to change the theme (in this case to hexo-theme-clean-dark).
4. Edit the theme's config.yml (in this case dockerfiles/dev/themes/hexo-theme-clean-dark/_config.yml) as needed according to the theme's readme.
5. Generate
```shell
cargo make generate
```
6. Take note of any errors during the generation process and fix as needed.  If you are not familiar or comfortable with troubleshooting such errors, it may be easier to pick a different theme.
Example error:
```shell
ERROR
ReferenceError: /home/hexojp/code/hexojp/themes/hexo-theme-clean-dark/layout/post.ejs:17
    15|         </div>
    16|         <div class="post-content article-entry">
 >> 17|             <!-- <%- partial('_partial/toc') %> -->
    18|             <%- page.content %>
    19|         </div>
    20|         <% if(page.tags){ %>

/home/hexojp/code/hexojp/themes/hexo-theme-clean-dark/layout/_partial/toc.ejs:1
 >> 1| <% if (post.toc != false) { %>
    2|     <div id="toc">
    3|       <%- toc(post.content, {list_number: false}) %>
    4|     </div>

post is not defined
    at eval ("/home/hexojp/code/hexojp/themes/hexo-theme-clean-dark/layout/_partial/toc.ejs":10:8)
    at toc (/home/hexojp/code/hexojp/node_modules/ejs/lib/ejs.js:703:17)
    at _View._compiledSync (/home/hexojp/code/hexojp/node_modules/hexo/lib/theme/view.js:132:24)
    at _View.renderSync (/home/hexojp/code/hexojp/node_modules/hexo/lib/theme/view.js:59:25)
    at Object.partial (/home/hexojp/code/hexojp/node_modules/hexo/lib/plugins/helper/partial.js:34:15)
    at eval ("/home/hexojp/code/hexojp/themes/hexo-theme-clean-dark/layout/post.ejs":25:17)
    at post (/home/hexojp/code/hexojp/node_modules/ejs/lib/ejs.js:703:17)
    at _View._compiled (/home/hexojp/code/hexojp/node_modules/hexo/lib/theme/view.js:136:50)
    at _View.render (/home/hexojp/code/hexojp/node_modules/hexo/lib/theme/view.js:39:17)
    at /home/hexojp/code/hexojp/node_modules/hexo/lib/hexo/index.js:64:21
    at tryCatcher (/home/hexojp/code/hexojp/node_modules/bluebird/js/release/util.js:16:23)
    at /home/hexojp/code/hexojp/node_modules/bluebird/js/release/method.js:15:34
    at RouteStream._read (/home/hexojp/code/hexojp/node_modules/hexo/lib/hexo/router.js:47:5)
    at Readable.read (node:internal/streams/readable:737:12)
    at resume_ (node:internal/streams/readable:1255:12)
    at process.processTicksAndRejections (node:internal/process/task_queues:82:21)
```
This one looks daunting, but is actually easy to fix.  In dockerfiles/dev/themes/hexo-theme/clean/dark/layout/post.ejs, the commented-out block in line 17 is causing the issue, so just delete that line and do a sync, fix permissions, and generate to try again.

Note that you may get deprecation warnings like the following:
```shell
Deprecation Warning: Using / for division outside of calc() is deprecated and will be removed in Dart Sass 2.0.0.

Recommendation: math.div(30em, 14) or calc(30em / 14)

More info and automated migrator: https://sass-lang.com/d/slash-div

   ╷
12 │ $fa-li-width:         (30em / 14) !default;
   │                        ^^^^^^^^^
   ╵
    themes/hexo-theme-clean-dark/source/css/font-awesome/scss/_variables.scss 12:24  @import
    themes/hexo-theme-clean-dark/source/css/font-awesome/scss/font-awesome.scss 6:9  root stylesheet
```
This is a sass warning, which is actually quite detailed and gives you suggestions on how to fix this.

It's optional to fix these, but if you know how to, I would recommend it as it cleans up these warnings.

In this case, these calculations need to happen inside a **calc()** block, so just add **calc** in front of the math operations that are mentioned.  For example, **(30em / 14)** becomes **calc(30em / 14)**.

Continue once you have reduced or eliminated all errors and warnings.

7. Start server
```shell
cargo make server
```
8. Check the [website](http://localhost:4000) to see if any updates are needed.

You may notice that the website does not look correct; perhaps the fonts don't look right, or things aren't aligned as expected.  If you're not comfortable with adjusting CSS, then you may wish to find another theme.

For this example theme, below are some updates that I made to get things to look a bit more normal on my system.  This is just an example of the types of updates you may need to make.  

Even with this updates to the hexo-theme-clean-dark, it still doesn't look exactly like the theme repo's screenshot, and the fonts don't look the best, so your mileage may vary based on what updates you make (and the time you want to spend messing with CSS).  This is the case with many Hexo themes - they don't work right or look right.  This is not the direct fault of the repo owner because libraries (including NPM libraries such as hexo, sass etc.) and browser technologies (such as CSS) go through evolutions and sometimes significant changes that may break or cause issues with legacy websites.  Many Hexo themes can be considered "legacy websites" in this case, because many have not been updated in several years and are unmaintained.  So while these issues are not the direct fault of the repo owner, any issues with the theme should be reported to the repo owner so they are aware of the issue and can make fixes.  But with many github repos, issues opened may sit eternally without being resolved, so oftentimes reporting github issues isn't helpful.  It all depends on how responsive and active the repo owner is.

Even these example updates will become obsolete at some point once the CSS spec or SASS changes again, so just use this as a general guide for the types of updates you may need to make.
- In theme_scss:
    - .footer:
        - add:
        ```css
        height: 50px;
        ```
    - .well.post-nav.a:
        - Comment out "float: left"
        ```css
        //float: left;
        ```
    - nav.a: 
        - add:
        ```css
        padding-left: 5px;
        padding-right: 5px;
        ```
        - Change font-family to:
        ```css
        font-family: ubuntu, icomoon, 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        ```
    - navbar .navbar-nav: 
        - change display to:
        ```css
        display: flex;
        ```
        - Comment out "float: left"
        ```css
        //float: left;
        ```
        - add flex-direction: row
        ```css
        flex-direction: row;
        ```
    - .content:
        - add:
        ```css
            padding-left: 50px;
            padding-right: 50px;
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
- The initial DB import may get a tablespace error.  You may need to edit dockerfiles/db/init-user-db.sh (where it says *Tablespace for initial db import*) to adjust the path.  If you don't know what path to use, run `cargo make db connect` and look around in the container (under /var/lib/postgresql/data/pg_tblspc/) and see what the folder is named, and adjust the script as needed.  But currently there is a wildcard, so this may not be required.
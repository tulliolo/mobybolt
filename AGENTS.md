# AGENTS.md – Quick Guidance for OpenCode Sessions

**What this file answers:**
- What commands are required to develop, run, or build this repository?
- How the repo is structured and where to edit documentation.
- Any non‑obvious steps or quirks that an autonomous agent could easily miss.

---

## Repository Type
- This is a **Jekyll documentation site** using the **Just the Docs** theme (see `_config.yml`).
- The source content lives in Markdown files under `guide/` and at the root (`index.md`).
- The generated static site lives in `_site/` (can be served as‑is).

## Development workflow
- **Prerequisites**: Ruby (≥ 2.7), Bundler (`gem install bundler`).
- **Install dependencies**:
  ```bash
  bundle install   # reads Gemfile & Gemfile.lock
  ```
- **Run a local development server** (auto‑reload enabled by default):
  ```bash
  bundle exec jekyll serve
  ```
  - Serves at `http://localhost:4000`.
  - The command reads `_config.yml` and serves the Markdown source; any change to docs is reflected instantly.
- **Build the static site** (e.g., for deployment or CI):
  ```bash
  bundle exec jekyll build
  ```
  - Output goes to the `_site/` directory.

## Editing guidance
- Add or modify documentation in the `guide/` hierarchy (e.g., `guide/mobybolt/setup/*.md`).
- Top‑level pages like `README.md`, `index.md` are also rendered.
- The navigation is driven by folder structure and front‑matter; no separate menu file.
- After editing, re‑run `bundle exec jekyll serve` or `build` to view changes.

## Gotchas & quirks
- The repository already contains a pre‑built `_site/`. **Do not delete** it unless you intend to rebuild.
- The only executable script is `start_server.sh`, which simply runs the above serve command; using the script is equivalent to the explicit command.
- No test suite, CI pipelines, or makefiles are present – the primary task is documentation generation.
- The theme configuration (`remote_theme: just-the-docs/just-the-docs`) means the site pulls theme assets at build time; an offline build without internet may fail.

---

*Agents should consult this file first to avoid guessing Ruby/Bundler steps, the correct Jekyll commands, and the location of source docs.*

# Clanning terminal

## General structure:

./Addons --> Addons repo integrated in the documentation, installable by users (Uses Page.mdx )

./Terminals --> Terminals repo integrated in the documentation, installable by users (Uses Page.mdx )

./Main --> What's going to be in-game and installed by users when installing the terminal

| ./Main/MainModule --> The core, a version will be additionally uploaded to roblox for auto-updating

## Architecture

The architecture diagram shows the high-level flow of the terminal: Server script → Main module → Wrapper → Terminal, with Addons attached to both the Main module and Terminals.

See the full diagram in `docs/architecture.md` for the Iconify-enabled version.

To preview the diagram inline, a Mermaid block with Iconify icons is included below. Note that some renderers (including GitHub) sanitize HTML inside Mermaid nodes and may not show the icons — use VS Code Markdown preview or a standalone HTML page that includes the Iconify script to view icons.

<script src="https://code.iconify.design/2/2.2.1/iconify.min.js"></script>

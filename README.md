# Anki Deck Builder

Build and rebuild Anki flashcard decks.

The strategy is presented in `build_chinese_deck.sh`:

1. Start with a `.tsv` file that has only one column: the terms from the source language.
1. The script then fetches translations and audio files from google translate. It updates the `.tsv` file to hold four columns. It downloads the mp3's into an auxilliary directory (which you can delete afterward if you wish).
1. The script then populates a sqlite database `collection.anki2` with note+card information for all of the terms in the `.tsv.`
1. The script then makes hard links whose names are decimal numbers [1-infinity], which is what Anki appears to require.
1. The script then zips the media files, `media` file, and sqlite db into a `.apkg` file.

## Dependencies

This application makes use of:

- Bash
- Node.js
- google-translate-token (Node.js module)

# On Chromebook

`export PYTHONIOENCODING=UTF-8` allows Python to interpret and print Chinese characters.
`export LANG=en_US.UTF-8` allows terminal to interpret and print Chinese characters.


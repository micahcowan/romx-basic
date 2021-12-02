# Things to check out before passing a release

- From DOS
  - Test that `BRUN ASOFT.LOADER` is harmless (just returns immediately)
  - Test that BASIC programs are rejected by `MAKE ASOFT ROM` if they're too large.
    - Test for 1 below, exactly at (should pass), 1 past, much past
- Booting ROM
  - Test that "booting" the ROM (as a "system ROM") gives the reject page, then successfully reboots to firmware menu on keypress
  - Test that boot succeeds in running the stored BASIC program

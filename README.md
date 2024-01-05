# LibCooldownTracker
This is a fork from the original LibCooldownTracker maintained by vendethiel.

The key differences with this fork is how the information is sourced and what is maintained. Additionally, there's zero intention to maintain Classic/Bcc/Wrath forks of information.

Rather than all of the information being sourced manually, base spell/abilities are pulled out of OmniCD using the handy `converter.lua` script and then manually inserted into the respective lua files. This could easily be automated in the future.

A few key differences in how the data works.
1. The english name is stored in the `LCT_SpellData` table.
2. OmniCD does not store CD reduction in its `spell_db` so if abilities or talents interact with each other that reduce the CDs, that is lost.
3. We also maintain the `buff` information if ever that is necessary.
4. There's less effort invested in dividing abilities by specialization, especially in code. The previous version was structured by specialization and it got rather complicated + high effort. The philosophy here is that the less work necessary, the easier it is to keep in sync.
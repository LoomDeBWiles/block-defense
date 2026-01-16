load the subagent and mcp playwright skill and the bead skill. this is a game repo with a very buggy game. The current bug is
  Place Tower doesn't place a tower, it just moves the popup. You need to only use claude-browser subagents to do your work, you
  must not do any work yourself. You will prompt them after loading the prompt principles skill. the game is supposed to look
  like this: [Image #1] , ask claude-browser to take an image to show you what is looks like. the current functionality is
  supposed to follow /home/ben/projects/game/block-defense/game_spec.md but the game is completely not playable. Use only
  subagents to (1) fully diagnose the bug, then the same agent will (2) create a bead to fix the bug then, (3) fix the bug in
  the code, then (4) close the bead, commit, push the work. that is the subagent loop that will depend on how good your prompt
  is. after the first bug is fixed you must use a subagetn 10 MORE TIMES to diagnose where does the game not meet the spec, and
  fix the bugs that are keeping from meeting spec in the same way as subagent 1.
  also there is a CONTEXT.md file that may be out of date but may be helpful
Title: **BUNKER COMMS**

A rythm game with morse code.
You get pop-ups with a word, and each letter's morse code value.
You need to input the message correctly via a button, respecting a timer.

Story has 2 options (I am not sure yet which one to choose):
1. Soldier. You are in a bunker and try to reach you comrades
2. Civilian. You are at home, you bought a morse code device and try it with your friends.


Implementation steps:

  **Step 1:** The Input Stuff. Figure out how to make a timer so the game knows if I’m just tapping (dot) or holding the button down (dash). I'll use some basic OOP here to make a "player" object that keeps track of its own timing and current dots/dashes.

  **Step 2:** Making it Readable. Set up a list or a table that turns the dot-dash patterns into actual letters. I'll make a "manager" object to handle the word I’m supposed to be typing and check if I’m getting the letters right or messing up.

  **Step 3:** Helping the Player. Draw the pop-ups with the words and the morse code values so people don't have to memorize it. I’ll make a UI object that handles drawing these guides and the timer bar so the code stays organized.

  **Step 4:** Sound and Feel. Add some beep sounds that match the button presses and some screen shake when you finish a word. I’ll use a simple particle object to make effects pop up whenever a letter is done correctly to give it some "juice."

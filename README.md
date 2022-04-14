# Necrocard

Necrocard was created in 72 hours for the WOWIE 3 game jam. It doesn't contain the absolute best code i've ever written,
but it does server as a nice example for a simple game made using [Pile](https://github.com/EinScott/Pile) (which you will need to build it).

I'll *sort of* try to keep this compatible with the current version of Pile but I won't make any promises... checked with Pile 3.0 @ 7cfd386

## Game description

**Rules**
- whoever reaches 0 energy ("hp") first, loses
- if you have no cards on your field at the end of your turn, you lose 2 energy
- in a fight, both cards are destroyed
- cards with equal attack can't fight
- in a fight, if your card's attack is greater, the enemy takes that amount of damage ("damage enemy")
- if it is smaller, you gain the energy of your card ("heal yourself")

**Extra challenge**
The game also features a slightly harder variant of the ai. You can encounter it randomly after your first match, but can also force to fight it by holding down the SHIFT key while clicking on the "play" or "restart" button.
# MysteryDungeonPkmnFaces
A plugin developped for PSDK, that aims to show pokemon faces with different emotions during messages.

## Installation

### Français
## Installation 
Les visages des Pokémons utilisés par le plugin sont stockés dans *graphics/pictures/pkmn_faces/portrait*, et le tracker permettant de choisir quel visage afficher dans *graphics/pictures/pkmn_faces*.

Vous devez donc copier le dossier *graphics* dans le dossier root de votre projet, ainsi que le script soit en version release (.psdkplug), soit en version script Ruby (.rb) dans votre dossier *scripts*.

Si vous souhaitez mettre à jour les visages utilisés, vous les retrouverez à l'adresse https://github.com/PMDCollab/SpriteCollab.
Il vous suffira de copier-coller le nouveau dossier portrait à la place de l'ancien, et de remplacer également le fichier de tracker.

## Crédits
Les sprites des visages sont tirés de https://github.com/PMDCollab/SpriteCollab. Les crédits obligatoires et la licence associés à leur utilisation y sont également disponibles.

## Utilisation 
Pour afficher un visage avec un message, vous devez utiliser, à l'intérieur du texte du message :
```bash
[pkmn_faces=position, expression, mirror, opacity!pkmn_id, pkmn_form, female, shiny]
```
Les différents paramètres sont :
  - position : coordonnée x de la fenêtre, à choisir entre right (10), left (-10), ou un entier. Si l'entier est négatif, le sprite sera affiché depuis le côté droit de la fenêtre.
  - expression : string, expression du visage, parmis "Normal", "Happy", "Pain", "Angry", "Worried", "Sad", "Crying", "Shouting", "Teary-Eyed", "Determined", "Joyous", "Inspired", "Surprised", "Dizzy", "Special0" , "Special1", "Sigh", "Stunned", "Special2", "Special3". Si l'expression n'est pas trouvée, une autre expression, la plus proche possible, sera choisie.
  - mirror (optionnel) : vaut true si le sprite doit être mirror
  - opacity (optionnel) : opacité du sprite (de 0 à 255)

  - pkmn_id : id ou nom anglais du pokemon à afficher
  - pkmn_form (optionnel) : nom de la forme à afficher (parmis "Mega", "Gigantamax", "Alola", "Galar"...). Pour une forme plus précise, regardez son nom dans le tracker.
  - female (optionnel) : vaut true si le sprite à afficher est celui d'une femelle
  - shiny (optionnel) : vaut true si le sprite à afficher est shiny.

Example : 
```bash
[pkmn_faces=left,Happy!5]Coucou !
```
```bash
[pkmn_faces=-10, sad, true!3,Mega,,true]Salut !
```

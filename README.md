# DragonQuest - Arena (prototipo)

Prototipo in Godot 4.7 (gl_compatibility) dell'arena tattica di **DragonQuest 3a edizione** (TSR), Libro Primo:
creazione del personaggio (regole 3-8) e combattimento a Pulse su griglia esagonale (regole 11-24).

## Come si avvia
- Apri la cartella con Godot 4.7 e premi Esegui.
- Test automatici (esempi del manuale + 30 partite IA contro IA):
  `godot --headless --path . res://tests/Test.tscn`
- Controllo dei glifi dei font: `python3 tools/controlla_glifi.py`

## Struttura
- `data/` tabelle del manuale in JSON (rigenerabili con `data/build_json.py`, se presente)
- `scripts/rules.gd` autoload che carica le tabelle
- `scripts/fighter.gd` figura e valori derivati (Strike Chance, Difesa, TMR, Initiative Value)
- `scripts/builder.gd` generazione del personaggio
- `scripts/hex_grid.gd` griglia, fronte/retro, linea di tiro
- `scripts/combat.gd` sequenza del Pulse, azioni, risoluzione attacchi, danni e ferite gravi
- `scripts/ia.gd` intelligenza dei nemici
- `scripts/arena_view.gd`, `scripts/main.gd` interfaccia

## Regole della casa (decise)
Ingaggio se almeno uno ha l'altro nella Melee Zone; linea di tiro in ordine di distanza; niente Fatica pre-combattimento;
niente danno extra 18.5; ferite gravi a lungo termine solo annotate; iniziativa D10 + PC; terreno aperto, muri, macerie.

## Non ancora implementato
Close combat e Grapple, colpi multipli, attacchi speciali (Trip, Entangle, Knockout, Shield Rush, Disarm come scelta),
armi da lancio a mano, combattimento a cavallo, mostri multi-esagono, magia, esportazione web e pubblicazione.

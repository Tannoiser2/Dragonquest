# DragonQuest - Arena (prototipo)

Prototipo in Godot 4.7 (gl_compatibility) dell'arena tattica di **DragonQuest 3a edizione** (TSR):
creazione completa del personaggio (caratteristiche, origini, retaggio, aspetto, armi, Collegio di magia,
incantesimi, abilità) e combattimento a Pulse su griglia esagonale con armi e magia.

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
- `scripts/magia.gd` magia in combattimento: preparazione, lancio, resistenza, effetti, contraccolpi, paura
- `scripts/creazione.gd` schermata di creazione a schede
- `scripts/ia.gd` intelligenza dei nemici (anche Adept)
- `data/magic.json` i 13 Collegi (351 voci, nomi italiani), `data/skills.json` le abilità,
  `data/magia_combattimento.json` le regole meccaniche dei 31 incantesimi da combattimento
- `scripts/arena_view.gd`, `scripts/main.gd` interfaccia

## Regole della casa (decise)
Ingaggio se almeno uno ha l'altro nella Melee Zone; linea di tiro in ordine di distanza; niente Fatica pre-combattimento;
niente danno extra 18.5; ferite gravi a lungo termine solo annotate; iniziativa D10 + PC; terreno aperto, muri, macerie.

## Non ancora implementato
Close combat e Grapple, colpi multipli, attacchi speciali (Trip, Entangle, Knockout, Shield Rush, Disarm come scelta),
armi da lancio a mano, combattimento a cavallo, mostri multi-esagono, incantesimi di evocazione e rituali in combattimento,
modificatori ambientali dei Collegi, traduzione italiana dei testi completi degli incantesimi (ora in inglese nel tooltip).

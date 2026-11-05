"""Nomi italiani di talenti, incantesimi e rituali (chiave: (collegio, codice))."""

N = {}

def c(num, testo):
    for riga in testo.strip().split('\n'):
        cod, nome = riga.split(' ', 1)
        N[(num, cod)] = nome.strip()

c(36, """
T-1 Vista delle streghe
G-1 Incantesimo di Ammaliamento
G-2 Incantesimo di Telecinesi
G-3 Incantesimo del Sonno incantato
G-4 Incantesimo del Cammino invisibile
G-5 Incantesimo di Parola con le creature incantate
G-6 Incantesimo di Localizzazione
G-7 Incantesimo di Ammaliamento di massa
G-8 Incantesimo di Invisibilità
G-9 Incantesimo di Avvizzimento
Q-1 Rituale di Incantamento
Q-2 Rituale del Cristallo della visione
Q-3 Rituale della Polvere del sonno
Q-4 Rituale della Polvere velenosa
S-1 Incantesimo di Ventriloquio
S-2 Incantesimo del Dardo di energia
S-3 Incantesimo di Apertura
S-4 Incantesimo di Incantamento delle armi
S-5 Incantesimo della Ragnatela intralciante
S-6 Incantesimo della Serratura magica
S-7 Incantesimo di Potenziamento dell'incantamento
S-8 Incantesimo di Levitazione
S-9 Incantesimo di Incantamento delle armature
S-10 Incantesimo dell'Occhio del mago
S-11 Incantesimo di Lentezza
S-12 Incantesimo di Rapidità
""")
c(37, """
T-1 Resistenza alla temperatura
T-2 Resistenza al dolore
T-3 Percezione del pericolo
G-1 Incantesimo di Percezione extrasensoriale
G-2 Incantesimo di Precognizione limitata
G-3 Incantesimo del Mantello della mente
G-4 Incantesimo di Empatia
G-5 Incantesimo di Ipnosi
G-6 Incantesimo di Controllo degli animali
G-7 Incantesimo di Controllo della persona
Q-1 Rituale di Vincolo della volontà
S-1 Incantesimo di Attacco mentale
S-2 Incantesimo di Telepatia
S-3 Incantesimo del Fantasma
S-4 Incantesimo di Disgregazione molecolare
S-5 Incantesimo di Riordino molecolare
S-6 Incantesimo dello Scudo di forza
S-7 Incantesimo di Guarigione
S-8 Incantesimo di Invisibilità
S-9 Incantesimo di Telecinesi
S-10 Incantesimo della Furia telecinetica
R-1 Rituale di Vincolo degli elementi
""")
c(38, """
T-1 Vista delle streghe
T-2 Immagine proiettata
G-1 Incantesimo del Lampo di luce
G-2 Incantesimo di Illusione visiva
G-3 Incantesimo di Illusione sonora
G-4 Incantesimo di Illusione olfattiva
G-5 Incantesimo di Illusione tattile
Q-1 Rituale della Nebbia illusoria
""")
c(39, """
Q-1 Rituale di Dissoluzione
S-1 Incantesimo di Ammaliamento
S-2 Incantesimo di Obbedienza forzata
R-1 Rituale di Divinazione magica
""")
c(40, """
T-1 Previsione del tempo
G-1 Incantesimo di Resistenza al freddo
G-2 Incantesimo di Creazione del ghiaccio
G-3 Incantesimo del Vento del mago
G-4 Incantesimo di Comunicazione con gli uccelli
G-5 Incantesimo del Fischio del vento
G-6 Incantesimo di Evocazione della foschia
G-7 Incantesimo di Richiamo degli uccelli
G-8 Incantesimo di Rilevamento dei fumi
Q-1 Rituale della Voce del vento
Q-2 Rituale di Vincolo dell'aria
S-1 Incantesimo della Tempesta di vento
S-2 Incantesimo di Richiamo della tempesta
S-3 Incantesimo di Costruzione di ghiaccio
S-4 Incantesimo di Controllo degli uccelli
S-5 Incantesimo del Vento gelido
S-6 Incantesimo dei Proiettili di ghiaccio
S-7 Incantesimo del Fulmine
S-8 Incantesimo di Ibernazione
S-9 Incantesimo dell'Arma del gelo
S-10 Incantesimo della Barriera di vento
S-11 Incantesimo del Simulacro di neve
S-12 Incantesimo del Muro di ghiaccio
S-13 Incantesimo del Raggio di gelo
S-14 Incantesimo del Gas soporifero
S-15 Incantesimo del Cammino sul vento
S-16 Incantesimo del Vortice
S-17 Incantesimo della Morte gelida
R-1 Rituale di Controllo del tempo atmosferico
R-2 Rituale di Evocazione e controllo dell'Elementale dell'aria
""")
c(41, """
T-1 Previsione del tempo
G-1 Incantesimo di Calma delle acque
G-2 Incantesimo di Creazione delle onde
G-3 Incantesimo di Parola con gli uccelli marini
G-4 Incantesimo di Galleggiamento
G-5 Incantesimo di Navigazione
G-6 Incantesimo di Purificazione dell'acqua
G-7 Incantesimo di Parola con i mammiferi acquatici
G-8 Incantesimo di Richiamo dei mammiferi acquatici
G-9 Incantesimo del Vento del mago
G-10 Incantesimo di Creazione dell'acqua
G-11 Incantesimo di Vista acquatica
G-12 Incantesimo di Respirazione subacquea
G-13 Incantesimo di Vincolo della nave
G-14 Incantesimo di Benedizione del mare
Q-1 Rituale di Vincolo dell'acqua
S-1 Incantesimo di Purificazione dei liquidi
S-2 Incantesimo di Trasmutazione dei liquidi
S-3 Incantesimo delle Acque guaritrici
S-4 Incantesimo delle Acque della forza
S-5 Incantesimo di Richiamo dei pesci
S-6 Incantesimo di Controllo dei pesci
S-7 Incantesimo di Controllo dei mammiferi marini
S-8 Incantesimo delle Acque della visione
S-9 Incantesimo della Vela di vento
S-10 Incantesimo di Richiamo della pioggia
S-11 Incantesimo del Maelstrom
S-12 Incantesimo della Tromba marina
R-1 Rituale di Evocazione e vincolo dell'Elementale dell'acqua
""")
c(42, """
T-1 Infravisione
G-1 Incantesimo di Pirogenesi
G-2 Incantesimo di Produzione del calore
G-3 Incantesimo di Resistenza al fuoco
G-4 Incantesimo di Luce
G-5 Incantesimo di Alterazione della temperatura
G-6 Incantesimo del Muro di fumo
G-7 Incantesimo di Ignifugazione
G-8 Incantesimo di Protezione dal fuoco magico
Q-1 Rituale di Vincolo del fuoco
S-1 Incantesimo del Muro di fuoco
S-2 Incantesimo del Dardo di fuoco
S-3 Incantesimo della Palla di fuoco
S-4 Incantesimo della Rete di fuoco
S-5 Incantesimo di Autocombustione
S-6 Incantesimo della Palla di fuoco implosiva
S-7 Incantesimo dell'Arma di fiamme
S-8 Incantesimo del Dardo di fuoco potenziato
S-9 Incantesimo del Fuoco invisibile
S-10 Incantesimo delle Fiamme del drago
S-11 Incantesimo della Rete di fiamme del drago
S-12 Incantesimo della Tempesta di fuoco
S-13 Incantesimo delle Fiamme maligne
S-14 Incantesimo di Incenerimento
S-15 Incantesimo di Evocazione della salamandra
S-16 Incantesimo di Evocazione dell'efreet
R-1 Rituale di Evocazione e controllo dell'Elementale del fuoco
""")
c(43, """
T-1 Rilevamento dell'aura
G-1 Incantesimo di Dialogo con gli animali
G-2 Incantesimo di Dialogo con le piante
G-3 Incantesimo di Controllo degli animali
G-4 Incantesimo di Mimetismo
G-5 Incantesimo del Cammino invisibile
G-6 Incantesimo di Guarigione
G-7 Incantesimo di Rilevamento di trappole e lacci
G-8 Incantesimo di Rilevamento dei veleni
G-9 Incantesimo di Incantamento minore
G-10 Incantesimo della Conoscenza delle erbe
G-11 Incantesimo di Inseguimento delle tracce
Q-1 Rituale di Richiamo degli animali
S-1 Incantesimo del Martello di terra
S-2 Incantesimo delle Mani di terra
S-3 Incantesimo della Forza della pietra
S-4 Incantesimo dell'Armatura di terra
S-5 Incantesimo dell'Arma di diamante
S-6 Incantesimo di Creazione delle gemme
S-7 Incantesimo di Crescita animale
S-8 Incantesimo di Incantamento delle piante
S-9 Incantesimo di Vincolo degli animali
S-10 Incantesimo di Evocazione e controllo dell'Elementale della terra
S-11 Incantesimo della Morte sprofondante
S-12 Incantesimo del Muro di pietra
S-13 Incantesimo del Muro di ferro
S-14 Incantesimo dello Scavo di gallerie
S-15 Incantesimo della Pelle di troll
S-16 Incantesimo del Magma fumante
S-17 Incantesimo dei Giavellotti di diamante
S-18 Incantesimo di Trasformazione della terra
""")
c(44, """
T-1 Parola con le creature delle ombre
T-2 Visione notturna
T-3 Rilevamento dell'aura
G-1 Incantesimo di Mimetismo
G-2 Incantesimo di Luce
G-3 Incantesimo di Oscurità
G-4 Incantesimo della Forma d'ombra
G-5 Incantesimo del Muro di luce stellare
G-6 Incantesimo del Muro di oscurità
G-7 Incantesimo della Vista delle streghe
G-8 Incantesimo della Forza dell'oscurità
G-9 Incantesimo del Cammino invisibile
Q-1 Rituale di Lettura delle stelle
Q-2 Rituale di Evocazione e vincolo delle creature delle ombre
S-1 Incantesimo di Guarigione
S-2 Incantesimo della Spada d'ombra e di stelle
S-3 Incantesimo del Fuoco stellare
S-4 Incantesimo della Meteora
S-5 Incantesimo delle Ali d'ombra
S-6 Incantesimo della Rete di luce stellare
S-7 Incantesimo della Rete di tenebra
S-8 Incantesimo dello Sciame di meteore
S-9 Incantesimo della Stella nana
S-10 Incantesimo del Fuoco nero
S-11 Incantesimo del Cammino nelle ombre
S-12 Incantesimo del Fuoco bianco
S-13 Incantesimo della Paura
R-1 Rituale di Evocazione e controllo della Sfera oscura
""")
c(45, """
G-1 Incantesimo di Evocazione dell'oscurità
G-2 Incantesimo di Putrefazione
G-3 Incantesimo di Offuscamento
G-4 Incantesimo di Fuoco e zolfo
G-5 Incantesimo di Riscaldamento del metallo
G-6 Incantesimo di Danno alle entità
G-7 Incantesimo dei Vapori nocivi
G-8 Incantesimo di Deformazione del legno
G-9 Incantesimo dell'Ariete di forza
G-10 Incantesimo di Respirazione dei vapori
Q-1 Rituale di Evocazione e vincolo dei non-morti minori
Q-2 Rituale di Dialogo con i morti
S-1 Incantesimo delle Ferite
S-2 Incantesimo del Muro di forza
S-3 Incantesimo del Muro di ossa
S-4 Incantesimo della Paura
S-5 Incantesimo della Paura di massa
S-6 Incantesimo della Terra sfregiata
S-7 Incantesimo di Animazione dei morti
S-8 Incantesimo del Mantello spettrale
S-9 Incantesimo dell'Arma d'ombra
S-10 Incantesimo della Mano della morte
S-11 Incantesimo del Fuoco invisibile
S-12 Incantesimo del Prosciugamento vitale
S-13 Incantesimo dell'Agonia
S-14 Incantesimo del Fantasma
R-1 Rituale di Evocazione e vincolo dei non-morti maggiori
R-2 Rituale di Prolungamento della vita
R-3 Rituale per Diventare non-morto
""")
c(46, """
T-1 Comunicazione con le bestie minori
G-1 Incantesimo di Richiamo dei piccoli mammiferi
G-2 Incantesimo di Richiamo di pesci e creature acquatiche
G-3 Incantesimo di Richiamo di lucertole, serpenti, insetti e ragni
G-4 Incantesimo di Richiamo degli uccelli comuni
G-5 Incantesimo di Richiamo delle cavalcature
G-6 Incantesimo di Richiamo di scimmie e preumani
G-7 Incantesimo di Richiamo dei felini
G-8 Incantesimo di Vincolo delle bestie minori
G-9 Incantesimo di Richiamo dei non-morti minori
G-10 Incantesimo di Comunicazione con i non-morti minori
G-11 Incantesimo del Muro di spine
G-12 Incantesimo di Richiamo della nebbia
G-13 Incantesimo dell'Empatia
G-14 Incantesimo di Richiamo dell'energia
Q-1 Rituale di Evocazione delle bestie minori
Q-2 Rituale di Evocazione dei non-morti minori
S-1 Incantesimo di Comunicazione con le bestie fantastiche
S-2 Incantesimo di Comunicazione con i senzienti maggiori
S-3 Incantesimo di Richiamo dei grandi mammiferi
S-4 Incantesimo di Richiamo dei mammiferi acquatici
S-5 Incantesimo di Richiamo degli umanoidi
S-6 Incantesimo di Richiamo del popolo fatato
S-7 Incantesimo di Vincolo delle bestie maggiori
S-8 Incantesimo di Controllo della persona
S-9 Incantesimo dei Sensi animali
S-10 Incantesimo di Richiamo delle entità della luce
S-11 Incantesimo di Richiamo delle entità delle tenebre
S-12 Incantesimo di Richiamo degli uccelli fantastici
S-13 Incantesimo di Richiamo dei mostri fantastici
S-14 Incantesimo di Richiamo dei non-morti maggiori
S-15 Incantesimo di Richiamo degli evocabili
S-16 Incantesimo di Proiezione dell'io
S-17 Incantesimo di Richiamo del drago
R-1 Rituale di Evocazione delle bestie maggiori
R-2 Rituale di Animazione dei morti
R-3 Rituale di Evocazione degli eroi
R-4 Rituale di Evocazione dell'imp
""")
c(47, """
T-1 Rilevamento dell'incantamento
G-1 Incantesimo di Riparazione
G-2 Incantesimo di Incantamento delle armi
G-3 Incantesimo di Incantamento delle armature
G-4 Incantesimo di Solidificazione dell'aria
G-5 Incantesimo di Solidificazione dell'acqua
Q-1 Rituale del Golem di stracci e spago
Q-2 Rituale del Golem d'argilla
Q-3 Rituale di Divinazione magica
Q-4 Rituale di Investitura
Q-5 Rituale di Preparazione degli amuleti
Q-6 Rituali di Preparazione di armi e armature
Q-7 Rituale di Preparazione degli abiti incantati
Q-8 Rituale di Preparazione dei mobili incantati
Q-9 Rituale di Preparazione di talismani e artefatti minori
Q-10 Rituale di Preparazione di bastoni e bacchette
Q-11 Rituale di Preparazione degli artefatti maggiori
S-1 Incantesimo della Fanghiglia scivolosa
S-2 Incantesimo di Forgiatura degli elementi
S-3 Incantesimo di Neutralizzazione dei golem
S-4 Incantesimo di Vincolo dei golem
S-5 Incantesimo di Animazione dei golem
R-1 Rituale per Trasformare la pietra in carne
R-2 Rituale del Golem di pietra
R-3 Rituale del Golem di ferro
R-4 Rituale del Golem di carne
R-5 Rituale di Vincolo delle cariche
R-6 Rituale di Vincolo delle investiture
R-7 Contenimento del mostro
R-22 Rituale del Nome degli artefatti
R-23 Rituale di Protezione degli artefatti per attitudine magica
R-24 Rituale di Divinazione antica
""")
c(48, """
T-1 Lettura delle lingue antiche
T-2 Decifrazione di codici e cifrari
T-3 Lettura dei bastoncini runici
T-4 Creazione di codici e cifrari
T-5 Richiamo della bacchetta
G-1 Incantesimo di Rilevamento dell'aura
G-2 Incantesimo di Oscurità
G-3 Incantesimo di Luce
G-4 Incantesimo di Pirogenesi
G-5 Incantesimo della Maledizione
G-6 Incantesimo di Illusione
G-7 Incantesimo di Controllo delle entità
G-8 Incantesimo di Purificazione
G-9 Incantesimo del Sigillo runico
Q-1 Rituale di Fabbricazione dei bastoncini runici
Q-2 Rituale di Fabbricazione della bacchetta runica
Q-3 Rituale di Protezione con i bastoncini runici
Q-4 Rituale di Guarigione
Q-5 Rune della vista
Q-6 Rituale dell'Invio
S-1 Incantesimo del Muro runico
S-2 Incantesimo di Richiamo degli spiriti totemici
S-3 Incantesimo di Creazione del portale runico
S-4 Incantesimo della Visitazione
S-5 Incantesimo della Verità
S-6 Incantesimo dell'Esilio
S-7 Incantesimo del Colpo
S-8 Incantesimo di Creazione dell'arma runica
S-9 Incantesimo di Vincolo
R-1 Rituale del Lancio delle rune
R-2 Rituale della Morte consumante
R-3 Rituale del Portale dimensionale
R-4 Rituale delle Rune del destino
""")

NOMI_EN_CORRETTI = {
 (46, 'S-1'): "Spell of Communication with Fantastical Beasts",
 (46, 'G-3'): "Spell of Summoning Lizards and Kindred, Snakes, Insects and Spiders",
 (42, 'R-1'): "Ritual of Summoning and Controlling Fire Elemental",
 (38, 'Q-1'): "Ritual of Illusory Fog",
 (47, 'Q-7'): "Ritual of Preparing Enchanted Clothing",
 (47, 'Q-8'): "Ritual of Preparing Enchanted Furniture",
 (47, 'Q-11'): "Ritual of Preparing Greater Artifacts",
}

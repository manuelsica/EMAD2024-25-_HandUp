import random
from collections import Counter


class Tessera:
    def __init__(self, lettera, punteggio):
        self.lettera = lettera
        self.punteggio = punteggio


class CasellaTipo:
    NORMALE = 0
    DOPPIO_LETTERA = 1
    TRIPLO_LETTERA = 2
    DOPPIO_PAROLA = 3
    TRIPLO_PAROLA = 4


class Casella:
    def __init__(self, lettera=None, tipo=CasellaTipo.NORMALE, moltiplicatore_lettera=1, moltiplicatore_parola=1):
        self.lettera = lettera
        self.tipo = tipo
        self.moltiplicatore_lettera = moltiplicatore_lettera
        self.moltiplicatore_parola = moltiplicatore_parola


class Giocatore:
    def __init__(self, ordine_giocatore, tessere_giocatore):
        self.ordine_giocatore = ordine_giocatore
        self.tessere_giocatore = tessere_giocatore
        self.punteggio_tot = 0
        self.posizione = 0


def crea_lista_tessere_scarabeo():
    tessere = []
    # tessere con punteggio 1
    tessere.extend([Tessera('A', 1)] * 12)
    tessere.extend([Tessera('E', 1)] * 12)
    tessere.extend([Tessera('I', 1)] * 12)
    tessere.extend([Tessera('O', 1)] * 12)
    tessere.extend([Tessera('C', 1)] * 7)
    tessere.extend([Tessera('R', 1)] * 7)
    tessere.extend([Tessera('S', 1)] * 7)
    tessere.extend([Tessera('T', 1)] * 7)
    # tessere con punteggio 2
    tessere.extend([Tessera('L', 2)] * 6)
    tessere.extend([Tessera('M', 2)] * 6)
    tessere.extend([Tessera('N', 2)] * 6)
    # tessere con punteggio 3
    tessere.extend([Tessera('P', 3)] * 4)
    # tessere con punteggio 4
    tessere.extend([Tessera('U', 4)] * 4)
    tessere.extend([Tessera('B', 4)] * 4)
    tessere.extend([Tessera('D', 4)] * 4)
    tessere.extend([Tessera('F', 4)] * 4)
    tessere.extend([Tessera('G', 4)] * 4)
    tessere.extend([Tessera('V', 4)] * 4)
    # tessere con punteggio 8
    tessere.extend([Tessera('H', 8)] * 2)
    tessere.extend([Tessera('Z', 8)] * 2)
    # tessere con punteggio 10
    tessere.extend([Tessera('Q', 10)] * 2)
    # jolly
    tessere.extend([Tessera('*', 0)] * 2)
    print(len(tessere))
    return tessere


def distribuisci_tessere(tessere, num_tessere):
    tessere_giocatore = []
    for _ in range(num_tessere):
        if tessere:  # Check if tessere is not empty
            indice = random.randrange(len(tessere))
            tessere_giocatore.append(tessere.pop(indice))
    print(len(tessere))
    return tessere_giocatore


def calcola_punteggio_parola(tessere):
    return sum(t.punteggio for t in tessere)


def crea_tabellone_scarabeo():
    tabellone = [[Casella() for _ in range(17)] for _ in range(17)]

    for i in range(1, 6):
        tabellone[i][i] = Casella(tipo=CasellaTipo.DOPPIO_PAROLA, moltiplicatore_parola=2)
        tabellone[i][16 - i] = Casella(tipo=CasellaTipo.DOPPIO_PAROLA, moltiplicatore_parola=2)
        tabellone[16 - i][i] = Casella(tipo=CasellaTipo.DOPPIO_PAROLA, moltiplicatore_parola=2)
        tabellone[16 - i][16 - i] = Casella(tipo=CasellaTipo.DOPPIO_PAROLA, moltiplicatore_parola=2)

    tabellone[0][0] = Casella(tipo=CasellaTipo.TRIPLO_PAROLA, moltiplicatore_parola=3)
    tabellone[0][16] = Casella(tipo=CasellaTipo.TRIPLO_PAROLA, moltiplicatore_parola=3)
    tabellone[16][0] = Casella(tipo=CasellaTipo.TRIPLO_PAROLA, moltiplicatore_parola=3)
    tabellone[16][16] = Casella(tipo=CasellaTipo.TRIPLO_PAROLA, moltiplicatore_parola=3)
    tabellone[8][0] = Casella(tipo=CasellaTipo.TRIPLO_PAROLA, moltiplicatore_parola=3)
    tabellone[0][8] = Casella(tipo=CasellaTipo.TRIPLO_PAROLA, moltiplicatore_parola=3)
    tabellone[8][16] = Casella(tipo=CasellaTipo.TRIPLO_PAROLA, moltiplicatore_parola=3)
    tabellone[16][8] = Casella(tipo=CasellaTipo.TRIPLO_PAROLA, moltiplicatore_parola=3)

    # Caselle con doppio punteggio lettera
    tabellone[7][7] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[7][9] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[9][7] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[9][9] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)

    tabellone[0][4] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[4][0] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[12][0] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[0][12] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)

    tabellone[12][16] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[16][12] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[12][0] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[0][12] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)

    tabellone[12][4] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[12][4] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[4][12] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[16][4] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[4][16] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)

    tabellone[2][7] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[3][8] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[2][9] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)

    tabellone[7][2] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[8][3] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[9][2] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)

    tabellone[14][7] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[13][8] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[14][9] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)

    tabellone[7][14] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[8][13] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)
    tabellone[9][14] = Casella(tipo=CasellaTipo.DOPPIO_LETTERA, moltiplicatore_lettera=2)

    tabellone[6][1] = Casella(tipo=CasellaTipo.TRIPLO_LETTERA, moltiplicatore_lettera=3)
    tabellone[1][6] = Casella(tipo=CasellaTipo.TRIPLO_LETTERA, moltiplicatore_lettera=3)

    tabellone[10][1] = Casella(tipo=CasellaTipo.TRIPLO_LETTERA, moltiplicatore_lettera=3)
    tabellone[1][10] = Casella(tipo=CasellaTipo.TRIPLO_LETTERA, moltiplicatore_lettera=3)

    tabellone[15][6] = Casella(tipo=CasellaTipo.TRIPLO_LETTERA, moltiplicatore_lettera=3)
    tabellone[6][15] = Casella(tipo=CasellaTipo.TRIPLO_LETTERA, moltiplicatore_lettera=3)

    tabellone[15][10] = Casella(tipo=CasellaTipo.TRIPLO_LETTERA, moltiplicatore_lettera=3)
    tabellone[10][15] = Casella(tipo=CasellaTipo.TRIPLO_LETTERA, moltiplicatore_lettera=3)

    tabellone[6][6] = Casella(tipo=CasellaTipo.TRIPLO_LETTERA, moltiplicatore_lettera=3)
    tabellone[6][10] = Casella(tipo=CasellaTipo.TRIPLO_LETTERA, moltiplicatore_lettera=3)

    tabellone[10][6] = Casella(tipo=CasellaTipo.TRIPLO_LETTERA, moltiplicatore_lettera=3)
    tabellone[10][10] = Casella(tipo=CasellaTipo.TRIPLO_LETTERA, moltiplicatore_lettera=3)

    return tabellone


def stampa_tabellone(tabellone):
    """Stampa il tabellone di gioco dello scarabeo."""
    for riga in tabellone:
        for casella in riga:
            print(casella.lettera if casella.lettera else " ", end=" ")  # Stampa la lettera o uno spazio
        print()


def controllo_mossa(tabellone, parola, riga, colonna, orientamento):
    """Controlla se una mossa è valida nel gioco dello Scarabeo.

    Args:
        tabellone: Il tabellone di gioco.
        parola: La parola da inserire.
        riga: La riga di inizio della parola.
        colonna: La colonna di inizio della parola.
        orientamento: L'orientamento della parola (O per orizzontale, V per verticale).

    Returns:
        True se la mossa è valida, False altrimenti.
    """

    # Controlli di base
    if not (0 <= riga < 17 and 0 <= colonna < 17):
        return False  # Posizione fuori dal tabellone
    if orientamento not in ("O", "V"):
        return False  # Orientamento non valido
    if orientamento == "O" and colonna + len(parola) > 17:
        return False  # Parola esce dal tabellone orizzontalmente
    if orientamento == "V" and riga + len(parola) > 17:
        return False  # Parola esce dal tabellone verticalmente

    # Verifica dell'intersezione con altre parole o con la casella centrale
    intersezione = False
    for i, lettera in enumerate(parola):
        r = riga + i if orientamento == "V" else riga
        c = colonna + i if orientamento == "O" else colonna
        if tabellone[r][c].lettera:
            intersezione = True
            break
        if r == 8 and c == 8:  # Verifica della casella centrale
            intersezione = True
            break

    if not intersezione:
        return False  # La parola non interseca nessuna altra parola o la casella centrale

    # Verifica che tutte le lettere della parola corrispondano a caselle vuote o occupate dalla stessa lettera
    for i, lettera in enumerate(parola):
        r = riga + i if orientamento == "V" else riga
        c = colonna + i if orientamento == "O" else colonna
        if tabellone[r][c].lettera and tabellone[r][c].lettera != lettera:
            return False  # Lettera non corrispondente a una lettera già presente

    return True


def posiziona_parola(tabellone, parola, riga, colonna, orientamento):
    """Posiziona una parola sul tabellone."""
    for i, lettera in enumerate(parola):
        r = riga + i if orientamento == "V" else riga
        c = colonna + i if orientamento == "O" else colonna
        tabellone[r][c].lettera = lettera


def punteggio_lettera(lettera):
    """Restituisce il punteggio associato a una lettera nello Scarabeo.

    Args:
        lettera: La lettera di cui si vuole conoscere il punteggio.

    Returns:
        Il punteggio della lettera, o 0 se la lettera non è presente nel dizionario.
    """
    punteggi = {
        'A': 1, 'B': 3, 'C': 3, 'D': 2, 'E': 1, 'F': 4, 'G': 2,
        'H': 4, 'I': 1, 'L': 1, 'M': 2, 'N': 1, 'O': 1, 'P': 3,
        'Q': 10, 'R': 1, 'S': 1, 'T': 1, 'U': 1, 'V': 4, 'Z': 10
    }
    return punteggi.get(lettera.upper(), 0)  # Convertiamo la lettera in maiuscolo per una corrispondenza più precisa


def controlla_tessere_disponibili(giocatore, parola):
    """Verifica se il giocatore ha tutte le tessere necessarie per formare la parola, considerando anche i jolly.

    Args:
        giocatore: L'oggetto Giocatore.
        parola: La parola da formare.

    Returns:
        True se il giocatore ha tutte le tessere, False altrimenti.
    """

    # Conta le occorrenze di ciascuna lettera nelle tessere del giocatore
    conteggio_tessere = Counter(tessera.lettera for tessera in giocatore.tessere_giocatore)

    # Calcola le lettere mancanti e le loro quantità
    lettere_mancanti = Counter(parola) - conteggio_tessere
    if (len(lettere_mancanti) > 0):
        # Conta i jolly
        numero_jolly = conteggio_tessere.get('*', 0)
        print(numero_jolly)
        # Chiedi al giocatore se vuole utilizzare i jolly
        for lettera, quantita in lettere_mancanti.items():
            print(f"Mancano {quantita} {lettera}'")
        if (numero_jolly < len(lettere_mancanti)):
            return False

        risposta = input(f"Vuoi utilizzare i jolly? (s/n): ")
        if risposta.lower() != 's':
            return False  # Il giocatore non vuole utilizzare i jolly

        # Sostituisci i jolly
        jolly_usati = 0
        for lettera, quantita in lettere_mancanti.items():
            while quantita > 0 and jolly_usati < numero_jolly:
                for tessera in giocatore.tessere_giocatore:
                    if tessera.lettera == '*' and quantita > 0:
                        tessera.lettera = lettera
                        tessera.punteggio = punteggio_lettera(lettera)
                        jolly_usati += 1
                        quantita -= 1
                        break
                # Se abbiamo trovato la lettera o utilizzato tutti i jolly necessari, usciamo dal ciclo interno
                if jolly_usati == numero_jolly or quantita == 0:
                    break

    return True


def rimuovi_tessere_usate(giocatore, parola):
    """Rimuove le tessere utilizzate dalla mano del giocatore."""
    for tessera in giocatore.tessere_giocatore:
        print(tessera.lettera)

    giocatore.tessere_giocatore = [tessera for tessera in giocatore.tessere_giocatore if tessera.lettera not in parola]

    for tessera in giocatore.tessere_giocatore:
        print(tessera.lettera)
    print(giocatore.tessere_giocatore)


def loop_di_gioco(giocatori, tabellone, tessere):
    partita = True
    while partita:
        for giocatore in giocatori:
            if len(tessere) == 0:
                partita = False
                classifica_temporanea = calcola_classifica_temporanea(giocatori)
                print("Classifica finale:")
                for i, giocatore in enumerate(classifica_temporanea, start=1):
                    print(f"{i}. Giocatore {giocatore.ordine_giocatore}: {giocatore.punteggio_tot} punti")
                break
            print(partita)
            print(f"\nTurno del Giocatore {giocatore.ordine_giocatore}:")
            print("Le tue tessere:", [tessera.lettera for tessera in giocatore.tessere_giocatore])

            parola = input("Inserisci la parola da giocare (o 'passa' per saltare il turno): ").upper()
            if parola == "PASSA":
                print(f"Giocatore {giocatore.ordine_giocatore} passa il turno.")
                continue

            riga = int(input("Inserisci la riga di partenza (0-16): "))
            colonna = int(input("Inserisci la colonna di partenza (0-16): "))
            orientamento = input("Inserisci l'orientamento (O per orizzontale, V per verticale): ").upper()

            if controllo_mossa(tabellone, parola, riga, colonna, orientamento):
                if len(giocatore.tessere_giocatore) >= len(parola):
                    if controlla_tessere_disponibili(giocatore, parola):
                        giocatore.punteggio_tot += calcola_punteggio(tabellone, parola, riga, colonna, orientamento,
                                                                     giocatore.tessere_giocatore)
                        rimuovi_tessere_usate(giocatore, parola)
                        posiziona_parola(tabellone, parola, riga, colonna, orientamento)
                        stampa_tabellone(tabellone)
                        giocatore.tessere_giocatore.extend(
                            distribuisci_tessere(tessere, 8 - len(giocatore.tessere_giocatore)))
                        print("Nuove tessere:", [tessera.lettera for tessera in giocatore.tessere_giocatore])
                        print(giocatore.punteggio_tot)
                        classifica_temporanea = calcola_classifica_temporanea(giocatori)
                        print("Classifica temporanea:")
                        for i, giocatore in enumerate(classifica_temporanea, start=1):
                            print(f"{i}. Giocatore {giocatore.ordine_giocatore}: {giocatore.punteggio_tot} punti")
                    else:
                        print("Non hai le tessere necessarie.")
                else:
                    print("Non hai abbastanza tessere.")
            else:
                print("Mossa non valida.")



def calcola_punteggio(tabellone, parola, riga, colonna, orientamento, tessere):
    punteggio_totale = 0
    moltiplicatore_parola = 1

    for i, lettera in enumerate(parola):
        r = riga + i if orientamento == "V" else riga
        c = colonna + i if orientamento == "O" else colonna
        casella = tabellone[r][c]
        punteggio_lettera = next(t.punteggio for t in tessere if t.lettera == lettera)
        punteggio_parziale = punteggio_lettera * casella.moltiplicatore_lettera
        punteggio_totale += punteggio_parziale

        # Applica il moltiplicatore della parola solo alla fine
        if casella.tipo in (CasellaTipo.DOPPIO_PAROLA, CasellaTipo.TRIPLO_PAROLA):
            moltiplicatore_parola *= casella.moltiplicatore_parola

    punteggio_totale *= moltiplicatore_parola
    return punteggio_totale


def calcola_classifica_temporanea(giocatori):
    """Calcola e restituisce una nuova lista di giocatori ordinata per punteggio decrescente.

    Args:
      giocatori: La lista di giocatori.

    Returns:
      Una nuova lista di giocatori ordinata per punteggio.
    """

    return sorted(giocatori, key=lambda giocatore: giocatore.punteggio_tot, reverse=True)


def main():
    tessere = crea_lista_tessere_scarabeo()

    num_giocatori = int(input("Inserire numero di giocatori: "))
    giocatori = []
    for i in range(num_giocatori):
        giocatori.append(Giocatore(num_giocatori - i, distribuisci_tessere(tessere, 8)))

    tabellone = crea_tabellone_scarabeo()
    stampa_tabellone(tabellone)
    loop_di_gioco(giocatori, tabellone, tessere)


if __name__ == "__main__":
    main()

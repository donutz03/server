'''
Acesta este programul pentru convertirea oricarei cifre de la 0 la 9 in cod EXCES-3. 
Conceptul teoretic este simplu, algoritmul incepe prin a aduna 3 la fiecare cifra. Cifrele sunt salvate intr-un vector. Apoi,
valoarea "cat" ia valoarea cifrei+3, restul ia valoarea catului modulo 2, iar catul se actualizeaza prin impartirea intreaga la 2 
de fiecare data. Dupa acesti 2 pasi, restul se aduna la inceputul variabilei de tip string exces3, care contine codul cifrei in EXCES-3.
Acest procedeu se executa pana cand catul ia valoarea 0. In final, se printeaza cifra si valoarea corespunzatoare in EXCES-3.
'''

# Urmatoarele linii pun toate cifrele de la 0 la 9 marite cu 3 intr-un vector de dimensiune 10 si le convertesc pe rand in cod EXCES-3.
# Apoi, fiecare cifra si codul corespunzator sunt afisate pe ecran

exces3 = ''  # Aceasta variabila este utilizata pentru memorarea codului exces-3 al fiecarei cifre
digits = []
digitsinexces3 = []
for i in range(10):
    digits.append(i+3)
    # print(digits[i])
    # se creeaza vectorul cu cifrele de la 0 la 9 convertite in 3-12, pentru a incepe convertirea in codul exces-3

for x in digits:
    cat = x
    while (True):
        rest = cat % 2
        cat = int(cat/2)
        exces3 = str(rest) + exces3
        if (cat == 0):
            break
    k = len(exces3)
    # adauga zerouri in fata codului pana se ajunge la o lungime de 4, exemplu 1 in exces-3 este 0011, in loc de 11
    exces3 = '0' * (4-k) + exces3
    digitsinexces3.append(exces3)
    exces3 = ''
    # Variabila exces3 se reseteaza la '' pentru a putea fi reinitializata cu codul unei noi cifre

for i in range(10):
    print(f"Cifra {i} este {digitsinexces3[i]} in cod EXCES-3.")

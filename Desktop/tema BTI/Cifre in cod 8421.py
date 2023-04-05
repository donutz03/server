'''
Acesta este programul pentru convertirea oricarei cifre de la 0 la 9 in cod 8421
Conceptul teoretic este simplu, variabila "cat" ia valoarea cifrei, care este citita de la tastatura, restul ia valoarea catului
modulo 2, iar catul se actualizeaza prin impartirea intreaga la 2 de fiecare data. Dupa acesti 2 pasi, restul se aduna la inceputul 
variabilei de tip string cod8421. Acest procedeu se executa pana cand catul ia valoarea 0. In final, se printeaza cod8421.
'''

''' 
Mai jos este codul pentru convertirea unei cifre citite de la tastatura in cod 8421.
digit = int(input("Please enter a digit: (from 0 to 9) "))
cod8421 = ""
cat = digit
while (True):
    rest = cat % 2
    cat = int(cat/2)
    cod8421 = str(rest) + cod8421
    if (cat == 0):
        break
print(cod8421)

'''

# Urmatoarele linii pun toate cifrele de la 0 la 9 intr-un vector de dimensiune 10 si le convertesc pe rand in cod 8421.
# Codul folosit pentru transformare este cel explicat intre ''' ''' mai sus
# Apoi, fiecare cifra si codul corespunzator sunt afisate pe ecran

cod8421 = ''
digits = []
digitsin8421 = []
for i in range(10):
    digits.append(i)
    # print(digits[i])

for i in range(10):
    cat = digits[i]
    while (True):
        rest = cat % 2
        cat = int(cat/2)
        cod8421 = str(rest) + cod8421
        if (cat == 0):
            break
    k = len(cod8421)
    # adauga zerouri in fata codului pana se ajunge la o lungime de 4, exemplu 1 in 8421 este 0001, in loc de 1
    cod8421 = '0' * (4-k) + cod8421
    digitsin8421.append(cod8421)
    cod8421 = ''

for i in range(10):
    print(f"Cifra {i} este {digitsin8421[i]} in cod 8421.")

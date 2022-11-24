#include "des.h"

static BYTE K0  [64+1];
static BYTE K1  [64+1];
static BYTE K2  [64+1];
static BYTE K3  [64+1];
static BYTE K4  [64+1];
static BYTE K5  [64+1];
static BYTE K6  [64+1];
static BYTE K7  [64+1];
static BYTE K8  [64+1];
static BYTE K9  [64+1];
static BYTE K10 [64+1];
static BYTE K11 [64+1];
static BYTE K12 [64+1];
static BYTE K13 [64+1];
static BYTE K14 [64+1];
static BYTE K15 [64+1];
static BYTE K16 [64+1];

BYTE * K [17]={K0,K1,K2,K3,K4,K5,K6,K7,K8,K9,K10,K11,K12,K13,K14,K15,K16};

static BYTE IpDir [] =
{
	 00,
   58, 50, 42, 34, 26, 18, 10,  2, 60, 52, 44, 36, 28, 20, 12,  4,
   62, 54, 46, 38, 30, 22, 14,  6, 64, 56, 48, 40, 32, 24, 16,  8,
   57, 49, 41, 33, 25, 17,  9,  1, 59, 51, 43, 35, 27, 19, 11,  3,
   61, 53, 45, 37, 29, 21, 13,  5, 63, 55, 47, 39, 31, 23, 15,  7
};

static BYTE IpInv [] =
{
   00,
   40,  8, 48, 16, 56, 24, 64, 32, 39,  7, 47, 15, 55, 23, 63, 31,
   38,  6, 46, 14, 54, 22, 62, 30, 37,  5, 45, 13, 53, 21, 61, 29,
   36,  4, 44, 12, 52, 20, 60, 28, 35,  3, 43, 11, 51, 19, 59, 27,
   34,  2, 42, 10, 50, 18, 58, 26, 33,  1, 41,  9, 49, 17, 57, 25
};

static BYTE E [] =
{
   00,
   32,  1,  2,  3,  4,  5,  4,  5,  6,  7,  8,  9,  8,  9, 10, 11, 12, 13,
	 12, 13, 14, 15, 16, 17, 16, 17, 18, 19, 20, 21, 20, 21, 22, 23, 24, 25,
   24, 25, 26, 27, 28, 29, 28, 29, 30, 31, 32,  1
};

static BYTE P [] =
{
   00,
   16,  7, 20, 21, 29, 12, 28, 17,  1, 15, 23, 26,  5, 18, 31, 10,
    2,  8, 24, 14, 32, 27,  3,  9, 19, 13, 30,  6, 22, 11,  4, 25
};

static BYTE S [8][64] =
{
/* --- S 1 --- */
   {
   14,  4, 13,  1,  2, 15, 11,  8,  3, 10,  6, 12,  5,  9,  0,  7,
		0, 15,  7,  4, 14,  2, 13,  1, 10,  6, 12, 11,  9,  5,  3,  8,
    4,  1, 14,  8, 13,  6,  2, 11, 15, 12,  9,  7,  3, 10,  5,  0,
   15, 12,  8,  2,  4,  9,  1,  7,  5, 11,  3, 14, 10,  0,  6, 13,
   },
/* --- S 2 --- */
   {
   15,  1,  8, 14,  6, 11,  3,  4,  9,  7,  2, 13, 12,  0,  5, 10,
    3, 13,  4,  7, 15,  2,  8, 14, 12,  0,  1, 10,  6,  9, 11,  5,
    0, 14,  7, 11, 10,  4, 13,  1,  5,  8, 12,  6,  9,  3,  2, 15,
   13,  8, 10,  1,  3, 15,  4,  2, 11,  6,  7, 12,  0,  5, 14,  9,
   },
/* --- S 3 --- */
   {
   10,  0,  9, 14,  6,  3, 15,  5,  1, 13, 12,  7, 11,  4,  2,  8,
   13,  7,  0,  9,  3,  4,  6, 10,  2,  8,  5, 14, 12, 11, 15,  1,
   13,  6,  4,  9,  8, 15,  3,  0, 11,  1,  2, 12,  5, 10, 14,  7,
    1, 10, 13,  0,  6,  9,  8,  7,  4, 15, 14,  3, 11,  5,  2, 12,
   },
/* --- S 4 --- */
   {
		7, 13, 14,  3,  0,  6,  9, 10,  1,  2,  8,  5, 11, 12,  4, 15,
   13,  8, 11,  5,  6, 15,  0,  3,  4,  7,  2, 12,  1, 10, 14,  9,
   10,  6,  9,  0, 12, 11,  7, 13, 15,  1,  3, 14,  5,  2,  8,  4,
    3, 15,  0,  6, 10,  1, 13,  8,  9,  4,  5, 11, 12,  7,  2, 14,
	 },
/* --- S 5 --- */
   {
    2, 12,  4,  1,  7, 10, 11,  6,  8,  5,  3, 15, 13,  0, 14,  9,
   14, 11,  2, 12,  4,  7, 13,  1,  5,  0, 15, 10,  3,  9,  8,  6,
    4,  2,  1, 11, 10, 13,  7,  8, 15,  9, 12,  5,  6,  3,  0, 14,
   11,  8, 12,  7,  1, 14,  2, 13,  6, 15,  0,  9, 10,  4,  5,  3,
   },
/* --- S 6 --- */
   {
   12,  1, 10, 15,  9,  2,  6,  8,  0, 13,  3,  4, 14,  7,  5, 11,
   10, 15,  4,  2,  7, 12,  9,  5,  6,  1, 13, 14,  0, 11,  3,  8,
    9, 14, 15,  5,  2,  8, 12,  3,  7,  0,  4, 10,  1, 13, 11,  6,
    4,  3,  2, 12,  9,  5, 15, 10, 11, 14,  1,  7,  6,  0,  8, 13,
   },
/* --- S 7 --- */
	 {
    4, 11,  2, 14, 15,  0,  8, 13,  3, 12,  9,  7,  5, 10,  6,  1,
   13,  0, 11,  7,  4,  9,  1, 10, 14,  3,  5, 12,  2, 15,  8,  6,
    1,  4, 11, 13, 12,  3,  7, 14, 10, 15,  6,  8,  0,  5,  9,  2,
		6, 11, 13,  8,  1,  4, 10,  7,  9,  5,  0, 15, 14,  2,  3, 12,
   },
/* --- S 8 --- */
   {
   13,  2,  8,  4,  6, 15, 11,  1, 10,  9,  3, 14,  5,  0, 12,  7,
    1, 15, 13,  8, 10,  3,  7,  4, 12,  5,  6, 11,  0, 14,  9,  2,
    7, 11,  4,  1,  9, 12, 14,  2,  0,  6, 10, 13, 15,  3,  5,  8,
    2,  1, 14,  7,  4, 10,  8, 13, 15, 12,  9,  0,  3,  5,  6, 11,
   }
};

static BYTE Pc1 [] =
{
   00,
   57, 49, 41, 33, 25, 17,  9,  1, 58, 50, 42, 34, 26, 18,
   10,  2, 59, 51, 43, 35, 27, 19, 11,  3, 60, 52, 44, 36,
	 63, 55, 47, 39, 31, 23, 15,  7, 62, 54, 46, 38, 30, 22,
   14,  6, 61, 53, 45, 37, 29, 21, 13,  5, 28, 20, 12,  4
};

static BYTE Pc2 [] =
{
   00,
   14, 17, 11, 24,  1,  5,  3, 28, 15,  6, 21, 10,
   23, 19, 12,  4, 26,  8, 16,  7, 27, 20, 13,  2,
   41, 52, 31, 37, 47, 55, 30, 40, 51, 45, 33, 48,
   44, 49, 39, 56, 34, 53, 46, 42, 50, 36, 29, 32
};

static BYTE Lshifts [] =
{
   00,
   1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1
};

static BYTE L0  [128+1];
static BYTE L1  [1];
static BYTE L2  [1];
static BYTE L3  [1];
static BYTE L4  [1];
static BYTE L5  [1];
static BYTE L6  [1];
static BYTE L7  [1];
static BYTE L8  [1];
static BYTE L9  [1];
static BYTE L10 [1];
static BYTE L11 [1];
static BYTE L12 [1];
static BYTE L13 [1];
static BYTE L14 [1];
static BYTE L15 [1];
static BYTE L16 [1];

static BYTE *L[17]={L0,L1,L2,L3,L4,L5,L6,L7,L8,L9,L10,L11,L12,L13,L14,L15,L16};

static BYTE R0  [1];
static BYTE R1  [1];
static BYTE R2  [1];
static BYTE R3  [1];
static BYTE R4  [1];
static BYTE R5  [1];
static BYTE R6  [1];
static BYTE R7  [1];
static BYTE R8  [1];
static BYTE R9  [1];
static BYTE R10 [1];
static BYTE R11 [1];
static BYTE R12 [1];
static BYTE R13 [1];
static BYTE R14 [1];
static BYTE R15 [1];
static BYTE R16 [1];

static BYTE * R[17]={R0,R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12,R13,R14,R15,R16};

void   Dilate (BYTE *, BYTE *, int );
void   Compr (BYTE *, BYTE *, int );
void   DecaleGauche (BYTE *, int );
void   Matrice (BYTE *, BYTE *, BYTE *, int );
void   Calculcle (BYTE *);
BYTE  *OuExclusif (BYTE *, BYTE *, int );
BYTE  *Fdes (BYTE *, BYTE *, int );

/* ------------------------------------------------------------------------
Module      : Dilate
Description : la fonction Dilate isole les LngBits du tableau M et les
		    range dans le tableau Md. Ainsi le tableau Md ne contient
		    en retour que des 0 et 1.
Entrée(s)   : (1) un pointeur de tableau de caractères (le contenu de ce
			   tableau sera modifié en retour).
		      (2) un pointeur de tableau de caractères (le tableau contient
			   les octets à traiter).
		    (3) un int qui correspond au nb de bits que l'on veut ranger
			   dans (1)
Sortie(s)   : pas de paramètre
Remarque    : le fait d'isoler tous les bits d'un ensemble d'octets et de
		    placer ces bits dans un tableau permet de les permuter de
		    facon simple.
-------------------------------------------------------------------------- */
void Dilate ( BYTE *Md, BYTE *M, int LngEnBits)
{
	int i;

	Md++;
	for (i = 0; i < LngEnBits; i++)
		Md [i] = (BYTE)((M [i>>3] >> (~i & 7)) & 1); /*E001*/
	return;
}

/* ------------------------------------------------------------------------
Module      : Compr
Description : la fonction Compr est la fonction inverse de la fonction
		    Dilate car partant d'un ensmble de bits contenus dans Md
		    (un bit = un char), on les compresse afin de retrouver des
		    octets que l'on range dans M.
Entrée(s)   : (1) un pointeur de tableau de caractères
			   (le contenu de ce tableau sera modifie en retour).
		    (2) un pointeur de tableau de caractères
			   (le tableau contient les octets à traiter).
		    (3) un int qui correspond au nb de bits
			   à compresser en (LngEnBits/8) octets.
Sortie(s)   : pas de paramètre
-------------------------------------------------------------------------- */
void Compr (BYTE *M, BYTE *Md, int LngEnBits)
{
	int i, j, LngEnOcts, NextOct, NumDeBits;

	Md++;
	LngEnOcts = LngEnBits >> 3;
	NextOct   = 0;

	for (i = 0; i < LngEnOcts; i++)
	{
		M [i]     = 0;
		NumDeBits = NextOct;
		NextOct  += 8;

		for (j = NumDeBits; j < NextOct; j++)
			M [i] |= Md [j] << (~j & 7);
	}
	return;
}

/* ------------------------------------------------------------------------
Module      : DecaleGauche
Description : on permute circulairement et à gauche les octets du
		    tableau cleI (par le milieu !! voir exemple )
Entrée(s)   : (1) un pointeur de tableau de caractères (les octets de ce
				 tableau seront permutes de 1 ou 2 à gauche)
		    (2) un int qui vaut 1 ou 2 et qui indique le nombre de
			   permutations souhaitées.
Sortie(s)   : pas de paramètre
Exemple     : pour NbDeDecal = 1
		    avant: cleI[1],cleI[2]...cleI[28]//cleI[29],cleI[30]...cleI[56]
				    X       Y   A     Z         T        U    B     V
		    après:    Y       A   ?     X         U        B    ?     T
Remarque    : cette fonction est utilisée afin de calculer les clefs pour
		    l'algorithme D.E.S.
-------------------------------------------------------------------------- */
void DecaleGauche (BYTE *cleI, int NbDeDecal)
{
	int j;
	BYTE Aux, Aux1, Aux2;

	if (NbDeDecal == 1)
	{
		Aux = cleI [1];
		for (j = 1; j < 28; j++)
			cleI [j] = cleI [j+1];
		cleI [28] = Aux;
		Aux = cleI [29];
		for (j = 29; j < 56; j++)
			cleI [j] = cleI [j+1];
		cleI [56] = Aux;
	}
	else   /* NbDecal == 2 !! */
	{
		Aux1 = cleI [1];
		Aux2 = cleI [2];
		for (j = 1; j < 27; j++)
			cleI [j] = cleI [j+2];
		cleI [27] = Aux1;
		cleI [28] = Aux2;
		Aux1 = cleI [29];
		Aux2 = cleI [30];
		for (j = 29; j < 55; j++)
			cleI [j] = cleI [j+2];
		cleI [55] = Aux1;
		cleI [56] = Aux2;
	}
	return;
}

/* ------------------------------------------------------------------------
Module      : Matrice
Description : on effectue l'operation suivante: TabFinal[i]=TabInital[Mat(i)]
Entrée(s)   : (1) Mr qui est un pointeur de tableau de caractère contient
			   en retour les octets du tableau de caractère M (2). Les
			   octets de M auront d'abord été permutés par la matrice
			   Mat de longueur LngEnBits.
		    (2) un pointeur de tableau de caractères (le tableau contient
			   les octets à traiter).
		    (3) un pointeur de tableau de caractères qui correspond a
			   une des matrices du D.E.S.
		    (4) un int qui indique la taille de la Matrice Mat (3)
Sortie(s)   : pas de paramètre
Remarque    : cette fonction est utilisée de nombreuses fois dans
			  l'algorithme D.E.S.
-------------------------------------------------------------------------- */
void Matrice (BYTE *Mr, BYTE *M, BYTE *Mat, int LngEnBits)
{
	int i;

	for (i = 1; i <= LngEnBits; i++)
		Mr [i] = M [ Mat[i] ];
	return;
}

/* ------------------------------------------------------------------------
Module      : Calculcle
Description : la fonction calcule l'ensemble des clefs utilisées pour un
		    calcul D.E.S et les range dans K0,..,K16. La clef initiale
		    servant à calculer ces clefs auxiliaires se trouve dans le
		    tableau cle[i]. (8 octets pour la clef initial dont 56 bits utiles)
Entrée(s)   : (1) clé de chiffrement
Sortie(s)   : OK ou PB
Remarque    : On peut eviter de recalculer les clefs Ki en prenant en compte
		    la remarque se trouvant dans le corps de la fonction. Pour
		    amorcer le processus, on devra faire un calcul de clef à vide
		    au debut du programme utilisant le D.E.S.
-------------------------------------------------------------------------- */
void Calculcle(BYTE *new_cle)
{
	static BYTE Oldcle [] = "12345678";
	BYTE cleAux [64+1];
	int i,Flag;

	Flag = 0;
	for (i = 0; i < 8; i++)
		if (new_cle [i] == Oldcle[i])
			++Flag;

/*  on peut ici si on le désire tester Flag afin de savoir si on n'a pas
  déjà calculé l'ensemble des clefs
  exemple :   if  (Flag == 8) return(1);*/

	Dilate (cleAux, new_cle, 64);
	Matrice (K[0], cleAux, Pc1, 56);
	for (i = 1; i < 17; i++)
	{
		DecaleGauche (K [0], Lshifts [i]);
		Matrice (K [i], K [0], Pc2, 48);
	}
	for (i = 0; i < 8; i++)
		Oldcle [i] = new_cle [i];
	Oldcle [8] = 0;
}

/* ------------------------------------------------------------------------
Module      : OuExclusif
Description : effectue un ou exclusif entre deux tableaux
Entrée(s)   : chemin & nom du premier fichier (contiendra le resultat en retour)
		    chemin & nom du second fichier
		    nombre d'octet
Sortie(s)   : OK ou PB
------------------------------------------------------------------------ */
BYTE *OuExclusif (BYTE *Dest, BYTE *Source, int LngEnBits)
{
	int i;

	for (i = 1; i <= LngEnBits; i++)
		Dest [i] ^= Source [i];
	return (Dest);
}

/* ------------------------------------------------------------------------
Module      : Fdes
Description : fonction Fdes interne au calcul du D.E.S
		    (voir algorithme D.E.S)
Entrée(s)   : pas de paramètre
Sortie(s)   : OK ou PB
------------------------------------------------------------------------ */
BYTE *Fdes (BYTE *Dest, BYTE *Source, int Rang)
{
	BYTE Inter_48 [48+1];
	BYTE Inter_32 [32+1];
	BYTE ResDeS   [8];
	BYTE Aux1, Aux2;
	int i;

	Matrice (Inter_48, Source, E, 48);
	OuExclusif (Inter_48, K [Rang], 48);
	for (i = 0; i < 8; i++)
	{
		Aux1 = (BYTE)(6 * i); /*E001*/
		Aux2 = (BYTE)( (Inter_48 [1+Aux1] << 5) + (Inter_48 [6+Aux1] << 4) +
			   (Inter_48 [2+Aux1] << 3) + (Inter_48 [3+Aux1] << 2) +
			   (Inter_48 [4+Aux1] << 1) + Inter_48 [5+Aux1] ); /*E001*/
		ResDeS [i] = S [i] [Aux2];
	}
	ResDeS [0] = (BYTE)( (ResDeS [0] << 4) + ResDeS[1] );/*E001*/
	ResDeS [1] = (BYTE)( (ResDeS [2] << 4) + ResDeS[3] );/*E001*/
	ResDeS [2] = (BYTE)( (ResDeS [4] << 4) + ResDeS[5] );/*E001*/
	ResDeS [3] = (BYTE)( (ResDeS [6] << 4) + ResDeS[7] );/*E001*/
	Dilate  (Inter_32, ResDeS,  32);
	Matrice (Dest, Inter_32, P, 32);
	return  (Dest);
}

/* ------------------------------------------------------------------------
Module      : des
Description : la fonction des effectue un chiffrement par l'algorithme D.E.S.
Entrée(s)   : (1) ResDuchiff un pointeur de tableau de huit
			   caractères(contient le résultat du Des (chiffré)
		    (2) Achiff un pointeur de tableau de huit caractères
			   (contient la donnée à chiffrer sur huit octets)
		    (3) sens 0 = > chiffre
				   1 = > dechiffre
		    (4) cle de chiffrement
Sortie(s)   : pas de paramètre
------------------------------------------------------------------------ */
void des (BYTE *ResDuChiff, BYTE *Achiff, BYTE sens, BYTE *cle)
{
	BYTE Md[64+1], ResDeF[64+1];
	int i;

	Calculcle (cle);

	Dilate  (Md, Achiff, 64);
	Matrice (L[0], Md, IpDir, 64);
	R [0] = &L [0][32];

	for (i = 1; i < 17; i++)
	{
		L [i] = R [i-1];
		if ( sens == CHIFFRE )
			R [i] = OuExclusif (L [i-1], Fdes (ResDeF, R [i-1], i), 32);
		else R [i] = OuExclusif (L [i-1], Fdes (ResDeF, R [i-1], 17-i), 32);
	}                                          
	for (i = 1; i <= 32; i++)
		R [16] [i+32] = L [16] [i];
	Matrice (Md, R [16], IpInv, 64);
	Compr (ResDuChiff, Md, 64);
}

/* ------------------------------------------------------------------------
Module      : tripledes
Description : effectue un triple DES
Entrée(s)   : (1) résultat, contient la chaine en clair
		      (2) diversifiant, contient la chaine à déchiffrer
		      (3) mode 0 => Chiffrement
					   1 => Déchiffrement
			  (4) key_H, adresse de la clef ( poid fort )
		      (5) key_L, adresse de la clef ( poid faible )
Sortie(s)   : OK ou PB
------------------------------------------------------------------------ */
void tripledes_2keys (BYTE *resultat, BYTE *diversifiant, BYTE mode, BYTE *key_H, BYTE *key_L)
{
	/* --- décryptage avec clef poids fort ---*/
	des( resultat, diversifiant, mode, key_H);

	/* --- encryptage avec clef poids faible ---*/
	if (mode == CHIFFRE)
		des( diversifiant, resultat, DECHIFFRE, key_L);
	else
		des( diversifiant, resultat, CHIFFRE, key_L);


	/* --- décryptage avec clef poids fort ---*/
	des( resultat, diversifiant, mode, key_H);
}

void tripledes_3keys (BYTE *resultat, BYTE *diversifiant, BYTE mode, BYTE *key1, BYTE *key2, BYTE *key3)
{
	des( resultat, diversifiant, mode, key1);

	if (mode == CHIFFRE)
		des( diversifiant, resultat, DECHIFFRE, key2);
	else
		des( diversifiant, resultat, CHIFFRE, key2);

	des( resultat, diversifiant, mode, key3);
}

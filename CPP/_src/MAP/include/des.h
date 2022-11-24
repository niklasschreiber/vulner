/*---------------------------------------------*/
/* Security library DES                        */
/*---------------------------------------------*/
/* File:    des.h (header)                     */
/* Author : V.CE. / Etude & Developpement      */
/* Company: De La Rue Cards & Systems          */
/*                                             */
/* Date of creation : 22/05/95                 */
/*---------------------------------------------*/
/* Description : contains the functions to     */
/*               cipher and decipher data with */
/*				 DES algorithm.				   */
/* Modules  :                                  */
/*			- Dilate                           */
/*		    - Compr                            */
/*		    - DecaleGauche                     */
/*		    - Matrice                          */
/*		    - Calculcle                        */
/*		    - OuExclusif                       */
/*		    - Fdes                             */
/*			- des                              */
/*		    - tripledes                        */
/*---------------------------------------------*/
/* related files :  des.h (header)             */
/* externals used : none                       */
/*---------------------------------------------*/

/*--------------------------------------------------------------------------------------*/
/* Modification story                                                                   */
/*--------------------------------------------------------------------------------------*/
/*    Author   |    Date     |               Comments                        | edition  */
/*--------------------------------------------------------------------------------------*/
/* L. REMAURY  |  05-11-98   | Cast of types unsigned short and long         |  E001    */ 
/*             |             |                                               |          */
/*             |  16-09-98   |  creation V1                                  |  E000    */ 
/*             |             |                                               |          */
/*--------------------------------------------------------------------------------------*/
/* Linea commentata da Fabrizio Santagostino (1/3/2000)									*/
/* static char __file_identification[] = "Ã√Ã√Ã√Ã√DES.C_E001" ;                         */


#ifndef _DES_H
#define _DES_H

#define CHIFFRE 0
#define DECHIFFRE 1

typedef unsigned int  word;
typedef unsigned char BYTE; /* Dichiarazione aggiunta da Fabrizio Santagostino (1/3/2000)*/

void des (BYTE *ResDuChiff, BYTE *Achiff, BYTE sens, BYTE *cle);

// F.Berrouet - 26/03/2009
void tripledes_2keys(BYTE *resultat, BYTE *diversifiant, BYTE mode, BYTE *key_H, BYTE *key_L);
void tripledes_3keys(BYTE *resultat, BYTE *diversifiant, BYTE mode, BYTE *key1, BYTE *key2, BYTE *key3);

#endif

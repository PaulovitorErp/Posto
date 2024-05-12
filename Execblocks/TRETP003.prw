#include 'protheus.ch'

/*/{Protheus.doc} TRETP003
Chamado pelo P.E. MA103OPC para incluir a op��o de Stats do LMC
no menu do Documento de Entrada
@author Totvs TBC
@since 13/10/2017
@version 1.0
@return Array

@type function
/*/

User Function TRETP003()

Local _aRotNew	:= {}
//Local _aRotina	:= aClone(Paramixb)

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combust�vel (Posto Inteligente).
//Caso o Posto Inteligente n�o esteja habilitado n�o faz nada...
If !lMvPosto
	Return _aRotNew
EndIf

AAdd(_aRotNew,{"Status LMC", "U_TRETE013", 4, 0 })

Return _aRotNew

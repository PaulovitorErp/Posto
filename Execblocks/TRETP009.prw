#Include "Protheus.ch"

/*/{Protheus.doc} TRETP009
Fun��o chamada pelo P.E. MTA010MNU para adicionar rotinas no cadastro de Produtos.

@author TBC
@since 29/11/2018
@version 1.0
@return Nulo

@type function
/*/

User Function TRETP009()
	
	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combust�vel (Posto Inteligente).
	//Caso o Posto Inteligente n�o esteja habilitado n�o faz nada...
	If !lMvPosto
		Return
	EndIf

	#IFDEF TOP
		aAdd( aRotina, { "Negocia��o de Pre�os"	 , "U_TRETA023(1)", 0, 4 } ) // Negocia�ao de Pre�os
	#ENDIF
	
Return                          

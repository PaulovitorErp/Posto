#Include "Protheus.ch"

/*/{Protheus.doc} TRETP009
Função chamada pelo P.E. MTA010MNU para adicionar rotinas no cadastro de Produtos.

@author TBC
@since 29/11/2018
@version 1.0
@return Nulo

@type function
/*/

User Function TRETP009()
	
	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return
	EndIf

	#IFDEF TOP
		aAdd( aRotina, { "Negociação de Preços"	 , "U_TRETA023(1)", 0, 4 } ) // Negociaçao de Preços
	#ENDIF
	
Return                          

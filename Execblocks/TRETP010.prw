#Include "Protheus.ch"

/*/{Protheus.doc} TRETP010
Chamado pelo P.E. OM010MNU para inclusao da rotina Cad.Preco Prod.+ Forma
no menu da tabela de preço 

@author TBC
@since 29/11/2018
@version 1.0
@return Nulo

@type function
/*/

User Function TRETP010()

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return
	EndIf
	
	#IFDEF TOP
		aadd(aRotina,{"Negociação de Preços", "U_TRETA023()", 0 , 4,0,NIL})	// Negociaçao de Preços  
		aadd(aRotina,{"Enviar Preço Bicos", "U_TRETE002(.T.)", 0 , 4,0,NIL})	// Envio de preços para automação
	#ENDIF
	
Return  

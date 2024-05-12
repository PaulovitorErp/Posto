#Include "Protheus.ch"

/*/{Protheus.doc} TRETP010
Chamado pelo P.E. OM010MNU para inclusao da rotina Cad.Preco Prod.+ Forma
no menu da tabela de pre�o 

@author TBC
@since 29/11/2018
@version 1.0
@return Nulo

@type function
/*/

User Function TRETP010()

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combust�vel (Posto Inteligente).
	//Caso o Posto Inteligente n�o esteja habilitado n�o faz nada...
	If !lMvPosto
		Return
	EndIf
	
	#IFDEF TOP
		aadd(aRotina,{"Negocia��o de Pre�os", "U_TRETA023()", 0 , 4,0,NIL})	// Negocia�ao de Pre�os  
		aadd(aRotina,{"Enviar Pre�o Bicos", "U_TRETE002(.T.)", 0 , 4,0,NIL})	// Envio de pre�os para automa��o
	#ENDIF
	
Return  

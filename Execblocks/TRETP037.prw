#include "protheus.ch"

/*/{Protheus.doc} TRETP037
Chamado pelo P.E. FISTRFNFE para adicionar a op��o de estornar a NFE
@since 12/02/2016
@version P11
@param Nao recebe parametros
@return nulo
/*/


User Function TRETP037()

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combust�vel (Posto Inteligente).
	//Caso o Posto Inteligente n�o esteja habilitado n�o faz nada...
	If !lMvPosto
		Return
	EndIf

	AAdd(aRotina,{'Estorno NF s/ CF','U_TRETE033' , 0 , 3,0,NIL})

Return

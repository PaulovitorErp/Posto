#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETP001 (OM040BRW)
Ponto de entrada usado para inserir botões específicos (browse), no cadastro de Motoristas (OMSA040).
@author Danilo Brito
@since 24/09/2018
@version 1.0
@return xRet, Array com menus
@type function
/*/
user function TRETP001()

	Local aRotina := {}
	
	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return aRotina
	EndIf

	aadd(aRotina, { "Importar",	"U_TRETA001()"	,0 , 3 } )

return aRotina

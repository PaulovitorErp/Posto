#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETP002 (OM060BRW)
Ponto de entrada usado para inserir botões específicos (browse), no cadastro de Veiculos (OMSA060).
@author Danilo Brito
@since 24/09/2018
@version 1.0
@return xRet, Array com menus
@type function
/*/
user function TRETP002()

	Local aRotina := {}

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return aRotina
	EndIf

	aadd(aRotina, { "Importar",	"U_TRETA002()"	,0 , 3 } )
	aadd(aRotina, { "Transferencia",	"U_TRETA003()"	,0 , 3 } )
	aadd(aRotina, { "Desvinc. Placas",	"U_TRETA02C()"	,0 , 3 } )

return aRotina

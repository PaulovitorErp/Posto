#include 'totvs.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} F190SE5
Tratamento complementar
O ponto de entrada F190SE5 sera utilizado no tratamento complementar da gravacao do movimento no SE5 na liberacao de cheques.

@author Totvs GO
@since 28/08/2020
@version 1.0
@return Retorna URET(nulo)

@type function
/*/
User Function F190SE5()

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP032")
		lRet := ExecBlock("TRETP032",.F.,.F.)
	EndIf

Return

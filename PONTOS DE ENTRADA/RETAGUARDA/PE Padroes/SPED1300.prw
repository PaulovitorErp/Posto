#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} SPED1300
P.E. com objetivo de informar a Movimentação Diária de Combustíveis
@author Maiki Perin
@since 24/10/2018
@version 1.0
@param ParamIxb[1] - cAlias
@param ParamIxb[2] - dDataDe
@param ParamIxb[3] - dDataAte
@param ParamIxb[4] - aReg0200
@param ParamIxb[5] - aReg0190
@return nulo
/*/
User Function SPED1300()

	Local _aParam 	:= aClone(PARAMIXB)
	Local cPe1300	:= SuperGetMv("MV_XPE1300",.F.,"TRETP012")

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If cPe1300 == "TRETP012"

		//Projeto TOTVS PDV
		If ExistBlock("TRETP012")
			ExecBlock("TRETP012", .F., .F., _aParam)
		EndIf
	Endif

Return

#Include "Protheus.ch"

/*/{Protheus.doc} MT121BRW
Ponto de etrada utilizado na rotina pedido de compras
para adicinonar opçóes ao Array aRotina que contem os menus do programa

@author Ricardo Quintais
@since 29/01/2015
@version 1.0
@return nulo
@type function
/*/

User Function MT121BRW()
	
	Local cMV_XPECRC := SuperGetMv("MV_XPECRC",,"2") //Qual PE usar para CRC: 1-Sigaloja;2=TotvsPDV

	/////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                 //
	/////////////////////////////////////////////////////////////////////////////////////////
	If cMV_XPECRC == "2" .AND. ExistBlock("TRETP004")
		ExecBlock("TRETP004",.F.,.F.)
	EndIf

Return

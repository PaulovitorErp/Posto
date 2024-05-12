#include "Protheus.ch"
#include "rwmake.ch"


/*/{Protheus.doc} MT100TOK
Ponto de entrada para validar a inclusao da NF de entrada

@author Totvs TBC
@since 05/12/2013
@version 1.0
@type function
/*/

User Function MT100TOK()

	Local _lRet  := .T.
	Local aParan := aClone(Paramixb)
	Local cMV_XPECRC := SuperGetMv("MV_XPECRC",,"2") //Qual PE usar para CRC: 1-Sigaloja;2=TotvsPDV

	/////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                 //
	/////////////////////////////////////////////////////////////////////////////////////////
	If cMV_XPECRC == "2" .AND. ExistBlock("TRETP006")
		_lRet := ExecBlock("TRETP006",.F.,.F.,aParan)
	EndIf

Return _lRet

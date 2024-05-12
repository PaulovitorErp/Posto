#include "totvs.ch"
#include "topconn.ch"

/*/{Protheus.doc} PE01NFESEFAZ.
Ponto de entrada executado antes da montagem do XML, no momento da transmissão da NFe
@author TOTVS
@since 27/08/2016
@version P12                                                                                          
@param nulo
@return nulo
/*/
User Function PE01NFESEFAZ()

	Local _aParam := aClone(PARAMIXB)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If  ExistBlock("TRETP013")
		_aParam := ExecBlock("TRETP013",.F.,.F.,_aParam)
	Endif

Return _aParam

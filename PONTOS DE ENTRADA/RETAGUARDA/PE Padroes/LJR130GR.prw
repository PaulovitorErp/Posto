#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJR130GR
Ponto de entrada permite efetuar qualquer atualização na base após a gravação dos itens da nota fiscal (arquivo SD2), 
pois é chamado logo após a geração desse arquivo..

@author Totvs
@since 28/08/2019
@version 1.0
@return lRet

@type function
/*/
User function LJR130GR()
	
	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP019")
		ExecBlock("TRETP019",.F.,.F.)
	EndIf
	
Return
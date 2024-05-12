#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} M103XFIN
O ponto de entrada M103XFIN é responsável pela validação dos títulos financeiros, na exclusão do Documento de Entrada.
No término da função, permite alterar a validação e configurar se seus avisos serão exibidos.

@author Pablo Cavalcante
@since 19/11/2017
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function M103XFIN()
Local xRet
Local aParam := aClone(ParamIxb)
	
///////////////////////////////////////////////////////////////////////////////////////////
//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
/////////////////////////////////////////////////////////////////////////////////////////
If ExistBlock("TRETP026")
	 xRet := ExecBlock("TRETP026",.F.,.F.,aParam)
EndIf

Return xRet

#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} M103XFIN
O ponto de entrada M103XFIN � respons�vel pela valida��o dos t�tulos financeiros, na exclus�o do Documento de Entrada.
No t�rmino da fun��o, permite alterar a valida��o e configurar se seus avisos ser�o exibidos.

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

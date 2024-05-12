#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ7082
Este Ponto de entrada permite a execução de um processo customizado, para que se possa determinar se a venda será processada pelo LjGrvBatch.
Se a venda não for processada e não sofrer nenhuma alteração, ela tentará ser processada na próxima execução do LjGrvBatch.

@author Pablo Nunes
@since 03/01/2020
@version 1.0
@return 	
Retorno Lógico .T. = a venda será processada .F. = a venda não será processada

@type function
/*/
User Function LJ7082()

	Local aParam := aClone(ParamIxb)
	Local xRet := .T.

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP029")
		xRet := ExecBlock("TRETP029",.F.,.F.,aParam)
	Endif

Return xRet
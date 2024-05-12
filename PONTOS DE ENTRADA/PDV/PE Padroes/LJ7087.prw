#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ7087
Customização da definição do tipo emissão da venda, "Cupom ou Nota?".

Seu retorno deve ser um numérico de 0 a 2, onde:
0 = É definido com a apresentação da pergunta (padrão)
1 = Emissão de CF ou NFC-e (sem a apresentação da pergunta)
2 = Emissão de Nota Fiscal (sem a apresentação da pergunta)

@author thebr
@since 26/11/2018
@version 1.0
@return Nil

@type function
/*/
User Function LJ7087()

	Local xRet

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP007")
		xRet := ExecBlock("TPDVP007",.F.,.F.)
	EndIf

Return xRet

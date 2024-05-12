#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ7087
Customiza��o da defini��o do tipo emiss�o da venda, "Cupom ou Nota?".

Seu retorno deve ser um num�rico de 0 a 2, onde:
0 = � definido com a apresenta��o da pergunta (padr�o)
1 = Emiss�o de CF ou NFC-e (sem a apresenta��o da pergunta)
2 = Emiss�o de Nota Fiscal (sem a apresenta��o da pergunta)

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

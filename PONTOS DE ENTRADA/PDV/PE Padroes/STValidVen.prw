#include 'protheus.ch'

/*/{Protheus.doc} STValidVen
Este Ponto de Entrada � executado ap�s a sele��o do vendedor no TOTVS PDV, 
faz a valida��o se o vendedor selecionado � v�lido ou n�o segundo a regra de neg�cios.

@author Pablo Cavalcante
@since 18/09/2020
@version P12
@param PARAMIXB[1]: Caracter - Codigo do vendedor Selecionado
@return Deve ser um array com a mesma estrutura abaixo:
    aRet(array), sendo:
        -aret[1] - L�gico - Resultado da valida��o
        -aret[2] - Caracter - Mensagem a ser exibida caso a Valida��o retorne Falso(.F.)
/*/
User Function STValidVen()

    Local xRet
    Local aParam 	:= aClone(ParamIxb)
    Local aArea		:= GetArea()

    ///////////////////////////////////////////////////////////////////////////////////////////
    //             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
    ///////////////////////////////////////////////////////////////////////////////////////////
    If ExistBlock("TPDVP023")
        xRet := ExecBlock("TPDVP023",.F.,.F.,aParam)
    EndIf

    RestArea(aArea)

Return xRet

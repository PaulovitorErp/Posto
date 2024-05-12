#include 'protheus.ch'

/*/{Protheus.doc} STValidVen
Este Ponto de Entrada é executado após a seleção do vendedor no TOTVS PDV, 
faz a validação se o vendedor selecionado é válido ou não segundo a regra de negócios.

@author Pablo Cavalcante
@since 18/09/2020
@version P12
@param PARAMIXB[1]: Caracter - Codigo do vendedor Selecionado
@return Deve ser um array com a mesma estrutura abaixo:
    aRet(array), sendo:
        -aret[1] - Lógico - Resultado da validação
        -aret[2] - Caracter - Mensagem a ser exibida caso a Validação retorne Falso(.F.)
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

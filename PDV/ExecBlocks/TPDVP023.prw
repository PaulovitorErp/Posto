#include 'protheus.ch'

/*/{Protheus.doc} TPDVP023
(STValidVen) Este Ponto de Entrada é executado após a seleção do vendedor no TOTVS PDV, 
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
User Function TPDVP023()

    Local aArea := GetArea()
    Local aAreaSA3 := SA3->(GetArea())
    Local cCodVend := PARAMIXB[1] //Codigo do vendedor recebido via parametro
    //Local cVenPad := SuperGetMv( "MV_VENDPAD",,"")//Vendedor padrao
    Local aRet := {.T.,""} //Retorno

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
    //Caso o Posto Inteligente não esteja habilitado não faz nada...
    If !lMvPosto
        Return aRet
    EndIf

    SA3->(DbSetOrder(1)) //A3_FILIAL+A3_COD
    SA3->(DbSeek(xFilial("SA3")+cCodVend))
    If SA3->(!Eof()) .and. !U_TPDVP23A(cCodVend)
        aRet := {.F.,"O cargo (A3_CARGO) do vendedor "+SA3->A3_COD+"-"+AllTrim(SA3->A3_NOME)+" não está liberado para ser utilizado no PDV."}
    EndIf

    RestArea(aAreaSA3)
    RestArea(aArea)

Return aRet

//-------------------------------------------------------------------
/*/{Protheus.doc} TPDVP23A
Regra que especifica se o Vendedor pode ou não ser selecionado no PDV
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TPDVP23A(cCodVend)

    Local aArea := GetArea()
    Local aAreaSA3 := SA3->(GetArea())
    Local lRet := .T.
    Local cCargos := SuperGetMv("MV_XCARGVD",,"") //Lista de cargos de vendedores habilitados para para o PDV

    If !Empty(cCargos)
        SA3->(DbSetOrder(1)) //A3_FILIAL+A3_COD
        SA3->(DbSeek(xFilial("SA3")+cCodVend))
        If SA3->(!Eof()) .and. !(SA3->A3_CARGO $ cCargos)
            lRet := .F. //cargo do vendedor não esta liberado no parametro "MV_XCARGVD"
        EndIf
    EndIf

    RestArea(aAreaSA3)
    RestArea(aArea)

Return lRet

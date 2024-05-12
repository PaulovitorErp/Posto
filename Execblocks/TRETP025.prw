#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ720CABEC
Esse ponto de entrada � chamado para a incluis�o de campos adicionais no cabe�alho da NF de devolu��o.

@author Pablo Cavalcante
@since 26/11/2019
@version 1.0
@return lRet

@type function
/*/
User Function TRETP025()

	Local aCab := ParamIxb[1]
    //Local aDocDev := ParamIxb[2] //Array of Record - Armazena a s�rie, n�mero e cliente+loja da NF de devolu��o e o tipo de opera��o (1=troca ou 2=devolu��o)
    Local cMotivo := ""
    Local aRet := {}
    Local aParamBox := {}

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combust�vel (Posto Inteligente).
    //Caso o Posto Inteligente n�o esteja habilitado n�o faz nada...
    If !lMvPosto
        Return aCab
    EndIf

    Private lMsErroAuto := .F. // variavel interna da rotina automatica

    //conout(">> TRETP025 -> aDocDev: "+U_toString(aDocDev))
    //>> TRETP025 -> aDocDev: [["1  ", "000003722", "000626", "01", 2, "         ", []]]
    //If len(aDocDev) >= 5 .AND. aDocDev[5] = 2 //1=troca ou 2=devolu��o

        If SF1->( FieldPos("F1_XMOTDEV") ) > 0
            AAdd(aParamBox,{1,"C�digo Motivo Devolu��o",Space(TamSX3("F1_XMOTDEV")[1]),"@!","ExistCpo('U0F',mv_par01)","U0F","",0,.F.}) // Tipo caractere
            While .T.
                If ParamBox(aParamBox,"Motivo de Devolu��o",@aRet,,,,,,,.F.,.F.)
                    cMotivo := aRet[1]
                    AAdd( aCab, { "F1_XMOTDEV", cMotivo, Nil } ) // Motivo de Devolu��o
                EndIf
                If Empty(cMotivo)
                    MsgAlert("Obrigat�rio informar um Motivo de Devolu��o.","Aten��o")
                Else
                    Exit //said do While .T.
                EndIf
            EndDo
        EndIf

        If lMsErroAuto //limpa o cache do MostraErro
            cErroExec := MostraErro("\temp")
            //Conout("============ ERRO LJ720CABEC =============")
            //Conout(cErroExec)
            cErroExec := ""
        EndIf

    //EndIf

Return aCab

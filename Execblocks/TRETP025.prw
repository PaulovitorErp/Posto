#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ720CABEC
Esse ponto de entrada é chamado para a incluisão de campos adicionais no cabeçalho da NF de devolução.

@author Pablo Cavalcante
@since 26/11/2019
@version 1.0
@return lRet

@type function
/*/
User Function TRETP025()

	Local aCab := ParamIxb[1]
    //Local aDocDev := ParamIxb[2] //Array of Record - Armazena a série, número e cliente+loja da NF de devolução e o tipo de operação (1=troca ou 2=devolução)
    Local cMotivo := ""
    Local aRet := {}
    Local aParamBox := {}

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
    //Caso o Posto Inteligente não esteja habilitado não faz nada...
    If !lMvPosto
        Return aCab
    EndIf

    Private lMsErroAuto := .F. // variavel interna da rotina automatica

    //conout(">> TRETP025 -> aDocDev: "+U_toString(aDocDev))
    //>> TRETP025 -> aDocDev: [["1  ", "000003722", "000626", "01", 2, "         ", []]]
    //If len(aDocDev) >= 5 .AND. aDocDev[5] = 2 //1=troca ou 2=devolução

        If SF1->( FieldPos("F1_XMOTDEV") ) > 0
            AAdd(aParamBox,{1,"Código Motivo Devolução",Space(TamSX3("F1_XMOTDEV")[1]),"@!","ExistCpo('U0F',mv_par01)","U0F","",0,.F.}) // Tipo caractere
            While .T.
                If ParamBox(aParamBox,"Motivo de Devolução",@aRet,,,,,,,.F.,.F.)
                    cMotivo := aRet[1]
                    AAdd( aCab, { "F1_XMOTDEV", cMotivo, Nil } ) // Motivo de Devolução
                EndIf
                If Empty(cMotivo)
                    MsgAlert("Obrigatório informar um Motivo de Devolução.","Atenção")
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

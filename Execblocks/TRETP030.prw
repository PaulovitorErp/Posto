#include 'protheus.ch'
#include 'topconn.ch'

/*/{Protheus.doc} TRETP030 (SACI008)
PE executado apos gravar todos os dados da baixa a receber. 
Neste momento todos os registros já foram atualizados e destravados e a contabilizacao efetuada.

@author Danilo Brito
@since 18/07/2014
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETP030()
    
    Local aArea := GetArea()
    Local aAreaSE1 := SE1->(GetArea())
    Local aAreaSE5 := SE5->(GetArea())
    Local lRecibo := SuperGetMv("MV_XRECSE1",,.F.) //habilita impressao recibo apos baixa SE1
    Local lTxAcessor := SuperGetMV("MV_XTXACES",,.F.) //habilita uso de valores acessórios
    Local aParamX 
    Local cQry := ""

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
    //Caso o Posto Inteligente não esteja habilitado não faz nada...
    If !lMvPosto
        Return
    EndIf

    if !isblind()
        if lRecibo .AND. MsgYesNo("Deseja imprimir Recibo?","Atenção")

            aParamX := {SE1->E1_PREFIXO, ;
                        SE1->E1_NUM, ;
                        SE1->E1_PARCELA, ;
                        SE1->E1_TIPO, ;
                        SE1->E1_PREFIXO, ;
                        SE1->E1_NUM, ;
                        SE1->E1_PARCELA, ;
                        SE1->E1_TIPO, ;
                        SE1->E1_EMISSAO, ;
                        SE1->E1_EMISSAO, ;
                        1, ; //segunda via: 1=sim;0=nao
                        SE1->E1_CLIENTE, ;
                        SE1->E1_LOJA, ;
                        SE1->E1_CLIENTE, ;
                        SE1->E1_LOJA ;
                        }
            
            U_TRETR015(aParamX)
            RestArea(aAreaSE1)
        Endif
    endif

    if lTxAcessor .AND. FKC->(FieldPos("FKC_XNATUR")) > 0

        //Busco os valores acessorios na base
        If Select("QRYFKC") > 0
            QRYFKC->(DbCloseArea())
        Endif

        cQry += "SELECT SE5.R_E_C_N_O_ RECNOSE5, FKC.FKC_XNATUR "
        cQry += "FROM "+RetSqlName("SE5")+" SE5 "
        cQry += "INNER JOIN "+RetSqlName("FK6")+" FK6 ON ( "
        cQry += "    FK6.D_E_L_E_T_ = ' ' "
        cQry += "    AND FK6_FILIAL = '"+xFilial("FK6")+"'  "
        cQry += "    AND FK6_RECPAG = SE5.E5_RECPAG "
        cQry += "    AND FK6_IDORIG = SE5.E5_IDORIG "
        cQry += "    AND FK6_TABORI = SE5.E5_TABORI "
        cQry += "    AND FK6_TPDOC = SE5.E5_TIPODOC "
        cQry += "    AND FK6_HISTOR = SE5.E5_HISTOR "
        cQry += ") "
        cQry += "INNER JOIN "+RetSqlName("FKC")+" FKC ON ( "
        cQry += "    FKC.D_E_L_E_T_ = ' ' "
        cQry += "    AND FKC_FILIAL = '"+xFilial("FKC")+"' "
        cQry += "    AND FKC_CODIGO = FK6.FK6_CODVAL "
        cQry += ") "
        cQry += "WHERE SE5.D_E_L_E_T_ = ' ' "
        cQry += "AND SE5.E5_FILIAL = '"+xFilial("SE5")+"' "
        cQry += "AND SE5.E5_PREFIXO = '"+SE1->E1_PREFIXO+"' "
        cQry += "AND SE5.E5_NUMERO = '"+SE1->E1_NUM+"' "
        cQry += "AND SE5.E5_PARCELA = '"+SE1->E1_PARCELA+"' "
        cQry += "AND SE5.E5_TIPO = '"+SE1->E1_TIPO+"' "
        cQry += "AND SE5.E5_CLIFOR = '"+SE1->E1_CLIENTE+"' "
        cQry += "AND SE5.E5_LOJA = '"+SE1->E1_LOJA+"' "
        cQry += "AND SE5.E5_TIPODOC = 'VA' " //valor acessorio
        cQry += "AND SE5.E5_SITUACA <> 'C' " //valor acessorio

        cQry := ChangeQuery(cQry)
        TcQuery cQry NEW Alias "QRYFKC"
        if QRYFKC->(!Eof())
            while QRYFKC->(!Eof())

                if !empty(QRYFKC->FKC_XNATUR)
                    SE5->(DbGoTo(QRYFKC->RECNOSE5))
                    RecLock("SE5", .F.)
                        SE5->E5_NATUREZ := QRYFKC->FKC_XNATUR
                    SE5->(MsUnlock())
                endif

                QRYFKC->(DbSkip())
            enddo
        endif
        QRYFKC->(DbCloseArea())

    endif

    RestArea(aAreaSE5)
    RestArea(aAreaSE1)
    RestArea(aArea)

Return

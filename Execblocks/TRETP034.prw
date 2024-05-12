#include 'protheus.ch'
#include 'topconn.ch'

/*/{Protheus.doc} TRETP034 (SE5FI460)
O ponto de entrada SE5FI460 será utilizado na gravação complementar no SE5, 
pela gravação da baixa do título liquidado.

@type function
@version 12.1.25
@author Pablo
@since 25/05/2021

/*/
User Function TRETP034()

    Local aArea := GetArea()
    Local aAreaSE5 := SE5->(GetArea())
	Local cNumTitulo := ""
    Local lTxAcessor := SuperGetMV("MV_XTXACES",,.F.) //habilita uso de valores acessórios
    Local cQry := ""

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
    //Caso o Posto Inteligente não esteja habilitado não faz nada...
    If !lMvPosto
        Return
    EndIf

    If IsInCallStack("U_TRETE016") .and. Type("__cNumParc") = "C"
        //cNumTitulo := Posicione("FI7",1,xFilial("FI7")+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO+SE5->E5_CLIFOR+SE5->E5_LOJA,"FI7_NUMDES")
        cNumTitulo := __cNumParc
        If !Empty(cNumTitulo)
            RecLock("SE5", .F.)
            SE5->E5_HISTOR := "BX.EMIS.FAT."+cNumTitulo //VALOR BAIXADO P/LIQUIDAÇÃO
            SE5->(MsUnlock())
        EndIf
    EndIf

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
        cQry += "AND SE5.E5_PREFIXO = '"+SE5->E5_PREFIXO+"' "
        cQry += "AND SE5.E5_NUMERO = '"+SE5->E5_NUMERO+"' "
        cQry += "AND SE5.E5_PARCELA = '"+SE5->E5_PARCELA+"' "
        cQry += "AND SE5.E5_TIPO = '"+SE5->E5_TIPO+"' "
        cQry += "AND SE5.E5_CLIFOR = '"+SE5->E5_CLIFOR+"' "
        cQry += "AND SE5.E5_LOJA = '"+SE5->E5_LOJA+"' "
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
    RestArea(aArea)

Return
